-- --------------------------------------------------------------------
-- >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
-- --------------------------------------------------------------------
-- Copyright (c) 2001 - 2009 by Lattice Semiconductor Corporation
-- --------------------------------------------------------------------
--
-- Permission:
--
-- Lattice Semiconductor grants permission to use this code for use
-- in synthesis for any Lattice programmable logic product. Other
-- use of this code, including the selling or duplication of any
-- portion is strictly prohibited.
--
-- Disclaimer:
--
-- This VHDL or Verilog source code is intended as a design reference
-- which illustrates how these types of functions can be implemented.
-- It is the user's responsibility to verify their design for
-- consistency and functionality through the use of formal
-- verification methods. Lattice Semiconductor provides no warranty
-- regarding the use or functionality of this code.
--
-- --------------------------------------------------------------------
--
-- Lattice Semiconductor Corporation
-- 5555 NE Moore Court
-- Hillsboro, OR 97214
-- U.S.A
--
-- TEL: 1-800-Lattice (USA and Canada)
-- 503-268-8001 (other locations)
--
-- web: http://www.latticesemi.com/
-- email: techsupport@latticesemi.com
--
-- --------------------------------------------------------------------
-- Code Revision History :
-- --------------------------------------------------------------------
-- Ver: | Author |Mod. Date |Changes Made:
-- V1.0 | K.P.   | 7/09     | Initial ver
--                          | converted from LSC referenec design RD1042
-- V1.1 | Peter  | 8/09                 | Add VHDL design 
-- --------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity intface is
  generic(CLK_IN_MHZ : integer := 25;
          BAUD_RATE  : integer := 115200;
          ADDRWIDTH  : integer := 3;
          DATAWIDTH  : integer := 8;
          MODEM_B    : boolean := true;
          FIFO       : boolean := false);
  port(
    -- Global reset and clock
    reset    : in  std_logic;
    clk      : in  std_logic;
    -- wishbone interface
    adr_i    : in  std_logic_vector(7 downto 0);
    dat_i    : in  std_logic_vector(15 downto 0);
    dat_o    : out std_logic_vector(15 downto 0);
    stb_i    : in  std_logic;
    cyc_i    : in  std_logic;
    we_i     : in  std_logic;
    sel_i    : in  std_logic_vector(3 downto 0);
    bte_i    : in  std_logic_vector(1 downto 0);
    ack_o    : out std_logic;
    intr     : out std_logic;
    -- Registers
    rbr      : in  std_logic_vector(DATAWIDTH-1 downto 0);
    rbr_fifo : in  std_logic_vector(7 downto 0);
    thr      : out std_logic_vector(DATAWIDTH-1 downto 0);
    -- Rising edge of registers read/write strobes
    rbr_rd   : out std_logic;
    thr_wr   : out std_logic;
    lsr_rd   : out std_logic;

    msr_rd : out std_logic;
    msr    : in  std_logic_vector(DATAWIDTH -1 downto 0);
    mcr    : out std_logic_vector(1 downto 0);

    -- Receiver/Transmitter control
    databits         : out std_logic_vector(1 downto 0);
    stopbits         : out std_logic_vector(1 downto 0);
    parity_en        : out std_logic;
    parity_even      : out std_logic;
    parity_stick     : out std_logic;
    tx_break         : out std_logic;
    -- Receiver/Transmitter status
    rx_rdy           : in  std_logic;
    overrun_err      : in  std_logic;
    parity_err       : in  std_logic;
    frame_err        : in  std_logic;
    break_int        : in  std_logic;
    thre             : in  std_logic;
    temt             : in  std_logic;
    fifo_empty       : in  std_logic;
    fifo_empty_thr   : out std_logic;
    thr_rd           : in  std_logic;
    fifo_almost_full : in  std_logic;
    divisor          : out std_logic_vector(15 downto 0)
    );
