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

entity txmitt is
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

end;


architecture design of txmitt is

--component txmitt_fifo
--      port(   Data : in std_logic_vector(10 downto 0);
--                      Clock : in std_logic;
--                      WrEn : in std_logic;
--                      RdEn : in std_logic;
--                      Reset : in std_logic;
--                      Q : out std_logic_vector(7 downto 0);
--                      Q_error : out std_logic_vector(2 downto 0);
--                      Empty : out std_logic;
--                      Full : out std_logic;
--                      AlmostEmpty : out std_logic;
--                      AlmostFull : out std_logic
--      );
--end component;


  signal tx_output      : std_logic;
  signal tsr            : std_logic_vector(DATAWIDTH-1 downto 0);
  signal tx_parity      : std_logic;
  signal thr_empty      : std_logic;
  signal tsr_empty      : std_logic;
--signal tx_in_start_s : std_logic;
  signal tx_in_shift_s  : std_logic;
  signal tx_in_stop_s   : std_logic;
  signal tx_in_shift_s1 : std_logic;    --txin_shift_s delayed 1 clock
  signal tx_in_stop_s1  : std_logic;    --txin_stop_s delayed 1 clock
--signal txclk_ena : std_logic;
--signal txclk_enb : std_logic;
  signal tx_cnt         : std_logic_vector(2 downto 0);
--signal count_v : std_logic_vector(3 downto 0);

  signal thr_rd_int   : std_logic;
  signal thr_rd_delay : std_logic;
  signal last_word    : std_logic;

-- State Machine Definition
  constant start        : std_logic_vector(2 downto 0) := "000";
  constant shift        : std_logic_vector(2 downto 0) := "001";
  constant parity       : std_logic_vector(2 downto 0) := "010";
  constant stop_1bit    : std_logic_vector(2 downto 0) := "011";
  constant stop_2bit    : std_logic_vector(2 downto 0) := "100";
  constant stop_halfbit : std_logic_vector(2 downto 0) := "101";
  constant start1       : std_logic_vector(2 downto 0) := "110";

  signal tx_state : std_logic_vector(2 downto 0);

--constant lat_family : string := "LATTICE_FAMILY";

  signal counter   : std_logic_vector(15 downto 0);
  signal divisor_2 : std_logic_vector(15 downto 0);

begin

  divisor_2 <= '0' & divisor(15 downto 1);  --divide divisor by 2 by shifting on bit to right

  gen_fifo_wr : if (FIFO = true) generate

-- Generate Single cycle THR FIFO read signal
    process(clk, reset)
    begin
      if (reset = '1') then
        thr_rd_delay <= '0';
      elsif rising_edge(clk) then
        thr_rd_delay <= thr_rd_int;
      end if;
    end process;

    thr_rd <= thr_rd_int and not(thr_rd_delay);


  end generate gen_fifo_wr;


