library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_textio.all;          -- I/O for logic types

library work;
use work.rv_components.all;
use work.utils.all;

library STD;
use STD.textio.all;                     -- basic I/O


entity execute is
  generic(
    REGISTER_SIZE        : positive;
    REGISTER_NAME_SIZE   : positive;
    INSTRUCTION_SIZE     : positive;
    SIGN_EXTENSION_SIZE  : positive;
    RESET_VECTOR         : natural;
    MULTIPLY_ENABLE      : boolean;
    DIVIDE_ENABLE        : boolean;
    SHIFTER_SINGLE_CYCLE : natural range 0 to 2;
    INCLUDE_COUNTERS     : boolean;
    FORWARD_ALU_ONLY     : boolean);
  port(
    clk         : in std_logic;
    reset       : in std_logic;
    valid_input : in std_logic;

    br_taken_in  : in std_logic;
    pc_current   : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction  : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    subseq_instr : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

    rs1_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    rs2_data       : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    sign_extension : in std_logic_vector(SIGN_EXTENSION_SIZE-1 downto 0);

    wb_sel  : buffer std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
    wb_data : buffer std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_en   : buffer std_logic;

    to_host   : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    from_host : in  std_logic_vector(REGISTER_SIZE-1 downto 0);

    branch_pred : out std_logic_vector(REGISTER_SIZE*2+3 -1 downto 0);

    stall_pipeline : buffer std_logic;
--memory-bus
    address        : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    byte_en        : out    std_logic_vector(REGISTER_SIZE/8 -1 downto 0);
    write_en       : out    std_logic;
    read_en        : out    std_logic;
    write_data     : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    read_data      : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    waitrequest    : in     std_logic;
    datavalid      : in     std_logic);
end;

architecture behavioural of execute is

  alias rd : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(11 downto 7);
  alias rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(19 downto 15);
  alias rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is
    instruction(24 downto 20);
  alias opcode : std_logic_vector(4 downto 0) is
    instruction(6 downto 2);

  signal predict_corr    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal predict_corr_en : std_logic;

  constant FORWARD_ONLY_FROM_ALU : boolean := FORWARD_ALU_ONLY;

  -- various writeback sources
  signal br_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal alu_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ld_data_out  : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal upp_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal sys_data_out : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal br_data_en  : std_logic;
  signal alu_data_en : std_logic;
  signal ld_data_en  : std_logic;
  signal upp_data_en : std_logic;
  signal sys_data_en : std_logic;
  signal less_than   : std_logic;
  signal wb_mux      : std_logic_vector(1 downto 0);

  signal alu_stall : std_logic;

  signal br_bad_predict : std_logic;
  signal br_new_pc      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal predict_pc     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal syscall_en     : std_logic;
  signal syscall_target : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal rs1_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal rs2_data_fwd : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal ls_unit_waiting : std_logic;

  signal fwd_sel  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal fwd_data : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal fwd_en   : std_logic;
  signal fwd_mux  : std_logic;


  signal valid_instr  : std_logic;
  signal ld_latch_en  : std_logic;
  signal ld_latch_out : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ld_rd        : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rd_latch     : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  constant ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

  type fwd_mux_t is (ALU_FWD, JAL_FWD, SYS_FWD, NO_FWD);
  signal rs1_mux : fwd_mux_t;
  signal rs2_mux : fwd_mux_t;

  signal finished_instr : std_logic;

  signal illegal_alu_instr : std_logic;

  signal is_branch    : std_logic;
  signal br_taken_out : std_logic;

  constant JAL_OP   : std_logic_vector(4 downto 0) := "11011";
  constant JALR_OP  : std_logic_vector(4 downto 0) := "11001";
  constant LUI_OP   : std_logic_vector(4 downto 0) := "01101";
  constant AUIPC_OP : std_logic_vector(4 downto 0) := "00101";
  constant ALU_OP   : std_logic_vector(4 downto 0) := "01100";
  constant ALUI_OP  : std_logic_vector(4 downto 0) := "00100";
  constant CSR_OP   : std_logic_vector(4 downto 0) := "11100";
  constant LD_OP    : std_logic_vector(4 downto 0) := "00000";

  alias ni_rs1 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is subseq_instr(19 downto 15);
  alias ni_rs2 : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) is subseq_instr(24 downto 20);

  signal use_after_load_stall : std_logic;
