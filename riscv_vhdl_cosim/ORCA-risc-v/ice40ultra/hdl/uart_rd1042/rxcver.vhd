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

entity rxcver is
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

end;


architecture design of rxcver is

  component rxcver_fifo
    port(Data        : in  std_logic_vector(10 downto 0);
         Clock       : in  std_logic;
         WrEn        : in  std_logic;
         RdEn        : in  std_logic;
         Reset       : in  std_logic;
         Q           : out std_logic_vector(7 downto 0);
         Q_error     : out std_logic_vector(2 downto 0);
         Empty       : out std_logic;
         Full        : out std_logic;
         AlmostEmpty : out std_logic;
         AlmostFull  : out std_logic
         );
  end component;

  signal databit_recved_num : std_logic_vector(3 downto 0);
  signal rsr                : std_logic_vector(DATAWIDTH-1 downto 0);
  signal rx_parity_err      : std_logic;
  signal rx_frame_err       : std_logic;
  signal rx_idle            : std_logic;
  signal rbr_datardy        : std_logic;
--signal count : std_logic_vector(3 downto 0);
  signal hunt               : std_logic;
  signal hunt_one           : std_logic;
  signal sin_d0             : std_logic;
  signal sin_d1             : std_logic;
  signal rx_frame_err_d1    : std_logic;
  signal rx_idle_d1         : std_logic;
  signal overrun_err_int    : std_logic;
  signal parity_err_int     : std_logic;
  signal frame_err_int      : std_logic;
  signal break_int_int      : std_logic;
  signal sampled_once       : std_logic;
--signal rxclk_en : std_logic;

--signal rbr_fifo : std_logic_vector(7 downto 0);
  signal rbr_fifo_error : std_logic_vector(2 downto 0);

  constant idle   : std_logic_vector(2 downto 0) := "000";
  constant shift  : std_logic_vector(2 downto 0) := "001";
  constant parity : std_logic_vector(2 downto 0) := "010";
  constant stop   : std_logic_vector(2 downto 0) := "011";
  constant idle1  : std_logic_vector(2 downto 0) := "100";

  signal cs_state : std_logic_vector(2 downto 0);

-- constant lat_family : string := "LATTICE_FAMILY";

  signal fifo_full         : std_logic;
  signal fifo_empty_int    : std_logic;
--signal fifo_almost_full : std_logic;
  signal fifo_almost_empty : std_logic;
  signal fifo_din          : std_logic_vector(10 downto 0);
  signal fifo_wr           : std_logic;
  signal fifo_wr_q         : std_logic;
  signal fifo_wr_pulse     : std_logic;

  signal counter      : std_logic_vector(15 downto 0);
  signal divisor_2    : std_logic_vector(15 downto 0);
  signal sin_d0_delay : std_logic;

begin

  fifo_empty <= fifo_empty_int;
  divisor_2  <= '0' & divisor(15 downto 1);  --divide divisor by 2 by shifting on bit to right

-- Generate hunt
  process(clk, reset)
  begin
    if (reset = '1') then
      hunt <= '0';
    elsif rising_edge(clk) then
      if ((cs_state = idle) and (sin_d0 = '0') and (sin_d1 = '1')) then
        --Set Hunt when SIN falling edge is found at the idle state
        hunt <= '1';
      elsif ((sampled_once = '1') and (sin_d0 = '0')) then
        -- Start bit is successfully sampled twice after framing error
        -- set Hunt_r "true" for resynchronizing of next frame
        hunt <= '1';
      elsif ((rx_idle = '0') or (sin_d0 = '1')) then
        hunt <= '0';
      end if;
    end if;
  end process;


-- hunt_one :
--   hunt_one, used for BI flag generation, indicates that there is at
--   least a '1' in the (data + parity + stop) bits of the frame.
--   Break Interrupt flag(BI) is set to '1' whenever the received input
--   is held at the '0' state for all bits in the frame (Start bit +
--   Data bits + Parity bit + Stop bit).  So, as long as hunt_one is still
--   low after all bits are received, BI will be set to '1'.
  process(clk, reset)
  begin
    if (reset = '1') then
      hunt_one <= '0';
    elsif rising_edge(clk) then
      if (hunt = '1') then
        hunt_one <= '0';
      elsif ((rx_idle = '0') and (counter = divisor_2) and (sin_d0 = '1')) then
        hunt_one <= '1';
      end if;
    end if;
  end process;