--///////////////////////////////////////////////////////////////////////////////
-- Transmitter Finite State Machine
--//////////////////////////////////////////////////////////////////////////////

  gen_SM_fifo : if (FIFO = true) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        thr_rd_int <= '0';
      elsif rising_edge(clk) then
        if ((tx_state = start) and (fifo_empty_thr = '0') and (thr_rd_int = '0')) then
          thr_rd_int <= '1';
        elsif (tx_state = shift) then
          thr_rd_int <= '0';
        end if;
      end if;
    end process;


    process(clk, reset)
    begin
      if (reset = '1') then
        tx_cnt    <= (others => '0');
        tsr       <= (others => '0');
        tx_output <= '1';
        tx_parity <= '1';
        tx_state  <= start;
        last_word <= '0';
        counter   <= "0000000000000000";
      elsif rising_edge(clk) then
        case tx_state is
          when start =>
            if (thr_rd_delay = '1') then
              tx_state <= start1;
            end if;
          when start1 =>
            if (last_word = '1') then
              last_word <= '0';
            end if;
            if (counter = "0000000000000000") then
              counter <= divisor;
            else
              if (counter = "0000000000000001") then
                counter   <= (others => '0');
                tx_state  <= shift;
                tx_parity <= not(parity_even);  -- TxParity initialization
                tx_cnt    <= (others => '0');
                tsr       <= thr;
              else
                counter <= counter - '1';
              end if;
            end if;
            tx_output <= '0';
          when shift =>
            tx_output <= tsr(0);
            if (counter = "0000000000000000") then
              counter <= divisor;
            else
              if (counter = "0000000000000001") then
                tx_parity <= tx_parity xor tsr(0);
                counter   <= (others => '0');
                tsr       <= '0' & tsr(7 downto 1);
                tx_cnt    <= tx_cnt + '1';
                if (((databits = "00") and (tx_cnt = "100")) or
                    ((databits = "01") and (tx_cnt = "101")) or
                    ((databits = "10") and (tx_cnt = "110")) or
                    ((databits = "11") and (tx_cnt = "111"))) then
                  if (parity_en = '1') then
                    tx_state <= parity;
                  else
                    tx_state <= stop_1bit;
                  end if;
                end if;
              else
                counter <= counter - '1';
              end if;
            end if;
          when parity =>
            if (counter = "0000000000000000") then
              counter <= divisor;
            else
              if (counter = "0000000000000001") then
                counter  <= (others => '0');
                tx_state <= stop_1bit;
              else
                counter <= counter - '1';
              end if;
            end if;
            if (parity_stick = '1') then
              tx_output <= not(parity_even);
            else
              tx_output <= tx_parity;
            end if;
          when stop_1bit =>
            if (counter = "0000000000000000") then
              counter <= divisor;
            else
              if (counter = "0000000000000001") then
                counter <= (others => '0');
                if (fifo_empty_thr = '1') then
                  last_word <= '1';
                end if;
                if (stopbits = "00") then     -- 1 stop bit
                  tx_state <= start;
                elsif (stopbits = "01") then  -- 1.5 stop bits(for 5-bit data only)
                  tx_state <= stop_halfbit;
                else
                  tx_state <= stop_2bit;  -- 2 stop bits(for 6,7,8-bit data)
                end if;
              else
                counter <= counter - '1';
              end if;
            end if;
            tx_output <= '1';
          when stop_2bit =>
            if (counter = "0000000000000000") then
              counter <= divisor;
            else
              if (counter = "0000000000000001") then
                counter  <= (others => '0');
                tx_state <= start;
              else
                counter <= counter - '1';
              end if;
            end if;
            tx_output <= '1';
          when stop_halfbit =>
            if (counter = "0000000000000000") then
              counter <= divisor_2;
            else
              if (counter = "0000000000000001") then
                counter  <= (others => '0');
                tx_state <= start;
              else
                counter <= counter - '1';
              end if;
            end if;
            tx_output <= '1';
          when others => tx_state <= start;
        end case;
      end if;
    end process;

  end generate gen_SM_fifo;


  gen_SM_nofifo : if (FIFO = false) generate


    process(clk, reset)
    begin
      if (reset = '1') then
        tx_cnt    <= (others => '0');
        tsr       <= (others => '0');
        tx_output <= '1';
        tx_parity <= '1';
        tx_state  <= start;
        last_word <= '0';
        counter   <= "0000000000000000";
      elsif rising_edge(clk) then
        case tx_state is
          when start =>
            if (thr_empty = '0') then
              tx_state <= start1;
            end if;
          when start1 =>
            if (counter = "0000000000000000") then
              counter <= divisor;
            else
              if (counter = "0000000000000001") then
                counter   <= (others => '0');
                tx_state  <= shift;
                tx_parity <= not(parity_even);  -- TxParity initialization
                tx_cnt    <= (others => '0');
                tsr       <= thr;
              else
                counter <= counter - '1';
              end if;
            end if;
            tx_output <= '0';
          when shift =>
            tx_output <= tsr(0);
            if (counter = "0000000000000000") then
              counter <= divisor;
            else
              if (counter = "0000000000000001") then
                tx_parity <= tx_parity xor tsr(0);
                counter   <= (others => '0');
                tsr       <= '0' & tsr(7 downto 1);
                tx_cnt    <= tx_cnt + '1';
                if (((databits = "00") and (tx_cnt = "100")) or
                    ((databits = "01") and (tx_cnt = "101")) or
                    ((databits = "10") and (tx_cnt = "110")) or
                    ((databits = "11") and (tx_cnt = "111"))) then
                  if (parity_en = '1') then
                    tx_state <= parity;
                  else
                    tx_state <= stop_1bit;
                  end if;
                end if;
              else
                counter <= counter - '1';
              end if;
            end if;
          when parity =>
            if (counter = "0000000000000000") then
              counter <= divisor;
            else
              if (counter = "0000000000000001") then
                counter  <= (others => '0');
                tx_state <= stop_1bit;
              else
                counter <= counter - '1';
              end if;
            end if;
            if (parity_stick = '1') then
              tx_output <= not(parity_even);
            else
              tx_output <= tx_parity;
            end if;
          when stop_1bit =>
            if (counter = "0000000000000000") then
              counter <= divisor;
            else
              if (counter = "0000000000000001") then
                counter <= (others => '0');
                if (stopbits = "00") then     -- 1 stop bit
                  tx_state <= start;
                elsif (stopbits = "01") then  -- 1.5 stop bits(for 5-bit data only)
                  tx_state <= stop_halfbit;
                else
                  tx_state <= stop_2bit;  -- 2 stop bits(for 6,7,8-bit data)
                end if;
              else
                counter <= counter - '1';
              end if;
            end if;
            tx_output <= '1';
          when stop_2bit =>
            if (counter = "0000000000000000") then
              counter <= divisor;
            else
              if (counter = "0000000000000001") then
                counter  <= (others => '0');
                tx_state <= start;
              else
                counter <= counter - '1';
              end if;
            end if;
            tx_output <= '1';
          when stop_halfbit =>
            if (counter = "0000000000000000") then
              counter <= divisor_2;
            else
              if (counter = "0000000000000001") then
                counter  <= (others => '0');
                tx_state <= start;
              else
                counter <= counter - '1';
              end if;
            end if;
            tx_output <= '1';
          when others => tx_state <= start;
        end case;
      end if;
    end process;

  end generate gen_SM_nofifo;