begin
  valid_instr <= valid_input and not use_after_load_stall;
  -----------------------------------------------------------------------------
  -- REGISTER FORWADING
  -- Knowing the next instruction coming downt the pipeline, we can
  -- generate the mux select bits for the next cycle.
  -- there are several functional units that could generate a writeback. ALU,
  -- JAL, Syscalls,load_stare. the syscall and alu forward directly to the next
  -- instruction. on a load instruction, we don't have enogh time to forward it
  -- directly so we save it into a temporary register.  JAL and JALR always
  -- result in a pipeline flush so we don't have to worry about forwarding the
  -- writeback register. This means that the source register can come either
  -- from the register file if there is no forwarding, the saved register from
  -- a load instruction or from forwarding the csr read or alu instruction.
  --
  -- Note that because the load instruction doesn't directly forward into the
  -- next instruction, we have to watch out for use after load hazards.
  -----------------------------------------------------------------------------
  ALU_ONLY_FWD : if FORWARD_ONLY_FROM_ALU generate
    with rs1_mux select
      rs1_data_fwd <=
      alu_data_out when ALU_FWD,
      rs1_data     when others;
    with rs2_mux select
      rs2_data_fwd <=
      alu_data_out when ALU_FWD,
      rs2_data     when others;
  end generate;

  ALL_FWD : if not FORWARD_ONLY_FROM_ALU generate
    with rs1_mux select
      rs1_data_fwd <=
      sys_data_out when SYS_FWD,
      alu_data_out when ALU_FWD,
      br_data_out  when JAL_FWD,
      rs1_data     when NO_FWD;
    with rs2_mux select
      rs2_data_fwd <=
      sys_data_out when SYS_FWD,
      alu_data_out when ALU_FWD,
      br_data_out  when JAL_FWD,
      rs2_data     when NO_FWD;
  end generate ALL_FWD;

  wb_mux <= "00" when sys_data_en = '1' else
            "01" when ld_data_en = '1' else
            "10" when br_data_en = '1' else
            "11";                       --when alu_data_en = '1'
  with wb_mux select
    wb_data <=
    sys_data_out when "00",
    ld_data_out  when "01",
    br_data_out  when "10",
    alu_data_out when others;

  wb_en  <= sys_data_en or ld_data_en or br_data_en or alu_data_en when wb_sel /= ZERO else '0';
  wb_sel <= rd_latch;

  fwd_data <= sys_data_out when sys_data_en = '1' else
              alu_data_out when alu_data_en = '1' else
              br_data_out;

  stall_pipeline <= (ls_unit_waiting or alu_stall or use_after_load_stall) and valid_input;


  process(clk)
    variable next_instr  : std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    variable current_alu : boolean;
  begin
    if rising_edge(clk) then


      --calculate where the next forward data will go
      current_alu := opcode = LUI_OP or
                     opcode = AUIPC_OP or
                     opcode = ALU_OP or
                     opcode = ALUI_OP;
      if stall_pipeline = '0' then
        if rd = ni_rs1 and rd /= ZERO and valid_instr = '1' then
          if (current_alu) then
            rs1_mux <= ALU_FWD;
          elsif (opcode = JAL_OP or opcode = JALR_OP) and not FORWARD_ONLY_FROM_ALU then
            rs2_mux <= JAL_FWD;
          elsif opcode = CSR_OP and not FORWARD_ONLY_FROM_ALU then
            rs2_mux <= SYS_FWD;
          else
            rs1_mux <= NO_FWD;
          end if;
        else
          rs1_mux <= NO_FWD;
        end if;

        if rd = ni_rs2 and rd /= ZERO and valid_instr = '1' then
          if current_alu then
            rs2_mux <= ALU_FWD;
          elsif (opcode = JAL_OP or opcode = JALR_OP) and not FORWARD_ONLY_FROM_ALU then
            rs2_mux <= JAL_FWD;
          elsif opcode = CSR_OP and not FORWARD_ONLY_FROM_ALU then
            rs2_mux <= SYS_FWD;
          else
            rs2_mux <= NO_FWD;
          end if;
        else
          rs2_mux <= NO_FWD;
        end if;

      end if;

      --save various flip flops for forwarding
      --and writeback
      if ls_unit_waiting = '0' then
        rd_latch <= rd;
      end if;

      use_after_load_stall <= '0';
      if FORWARD_ONLY_FROM_ALU then
        if (ni_rs2 = rd or ni_rs1 = rd) and not current_alu then
          use_after_load_stall <= valid_instr;
        end if;
      else
        if (ni_rs2 = rd or ni_rs1 = rd) and opcode = LD_OP then
          use_after_load_stall <= valid_instr;
        end if;
      end if;

    end if;


  end process;

  alu : component arithmetic_unit
    generic map (
      INSTRUCTION_SIZE     => INSTRUCTION_SIZE,
      REGISTER_SIZE        => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE  => SIGN_EXTENSION_SIZE,
      MULTIPLY_ENABLE      => MULTIPLY_ENABLE,
      DIVIDE_ENABLE        => DIVIDE_ENABLE,
      SHIFTER_SINGLE_CYCLE => SHIFTER_SINGLE_CYCLE)
    port map (
      clk               => clk,
      stall_in          => stall_pipeline,
      valid             => valid_instr,
      rs1_data          => rs1_data_fwd,
      rs2_data          => rs2_data_fwd,
      instruction       => instruction,
      sign_extension    => sign_extension,
      program_counter   => pc_current,
      data_out          => alu_data_out,
      data_enable       => alu_data_en,
      illegal_alu_instr => illegal_alu_instr,
      less_than         => less_than,
      stall_out         => alu_stall);


  branch : entity work.branch_unit(latch_middle)
    generic map (
      REGISTER_SIZE       => REGISTER_SIZE,
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE)
    port map(
      clk            => clk,
      reset          => reset,
      valid          => valid_instr,
      stall          => stall_pipeline,
      rs1_data       => rs1_data_fwd,
      rs2_data       => rs2_data_fwd,
      current_pc     => pc_current,
      br_taken_in    => br_taken_in,
      instr          => instruction,
      less_than      => less_than,
      sign_extension => sign_extension,
      data_out       => br_data_out,
      data_out_en    => br_data_en,
      new_pc         => br_new_pc,
      is_branch      => is_branch,
      br_taken_out   => br_taken_out,
      bad_predict    => br_bad_predict);

  ls_unit : component load_store_unit
    generic map(
      REGISTER_SIZE       => REGISTER_SIZE,
      SIGN_EXTENSION_SIZE => SIGN_EXTENSION_SIZE,
      INSTRUCTION_SIZE    => INSTRUCTION_SIZE)
    port map(
      clk            => clk,
      reset          => reset,
      valid          => valid_instr,
      rs1_data       => rs1_data_fwd,
      rs2_data       => rs2_data_fwd,
      instruction    => instruction,
      sign_extension => sign_extension,
      waiting        => ls_unit_waiting,
      data_out       => ld_data_out,
      data_enable    => ld_data_en,
      --memory bus
      address        => address,
      byte_en        => byte_en,
      write_en       => write_en,
      read_en        => read_en,
      write_data     => write_data,
      read_data      => read_data,
      waitrequest    => waitrequest,
      readvalid      => datavalid);
  process(clk)
  begin