-- rbr_datardy :
-- This will be set to indicate that the data in rbr is ready for read and
-- will be cleared after rbr is read.
--
  gen_datardy_fifo : if (FIFO = true) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        rbr_datardy <= '0';
      elsif rising_edge(clk) then
        if (fifo_empty_int = '1') then
          -- clear RbrDataRDY when RBR is read by CPU in 450 or FIFO is
          -- empty in 550 mode
          rbr_datardy <= '0';
        elsif (fifo_empty_int = '0') then
          -- set RbrDataRDY at RxIdle_r rising edge
          rbr_datardy <= '1';
        end if;
      end if;
    end process;

  end generate gen_datardy_fifo;

  gen_datardy_nofifo : if (FIFO = false) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        rbr_datardy <= '0';
      elsif rising_edge(clk) then
        if (rbr_rd = '1') then
          -- clear RbrDataRDY when RBR is read by CPU in 450 or FIFO is
          -- empty in 550 mode
          rbr_datardy <= '0';
        elsif ((rx_idle = '1') and (rx_idle_d1 = '0')) then
          -- set RbrDataRDY at RxIdle_r rising edge
          rbr_datardy <= '1';
        end if;
      end if;
    end process;

  end generate gen_datardy_nofifo;


-- sampled_once :
--   This will be set for one clk clock after a framing error occurs not
--   because of BREAK and a low sin signal is sampled by the clk right
--   after the sample time of the Stop bit which causes the framing error.
  process(clk, reset)
  begin
    if (reset = '1') then
      sampled_once <= '0';
    elsif rising_edge(clk) then
      if ((rx_frame_err = '1') and (rx_frame_err_d1 = '0') and (sin_d0 = '0') and (hunt_one = '1')) then
        -- Start bit got sampled once
        sampled_once <= '1';
      else
        sampled_once <= '0';
      end if;
    end if;
  end process;

-- rx_idle Flag
  process(clk, reset)
  begin
    if (reset = '1') then
      rx_idle <= '1';
    elsif rising_edge(clk) then
      if (cs_state = idle) then
        rx_idle <= '1';
      else
        rx_idle <= '0';
      end if;
    end if;
  end process;

--///////////////////////////////////////////////////////////////////////////////
-- Receiver Finite State Machine
--//////////////////////////////////////////////////////////////////////////////
--  rx_parity_err:
--               rx_parity_err is a dynamic Parity Error indicator which is
--               initialized to 0 for even parity and 1 for odd parity.
--               For odd parity, if there are odd number of '1's in the
--               (data + parity) bits, the XOR will bring rx_parity_err back to 0
--               which means no parity error, otherwise rx_parity_err will be 1 to
--               indicate a parity error.
-- parity_stick='1' means Stick Parity is enabled.  In this case,
--               the accumulated dynamic rx_parity_err result will be ignored.  A new
--               value will be assigned to rx_parity_err based on the even/odd parity
--               mode setting and the sin sampled in parity bit.
--                  parity_even='0'(odd parity):
--                     sin needs to be '1', otherwise it's a stick parity error.
--                  parity_even='1'(even parity):
--                     sin needs to be '0', otherwise it's a stick parity error.
  process(clk, reset)
  begin
    if (reset = '1') then
      rsr                <= (others => '0');
      databit_recved_num <= "0000";
      rx_parity_err      <= '1';
      rx_frame_err       <= '0';
      cs_state           <= idle;
      counter            <= "0000000000000000";
    elsif rising_edge(clk) then
      case cs_state is
        when idle =>
          if ((sin_d0 = '0') and (sin_d0_delay = '1')) then
            cs_state <= idle1;
          end if;
          counter <= divisor - '1';
        when idle1 =>
          if (counter = divisor_2) then
            if (sin_d0 = '1') then
              cs_state <= idle;
            else
              rsr                <= (others => '0');
              databit_recved_num <= "0000";
              rx_parity_err      <= not(parity_even);
              rx_frame_err       <= '0';
            end if;
          end if;

          if (counter = "0000000000000001") then
            cs_state <= shift;
            counter  <= divisor;
          else
            counter <= counter - '1';
          end if;
        when shift =>
          if (counter = divisor_2) then
            rsr                <= sin_d0 & rsr(7 downto 1);
            rx_parity_err      <= rx_parity_err xor sin_d0;
            databit_recved_num <= databit_recved_num + '1';
          end if;

          if (counter = "0000000000000001") then
            if (((databits = "00") and (databit_recved_num = "0101")) or
                ((databits = "01") and (databit_recved_num = "0110")) or
                ((databits = "10") and (databit_recved_num = "0111")) or
                ((databits = "11") and (databit_recved_num = "1000"))) then
              if (parity_en = '0') then
                cs_state <= stop;
              else
                cs_state <= parity;
              end if;
            end if;
            counter <= divisor;
          else
            counter <= counter - '1';
          end if;
        when parity =>
          if (counter = divisor_2) then
            if (parity_stick = '0') then
              rx_parity_err <= rx_parity_err xor sin_d0;
            else
              if (parity_even = '0') then
                rx_parity_err <= not(sin_d0);
              else
                rx_parity_err <= sin_d0;
              end if;
            end if;
          end if;

          if (counter = "0000000000000001") then
            cs_state <= stop;
            counter  <= divisor;
          else
            counter <= counter - '1';
          end if;
        when stop =>
          if (counter = divisor_2) then
                                        -- The Receiver checks the 1st Stopbit only regardless of the number
                                        -- of Stop bits selected.
                                        -- Stop bit needs to be '1', otherwise it's a Framing error
            rx_frame_err <= not(sin_d0);
            cs_state     <= idle;
          end if;
          counter <= counter - '1';
        when others => cs_state <= idle;
      end case;
    end if;
  end process;


