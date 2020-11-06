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
--
entity uart_core is
  generic(
    CLK_IN_MHZ : integer := 25;
    BAUD_RATE  : integer := 115200;
    ADDRWIDTH  : integer := 3;
    DATAWIDTH  : integer := 8;
    MODEM_B    : boolean := true;
    FIFO       : boolean := false
    );
  port(
-- Global reset and clock
    CLK        : in  std_logic;
    RESET      : in  std_logic;
-- wishbone interface
    UART_ADR_I : in  std_logic_vector(7 downto 0);
    UART_DAT_I : in  std_logic_vector(15 downto 0);
    UART_DAT_O : out std_logic_vector(15 downto 0);
    UART_STB_I : in  std_logic;
    UART_CYC_I : in  std_logic;
    UART_WE_I  : in  std_logic;
    UART_SEL_I : in  std_logic_vector(3 downto 0);
    UART_CTI_I : in  std_logic_vector(2 downto 0);
    UART_BTE_I : in  std_logic_vector(1 downto 0);
    UART_ACK_O : out std_logic;
    INTR       : out std_logic;
-- Receiver interface
    SIN        : in  std_logic;
    RXRDY_N    : out std_logic;
-- Transmitter interface
--Generate --if MODEM

--begin
    DCD_N : in  std_logic;
    CTS_N : in  std_logic;
    DSR_N : in  std_logic;
    RI_N  : in  std_logic;
    DTR_N : out std_logic;
    RTS_N : out std_logic;

--end Generate ;
--
    SOUT    : out std_logic;
    TXRDY_N : out std_logic
    );
end uart_core;