end;
--
architecture design of intface is
  component txcver_fifo
    port(Data               : in  std_logic_vector(7 downto 0);
                Clock       : in  std_logic;
                WrEn        : in  std_logic;
                RdEn        : in  std_logic;
                Reset       : in  std_logic;
                Q           : out std_logic_vector(7 downto 0);
                Empty       : out std_logic;
                Full        : out std_logic;
                AlmostEmpty : out std_logic;
                AlmostFull  : out std_logic
                );
  end component;

  signal ack_o_int   : std_logic;
  signal data_8bit   : std_logic_vector(DATAWIDTH-1 downto 0);
  signal thr_fifo    : std_logic_vector(DATAWIDTH-1 downto 0);
  signal thr_nonfifo : std_logic_vector(DATAWIDTH-1 downto 0);
  signal lsr         : std_logic_vector(6 downto 0);
  signal lcr         : std_logic_vector(6 downto 0);
  signal iir         : std_logic_vector(3 downto 0);
--
--u1:if ( MODEM_B = true) generate
  signal ier         : std_logic_vector(3 downto 0);
--end generate u1;
--
--if( not MODEM_B ) Generate
--signal ier :std_logic_vector(2 downto 0);
--end Generate;

--if(MODEM_B) Generate
  --mod_stat
  signal modem_stat    : std_logic;
  signal modem_int     : std_logic;
  signal msr_rd_strobe : std_logic;
--signal msr_rd:std_logic;
--end Generate;
---
  signal rx_rdy_int    : std_logic;
  signal thre_int      : std_logic;
  signal dataerr_int   : std_logic;
  signal data_err      : std_logic;

  signal thr_wr_strobe          : std_logic;
  signal rbr_rd_strobe          : std_logic;
  signal iir_rd_strobe          : std_logic;
  signal iir_rd_strobe_delay    : std_logic;
  signal lsr_rd_strobe          : std_logic;
  signal div_wr_strobe          : std_logic;
--signal lsr_rd : std_logic;
  signal lsr2_r, lsr3_r, lsr4_r : std_logic;

--signal thr_wr : std_logic;
  signal rbr_rd_fifo    : std_logic;
  signal rbr_rd_nonfifo : std_logic;

-- FIFO signals for FIFO mode
  signal fifo_full_thr         : std_logic;
--signal fifo_empty_thr : std_logic;
  signal fifo_almost_full_thr  : std_logic;
  signal fifo_almost_empty_thr : std_logic;
  signal fifo_din_thr          : std_logic_vector(7 downto 0);
--signal fifo_wr_thr : std_logic;
--signal fifo_wr_q_thr : std_logic;
  signal fifo_wr_pulse_thr     : std_logic;

  constant divisor_constant : integer := ((CLK_IN_MHZ*1000*1000)/(BAUD_RATE));

-- changed for mico8 support from 5bit to 3 bit reg_addr
  constant A_RBR : std_logic_vector(2 downto 0) := "000";
  constant A_THR : std_logic_vector(2 downto 0) := "000";
  constant A_IER : std_logic_vector(2 downto 0) := "001";
  constant A_IIR : std_logic_vector(2 downto 0) := "010";
  constant A_LCR : std_logic_vector(2 downto 0) := "011";
  constant A_LSR : std_logic_vector(2 downto 0) := "101";
  constant A_DIV : std_logic_vector(2 downto 0) := "111";
--
--if(MODEM_B) Generate
  constant A_MSR : std_logic_vector(2 downto 0) := "110";
  constant A_MCR : std_logic_vector(2 downto 0) := "100";
--end Generate;
--
  constant idle  : std_logic_vector(2 downto 0) := "000";
  constant int0  : std_logic_vector(2 downto 0) := "001";
  constant int1  : std_logic_vector(2 downto 0) := "010";
  constant int2  : std_logic_vector(2 downto 0) := "011";
  constant int3  : std_logic_vector(2 downto 0) := "100";



  signal cs_state : std_logic_vector(2 downto 0);

begin

  u1 : if(MODEM_B = true) generate
    msr_rd <= msr_rd_strobe;
  end generate u1;
--
  u2 : if (MODEM_B = true) generate
    msr_rd_strobe <= '1' when (adr_i(ADDRWIDTH-1 downto 0) = A_MSR(2 downto 0)) and (cyc_i = '1') and (stb_i = '1') and (we_i = '0') else '0';
