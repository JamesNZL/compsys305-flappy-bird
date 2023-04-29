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

LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

LIBRARY work;

ENTITY main IS 
	PORT
	(
		clk :  IN  STD_LOGIC;
		pb1 :  IN  STD_LOGIC;
		pb2 :  IN  STD_LOGIC;
		red_out :  OUT  STD_LOGIC;
		green_out :  OUT  STD_LOGIC;
		blue_out :  OUT  STD_LOGIC;
		horiz_sync_out :  OUT  STD_LOGIC;
		vert_sync_out :  OUT  STD_LOGIC;
		PS2_CLK: INOUT  STD_LOGIC;
		PS2_DAT: INOUT STD_LOGIC
		
	);
END main;

ARCHITECTURE bdf_type OF main IS 

COMPONENT vga_sync
	PORT(clock_25Mhz : IN STD_LOGIC;
		 red : IN STD_LOGIC;
		 green : IN STD_LOGIC;
		 blue : IN STD_LOGIC;
		 red_out : OUT STD_LOGIC;
		 green_out : OUT STD_LOGIC;
		 blue_out : OUT STD_LOGIC;
		 horiz_sync_out : OUT STD_LOGIC;
		 vert_sync_out : OUT STD_LOGIC;
		 pixel_column : OUT signed(9 DOWNTO 0);
		 pixel_row : OUT signed(9 DOWNTO 0)
	);
END COMPONENT;

component obstacle is
   port(
        enable, pb1, clk, vert_sync : in std_logic;
        pixel_row, pixel_column : in signed(9 downto 0);
        green, inPixel : out std_logic);--red, green, blue, inPixel : out std_logic);
end component;

component MOUSE
   PORT( clock_25Mhz, reset 		: IN std_logic;
         mouse_data					: INOUT std_logic;
         mouse_clk 					: INOUT std_logic;
         left_button, right_button	: OUT std_logic;
		   mouse_cursor_row 			: OUT signed(9 DOWNTO 0); 
		   mouse_cursor_column 		: OUT signed(9 DOWNTO 0));       	
END component;

COMPONENT pll
	PORT(refclk : IN STD_LOGIC;
		 rst : IN STD_LOGIC;
		 outclk_0 : OUT STD_LOGIC;
		 locked : OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT bird
	PORT(pb1, pb2, clk, vert_sync : in std_logic;
        pixel_row, pixel_column : in signed(9 downto 0);
        red, inPixel : out std_logic);--green, blue, inPixel : out std_logic);
END COMPONENT;

SIGNAL	vgaClk :  STD_LOGIC;
SIGNAL	paintR :  STD_LOGIC;
SIGNAL	paintG :  STD_LOGIC;
SIGNAL	paintB :  STD_LOGIC;
SIGNAL	birdR :  STD_LOGIC;
SIGNAL	birdG :  STD_LOGIC;
SIGNAL	birdB :  STD_LOGIC;
SIGNAL	obsR :  STD_LOGIC;
SIGNAL	obsG :  STD_LOGIC;
SIGNAL	obsB :  STD_LOGIC;
SIGNAL	Reset :  STD_LOGIC;
SIGNAL	VSYNC :  STD_LOGIC;
SIGNAL	xPos :  signed(9 DOWNTO 0);
SIGNAL	yPos :  signed(9 DOWNTO 0);
SIGNAL	LEFTBUTTONevent :  STD_LOGIC;
SIGNAL	RIGHTBUTTONevent :  STD_LOGIC;
SIGNAL	MOUSEROW :  signed(9 DOWNTO 0);
SIGNAL	MOUSECOLUMN :  signed(9 DOWNTO 0);
SIGNAL	OBST1 : std_logic;
SIGNAL	ObDet : std_logic;
SIGNAL	BiDet : std_logic;



BEGIN 
vert_sync_out <= VSYNC;
Reset <= '0';



b2v_inst : vga_sync
PORT MAP(clock_25Mhz => vgaClk,
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
		 
mouseymouse : MOUSE
PORT MAP(clock_25Mhz => vgaClk,
			reset => RESET,
         mouse_data => PS2_DAT,
         mouse_clk => PS2_CLK,
         left_button => LEFTBUTTONevent,
			right_button => RIGHTBUTTONevent,
		   mouse_cursor_row => MOUSEROW,
		   mouse_cursor_column => MOUSECOLUMN);

obstacle1 : obstacle
port map(enable => OBST1,
			pb1 => pb1,
			clk => vgaClk,
			vert_sync => VSYNC,
         pixel_row => xPos,
			pixel_column => yPos,
         --red => obsR,
			green => paintG);--obsG),
			--blue => obsB);

b2v_inst3 : pll
PORT MAP(refclk => clk,
		   rst => Reset,
		   outclk_0 => vgaClk);


b2v_inst5 : bird
PORT MAP(pb1 => pb1,
		 pb2 => LEFTBUTTONevent,
		 clk => vgaClk,
		 vert_sync => VSYNC,
		 pixel_column => xPos,
		 pixel_row => yPos,
		 red => paintR); --birdR,
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

END bdf_type;