architecture design of uart_core is

  component intface
    generic(CLK_IN_MHZ : integer := 25;
            BAUD_RATE  : integer := 115200;
            ADDRWIDTH  : integer := 3;
            DATAWIDTH  : integer := 8;
            MODEM_B    : boolean := true;
            FIFO       : boolean := false);
    port(
      -- Global reset and clock
      reset            : in  std_logic;
      clk              : in  std_logic;
      -- wishbone interface
      adr_i            : in  std_logic_vector(7 downto 0);
      dat_i            : in  std_logic_vector(15 downto 0);
      dat_o            : out std_logic_vector(15 downto 0);
      stb_i            : in  std_logic;
      cyc_i            : in  std_logic;
      we_i             : in  std_logic;
      sel_i            : in  std_logic_vector(3 downto 0);
      bte_i            : in  std_logic_vector(1 downto 0);
      ack_o            : out std_logic;
      intr             : out std_logic;
      -- Registers
      rbr              : in  std_logic_vector(DATAWIDTH-1 downto 0);
      rbr_fifo         : in  std_logic_vector(7 downto 0);
      thr              : out std_logic_vector(DATAWIDTH-1 downto 0);
      -- Rising edge of registers read/write strobes
      rbr_rd           : out std_logic;
      thr_wr           : out std_logic;
      lsr_rd           : out std_logic;
      -- if (MODEM) Generate
      --begin
      msr_rd           : out std_logic;
      msr              : in  std_logic_vector(DATAWIDTH -1 downto 0);
      mcr              : out std_logic_vector(1 downto 0);
      --end Generate;
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
  end component;

  component rxcver
    generic(DATAWIDTH : integer := 8;
            FIFO      : boolean := false);
    port(
      -- Global reset and clock
      reset            : in  std_logic;
      clk              : in  std_logic;
      -- Register
      rbr              : out std_logic_vector(DATAWIDTH-1 downto 0);
      rbr_fifo         : out std_logic_vector(7 downto 0);
      -- Rising edge of rbr, lsr read strobes
      rbr_rd           : in  std_logic;
      lsr_rd           : in  std_logic;
      -- Receiver input
      sin              : in  std_logic;
      -- Receiver control
      databits         : in  std_logic_vector(1 downto 0);
      parity_en        : in  std_logic;
      parity_even      : in  std_logic;
      parity_stick     : in  std_logic;
      -- Receiver status
      rx_rdy           : out std_logic;
      overrun_err      : out std_logic;
      parity_err       : out std_logic;
      frame_err        : out std_logic;
      break_int        : out std_logic;
      fifo_empty       : out std_logic;
      fifo_almost_full : out std_logic;
      divisor          : in  std_logic_vector(15 downto 0)
      );
  end component;

  component txmitt
    generic(DATAWIDTH : integer := 8;
            FIFO      : boolean := false);
    port(
      -- Global reset and clock
      reset          : in  std_logic;
      clk            : in  std_logic;
      -- Register THR
      thr            : in  std_logic_vector(DATAWIDTH-1 downto 0);
      -- THR write strobe
      thr_wr         : in  std_logic;
      -- Transmitter output
      sout           : out std_logic;
      -- Transmitter control
      databits       : in  std_logic_vector(1 downto 0);
      stopbits       : in  std_logic_vector(1 downto 0);
      parity_en      : in  std_logic;
      parity_even    : in  std_logic;
      parity_stick   : in  std_logic;
      tx_break       : in  std_logic;
      -- Transmitter status
      thre           : out std_logic;
      temt           : out std_logic;
      fifo_empty_thr : in  std_logic;
      thr_rd         : out std_logic;
      divisor        : in  std_logic_vector(15 downto 0)
      );
  end component;

--Modem_new : if(MODEM) Generate
  component modem
    generic(
      DATAWIDTH : integer := 8
      );                                
    port (
      reset  : in  std_logic;
      clk    : in  std_logic;
      msr    : out std_logic_vector(DATAWIDTH - 1 downto 0);
      mcr    : in  std_logic_vector(1 downto 0);
      msr_rd : in  std_logic;
      dcd_n  : in  std_logic;
      cts_n  : in  std_logic;
      dsr_n  : in  std_logic;
      ri_n   : in  std_logic;
      dtr_n  : out std_logic;
      rts_n  : out std_logic
      );
  end component;
--end Generate Modem_new;


  signal RBR_FIFO     : std_logic_vector(7 downto 0);
  signal RBR          : std_logic_vector(DATAWIDTH-1 downto 0);
  signal THR          : std_logic_vector(DATAWIDTH-1 downto 0);
  signal databits     : std_logic_vector(1 downto 0);
  signal stopbits     : std_logic_vector(1 downto 0);
  signal parity_en    : std_logic;
  signal parity_even  : std_logic;
  signal parity_stick : std_logic;
  signal tx_break     : std_logic;
  signal thr_wr       : std_logic;
  signal rbr_rd       : std_logic;
  signal lsr_rd       : std_logic;
  signal rx_rdy       : std_logic;
  signal parity_err   : std_logic;
  signal frame_err    : std_logic;
  signal overrun_err  : std_logic;
  signal break_int    : std_logic;
  signal THRE         : std_logic;
  signal TEMT         : std_logic;

  signal fifo_empty       : std_logic;
  signal fifo_empty_thr   : std_logic;
  signal thr_rd           : std_logic;
  signal fifo_almost_full : std_logic;

  signal divisor : std_logic_vector(15 downto 0);
----
--Modem_new :if(MODEM) generate
  signal msr     : std_logic_vector(DATAWIDTH-1 downto 0);
  signal mcr     : std_logic_vector(1 downto 0);
  signal msr_rd  : std_logic;
--end Generate Modem_new;
--
begin

  u_intface : intface generic map(
    CLK_IN_MHZ => CLK_IN_MHZ,
    BAUD_RATE  => BAUD_RATE,
    ADDRWIDTH  => ADDRWIDTH,
    DATAWIDTH  => DATAWIDTH,
    MODEM_B    => MODEM_B,
    FIFO       => FIFO
    )
    port map (
      reset            => RESET,
      clk              => CLK,
      adr_i            => UART_ADR_I,
      dat_i            => UART_DAT_I,
      dat_o            => UART_DAT_O,
      stb_i            => UART_STB_I,
      cyc_i            => UART_CYC_I,
      we_i             => UART_WE_I,
      sel_i            => UART_SEL_I,
      bte_i            => UART_BTE_I,
      ack_o            => UART_ACK_O,
      intr             => INTR,
      rbr              => RBR,
      rbr_fifo         => RBR_FIFO,
      thr              => THR,
      rbr_rd           => rbr_rd,
      thr_wr           => thr_wr,
      lsr_rd           => lsr_rd,
      --
      --Modem_new: if (MODEM) Generate
      msr_rd           => msr_rd,
      msr              => msr,
      mcr              => mcr,
      --end Generate Modem_new;
      --
      databits         => databits,
      stopbits         => stopbits,
      parity_en        => parity_en,
      parity_even      => parity_even,
      parity_stick     => parity_stick,
      tx_break         => tx_break,
      rx_rdy           => rx_rdy,
      overrun_err      => overrun_err,
      parity_err       => parity_err,
      frame_err        => frame_err,
      break_int        => break_int,
      thre             => THRE,
      temt             => TEMT,
      fifo_empty       => fifo_empty,
      fifo_empty_thr   => fifo_empty_thr,
      thr_rd           => thr_rd,
      fifo_almost_full => fifo_almost_full,
      divisor          => divisor
      );

  u_rxcver : rxcver generic map(
    DATAWIDTH => DATAWIDTH,
    FIFO      => FIFO
    )
    port map (
      reset            => RESET,
      clk              => CLK,
      rbr              => RBR,
      rbr_fifo         => RBR_FIFO,
      rbr_rd           => rbr_rd,
      lsr_rd           => lsr_rd,
      sin              => SIN,
      databits         => databits,
      parity_en        => parity_en,
      parity_even      => parity_even,
      parity_stick     => parity_stick,
      rx_rdy           => rx_rdy,
      overrun_err      => overrun_err,
      parity_err       => parity_err,
      frame_err        => frame_err,
      break_int        => break_int,
      fifo_empty       => fifo_empty,
      fifo_almost_full => fifo_almost_full,
      divisor          => divisor
      );

  u_txmitt : txmitt generic map(
    DATAWIDTH => DATAWIDTH,
    FIFO      => FIFO
    )
    port map (
      reset          => RESET,
      clk            => CLK,
      thr            => THR,
      thr_wr         => thr_wr,
      sout           => SOUT,
      databits       => databits,
      stopbits       => stopbits,
      parity_en      => parity_en,
      parity_even    => parity_even,
      parity_stick   => parity_stick,
      tx_break       => tx_break,
      thre           => THRE,
      temt           => TEMT,
      fifo_empty_thr => fifo_empty_thr,
      thr_rd         => thr_rd,
      divisor        => divisor
      );
--
--Modem_new : if(MODEM) Generate
  u_modem : modem
    generic map(
      DATAWIDTH => DATAWIDTH
      )                         
    port map(
      reset  => reset,
      clk    => clk,
      msr    => msr,
      mcr    => mcr,
      msr_rd => msr_rd,
      dcd_n  => dcd_n,
      cts_n  => cts_n,
      dsr_n  => dsr_n,
      ri_n   => ri_n,
      dtr_n  => DTR_N,
      rts_n  => RTS_N
      );
--end Generate Modem_new;


--// TXRDY_N, RXRDY_N is low active output
  TXRDY_N <= not(THRE);
  RXRDY_N <= not(rx_rdy);
--
--INTR    <= intr;
--SOUT    <= sout;
--  `ifdef MODEM
--DTR_N         <= dtr_n;
--assign #5 RTS_N   = rts_n;
--`endif 
end design;

