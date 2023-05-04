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
        VGA_R : out std_logic_vector(3 downto 0);--VGA_R
        VGA_G : out std_logic_vector(3 downto 0);
        VGA_B : out std_logic_vector(3 downto 0);
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
            red : in std_logic_vector(3 downto 0);
            green : in std_logic_vector(3 downto 0);
            blue : in std_logic_vector(3 downto 0);
            red_out : out std_logic_vector(3 downto 0);
            green_out : out std_logic_vector(3 downto 0);
            blue_out : out std_logic_vector(3 downto 0);
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
            red, green, blue : out std_logic_vector(3 downto 0);
				inPixel : out std_logic);
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
            red, green, blue : out std_logic_vector(3 downto 0);
				inPixel, died : out std_logic);
    end component;
	 
	 
	component char_romBACKGROUND
	PORT
	(
		character_address	:	IN signed(18 DOWNTO 0);
		clock				: 	IN STD_LOGIC ;
		rom_mux_output		:	OUT STD_LOGIC_VECTOR (11 downto 0)
	);
	end component;

    signal vgaClk : std_logic;
    signal paintR : std_logic_vector(3 downto 0);
    signal paintG : std_logic_vector(3 downto 0);
    signal paintB : std_logic_vector(3 downto 0);
    signal birdR : std_logic_vector(3 downto 0);
    signal birdG : std_logic_vector(3 downto 0);
    signal birdB : std_logic_vector(3 downto 0);
    signal obsR : std_logic_vector(3 downto 0);
    signal obsG : std_logic_vector(3 downto 0);
    signal obsB : std_logic_vector(3 downto 0);
    signal Reset : std_logic;
    signal VSYNC : std_logic;
    signal xPos : signed(9 downto 0);
    signal yPos : signed(9 downto 0);
    signal LEFTBUTTONevent : std_logic;
    signal RIGHTBUTTONevent : std_logic;
    signal MOUSEROW : signed(9 downto 0);
    signal MOUSECOLUMN : signed(9 downto 0);
    signal movementEnable : std_logic := '1';
    signal OBST1 : std_logic;
    signal ObDet : std_logic;
    signal BiDet : std_logic;
    signal BiDied : std_logic := '0';
	 signal charadress: signed(18 downto 0) := (others => '0');
	 signal muxoutput: std_logic_vector(11 downto 0);

begin

    vert_sync_out <= VSYNC;
    Reset <= '0';

    vga : vga_sync
    port map(
        clock_25Mhz => vgaClk,
        red => paintR,
        green => paintG,
        blue => paintB,
        red_out => VGA_R,
        green_out => VGA_G,
        blue_out => VGA_B,
        horiz_sync_out => horiz_sync_out,
        vert_sync_out => VSYNC,
        pixel_column => xPos,
        pixel_row => yPos);
		  
	background : char_romBACKGROUND
	port map(
	   character_address	=> charadress,
		clock => vgaClk,
		rom_mux_output => muxoutput);

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
        red => obsR,
        green => obsG,
        blue => obsB,
        inPixel => ObDet);

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
        red => birdR,
        green => birdG,
        blue => birdB,
        inPixel => BiDet,
        died => BiDied);

    --SET TEST OBSTACLE ENABLE		 
    OBST1 <= '1';

    setObstacles : process (clk)
    begin
        if rising_edge(clk) then
            --SET OBSTACLES INTERMITTENTLY
        end if;
    end process setObstacles;

    -------------COLLISIONS & DRAWING--------------

    paintScreen : process (vgaClk)
    begin
        if rising_edge(vgaClk) then
		  
		  --increase the character adress by one every clock cycle
		  -- call the muxoutput associated to the character adress
		  -- reaches end amount then reset
		  
		  if charadress = "1001010111111111111" then
                charadress <= (others => '0');
            else
                charadress <= charadress + 1;
            end if;
		  
		  
		  
		
            -- Painting the sprite
            if (BiDet = '1') then
                paintR <= birdR;
                paintG <= birdG;
                paintB <= birdB;
            elsif (ObDet = '1') then
                paintR <= obsR;
                paintG <= obsG;
                paintB <= obsB;
            else
                paintR <= muxoutput(11 downto 8);
                paintG <= muxoutput(7 downto 4);
                paintB <= muxoutput(3 downto 0);
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