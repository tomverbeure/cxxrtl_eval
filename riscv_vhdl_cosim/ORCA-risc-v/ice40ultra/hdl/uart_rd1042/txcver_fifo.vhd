--// --------------------------------------------------------------------
--// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
--// --------------------------------------------------------------------
--// Copyright (c) 2001 - 2008 by Lattice Semiconductor Corporation
--// --------------------------------------------------------------------
--//
--// Permission:
--//
--// Lattice Semiconductor grants permission to use this code for use
--// in synthesis for any Lattice programmable logic product. Other
--// use of this code, including the selling or duplication of any
--// portion is strictly prohibited.
--//
--// Disclaimer:
--//
--// This VHDL or Verilog source code is intended as a design reference
--// which illustrates how these types of functions can be implemented.
--// It is the user's responsibility to verify their design for
--// consistency and functionality through the use of formal
--// verification methods. Lattice Semiconductor provides no warranty
--// regarding the use or functionality of this code.
--//
--// --------------------------------------------------------------------
--//
--// Lattice Semiconductor Corporation
--// 5555 NE Moore Court
--// Hillsboro, OR 97214
--// U.S.A
--//
--// TEL: 1-800-Lattice (USA and Canada)
--// 503-268-8001 (other locations)
--//
--// web: http://www.latticesemi.com/
--// email: techsupport@latticesemi.com
--//
--// --------------------------------------------------------------------
--// Code Revision History :
--// --------------------------------------------------------------------
--// Ver: | Author |Mod. Date |Changes Made:
--// V1.0 |        |          | Initial ver
--// V1.1 | S.R.   |18/12/08  | modified to support Mico8
--// --------------------------------------------------------------------
--//`ifndef TXFIFO_FILE
--//`define TXFIFO_FILE
--`include "system_conf.v"
--`include "pmi_fifo.v"
--`timescale 1ns / 10ps
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity txcver_fifo is
  port(
    Data        : in  std_logic_vector(7 downto 0);
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
end txcver_fifo;
--
--module txcver_fifo (Data, Clock, WrEn, RdEn, Reset, Q, Empty, Full,
--                    AlmostEmpty, AlmostFull);

---input [7:0] Data;
---input Clock;
---input WrEn;
---input RdEn;
---input Reset;
---output [7:0] Q;
---output Empty;
---output Full;
---output AlmostEmpty;
---output AlmostFull;
architecture fifo_tx of txcver_fifo is
--
  constant lat_family : string := "XO";
--

--
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
--
-- signal declare
begin
--
  tx_fifo_inst : pmi_fifo
    generic map(
      pmi_data_width        => 8,
      pmi_data_depth        => 16,
      pmi_full_flag         => 16,
      pmi_empty_flag        => 0,
      pmi_almost_full_flag  => 8,
      pmi_almost_empty_flag => 4,
      pmi_regmode           => "noreg",
      pmi_family            => lat_family,
      module_type           => "pmi_fifo",
      pmi_implementation    => "EBR"
      )
    port map (
      Data        => Data ,
      Clock       => Clock ,
      WrEn        => WrEn ,
      RdEn        => RdEn ,
      Reset       => Reset ,
      Q           => Q ,
      Empty       => Empty ,
      Full        => Full ,
      AlmostEmpty => AlmostEmpty ,
      AlmostFull  => AlmostFull
      );
end fifo_tx;

--   parameter              lat_family   = `LATTICE_FAMILY;
--//
--generate
--              if (lat_family == "SC" || lat_family == "SCM")
--              begin
--              pmi_fifo_dc
--                      #(.pmi_data_width_w(8),
--                      .pmi_data_width_r(8),
--                      .pmi_data_depth_w(16),
--                      .pmi_data_depth_r(16),
--                      .pmi_full_flag(16),
--                      .pmi_empty_flag(0),
--                      .pmi_almost_full_flag(8),
--                      .pmi_almost_empty_flag(4),
--                      .pmi_regmode("noreg"),
--                      .pmi_family(`LATTICE_FAMILY),
--                      .module_type("pmi_fifo_dc"),
--            .pmi_implementation("LUT")
--            )
--                      tx_fifo_inst_dc
--                                      (
--            .Data(Data),
--            .WrClock(Clock),
--                                              .RdClock(Clock),
--                                              .WrEn   (WrEn),
--                                              .RdEn   (RdEn),
--                                              .Reset  (Reset),
--                                              .RPReset(Reset),
--                                              .Q      (Q),
--                                              .Empty  (Empty),
--                                              .Full   (Full),
--                                              .AlmostEmpty (AlmostEmpty),
--                                              .AlmostFull (AlmostFull)
--                                              );
--    end
--    else
--    begin
--        pmi_fifo #(
--                 .pmi_data_width(8),
--                 .pmi_data_depth(16),
--                 .pmi_full_flag(16),
--                 .pmi_empty_flag(0),
--                 .pmi_almost_full_flag(8),
--                 .pmi_almost_empty_flag(4),
--                 .pmi_regmode("noreg"),
--                 .pmi_family(`LATTICE_FAMILY),
--                 .module_type("pmi_fifo"),
--                 .pmi_implementation("LUT")
--                 )
--              tx_fifo_inst
--                 (
--                      .Data(Data),
--                  .Clock(Clock),
--                  .WrEn(WrEn),
--                  .RdEn(RdEn),
--                  .Reset(Reset),
--                  .Q(Q),
--                  .Empty(Empty),
--                  .Full(Full),
--                  .AlmostEmpty(AlmostEmpty),
--                  .AlmostFull(AlmostFull)
--                  );
--     end
--endgenerate
--//
--endmodule//`endif
