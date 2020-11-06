-- --------------------------------------------------------------------
-- >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
-- --------------------------------------------------------------------
-- Copyright (c) 2001 - 2008 by Lattice Semiconductor Corporation
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
-- V1.0 |        |          | Initial ver
-- V1.1 | S.R.   |18/12/08  | modified to support Mico8
-- --------------------------------------------------------------------
--`ifndef RXFIFO_FILE
--`define RXFIFO_FILE
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
--
entity rxcver_fifo is
  port (
    Data        : in  std_logic_vector(10 downto 0);
    Clock       : in  std_logic;
    WrEn        : in  std_logic;
    RdEn        : in  std_logic;
    Reset       : in  std_logic;
    Q           : out std_logic_vector(7 downto 0);
    Q_error     : out std_logic_vector(2 downto 0);
    Empty       : out std_logic;
    Full        : out std_logic;
    AlmostEmpty : out std_logic;
    AlmostFull  : out std_logic);   
end entity rxcver_fifo;

architecture translated of rxcver_fifo is

  type     xhdl_17 is array (15 downto 0) of std_logic_vector(2 downto 0);
  constant lat_family        : string                       := "XO";
  signal   Q_node            : std_logic_vector(7 downto 0);
  signal   fifo              : xhdl_17;
  signal   wr_pointer1       : std_logic_vector(4 downto 0) := "00000";
  signal   rd_pointer1       : std_logic_vector(4 downto 0) := "00000";
  signal   rd_pointer_prev   : std_logic_vector(4 downto 0) := "00000";
  signal   valid_RdEn        : std_logic;
  signal   Q_xhdl1           : std_logic_vector(7 downto 0);
  signal   Q_error_xhdl2     : std_logic_vector(2 downto 0);
  signal   Empty_xhdl3       : std_logic;
  signal   Full_xhdl4        : std_logic;
  signal   AlmostEmpty_xhdl5 : std_logic;
  signal   AlmostFull_xhdl6  : std_logic;

  component pmi_fifo is
    generic (
      pmi_data_width        : integer := 8;
      pmi_data_depth        : integer := 256;
      pmi_full_flag         : integer := 256;
      pmi_empty_flag        : integer := 0;
      pmi_almost_full_flag  : integer := 252;
      pmi_almost_empty_flag : integer := 4;
      pmi_regmode           : string  := "reg";
      pmi_family            : string  := "EC";
      module_type           : string  := "pmi_fifo";
      pmi_implementation    : string  := "EBR"
      );
    port (
      Data        : in  std_logic_vector(pmi_data_width-1 downto 0);
      Clock       : in  std_logic;
      WrEn        : in  std_logic;
      RdEn        : in  std_logic;
      Reset       : in  std_logic;
      Q           : out std_logic_vector(pmi_data_width-1 downto 0);
      Empty       : out std_logic;
      Full        : out std_logic;
      AlmostEmpty : out std_logic;
      AlmostFull  : out std_logic
      );
  end component pmi_fifo;


begin
  Q           <= Q_xhdl1;
  Q_error     <= Q_error_xhdl2;
  Empty       <= Empty_xhdl3;
  Full        <= Full_xhdl4;
  AlmostEmpty <= AlmostEmpty_xhdl5;
  AlmostFull  <= AlmostFull_xhdl6;

  rx_fifo_inst : pmi_fifo
    generic map (
      pmi_family            => lat_family,
      pmi_empty_flag        => 0,
      pmi_data_depth        => 16,
      module_type           => "pmi_fifo",
      pmi_almost_full_flag  => 1,
      pmi_full_flag         => 16,
      pmi_implementation    => "EBR",
      pmi_data_width        => 8,
      pmi_regmode           => "noreg",
      pmi_almost_empty_flag => 0
      )
    port map (
      Data        => Data(10 downto 3),
      Clock       => Clock,
      WrEn        => WrEn,
      RdEn        => RdEn,
      Reset       => Reset,
      Q           => Q_node,
      Empty       => Empty_xhdl3,
      Full        => Full_xhdl4,
      AlmostEmpty => AlmostEmpty_xhdl5,
      AlmostFull  => AlmostFull_xhdl6
      ); 
  process (Clock, Reset)
    variable wr_pointer1_reg     : integer := 0;
    variable rd_pointer_prev_reg : integer := 0;
  begin
    if (Reset = '1') then
      wr_pointer1     <= "00000";
      rd_pointer1     <= "00000";
      valid_RdEn      <= '0';
      rd_pointer_prev <= "00000";
      fifo(0)         <= "000";
      fifo(1)         <= "000";
      fifo(2)         <= "000";
      fifo(3)         <= "000";
      fifo(4)         <= "000";
      fifo(5)         <= "000";
      fifo(6)         <= "000";
      fifo(7)         <= "000";
      fifo(8)         <= "000";
      fifo(9)         <= "000";
      fifo(10)        <= "000";
      fifo(11)        <= "000";
      fifo(12)        <= "000";
      fifo(13)        <= "000";
      fifo(14)        <= "000";
      fifo(15)        <= "000";
    elsif (Clock'event and Clock = '1') then
      if ((WrEn = '1' and RdEn /= '1') and Full_xhdl4 /= '1') then
        wr_pointer1_reg       := conv_integer(wr_pointer1(3 downto 0));
        fifo(wr_pointer1_reg) <= Data(2 downto 0);
        wr_pointer1           <= wr_pointer1 + "00001";
      elsif ((WrEn /= '1' and RdEn = '1') and Empty_xhdl3 /= '1') then
        valid_RdEn      <= '1';
        rd_pointer_prev <= rd_pointer1;
        rd_pointer1     <= rd_pointer1 + "00001";
      elsif (WrEn = '1' and RdEn = '1') then
        rd_pointer_prev       <= rd_pointer1;
        valid_RdEn            <= '1';
        --fifo(integer(wr_pointer1(3 downto 0))) <= Data(2 DOWNTO 0);    
        wr_pointer1_reg       := conv_integer(wr_pointer1(3 downto 0));
        fifo(wr_pointer1_reg) <= Data(2 downto 0);
        --
        rd_pointer1           <= rd_pointer1 + "00001";
        wr_pointer1           <= wr_pointer1 + "00001";
        
      end if;
      --             else
      --               valid_RdEn          <= 1'b0;          

      if (valid_RdEn = '1') then
        rd_pointer_prev_reg       := conv_integer(rd_pointer_prev(3 downto 0));
        fifo(rd_pointer_prev_reg) <= "000";
        valid_RdEn                <= '0';
      end if;
    end if;
  end process;
  -- Data is only valid for single clock cycle after read to the FIFO occurs  
  --    assign   Q = {Q_node, fifo[rd_pointer_prev%16]};
  Q_xhdl1       <= Q_node;
  Q_error_xhdl2 <= fifo(conv_integer(rd_pointer_prev(3 downto 0)));

end architecture translated;
