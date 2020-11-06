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

entity modem is
  generic (
    DATAWIDTH : integer := 8);    
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
end modem;

architecture translated of modem is


  signal msr_reg     : std_logic_vector(DATAWIDTH - 1 downto 0);
  signal ctsn_d1     : std_logic;
  signal dsrn_d1     : std_logic;
  signal dcdn_d1     : std_logic;
  signal rin_d1      : std_logic;
  signal msr_xhdl1   : std_logic_vector(DATAWIDTH - 1 downto 0);
  signal dtr_n_xhdl2 : std_logic;
  signal rts_n_xhdl3 : std_logic;

begin
  msr         <= msr_xhdl1;
  dtr_n       <= dtr_n_xhdl2;
  rts_n       <= rts_n_xhdl3;
  dtr_n_xhdl2 <= not mcr(0);
  rts_n_xhdl3 <= not mcr(1);
  msr_xhdl1   <= msr_reg;

  process(clk, reset)
  begin
    --WAIT UNTIL (clk'EVENT AND clk = '1') OR (reset'EVENT AND reset = '1');
    if (reset = '1') then
      msr_reg <= (others => '0');
      ctsn_d1 <= '1';
      dsrn_d1 <= '1';
      dcdn_d1 <= '1';
      rin_d1  <= '1';
    elsif rising_edge(clk)then
      ctsn_d1 <= cts_n;
      dsrn_d1 <= dsr_n;
      dcdn_d1 <= dcd_n;
      rin_d1  <= ri_n;
      if (msr_rd = '1') then
        msr_reg <= (others => '0');
      else
        msr_reg(0) <= msr_reg(0) or (ctsn_d1 xor cts_n);
        msr_reg(1) <= msr_reg(1) or (dsrn_d1 xor dsr_n);
        msr_reg(2) <= msr_reg(2) or (not rin_d1 and ri_n);
        msr_reg(3) <= msr_reg(3) or (dcdn_d1 xor dcd_n);
        msr_reg(4) <= not cts_n;
        msr_reg(5) <= not dsr_n;
        msr_reg(6) <= not ri_n;
        msr_reg(7) <= not dcd_n;
      end if;
    end if;
  end process;
end translated;
