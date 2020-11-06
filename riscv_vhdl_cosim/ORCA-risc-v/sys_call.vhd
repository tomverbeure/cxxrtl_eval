library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
entity instruction_legal is
  generic (
    INSTRUCTION_SIZE         : positive;
    CHECK_LEGAL_INSTRUCTIONS : boolean);
  port (
    instruction       : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
    illegal_alu_instr : in  std_logic;
    legal             : out std_logic);
end entity;

architecture rtl of instruction_legal is
  alias opcode7 is instruction(6 downto 0);
  alias func3 is instruction(14 downto 12);
begin

  legal <=
    '1' when (CHECK_LEGAL_INSTRUCTIONS = false or
              opcode7 = "0110111" or
              opcode7 = "0010111" or
              opcode7 = "1101111" or
              (opcode7 = "1100111" and func3 = "000") or
              (opcode7 = "1100011" and func3 /= "010" and func3 /= "011") or
              (opcode7 = "0000011" and func3 /= "011" and func3 /= "110" and func3 /= "111") or
              (opcode7 = "0100011" and (func3 = "000" or func3 = "001" or func3 = "010")) or
              opcode7 = "0010011" or
              (opcode7 = "0110011" and not illegal_alu_instr = '1') or
              (opcode7 = "0001111" and instruction(31 downto 28)& instruction(19 downto 13) &instruction(11 downto 7) = x"0000") or
              opcode7 = "1110011") else '0';

end architecture;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity system_calls is

  generic (
    REGISTER_SIZE    : natural;
    INSTRUCTION_SIZE : natural;
    RESET_VECTOR     : natural;
    INCLUDE_COUNTERS : boolean);

  port (
    clk         : in std_logic;
    reset       : in std_logic;
    valid       : in std_logic;
    rs1_data    : in std_logic_vector(REGISTER_SIZE-1 downto 0);
    instruction : in std_logic_vector(INSTRUCTION_SIZE-1 downto 0);

    finished_instr : in std_logic;

    wb_data : out std_logic_vector(REGISTER_SIZE-1 downto 0);
    wb_en   : out std_logic;

    to_host       : out    std_logic_vector(REGISTER_SIZE-1 downto 0);
    from_host     : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    current_pc    : in     std_logic_vector(REGISTER_SIZE-1 downto 0);
    pc_correction : out    std_logic_vector(REGISTER_SIZE -1 downto 0);
    pc_corr_en    : buffer std_logic;

    illegal_alu_instr : in std_logic;

    use_after_load_stall : in std_logic;
    predict_corr         : in std_logic;
    load_stall           : in std_logic);

end entity system_calls;