--      msr_rd_strobe <= (adr_i(2 downto 0) = "000");-- AND cyc_i AND stb_i AND (not we_i);
  end generate u2;

  gen_thr_fifo : if (FIFO = true) generate

    thr <= thr_fifo;

  end generate gen_thr_fifo;

  gen_thr_nofifo : if (FIFO = false) generate

    thr <= thr_nonfifo;

  end generate gen_thr_nofifo;

  gen_rbr_rd_fifo : if (FIFO = true) generate

    rbr_rd <= rbr_rd_fifo;

  end generate gen_rbr_rd_fifo;

  gen_rbr_rd_nofifo : if (FIFO = false) generate

    rbr_rd <= rbr_rd_nonfifo;

  end generate gen_rbr_rd_nofifo;


-- UART baud 16x clock generator
  process(clk, reset)
  begin
    if (reset = '1') then
      divisor <= CONV_STD_LOGIC_VECTOR(divisor_constant, 16);
    elsif rising_edge(clk) then
      if (div_wr_strobe = '1') then
        divisor <= dat_i(15 downto 0);
      end if;
    end if;
  end process;

  process(clk, reset)
  begin
    if (reset = '1') then
      thr_wr <= '0';
    elsif rising_edge(clk) then
      thr_wr <= thr_wr_strobe;
    end if;
  end process;

  lsr_rd <= lsr_rd_strobe;

  rbr_rd_fifo <= rbr_rd_strobe;

  process(clk, reset)
  begin
    if (reset = '1') then
      rbr_rd_nonfifo <= '0';
    elsif rising_edge(clk) then
      rbr_rd_nonfifo <= rbr_rd_strobe;
    end if;
  end process;



