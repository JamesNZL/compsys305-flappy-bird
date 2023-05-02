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
        PS2_DAT : inout std_logic

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
            start_xPos : in signed(10 downto 0);
            pixel_row, pixel_column : in signed(9 downto 0);
            red, green, blue, inPixel : out std_logic);
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

    signal vgaClk : std_logic;
    signal paintR, paintG, paintB : std_logic;
    signal birdR, birdG, birdB : std_logic;
    signal obsOneR, obsOneG, obsOneB : std_logic;
    signal obsTwoR, obsTwoG, obsTwoB : std_logic;
    signal reset : std_logic;
    signal vsync : std_logic;
    signal xPos, yPos : signed(9 downto 0);
    signal leftButtonEvent, rightButtonEvent : std_logic;
    signal mouseRow, mouseColumn : signed(9 downto 0);
    signal movementEnable : std_logic := '1';
    signal ObOneDet, ObTwoDet, ObDet : std_logic;
    signal BiDet : std_logic;
    signal BiDied : std_logic := '0';

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
        pixel_column => xPos,
        pixel_row => yPos);

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
        start_xPos => TO_SIGNED(640, 11),
        pixel_row => yPos,
        pixel_column => xPos,
        red => obsOneR,
        green => obsOneG,
        blue => obsOneB,
        inPixel => ObOneDet);

    obstacle_two : obstacle
    port map(
        enable => movementEnable,
        pb1 => pb1,
        clk => vgaClk,
        vert_sync => vsync,
        start_xPos => TO_SIGNED(860, 11),
        pixel_row => yPos,
        pixel_column => xPos,
        red => obsTwoR,
        green => obsTwoG,
        blue => obsTwoB,
        inPixel => ObTwoDet);

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
        pixel_column => xPos,
        pixel_row => yPos,
        red => birdR,
        green => birdG,
        blue => birdB,
        inPixel => BiDet,
        died => BiDied);

    -------------COLLISIONS & DRAWING--------------

    --TODO: Pseudo randomize maybe with linear shift register

    ObDet <= (ObOneDet or ObTwoDet); -- TODO: !!!!!!!!!!! does this need to be inside the process maybe?

    paintScreen : process (vgaClk)
    begin
        if (rising_edge(vgaClk)) then

            -- Painting the sprite
            if (BiDet = '1') then
                paintR <= birdR;
                paintG <= birdG;
                paintB <= birdB;
            elsif (ObDet = '1') then
                paintR <= (obsOneR or obsTwoR); -- TODO: change to support 4 bit colour
                paintG <= (obsOneG or obsTwoG); -- TODO: this needs to be fixed
                paintB <= (obsOneB or obsTwoB);
            else
                paintR <= '0';
                paintG <= '1';
                paintB <= '1';
            end if;

            -- Collision detection
            if (((movementEnable = '1') and (BiDet = '1' nand ObDet = '1') and (BiDied = '0')) or (pb1 = '0')) then
                movementEnable <= '1';
            else
                movementEnable <= '0';
            end if;

        end if;
    end process paintScreen;

    ----------------------------------

end flappy_bird;