--************************************************************8
-- Generate tsr_empty and thr_empty signals
--************************************************************8

-- tsr_empty : will be set whenever tsr is empty

  gen_emptys_fifo : if (FIFO = true) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        tsr_empty <= '1';
      elsif rising_edge(clk) then
        if ((tx_in_stop_s = '0') and (tx_in_stop_s1 = '1') and (last_word = '1')) then
          tsr_empty <= '1';  -- Set TsrEmpty flag to '1' when StopBit(s) is all transmitted 
        elsif ((tx_in_shift_s = '1') and (tx_in_shift_s1 = '0')) then
          tsr_empty <= '0';  -- Reset TsrEmpty flag to '0' when data is transferred from THR to TSR
        end if;
      end if;
    end process;

    process(clk, reset)
    begin
      if (reset = '1') then
        thr_empty <= '1';
      elsif rising_edge(clk) then
        if (thr_wr = '1') then
          thr_empty <= '0';  -- Reset ThrEmpty flag to '0' when data is written into THR by CPU   
        elsif ((fifo_empty_thr = '1') and (tx_in_shift_s = '1') and (tx_in_shift_s1 = '0')) then
          thr_empty <= '1';  -- Set ThrEmpty flag to '1' THR FIFO is empty
        end if;
      end if;
    end process;

  end generate gen_emptys_fifo;


  gen_emptys_nofifo : if (FIFO = false) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        tsr_empty <= '1';
      elsif rising_edge(clk) then
        if ((tx_in_stop_s = '0') and (tx_in_stop_s1 = '1')) then
          tsr_empty <= '1';  -- Set TsrEmpty flag to '1' when StopBit(s) is all transmitted 
        elsif ((tx_in_shift_s = '1') and (tx_in_shift_s1 = '0')) then
          tsr_empty <= '0';  -- Reset TsrEmpty flag to '0' when data is transferred from THR to TSR
        end if;
      end if;
    end process;

    process(clk, reset)
    begin
      if (reset = '1') then
        thr_empty <= '1';
      elsif rising_edge(clk) then
        if (thr_wr = '1') then
          thr_empty <= '0';  -- Reset ThrEmpty flag to '0' when data is written into THR by CPU   
        elsif ((tx_in_shift_s = '1') and (tx_in_shift_s1 = '0')) then
          thr_empty <= '1';  -- Set ThrEmpty flag to '1' when data is transferred from THR to TSR
        end if;
      end if;
    end process;

  end generate gen_emptys_nofifo;


--////////////////////////////////////////////////////////////////////////////////
--       // Delayed signals for edge detections
--////////////////////////////////////////////////////////////////////////////////

  process(clk, reset)
  begin
    if (reset = '1') then
      tx_in_shift_s1 <= '0';
      tx_in_stop_s1  <= '0';
    elsif rising_edge(clk) then
      tx_in_shift_s1 <= tx_in_shift_s;
      tx_in_stop_s1  <= tx_in_stop_s;
    end if;
  end process;

--////////////////////////////////////////////////////////////////////////////////
--// Transmitter FSM state indication signals
--////////////////////////////////////////////////////////////////////////////////

--// tx_in_shift_s : will be set whenever transmitter is in shift state
  process(clk, reset)
  begin
    if (reset = '1') then
      tx_in_shift_s <= '0';
    elsif rising_edge(clk) then
      if (tx_state = shift) then
        tx_in_shift_s <= '1';
      else
        tx_in_shift_s <= '0';
      end if;
    end if;
  end process;

--// tx_in_stop_s : will be set whenever transmitter is in stop_1bit state
  process(clk, reset)
  begin
    if (reset = '1') then
      tx_in_stop_s <= '0';
    elsif rising_edge(clk) then
      if (tx_state = stop_1bit) then
        tx_in_stop_s <= '1';
      else
        tx_in_stop_s <= '0';
      end if;
    end if;
  end process;

--////////////////////////////////////////////////////////////////////////////////
--// Generate thre/temt flags
--////////////////////////////////////////////////////////////////////////////////

--// Transmitter Holding Register Empty Indicator
  thre <= thr_empty;

--// Transmitter Empty Indicator is set to '1' whenever thr and tsr are
--// both empty, and reset to '0' when either thr or tsr contain a character
  temt <= '1' when ((thr_empty = '1') and (tsr_empty = '1')) else '0';

--// Serial Data Output
--// If Break Control bit is set to 1, the serial output is forced to Zero
  sout <= '0' when (tx_break = '1') else tx_output;
  
end design;