--///////////////////////////////////////////////////////////////////////////////
-- Registers Read/Write Control Signals
--//////////////////////////////////////////////////////////////////////////////

  gen_RegRW_fifo : if (FIFO = true) generate

    thr_wr_strobe <= '1' when ((adr_i(ADDRWIDTH-1 downto 0) = A_THR) and (cyc_i = '1') and (stb_i = '1') and (we_i = '1') and (fifo_full_thr = '0') and (ack_o_int = '0')) else '0';
    rbr_rd_strobe <= '1' when ((adr_i(ADDRWIDTH-1 downto 0) = A_RBR) and (cyc_i = '1') and (stb_i = '1') and (we_i = '0') and (fifo_empty = '0') and (ack_o_int = '0'))    else '0';
    iir_rd_strobe <= '1' when ((adr_i(ADDRWIDTH-1 downto 0) = A_IIR) and (cyc_i = '1') and (stb_i = '1') and (we_i = '0') and (ack_o_int = '0'))                           else '0';
    lsr_rd_strobe <= '1' when ((adr_i(ADDRWIDTH-1 downto 0) = A_LSR) and (cyc_i = '1') and (stb_i = '1') and (we_i = '0') and (ack_o_int = '0'))                           else '0';

  end generate gen_RegRW_fifo;


  gen_RegRW_nofifo : if (FIFO = false) generate

    thr_wr_strobe <= '1' when ((adr_i(ADDRWIDTH-1 downto 0) = A_THR) and (cyc_i = '1') and (stb_i = '1') and (we_i = '1')) else '0';
    rbr_rd_strobe <= '1' when ((adr_i(ADDRWIDTH-1 downto 0) = A_RBR) and (cyc_i = '1') and (stb_i = '1') and (we_i = '0')) else '0';
    iir_rd_strobe <= '1' when ((adr_i(ADDRWIDTH-1 downto 0) = A_IIR) and (cyc_i = '1') and (stb_i = '1') and (we_i = '0')) else '0';
    lsr_rd_strobe <= '1' when ((adr_i(ADDRWIDTH-1 downto 0) = A_LSR) and (cyc_i = '1') and (stb_i = '1') and (we_i = '0')) else '0';

  end generate gen_RegRW_nofifo;

  div_wr_strobe <= '1' when ((adr_i(ADDRWIDTH-1 downto 0) = A_DIV) and (cyc_i = '1') and (stb_i = '1') and (we_i = '1')) else '0';


  gen_data8bit_fifo : if (FIFO = true) generate

    process(cyc_i, stb_i, we_i, adr_i, rbr_fifo, iir, lsr, msr)
    begin
      case adr_i(2 downto 0) is
        when A_RBR  => data_8bit <= rbr_fifo;
        when A_IIR  => data_8bit <= "0000" & iir;
        when A_LSR  => data_8bit <= "0" & lsr;
        when A_MSR  => data_8bit <= msr;
        when others => data_8bit <= "11111111";
      end case;
    end process;

  end generate gen_data8bit_fifo;


  gen_data8bit_nofifo : if (FIFO = false) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        data_8bit <= "11111111";
      elsif rising_edge(clk) then
        if ((cyc_i = '1') and (stb_i = '1') and (we_i = '0')) then
          case adr_i(2 downto 0) is
            when A_RBR  => data_8bit <= rbr;
            when A_IIR  => data_8bit <= "0000" & iir;
            when A_LSR  => data_8bit <= "0" & lsr;
            when A_MSR  => data_8bit <= msr;
            when others => data_8bit <= "11111111";
          end case;
        end if;
      end if;
    end process;

  end generate gen_data8bit_nofifo;

  dat_o <= "00000000" & data_8bit;

  gen_regs_nofifo : if (FIFO = false) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        thr_nonfifo <= (others => '0');
        --if(MODEM_B) Generate
        ier         <= "0000";
        mcr         <= "00";
        --end Generate;
        --
        --if( not MODEM_B) Generate
        --ier <= "000";
        --end Generate;
        --
        lcr         <= "0000000";
      elsif rising_edge(clk) then
        if ((cyc_i = '1') and (stb_i = '1') and (we_i = '1')) then
          case adr_i(2 downto 0) is
            when A_THR  => thr_nonfifo <= dat_i(7 downto 0);
                          --if(MODEM_B) Generate
            when A_IER  => ier         <= dat_i(3 downto 0);
            when A_MCR  => mcr         <= dat_i(1 downto 0);
                          --end Generate;
                          --
                          --if (not MODEM_B ) Generate
                          --when A_IER => ier <= dat_i(2 downto 0);
                          --end Generate;
                          --
            when A_LCR  => lcr         <= dat_i(6 downto 0);
            when others => null;
          end case;
        end if;
      end if;
    end process;

  end generate gen_regs_nofifo;


  gen_regs_fifo : if (FIFO = true) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        --
        --if(MODEM_B) Generate
        ier <= "0000";
        mcr <= "00";
        --end Generate;
        --
        --if( not MODEM_B) generate
        --      ier <= "000";
        --end generate;
        --
        lcr <= "0000000";
      elsif rising_edge(clk) then
        if ((cyc_i = '1') and (stb_i = '1') and (we_i = '1')) then
          case adr_i(2 downto 0) is
            --
            --if(MODEM_B) Generate
            when A_IER  => ier <= dat_i(3 downto 0);
            when A_MCR  => mcr <= dat_i(1 downto 0);
                          --end Generate;
                          --
                          --if (not MODEM_B ) Generate
                          --when A_IER => ier <= dat_i(2 downto 0);
                          --end Generate;
                          --
            when A_LCR  => lcr <= dat_i(6 downto 0);
            when others => null;
          end case;
        end if;
      end if;
    end process;

  end generate gen_regs_fifo;


  gen_txfifo : if (FIFO = true) generate

    fifo_wr_pulse_thr <= thr_wr_strobe;
    fifo_din_thr      <= dat_i(7 downto 0);

    TX_FIFO : txcver_fifo port map(
      Data        => fifo_din_thr,
      Clock       => clk,
      WrEn        => fifo_wr_pulse_thr,
      RdEn        => thr_rd,
      Reset       => reset,
      Q           => thr_fifo,
      Empty       => fifo_empty_thr,
      Full        => fifo_full_thr,
      AlmostEmpty => fifo_almost_empty_thr,
      AlmostFull  => fifo_almost_full_thr);

  end generate gen_txfifo;


--////////////////////////////////////////////////////////////////////////////////
--//  Line Control Register
--////////////////////////////////////////////////////////////////////////////////

