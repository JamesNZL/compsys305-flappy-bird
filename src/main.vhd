-- Copyright (C) 2018  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details.

-- PROGRAM		"Quartus Prime"
-- VERSION		"Version 18.1.0 Build 625 09/12/2018 SJ Standard Edition"
-- CREATED		"Sat Apr 29 15:09:55 2023"

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity main is
    port (
        clk : in std_logic;
        pb1 : in std_logic;
        pb2 : in std_logic;
        red_out : out std_logic;
        green_out : out std_logic;
        blue_out : out std_logic;
        horiz_sync_out : out std_logic;
        vert_sync_out : out std_logic;
        PS2_CLK : inout std_logic;
        PS2_DAT : inout std_logic;
        HEX1 : out std_logic_vector(6 downto 0);
        HEX0 : out std_logic_vector(6 downto 0)
        );
end main;

architecture flappy_bird of main is

    component vga_sync
        port (
            clock_25Mhz : in std_logic;
            red : in std_logic;
            green : in std_logic;
            blue : in std_logic;
            red_out : out std_logic;
            green_out : out std_logic;
            blue_out : out std_logic;
            horiz_sync_out : out std_logic;
            vert_sync_out : out std_logic;
            pixel_column : out signed(9 downto 0);
            pixel_row : out signed(9 downto 0)
        );
    end component;


    component obstacle is
        port (
            enable, pb1, clk, vert_sync : in std_logic;
            lfsrSeed : in std_logic_vector(8 downto 1);
            start_xPos : in signed(10 downto 0);
            pixel_row, pixel_column : in signed(9 downto 0);
            red, green, blue, inPixel, scoreTick : out std_logic);
    end component;

    component MOUSE
        port (
            clock_25Mhz, reset : in std_logic;
            mouse_data : inout std_logic;
            mouse_clk : inout std_logic;
            left_button, right_button : out std_logic;
            mouse_cursor_row : out signed(9 downto 0);
            mouse_cursor_column : out signed(9 downto 0));
    end component;

    component pll
        port (
            refclk : in std_logic;
            rst : in std_logic;
            outclk_0 : out std_logic;
            locked : out std_logic
        );
    end component;

    component bird
        port (
            enable, pb1, pb2, clk, vert_sync : in std_logic;
            pixel_row, pixel_column : in signed(9 downto 0);
            red, green, blue, inPixel, died : out std_logic);
    end component;

    component scoreCounter is
        port(Clk, Tick : in std_logic;
	    Reset : in std_logic;
        setNextDigit : out std_logic;
	    Q_Out : out std_logic_vector(3 downto 0));
    end component;

    component BCD_to_SevenSeg is
        port (BCD_digit : in std_logic_vector(3 downto 0);
              SevenSeg_out : out std_logic_vector(6 downto 0));
    end component;

    component char_rom is
        PORT(character_address	:	IN STD_LOGIC_VECTOR (5 DOWNTO 0);
		    font_row, font_col	:	IN STD_LOGIC_VECTOR (2 DOWNTO 0);
		    clock				: 	IN STD_LOGIC ;
		    rom_mux_output		:	OUT STD_LOGIC);
    end component;

    signal vgaClk : std_logic;
    signal paintR, paintG, paintB : std_logic;
	 signal scoreR, scoreG, scoreB : std_logic;
    signal birdR, birdG, birdB : std_logic;
    signal obsOneR, obsOneG, obsOneB : std_logic;
    signal obsTwoR, obsTwoG, obsTwoB : std_logic;
    signal reset : std_logic;
    signal vsync : std_logic;
    signal xPixel, yPixel : signed(9 downto 0);
    signal leftButtonEvent, rightButtonEvent : std_logic;
    signal mouseRow, mouseColumn : signed(9 downto 0);
    signal movementEnable : std_logic := '1';
    signal ObOneDet, ObTwoDet, ObDet : std_logic;
    signal ObOneTick, ObTwoTick, tensTick, hundredsTick : std_logic;
    signal scoreOnes, scoreTens : std_logic_vector(3 downto 0);
    signal BiDet : std_logic;
    signal BiDied : std_logic := '0';
	 signal charAddress : std_logic_vector( 5 downto 0);
	 signal fontrow, fontcol : STD_LOGIC_VECTOR (2 DOWNTO 0);
	 signal charOUTPUT : std_logic;