--create delayed versions
  end process;

  syscall : component system_calls
    generic map (
      REGISTER_SIZE    => REGISTER_SIZE,
      INSTRUCTION_SIZE => INSTRUCTION_SIZE,
      RESET_VECTOR     => RESET_VECTOR,
      INCLUDE_COUNTERS => INCLUDE_COUNTERS)
    port map (
      clk            => clk,
      reset          => reset,
      valid          => valid_instr,
      rs1_data       => rs1_data_fwd,
      instruction    => instruction,
      finished_instr => finished_instr,
      wb_data        => sys_data_out,
      wb_en          => sys_data_en,
      to_host        => to_host,
      from_host      => from_host,

      current_pc           => pc_current,
      pc_correction        => syscall_target,
      pc_corr_en           => syscall_en,
      illegal_alu_instr    => illegal_alu_instr,
      use_after_load_stall => '0',
      load_stall           => ls_unit_waiting,
      predict_corr         => predict_corr_en
      );


  finished_instr <= valid_instr and not stall_pipeline;

  predict_corr_en <= syscall_en or br_bad_predict;
  predict_corr    <= br_new_pc  when syscall_en = '0' else syscall_target;
  predict_pc      <= pc_current when rising_edge(clk);

  branch_pred <= branch_pack_signal(predict_pc,       --this pc
                                    predict_corr,     --branch target
                                    br_taken_out,     --taken
                                    predict_corr_en,  --flush
                                    is_branch);       --is_branch
--my_print : process(clk)
--  variable my_line : line;            -- type 'line' comes from textio
--begin
--  if rising_edge(clk) then
--    if valid_instr = '1' then
--      write(my_line, string'("executing pc = "));  -- formatting
--      hwrite(my_line, (pc_current));  -- format type std_logic_vector as hex
--      write(my_line, string'(" instr =  "));       -- formatting
--      hwrite(my_line, (instruction));  -- format type std_logic_vector as hex
--      if ls_unit_waiting = '1' then
--        write(my_line, string'(" stalling"));      -- formatting
--      end if;
--      writeline(output, my_line);     -- write to "output"
--    else
--    --write(my_line, string'("bubble"));  -- formatting
--    --writeline(output, my_line);     -- write to "output"
--    end if;
--  end if;
--end process my_print;

end architecture;
