-- top_util_pkg.vhd
-- Copyright (C) 2015 VectorBlox Computing, Inc.

-- synthesis library vbx_lib
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library work;

package top_util_pkg is
  --WISHBONE cycle type indicator (CTI)
  constant WB_CTI_CLASSIC            : std_logic_vector(2 downto 0) := "000";
  constant WB_CTI_CONSTANT_BURST     : std_logic_vector(2 downto 0) := "001";
  constant WB_CTI_INCREMENTING_BURST : std_logic_vector(2 downto 0) := "010";
  constant WB_CTI_END_OF_BURST       : std_logic_vector(2 downto 0) := "111";

  --WISHBONE burst type extension
  constant WB_BTE_LINEAR       : std_logic_vector(1 downto 0) := "00";
  constant WB_BTE_4_BEAT_WRAP  : std_logic_vector(1 downto 0) := "01";
  constant WB_BTE_8_BEAT_WRAP  : std_logic_vector(1 downto 0) := "10";
  constant WB_BTE_16_BEAT_WRAP : std_logic_vector(1 downto 0) := "11";

  -- Constant functions for derived constant generation
  function imax (
    constant M : integer;
    constant N : integer)
    return integer;
  function imin (
    constant M : integer;
    constant N : integer)
    return integer;
  function log2(
    constant N : integer)
    return integer;
  function log2_f(
    constant N : integer)
    return integer;

  -- Conversion functions, not constant
  function to_onehot (
    binary_encoded : std_logic_vector)
    return std_logic_vector;
  function replicate_bit (
    input_bit              : std_logic;
    constant RETURN_LENGTH : integer)
    return std_logic_vector;
  function or_slv (
    data_in : std_logic_vector)
    return std_logic;
  function and_slv (
    data_in : std_logic_vector)
    return std_logic;
end package;

package body top_util_pkg is

  function imax(
    constant M : integer;
    constant N : integer)
    return integer is
  begin
    if M < N then
      return N;
    end if;

    return M;
  end imax;

  function imin(
    constant M : integer;
    constant N : integer)
    return integer is
  begin
    if M < N then
      return M;
    end if;

    return N;
  end imin;

  function log2_f(
    constant N : integer)
    return integer is
    variable i : integer := 0;
  begin
    while (2**i <= n) loop
      i := i + 1;
    end loop;
    return i-1;
  end log2_f;

  function log2(
    constant N : integer)
    return integer is
    variable i : integer := 0;
  begin
    while (2**i < n) loop
      i := i + 1;
    end loop;
    return i;
  end log2;

  function to_onehot (
    binary_encoded : std_logic_vector)
    return std_logic_vector is
    variable onehot : std_logic_vector((2**binary_encoded'length)-1 downto 0);
  begin
    onehot                                       := (others => '0');
    onehot(to_integer(unsigned(binary_encoded))) := '1';

    return onehot;
  end to_onehot;
  
  function replicate_bit (
    input_bit              : std_logic;
    constant RETURN_LENGTH : integer)
    return std_logic_vector is
    variable data_out : std_logic_vector(RETURN_LENGTH-1 downto 0);
  begin
    data_out := (others => input_bit);
    return data_out;
  end replicate_bit;
  
  function or_slv (
    data_in : std_logic_vector)
    return std_logic is
    variable data_in_copy : std_logic_vector(data_in'length-1 downto 0);
    variable reduced_or   : std_logic;
  begin
    data_in_copy := data_in;            --Fix alignment/ordering
    reduced_or   := '0';
    for i in data_in_copy'left downto 0 loop
      reduced_or := reduced_or or data_in_copy(i);
    end loop;  -- i

    return reduced_or;
  end or_slv;

  function and_slv (
    data_in : std_logic_vector)
    return std_logic is
    variable data_in_copy : std_logic_vector(data_in'length-1 downto 0);
    variable reduced_and  : std_logic;
  begin
    data_in_copy := data_in;            --Fix alignment/ordering
    reduced_and  := '1';
    for i in data_in_copy'left downto 0 loop
      reduced_and := reduced_and and data_in_copy(i);
    end loop;  -- i

    return reduced_and;
  end and_slv;

end top_util_pkg;