architecture rtl of system_calls is

  alias csr     : std_logic_vector(11 downto 0) is instruction(31 downto 20);
  alias source  : std_logic_vector(4 downto 0) is instruction(19 downto 15);
  alias zimm    : std_logic_vector(4 downto 0) is instruction(19 downto 15);
  alias func3   : std_logic_vector(2 downto 0) is instruction(14 downto 12);
  alias dest    : std_logic_vector(4 downto 0) is instruction(11 downto 7);
  alias opcode  : std_logic_vector(4 downto 0) is instruction(6 downto 2);
  alias opcode7 : std_logic_vector(6 downto 0) is instruction(6 downto 0);
  alias func7   : std_logic_vector(6 downto 0) is instruction(31 downto 25);

  signal legal_instruction : std_logic;

  signal cycles        : unsigned(63 downto 0);
  signal instr_retired : unsigned(63 downto 0);

  --if INCLUDE_EXTRA_COUNTERS is enabled, then
  --INCLUDE_TIMERS must be enabled
  constant INCLUDE_TIMERS         : boolean := INCLUDE_COUNTERS;
  constant INCLUDE_EXTRA_COUNTERS : boolean := false;

  constant CHECK_LEGAL_INSTRUCTIONS : boolean := true;
  signal use_after_load_stalls      : unsigned(31 downto 0);
  signal jal_instructions           : unsigned(31 downto 0);
  signal jalr_instructions          : unsigned(31 downto 0);
  signal branch_mispredicts         : unsigned(31 downto 0);
  signal other_flush                : unsigned(31 downto 0);
  signal load_stalls                : unsigned(31 downto 0);

  signal mstatus_ie : std_logic;
  constant mtvec    : std_logic_vector(REGISTER_SIZE-1 downto 0) := x"00000200";
  signal mtime      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mtimeh     : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instret    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal instreth   : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal mepc      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mcause    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal mcause_i  : std_logic;
  signal mcause_ex : std_logic_vector(3 downto 0);
  signal mtohost   : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal mstatus : std_logic_vector(REGISTER_SIZE-1 downto 0);

  subtype csr_t is std_logic_vector(11 downto 0);
                                        --CSR constants
                                        --USER
  constant CSR_CYCLE     : csr_t := x"C00";
  constant CSR_TIME      : csr_t := x"C01";
  constant CSR_INSTRET   : csr_t := x"C02";
  constant CSR_CYCLEH    : csr_t := x"C80";
  constant CSR_TIMEH     : csr_t := x"C81";
  constant CSR_INSTRETH  : csr_t := x"C82";
                                        --MACHINE
  constant CSR_MCPUID    : csr_t := X"F00";
  constant CSR_MIMPID    : csr_t := X"F01";
  constant CSR_MHARTID   : csr_t := X"F10";
  constant CSR_MSTATUS   : csr_t := X"300";
  constant CSR_MTVEC     : csr_t := X"301";
  constant CSR_MTDELEG   : csr_t := X"302";
  constant CSR_MIE       : csr_t := X"304";
  constant CSR_MTIMECMP  : csr_t := X"321";
  constant CSR_MTIME     : csr_t := X"701";
  constant CSR_MTIMEH    : csr_t := X"741";
  constant CSR_MSCRATCH  : csr_t := X"340";
  constant CSR_MEPC      : csr_t := X"341";
  constant CSR_MCAUSE    : csr_t := X"342";
  constant CSR_MBADADDR  : csr_t := X"343";
  constant CSR_MIP       : csr_t := X"344";
  constant CSR_MBASE     : csr_t := X"380";
  constant CSR_MBOUND    : csr_t := X"381";
  constant CSR_MIBASE    : csr_t := X"382";
  constant CSR_MIBOUND   : csr_t := X"383";
  constant CSR_MDBASE    : csr_t := X"384";
  constant CSR_MDBOUND   : csr_t := X"385";
  constant CSR_HTIMEW    : csr_t := X"B01";
  constant CSR_HTIMEHW   : csr_t := X"B81";
  constant CSR_MTOHOST   : csr_t := X"780";
  constant CSR_MFROMHOST : csr_t := X"781";

  constant FENCE_I     : std_logic_vector(31 downto 0) := x"0000100F";
  -- EXECPTION CODES
  constant ILLEGAL_I   : std_logic_vector(3 downto 0)  := x"2";
  constant MMODE_ECALL : std_logic_vector(3 downto 0)  := x"B";
  constant UMODE_ECALL : std_logic_vector(3 downto 0)  := x"8";
  constant BREAKPOINT  : std_logic_vector(3 downto 0)  := x"3";

                                        --RESSET VECTORS
  constant SYSTEM_RESET :
    std_logic_vector(REGISTER_SIZE-1 downto 0) := std_logic_vector(to_unsigned(RESET_VECTOR - 16#00#, REGISTER_SIZE));
  constant MACHINE_MODE_TRAP :
    std_logic_vector(REGISTER_SIZE-1 downto 0) := std_logic_vector(to_unsigned(RESET_VECTOR - 16#40#, REGISTER_SIZE));

                                        --func3 constants
  constant CSRRW  : std_logic_vector(2 downto 0) := "001";
  constant CSRRS  : std_logic_vector(2 downto 0) := "010";
  constant CSRRC  : std_logic_vector(2 downto 0) := "011";
  constant CSRRWI : std_logic_vector(2 downto 0) := "101";
  constant CSRRSI : std_logic_vector(2 downto 0) := "110";
  constant CSRRCI : std_logic_vector(2 downto 0) := "111";


--internal signals
  signal csr_read_val  : std_logic_vector(REGISTER_SIZE -1 downto 0);
  signal csr_write_val : std_logic_vector(REGISTER_SIZE -1 downto 0);
  signal bit_sel       : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal ibit_sel      : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal resized_zimm  : std_logic_vector(REGISTER_SIZE-1 downto 0);

  component instruction_legal is
    generic (
      INSTRUCTION_SIZE         : positive;
      CHECK_LEGAL_INSTRUCTIONS : boolean);
    port (
      instruction       : in  std_logic_vector(INSTRUCTION_SIZE-1 downto 0);
      illegal_alu_instr : in  std_logic;
      legal             : out std_logic);
  end component;


begin  -- architecture rtl
  timers_if_gen : if INCLUDE_TIMERS generate
    counter_increment : process (clk, reset) is
    begin  -- process
      if reset = '1' then
        cycles        <= (others => '0');
        instr_retired <= (others => '0');

      elsif rising_edge(clk) then
        cycles <= cycles +1;
        if finished_instr = '1' then
          instr_retired <= instr_retired +1;
        end if;
      end if;
    end process;
  end generate timers_if_gen;
  EXTRA_COUNTERS_GEN : if INCLUDE_EXTRA_COUNTERS generate
    signal saved_opcode : std_logic_vector(4 downto 0);
  begin
    extra_counter_incr : process(clk)
    begin
      if reset = '1' then
        cycles        <= (others => '0');
        instr_retired <= (others => '0');

        use_after_load_stalls <= (others => '0');
        jal_instructions      <= (others => '0');
        jalr_instructions     <= (others => '0');
        branch_mispredicts    <= (others => '0');
        other_flush           <= (others => '0');
        load_stalls           <= (others => '0');

      elsif rising_edge(clk) then
        saved_opcode <= opcode;
        cycles       <= cycles +1;
        if finished_instr = '1' then
          instr_retired <= instr_retired +1;
        end if;
        if predict_corr = '1' then
          if saved_opcode = "11011" then
            jal_instructions <= jal_instructions + 1;
          elsif saved_opcode = "11001" then
            jalr_instructions <= jalr_instructions +1;
          elsif saved_opcode = "11000" then
            branch_mispredicts <= branch_mispredicts +1;
          else
            other_flush <= other_flush +1;
          end if;
        end if;
        if use_after_load_stall = '1' then
          use_after_load_stalls <= use_after_load_stalls + 1;
        end if;
        if load_stall = '1' then
          load_stalls <= load_stalls + 1;
        end if;
      end if;
    end process;
  end generate EXTRA_COUNTERS_GEN;


  mtime                          <= std_logic_vector(cycles(REGISTER_SIZE-1 downto 0));
  mtimeh                         <= std_logic_vector(cycles(63 downto 64-REGISTER_SIZE));
  mstatus(mstatus'left downto 1) <= (others => '0');
  mstatus(0)                     <= mstatus_ie;
  mcause(mcause'left)            <= mcause_i;
  mcause(mcause'left-1 downto 4) <= (others => '0');
  mcause(3 downto 0)             <= mcause_ex;

  instret  <= std_logic_vector(instr_retired(REGISTER_SIZE-1 downto 0));
  instreth <= std_logic_vector(instr_retired(63 downto 64-REGISTER_SIZE));

  -----------------------------------------------------------------------------
  -- different muxes based on different configurations
  -- Extra counters
  -- timers
  -- no timers
  -----------------------------------------------------------------------------
  read_mux_extra : if INCLUDE_EXTRA_COUNTERS generate
    with csr select
      csr_read_val <=
      mtime                                   when CSR_CYCLE,
      mtime                                   when CSR_TIME,
      mtimeh                                  when CSR_CYCLEH,
      mtimeh                                  when CSR_TIMEH,
      mstatus                                 when CSR_MSTATUS,
--      mtvec                                   when CSR_MTVEC,
      mepc                                    when CSR_MEPC,
      mcause                                  when CSR_MCAUSE,
      instret                                 when CSR_INSTRET,
      instreth                                when CSR_INSTRETH,
      std_logic_vector(jal_instructions)      when CSR_MBASE,
      std_logic_vector(jalr_instructions)     when CSR_MBOUND,
      std_logic_vector(branch_mispredicts)    when CSR_MIBASE,
      std_logic_vector(other_flush)           when CSR_MIBOUND,
      std_logic_vector(use_after_load_stalls) when CSR_MDBASE,
      std_logic_vector(load_stalls)           when CSR_MDBOUND,
      (others => '0')                         when others;

  end generate read_mux_extra;
  read_mux_timers : if INCLUDE_TIMERS generate
    with csr select
      csr_read_val <=
      mtime           when CSR_TIME,
      mtime           when CSR_CYCLE,
      mtimeh          when CSR_TIMEH,
      mtimeh          when CSR_CYCLEH,
      instret         when CSR_INSTRET,
      instreth        when CSR_INSTRETH,
      mstatus         when CSR_MSTATUS,
--      mtvec           when CSR_MTVEC,
      mepc            when CSR_MEPC,
      mcause          when CSR_MCAUSE,
      (others => '0') when others;
  end generate read_mux_timers;

  read_mux_notimer : if not INCLUDE_TIMERS and not INCLUDE_EXTRA_COUNTERS generate
    with csr select
      csr_read_val <=
      mstatus         when CSR_MSTATUS,
--      mtvec           when CSR_MTVEC,
      mepc            when CSR_MEPC,
      mcause          when CSR_MCAUSE,
      (others => '0') when others;
  end generate read_mux_notimer;


  bit_sel                                      <= rs1_data;
  ibit_sel(REGISTER_SIZE-1 downto zimm'left+1) <= (others => '0');
  ibit_sel(zimm'left downto 0)                 <= zimm;

  resized_zimm(4 downto 0)                <= zimm;
  resized_zimm(REGISTER_SIZE -1 downto 5) <= (others => '0');

  with func3 select
    csr_write_val <=
    rs1_data                      when CSRRW,
    csr_read_val or bit_sel       when CSRRS,
    csr_read_val and not bit_sel  when CSRRC,
    resized_zimm                  when CSRRWI,
    csr_read_val or ibit_sel      when CSRRSI,
    csr_read_val and not ibit_sel when CSRRCI,
    (others => 'X')               when others;



  output_proc : process(clk) is
  begin
    if rising_edge(clk) then
                                        --writeback to register file
      wb_data    <= csr_read_val;
      pc_corr_en <= '0';
      wb_en      <= '0';
      if valid = '1' then
        if legal_instruction = '0' then
          mcause_i      <= '0';
          mcause_ex     <= ILLEGAL_I;
          pc_corr_en    <= '1';
          pc_correction <= MACHINE_MODE_TRAP;
          mepc          <= current_pc;

        elsif opcode = "11100" then     --SYSTEM OP CODE
          if func3 /= "000" and func3 /= "100" then
            wb_en <= '1';
          end if;

          if zimm & func3 = "00000"&"000" then
            if CSR = x"000" then           --ECALL
              mcause_i      <= '0';
              mcause_ex     <= UMODE_ECALL;
              pc_corr_en    <= '1';
              pc_correction <= MACHINE_MODE_TRAP;
              mepc          <= current_pc;
            elsif CSR = x"001" then        --EBREAK
              mcause_i      <= '0';
              mcause_ex     <= BREAKPOINT;
              pc_corr_en    <= '1';
              pc_correction <= MACHINE_MODE_TRAP;
              mepc          <= current_pc;
            elsif CSR = x"100" then        --ERET
              pc_corr_en    <= '1';
              pc_correction <= mepc;
            end if;
          else
                                           --writeback to CSR
            case CSR is
                                           --read-write registers
              when CSR_MTOHOST =>
                mtohost <= csr_write_val;  --write only register
              when CSR_MEPC =>
                mepc <= csr_write_val;
              when others =>
                null;
            end case;
          end if;
        elsif instruction(31 downto 2) = FENCE_I(31 downto 2) then
          pc_correction <= std_logic_vector(unsigned(current_pc) + 4);
          pc_corr_en    <= '1';
        end if;  --opcode

      end if;  --valid
      if reset = '1' then
        mtohost    <= (others => '0');
        mstatus_ie <= '0';
        mcause_i   <= '0';
        mcause_ex  <= (others => '0');
      end if;  --reset
    end if;  --clk
  end process;

  to_host <= mtohost;



  li : component instruction_legal
    generic map(INSTRUCTION_SIZE         => INSTRUCTION_SIZE,
                CHECK_LEGAL_INSTRUCTIONS => CHECK_LEGAL_INSTRUCTIONS)
    port map(instruction       => instruction,
             illegal_alu_instr => illegal_alu_instr,
             legal             => legal_instruction);


end architecture rtl;
