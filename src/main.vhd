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
            pixel_row, pixel_column : in signed(9 downto 0);
            green, inPixel : out std_logic);--red, green, blue, inPixel : out std_logic);
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
            red, inPixel : out std_logic);--green, blue, inPixel : out std_logic);
    end component;

    signal vgaClk : std_logic;
    signal paintR : std_logic;
    signal paintG : std_logic;
    signal paintB : std_logic;
    signal birdR : std_logic;
    signal birdG : std_logic;
    signal birdB : std_logic;
    signal obsR : std_logic;
    signal obsG : std_logic;
    signal obsB : std_logic;
    signal Reset : std_logic;
    signal VSYNC : std_logic;
    signal xPos : signed(9 downto 0);
    signal yPos : signed(9 downto 0);
    signal LEFTBUTTONevent : std_logic;
    signal RIGHTBUTTONevent : std_logic;
    signal MOUSEROW : signed(9 downto 0);
    signal MOUSECOLUMN : signed(9 downto 0);
    signal movementEnable, OBST1 : std_logic;
    signal ObDet : std_logic;
    signal BiDet : std_logic;

begin

    vert_sync_out <= VSYNC;
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
        vert_sync_out => VSYNC,
        pixel_column => xPos,
        pixel_row => yPos);

    mousey_mouse : MOUSE
    port map(
        clock_25Mhz => vgaClk,
        reset => RESET,
        mouse_data => PS2_DAT,
        mouse_clk => PS2_CLK,
        left_button => LEFTBUTTONevent,
        right_button => RIGHTBUTTONevent,
        mouse_cursor_row => MOUSEROW,
        mouse_cursor_column => MOUSECOLUMN);

    obstacle_one : obstacle
    port map(
        enable => movementEnable,
        pb1 => pb1,
        clk => vgaClk,
        vert_sync => VSYNC,
        pixel_row => yPos,
        pixel_column => xPos,
        --red => obsR,
        green => paintG,
        inPixel => ObDet);--obsG),
    --blue => obsB);

    clock_div : pll
    port map(
        refclk => clk,
        rst => Reset,
        outclk_0 => vgaClk);

    elon : bird
    port map(
        enable => movementEnable,
        pb1 => pb1,
        pb2 => LEFTBUTTONevent,
        clk => vgaClk,
        vert_sync => VSYNC,
        pixel_column => xPos,
        pixel_row => yPos,
        red => paintR,
        inPixel => BiDet); --birdR,
    --green => birdG,
    --blue => birdB);

    --SET TEST OBSTACLE ENABLE		 
    OBST1 <= '1';

    setObstacles : process (clk)
    begin
        if rising_edge(clk) then
            --SET OBSTACLES INTERMITTENTLY
        end if;
    end process setObstacles;

    -------------COLLISIONS-----------

    -- BirdDetected 0 | ObstacleDetected 0 => move
    -- BirdDetected 0 | ObstacleDetected 1 => move
    -- BirdDetected 1 | ObstacleDetected 0 => move
    -- BirdDetected 1 | ObstacleDetected 1 => no move
    movementEnable <= '0' when ((BiDet = '1' and ObDet = '1') or (pb1 /= '0')) else
                      '1';

    ----------------------------------

    -------------DRAWING--------------

    drawSprite : process (clk)
    begin
        if rising_edge(clk) then

            if (BiDet = '1') then
                paintR <= birdR;
                paintG <= birdG;
                paintB <= birdB;
            elsif (ObDet = '1') then
                paintR <= obsR;
                paintG <= obsG;
                paintB <= obsB;
            end if;

        end if;
    end process drawSprite;

    ----------------------------------

end flappy_bird;