--************************************************************8
-- Receiver Buffer Register
--************************************************************8
  gen_rxbuf_fifo : if (FIFO = true) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        fifo_din <= (others => '0');
        fifo_wr  <= '0';
      elsif rising_edge(clk) then
        if ((rx_idle = '1') and (rx_idle_d1 = '0')) then
          if (break_int_int = '1') then
            fifo_din <= "00000000100";
            fifo_wr  <= '1';
            --end if;
          else
            case databits is
              when "00"   => fifo_din <= "000" & rsr(7 downto 3) & "0" & parity_err_int & frame_err_int;
              when "01"   => fifo_din <= "00" & rsr(7 downto 2) & "0" & parity_err_int & frame_err_int;
              when "10"   => fifo_din <= "0" & rsr(7 downto 1) & "0" & parity_err_int & frame_err_int;
              when others => fifo_din <= rsr & "0" & parity_err_int & frame_err_int;
            end case;
            fifo_wr <= '1';
          end if;
        else
          fifo_wr <= '0';
        end if;
      end if;
    end process;

    process(clk, reset)
    begin
      if (reset = '1') then
        fifo_wr_q <= '0';
      elsif rising_edge(clk) then
        fifo_wr_q <= fifo_wr;
      end if;
    end process;

    fifo_wr_pulse <= fifo_wr and not(fifo_wr_q);

    RX_FIFO : rxcver_fifo port map(
      Data        => fifo_din,
      Clock       => clk,
      WrEn        => fifo_wr_pulse,
      RdEn        => rbr_rd,
      Reset       => reset,
      Q           => rbr_fifo,
      Q_error     => rbr_fifo_error,
      Empty       => fifo_empty_int,
      Full        => fifo_full,
      AlmostEmpty => fifo_almost_empty,
      AlmostFull  => fifo_almost_full);

  end generate gen_rxbuf_fifo;


  gen_rxbuf_nofifo : if (FIFO = false) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        rbr <= (others => '0');
      elsif rising_edge(clk) then
        if ((rx_idle = '1') and (rx_idle_d1 = '0')) then
          case databits is
            when "00"   => rbr <= "000" & rsr(7 downto 3);
            when "01"   => rbr <= "00" & rsr(7 downto 2);
            when "10"   => rbr <= "0" & rsr(7 downto 1);
            when others => rbr <= rsr;
          end case;
        end if;
      end if;
    end process;


  end generate gen_rxbuf_nofifo;