begin

    vert_sync_out <= vsync;
    Reset <= '0';

    vga : vga_sync
    port map(
        clock_25Mhz => vgaClk,
        red => paintR,
        green => paintG,
        blue => paintB,
        red_out => red_out,
        green_out => green_out,
        blue_out => blue_out,
        horiz_sync_out => horiz_sync_out,
        vert_sync_out => vsync,
        pixel_column => xPixel,
        pixel_row => yPixel);
		  
		  
	 score_display : char_rom
	 port map(
	       character_address => charAddress,
		    font_row => fontrow,
			 font_col => fontcol,
		    clock => vgaClk,		
		    rom_mux_output => charOUTPUT);
	 

    mousey_mouse : MOUSE
    port map(
        clock_25Mhz => vgaClk,
        reset => RESET,
        mouse_data => PS2_DAT,
        mouse_clk => PS2_CLK,
        left_button => leftButtonEvent,
        right_button => rightButtonEvent,
        mouse_cursor_row => mouseRow,
        mouse_cursor_column => mouseColumn);

    obstacle_one : obstacle
    port map(
        enable => movementEnable,
        pb1 => pb1,
        clk => vgaClk,
        vert_sync => vsync,
        lfsrSeed => std_logic_vector(xPixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_xPos => TO_SIGNED(640, 11),
        pixel_row => yPixel,
        pixel_column => xPixel,
        red => obsOneR,
        green => obsOneG,
        blue => obsOneB,
        inPixel => ObOneDet,
        scoreTick => ObOneTick);

    obstacle_two : obstacle
    port map(
        enable => movementEnable,
        pb1 => pb1,
        clk => vgaClk,
        vert_sync => vsync,
        lfsrSeed => std_logic_vector(yPixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_xPos => TO_SIGNED(960, 11),
        pixel_row => yPixel,
        pixel_column => xPixel,
        red => obsTwoR,
        green => obsTwoG,
        blue => obsTwoB,
        inPixel => ObTwoDet,
        scoreTick => ObTwoTick);

    scoringOnes : scoreCounter
    port map(
        Clk => vgaClk,
        Tick => (ObOneTick or ObTwoTick),
	    Reset => pb1,
        setNextDigit => tensTick,
	    Q_Out => scoreOnes);

    scoringTens : scoreCounter
    port map(
        Clk => vgaClk,
        Tick => tensTick,
        Reset => pb1,
        setNextDigit => hundredsTick,
        Q_Out => scoreTens);

    ssegOnes : BCD_to_SevenSeg
    port map(
        BCD_digit => scoreOnes,
        SevenSeg_Out => HEX0);

    ssegTens : BCD_to_SevenSeg
    port map(
        BCD_digit => scoreTens,
        SevenSeg_Out => HEX1);

    clock_div : pll
    port map(
        refclk => clk,
        rst => Reset,
        outclk_0 => vgaClk);

    elon : bird
    port map(
        enable => movementEnable,
        pb1 => pb1,
        pb2 => leftButtonEvent,
        clk => vgaClk,
        vert_sync => vsync,
        pixel_column => xPixel,
        pixel_row => yPixel,
        red => birdR,
        green => birdG,
        blue => birdB,
        inPixel => BiDet,
        died => BiDied);

    -------------COLLISIONS--------------

    --TODO: Pseudo randomize maybe with linear shift register

    ObDet <= (ObOneDet or ObTwoDet);

    detectCollisions : process (vgaClk)
    begin
        if rising_edge(vgaClk) then

            if (((movementEnable = '1') and (BiDet = '1' nand ObDet = '1') and (BiDied = '0')) or (pb1 = '0')) then
                movementEnable <= '1';
            else
                movementEnable <= '0';
            end if;

        end if;
    end process detectCollisions;
	 
	 
	 -------------CHAR_ROM-------------
	 charAddress <= "000001";
	 fontrow <= "000";
	 fontcol <= "000";

    ----------------------------------

    -------------DRAWING--------------

    paintScreen : process (vgaClk)
    begin
        if (rising_edge(vgaClk)) then

            if (BiDet = '1') then
                paintR <= birdR;
                paintG <= birdG;
                paintB <= birdB;
			  elsif ((xPixel <= 30 and xPixel >= 10) and (yPixel <= 30 and yPixel >= 30)) then
					 paintR <= charOUTPUT;
					 paintG <= '0';
                paintB <= '0';
					 
            elsif (ObDet = '1') then
                paintR <= (obsOneR or obsTwoR); -- TODO: change to support 4 bit colour
                paintG <= (obsOneG or obsTwoG);
                paintB <= (obsOneB or obsTwoB);
					 
            else
                paintR <= '0';
                paintG <= '1';
                paintB <= '1';

            end if;

        end if;
    end process paintScreen;

    ----------------------------------

    -------------SCORING--------------
                
    ----------------------------------

end flappy_bird;