--// databits : "00"=5-bit, "01"=6-bit, "10"=7-bit, "11"=8-bit
  databits <= lcr(1 downto 0);

--// stopbits : "00"=1-bit, "01"=1.5-bit(5-bit data), "10"=2-bit(6,7,8-bit data)
  stopbits <= "00" when (lcr(2) = '0') else
              "01" when (lcr(2 downto 0) = "100") else
              "10";

--// parity_en : '0'=Parity Bit Enable, '1'=Parity Bit Disable
  parity_en <= lcr(3);

--// parity_even : '0'=Even Parity Selected, '1'=Odd Parity Selected
  parity_even <= lcr(4);

--// parity_stick : '0'=Stick Parity Disable, '1'=Stick Parity Enable
  parity_stick <= lcr(5);

--// tx_break : '0'=Disable BREAK assertion, '1'=Assert BREAK
  tx_break <= lcr(6);


--////////////////////////////////////////////////////////////////////////////////
--//  Line Status Register
--////////////////////////////////////////////////////////////////////////////////

  gen_lsr_fifo : if (FIFO = true) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        lsr2_r <= '0';
      elsif rising_edge(clk) then
        if (parity_err = '1') then
          lsr2_r <= '1';
        elsif (lsr_rd_strobe = '1') then
          lsr2_r <= '0';
        end if;
      end if;
    end process;

    process(clk, reset)
    begin
      if (reset = '1') then
        lsr3_r <= '0';
      elsif rising_edge(clk) then
        if (frame_err = '1') then
          lsr3_r <= '1';
        elsif (lsr_rd_strobe = '1') then
          lsr3_r <= '0';
        end if;
      end if;
    end process;

    process(clk, reset)
    begin
      if (reset = '1') then
        lsr4_r <= '0';
      elsif rising_edge(clk) then
        if (break_int = '1') then
          lsr4_r <= '1';
        elsif (lsr_rd_strobe = '1') then
          lsr4_r <= '0';
        end if;
      end if;
    end process;

    process(clk)
    begin
      if rising_edge(clk) then
        lsr <= temt & thre & lsr4_r & lsr3_r & lsr2_r & overrun_err & rx_rdy;
      end if;
    end process;

  end generate gen_lsr_fifo;


  gen_lsr_nofifo : if (FIFO = false) generate

    lsr <= temt & thre & break_int & frame_err & parity_err & overrun_err & rx_rdy;

  end generate gen_lsr_nofifo;


--////////////////////////////////////////////////////////////////////////////////
--// Interrupt Arbitrator
--////////////////////////////////////////////////////////////////////////////////

--// Int is the common interrupt line for all internal UART events
  u3 : if(MODEM_B = true) generate
    intr <= rx_rdy_int or thre_int or dataerr_int or modem_int;
  end generate u3;

  u4 : if(not MODEM_B) generate
    intr <= rx_rdy_int or thre_int or dataerr_int;
  end generate u4;
--// Receiving Data Error Flags including Overrun, Parity, Framing and Break

  gen_daterr_fifo : if (FIFO = true) generate

    data_err <= overrun_err or lsr2_r or lsr3_r or lsr4_r;

  end generate gen_daterr_fifo;

  gen_daterr_nofifo : if (FIFO = false) generate

    data_err <= overrun_err or parity_err or frame_err or break_int;

  end generate gen_daterr_nofifo;

  u5 : if (MODEM_B) generate
    modem_stat <= msr(0) or msr(1) or msr(2) or msr(3);
  end generate u5;

  gen_irr_delay_fifo : if (FIFO = true) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        iir_rd_strobe_delay <= '0';
      elsif rising_edge(clk) then
        iir_rd_strobe_delay <= iir_rd_strobe;
      end if;
    end process;

  end generate gen_irr_delay_fifo;


  gen_SM_fifo : if (FIFO = true) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        cs_state <= idle;
      elsif rising_edge(clk) then
        case cs_state is
          when idle =>
            if ((ier(2) = '1') and (data_err = '1')) then
              cs_state <= int0;
            elsif ((ier(0) = '1') and ((fifo_almost_full = '1') or (fifo_empty = '0'))) then
              cs_state <= int1;
            elsif ((ier(1) = '1') and (thre = '1')) then
              cs_state <= int2;
                                        --
              --        u7:if( MODEM_B = true) Generate
            elsif ((ier(3) = '1') and (modem_stat = '1')) then
              cs_state <= int3;
              --        end Generate u7;
                            --
            end if;
          when int0 =>
            if ((lsr_rd_strobe = '1') or (ier(2) = '0')) then
              if ((ier(0) = '1') and ((fifo_almost_full = '1') or (fifo_empty = '0'))) then
                cs_state <= int1;
              else
                cs_state <= idle;
              end if;
            end if;
          when int1 =>
            if ((data_err = '1') and (ier(2) = '1')) then
              cs_state <= int0;
            elsif ((fifo_almost_full = '0') or (ier(0) = '0')) then
              cs_state <= idle;
            end if;
          when int2 =>
            if ((iir_rd_strobe_delay = '1') or (thre = '0') or (ier(1) = '0')) then
              cs_state <= idle;
            end if;
            --