--////////////////////////////////////////////////////////////////////////////////
--// Delayed Signals for edge detections
--////////////////////////////////////////////////////////////////////////////////
  process(clk, reset)
  begin
    if (reset = '1') then
      sin_d0       <= '0';
      sin_d0_delay <= '0';
    elsif rising_edge(clk) then
      -- sin_d0 : Signal for rising edge detection of signal sin
      -- must be registered before using with sin_d1, 
      -- since sin is ASYNCHRONOUS!!! to the system clock
      sin_d0       <= sin;
      sin_d0_delay <= sin_d0;
    end if;
  end process;

  process(clk, reset)
  begin
    if (reset = '1') then
      sin_d1          <= '0';
      rx_frame_err_d1 <= '1';
    elsif rising_edge(clk) then
      -- sin_d1 : Signal for falling edge detection of signal SIN
      sin_d1          <= sin_d0;
      -- rx_frame_err_d1 :
      -- a delayed version of rx_frame_err for detacting the rising edge
      -- used to resynchronize the next frame after framing error
      rx_frame_err_d1 <= rx_frame_err;
    end if;
  end process;

  process(clk, reset)
  begin
    if (reset = '1') then
      rx_idle_d1 <= '1';
    elsif rising_edge(clk) then
      -- rx_idle_d1 : Signal for rising edge detection of signal rx_idle
      rx_idle_d1 <= rx_idle;
    end if;
  end process;


  --////////////////////////////////////////////////////////////////////////////////
  --// Generate Error Flags
  --////////////////////////////////////////////////////////////////////////////////

  --// Receiver Error Flags in lsr
  --//   overrun_err(OE), parity_err(PE), frame_err(FE), break_int(BI)
  --//   will be set to reflect the sin line status only after the whole frame
  --//   (Start bit + Data bits + Parity bit + Stop bit) is received.  A rising
  --//   edge of rx_idle indicates the whole frame is received.

  gen_err_flags_fifo : if (FIFO = true) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        parity_err_int <= '0';
        frame_err_int  <= '0';
        break_int_int  <= '0';
      elsif rising_edge(clk) then
        -- Set parity_err flag if rx_parity_err is 1 when Parity enable
        parity_err_int <= rx_parity_err and parity_en;
        -- Set frame_err flag if rx_frame_err is 1(Stop bit is sampled low)
        frame_err_int  <= rx_frame_err;
        -- Set break_int flag if hunt_one is still low
        break_int_int  <= not(hunt_one);
      end if;
    end process;

    process(clk, reset)
    begin
      if (reset = '1') then
        overrun_err_int <= '0';
      elsif rising_edge(clk) then
        if ((fifo_full = '1') and (fifo_wr = '1')) then
          overrun_err_int <= '1';
        elsif (lsr_rd = '1') then
          overrun_err_int <= '0';
        end if;
      end if;
    end process;

    overrun_err <= overrun_err_int;
    parity_err  <= rbr_fifo_error(1);
    frame_err   <= rbr_fifo_error(0);
    break_int   <= rbr_fifo_error(2);
-- Receiver ready for read when data is available in rbr
    rx_rdy      <= rbr_datardy;

  end generate gen_err_flags_fifo;

  gen_err_flags_nofifo : if (FIFO = false) generate

    process(clk, reset)
    begin
      if (reset = '1') then
        overrun_err_int <= '0';
        parity_err_int  <= '0';
        frame_err_int   <= '0';
        break_int_int   <= '0';
      elsif rising_edge(clk) then
        if ((rx_idle = '1') and (rx_idle_d1 = '0')) then  -- update at rxidle rising
          -- Set overrun_err flag if RBR data is still not read by CPU
          overrun_err_int <= rbr_datardy;
          -- Set parity_err flag if rx_parity_err is 1 when Parity enable
          parity_err_int  <= (parity_err_int or rx_parity_err) and parity_en;
          -- Set frame_err flag if rx_frame_err is 1(Stop bit is sampled low)
          frame_err_int   <= frame_err_int or rx_frame_err;
          -- Set break_int flag if hunt_one is still low
          break_int_int   <= break_int_int or not(hunt_one);
        elsif (lsr_rd = '1') then       -- clear when LSR is read
          parity_err_int  <= '0';
          frame_err_int   <= '0';
          overrun_err_int <= '0';
          break_int_int   <= '0';
        end if;
      end if;
    end process;

    overrun_err <= overrun_err_int;
    parity_err  <= parity_err_int;
    frame_err   <= frame_err_int;
    break_int   <= break_int_int;
-- Receiver ready for read when data is available in rbr
    rx_rdy      <= rbr_datardy;


  end generate gen_err_flags_nofifo;

end design;