--              u8:     if( MODEM_B = true ) Generate
            --
          when int3 =>
            if ((msr_rd_strobe = '1') or (ier(3) = '0')) then
              cs_state <= idle;
            end if;
            --          end Generate u8;

          when others => cs_state <= idle;
        end case;
      end if;
    end process;

  end generate gen_SM_fifo;

  gen_SM_nofifo : if (FIFO = false) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        cs_state <= idle;
      elsif rising_edge(clk) then
        case cs_state is
          when idle =>
            if ((ier(2) = '1') and (data_err = '1')) then
              cs_state <= int0;
            elsif ((ier(0) = '1') and (rx_rdy = '1')) then
              cs_state <= int1;
            elsif ((ier(1) = '1') and (thre = '1')) then
              cs_state <= int2;
              --u9:if( MODEM_B = true ) Generate
            elsif ((ier(3) = '1') and (modem_stat = '1')) then
              cs_state <= int3;
              --                        end Generate u9;
            end if;
          when int0 =>
            if ((lsr_rd_strobe = '1') or (ier(2) = '0')) then
              if ((ier(0) = '1') and (rx_rdy = '1')) then
                cs_state <= int1;
              else
                cs_state <= idle;
              end if;
            end if;
          when int1 =>
            if ((data_err = '1') and (ier(2) = '1')) then
              cs_state <= int0;
            elsif ((rx_rdy = '0') or (ier(0) = '0')) then
              cs_state <= idle;
            end if;
          when int2 =>
            if ((iir_rd_strobe = '1') or (thre = '0') or (ier(1) = '0')) then
              cs_state <= idle;
            end if;
            --
            --u10:              if( MODEM_B =true ) Generate
          when int3 =>
            if ((msr_rd_strobe = '1') or (ier(3) = '0')) then
              cs_state <= idle;
            end if;
            --          end Generate u10;
          when others => cs_state <= idle;
        end case;
      end if;
    end process;

  end generate gen_SM_nofifo;


--// ACK signal generate
  process(clk, reset)
  begin
    if (reset = '1') then
      ack_o_int <= '0';
    elsif rising_edge(clk) then
      if (ack_o_int = '1') then
        ack_o_int <= '0';
      elsif ((cyc_i = '1') and (stb_i = '1')) then
        ack_o_int <= '1';
      end if;
    end if;
  end process;

  ack_o <= ack_o_int;

--// Set Receiver Line Status Interrupt
  dataerr_int <= '1' when (cs_state = int0) else '0';

--// Set Received Data Available Interrupt
  rx_rdy_int <= '1' when (cs_state = int1) else '0';

--// Set thr Empty Interrupt
  thre_int <= '1' when (cs_state = int2) else '0';

  u11 : if(MODEM_B = true) generate
    modem_int <= '1'when (cs_state = int3)else '0';
  end generate u11;

--// Update IIR
  iir <= "0110" when (cs_state = int0) else
          "0100" when (cs_state = int1) else
          "0010" when (cs_state = int2) else
          --u12:        if( MODEM_B = true)generate
          "0000" when (cs_state = int3) else
          --    end generate u12;
          "0001";


end design;



