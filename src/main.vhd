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
        clk            : in    std_logic;
        pb1            : in    std_logic;
        pb2            : in    std_logic;
        red_out        : out   std_logic;
        green_out      : out   std_logic;
        blue_out       : out   std_logic;
        horiz_sync_out : out   std_logic;
        vert_sync_out  : out   std_logic;
        PS2_CLK        : inout std_logic;
        PS2_DAT        : inout std_logic;
        HEX1           : out   std_logic_vector(6 downto 0);
        HEX0           : out   std_logic_vector(6 downto 0)
    );
end main;

architecture flappy_bird of main is

    component vga_sync
        port (
            clock_25Mhz    : in  std_logic;
            red            : in  std_logic;
            green          : in  std_logic;
            blue           : in  std_logic;
            red_out        : out std_logic;
            green_out      : out std_logic;
            blue_out       : out std_logic;
            horiz_sync_out : out std_logic;
            vert_sync_out  : out std_logic;
            pixel_column   : out signed(9 downto 0);
            pixel_row      : out signed(9 downto 0)
        );
    end component;

    component obstacle is
        port (
            enable, pb1, clk, vert_sync          : in  std_logic;
            lfsrSeed                             : in  std_logic_vector(8 downto 1);
            start_xPos                           : in  signed(10 downto 0);
            pixel_row, pixel_column              : in  signed(9 downto 0);
            red, green, blue, inPixel, scoreTick : out std_logic);
    end component;

    component MOUSE
        port (
            clock_25Mhz, reset        : in    std_logic;
            mouse_data                : inout std_logic;
            mouse_clk                 : inout std_logic;
            left_button, right_button : out   std_logic;
            mouse_cursor_row          : out   signed(9 downto 0);
            mouse_cursor_column       : out   signed(9 downto 0));
    end component;

    component pll
        port (
            refclk   : in  std_logic;
            rst      : in  std_logic;
            outclk_0 : out std_logic;
            locked   : out std_logic
        );
    end component;

    component bird
        port (
            enable, pb1, pb2, clk, vert_sync : in  std_logic;
            pixel_row, pixel_column          : in  signed(9 downto 0);
            red, green, blue, inPixel, died  : out std_logic);
    end component;

    component scoreCounter is
        port (
            Clk, Tick    : in  std_logic;
            Reset        : in  std_logic;
            setNextDigit : out std_logic;
            Q_Out        : out std_logic_vector(3 downto 0));
    end component;

    component BCD_to_SevenSeg is
        port (
            BCD_digit    : in  std_logic_vector(3 downto 0);
            SevenSeg_out : out std_logic_vector(6 downto 0));
    end component;

    component char_rom is
        port (
            character_address  : in  std_logic_vector (5 downto 0);
            font_row, font_col : in  std_logic_vector (2 downto 0);
            clock              : in  std_logic;
            rom_mux_output     : out std_logic);
    end component;

    signal vgaClk                                       : std_logic;
    signal paintR, paintG, paintB                       : std_logic;
    signal scoreR, scoreG, scoreB                       : std_logic;
    signal birdR, birdG, birdB                          : std_logic;
    signal obsOneR, obsOneG, obsOneB                    : std_logic;
    signal obsTwoR, obsTwoG, obsTwoB                    : std_logic;
    signal reset                                        : std_logic;
    signal vsync                                        : std_logic;
    signal xPixel, yPixel                               : signed(9 downto 0);
    signal leftButtonEvent, rightButtonEvent            : std_logic;
    signal mouseRow, mouseColumn                        : signed(9 downto 0);
    signal movementEnable                               : std_logic := '1';
    signal ObOneDet, ObTwoDet, ObDet                    : std_logic;
    signal ObOneTick, ObTwoTick, tensTick, hundredsTick : std_logic;
    signal scoreOnes, scoreTens                         : std_logic_vector(3 downto 0);
    signal BiDet                                        : std_logic;
    signal BiDied                                       : std_logic := '0';
    signal charAddress                                  : std_logic_vector(5 downto 0);
    signal fontrow, fontcol                             : std_logic_vector (2 downto 0);
    signal charOUTPUT                                   : std_logic;
    signal counter                                      : std_logic_vector(2 downto 0) := "000";
    signal counter2                                     : std_logic_vector(2 downto 0) := "000";
    signal counter3                                     : std_logic_vector(2 downto 0) := "000";
    signal counter4                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter5                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter6                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter7                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter8                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter9                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter10                                    : std_logic_vector(2 downto 0) := "000";
	 signal counter11                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter12                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter13                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter14                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter15                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter16                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter17                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter18                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter19                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter20                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter21                                     : std_logic_vector(2 downto 0) := "000";
    signal counter22                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter23                                    : std_logic_vector(2 downto 0) := "000";
	 signal counter24                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter25                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter26                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter27                                    : std_logic_vector(2 downto 0) := "000";
	 signal counter28                                    : std_logic_vector(2 downto 0) := "000";
	 signal counter29                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter30                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter31                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter32                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter33                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter34                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter35                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter36                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter37                                     : std_logic_vector(2 downto 0) := "000";
	 signal counter38                                     : std_logic_vector(2 downto 0) := "000";

begin

    vert_sync_out <= vsync;
    Reset         <= '0';

    vga : vga_sync
    port map(
        clock_25Mhz    => vgaClk,
        red            => paintR,
        green          => paintG,
        blue           => paintB,
        red_out        => red_out,
        green_out      => green_out,
        blue_out       => blue_out,
        horiz_sync_out => horiz_sync_out,
        vert_sync_out  => vsync,
        pixel_column   => xPixel,
        pixel_row      => yPixel);

    score_display : char_rom
    port map(
        character_address => charAddress,
        font_row          => fontrow,
        font_col          => fontcol,
        clock             => vgaClk,
        rom_mux_output    => charOUTPUT);

    mousey_mouse : MOUSE
    port map(
        clock_25Mhz         => vgaClk,
        reset               => RESET,
        mouse_data          => PS2_DAT,
        mouse_clk           => PS2_CLK,
        left_button         => leftButtonEvent,
        right_button        => rightButtonEvent,
        mouse_cursor_row    => mouseRow,
        mouse_cursor_column => mouseColumn);

    obstacle_one : obstacle
    port map(
        enable       => movementEnable,
        pb1          => pb1,
        clk          => vgaClk,
        vert_sync    => vsync,
        lfsrSeed     => std_logic_vector(xPixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_xPos   => TO_SIGNED(640, 11),
        pixel_row    => yPixel,
        pixel_column => xPixel,
        red          => obsOneR,
        green        => obsOneG,
        blue         => obsOneB,
        inPixel      => ObOneDet,
        scoreTick    => ObOneTick);

    obstacle_two : obstacle
    port map(
        enable       => movementEnable,
        pb1          => pb1,
        clk          => vgaClk,
        vert_sync    => vsync,
        lfsrSeed     => std_logic_vector(yPixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_xPos   => TO_SIGNED(960, 11),
        pixel_row    => yPixel,
        pixel_column => xPixel,
        red          => obsTwoR,
        green        => obsTwoG,
        blue         => obsTwoB,
        inPixel      => ObTwoDet,
        scoreTick    => ObTwoTick);

    scoringOnes : scoreCounter
    port map(
        Clk          => vgaClk,
        Tick         => (ObOneTick or ObTwoTick),
        Reset        => pb1,
        setNextDigit => tensTick,
        Q_Out        => scoreOnes);

    scoringTens : scoreCounter
    port map(
        Clk          => vgaClk,
        Tick         => tensTick,
        Reset        => pb1,
        setNextDigit => hundredsTick,
        Q_Out        => scoreTens);

    ssegOnes : BCD_to_SevenSeg
    port map(
        BCD_digit    => scoreOnes,
        SevenSeg_Out => HEX0);

    ssegTens : BCD_to_SevenSeg
    port map(
        BCD_digit    => scoreTens,
        SevenSeg_Out => HEX1);

    clock_div : pll
    port map(
        refclk   => clk,
        rst      => Reset,
        outclk_0 => vgaClk);

    elon : bird
    port map(
        enable       => movementEnable,
        pb1          => pb1,
        pb2          => leftButtonEvent,
        clk          => vgaClk,
        vert_sync    => vsync,
        pixel_column => xPixel,
        pixel_row    => yPixel,
        red          => birdR,
        green        => birdG,
        blue         => birdB,
        inPixel      => BiDet,
        died         => BiDied);

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

    ----------------------------------

    -------------DRAWING--------------

    paintScreen : process (vgaClk)
        variable int_value : integer;
        variable flag      : integer range 0 to 1 := 0;
    begin
        if (rising_edge(vgaClk)) then
		  
		  
		  ---BOX PRINTED
		  
		   if ((xPixel >= 95 and xPixel < 545) and (yPixel >= 75 and yPixel < 405)) then
		  

          
            if ((xPixel >= 100  and xPixel < 540) and (yPixel >= 80 and yPixel < 400)) then
				
				---FLAPPYBIRD PRINTED
				    if ((xPixel >= 180  and xPixel < 196) and (yPixel >= 100 and yPixel < 108)) then 
					 

						 charAddress <= "000110";
						

						 fontcol <= counter;
						 fontrow <= counter2;

						 if (flag = 1) then
							  if (counter = "111") then
									counter  <= "000";
									counter2 <= std_logic_vector(unsigned(counter2) + 1);
									if (counter2 = "111") then
										 counter2 <= "000";
									end if;
							  else
									counter <= std_logic_vector(unsigned(counter) + 1);

							  end if;
						 end if;
						 
						 flag := (flag + 1) mod 2;
					if (charOUTPUT = '1') then
						 paintR <= '1';
						 paintG <= '1';
						 paintB <= '1';
					else
						 paintR <= '0';
						 paintG <= '0';
						 paintB <= '0';
					end if;

					 
					 elsif ((xPixel >= 196 and xPixel < 212) and (yPixel >= 100 and yPixel < 108)) then
						 charAddress <= "001100";

						 fontcol <= counter3;
						 fontrow <= counter4;
						 
						 
						 if (flag = 1) then

							 if (counter3 = "111") then
								  counter3 <= "000";
								  counter4 <= std_logic_vector(unsigned(counter4) + 1);
								  if (counter4 = "111") then
										counter4 <= "000";
								  end if;
							 else
								  counter3 <= std_logic_vector(unsigned(counter3) + 1);
							 end if;
							 
						 end if;
						 
						 flag := (flag + 1) mod 2;

						if (charOUTPUT = '1') then
							 paintR <= '1';
							 paintG <= '1';
							 paintB <= '1';
						else
							 paintR <= '0';
							 paintG <= '0';
							 paintB <= '0';
						end if;

						 
					elsif ((xPixel >= 212 and xPixel < 228) and (yPixel >= 100 and yPixel < 108)) then
						 
						 charAddress <= "000001";

						 fontcol <= counter5;
						 fontrow <= counter6;
						 
						 
						 if (flag = 1) then

							 if (counter5 = "111") then
								  counter5 <= "000";
								  counter6 <= std_logic_vector(unsigned(counter6) + 1);
								  if (counter6 = "111") then
										counter6 <= "000";
								  end if;
							 else
								  counter5 <= std_logic_vector(unsigned(counter5) + 1);
							 end if;
							 
						 end if;
						 
						 flag := (flag + 1) mod 2;
						 if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;


						 
					
						
				elsif ((xPixel >= 228 and xPixel < 244) and (yPixel >= 100 and yPixel < 108)) then
					  charAddress <= "010000";
					  fontcol <= counter7;
					  fontrow <= counter8;

					  if (flag = 1) then
							if (counter7 = "111") then
								 counter7 <= "000";
								 counter8 <= std_logic_vector(unsigned(counter8) + 1);
								 if (counter8 = "111") then
									  counter8 <= "000";
								 end if;
							else
								 counter7 <= std_logic_vector(unsigned(counter7) + 1);
							end if;
					  end if;

					  flag := (flag + 1) mod 2;

					if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

					  
				elsif ((xPixel >= 244 and xPixel < 260) and (yPixel >= 100 and yPixel < 108)) then
						  charAddress <= "010000";
						  fontcol <= counter9;
						  fontrow <= counter10;

						  if (flag = 1) then
								if (counter9 = "111") then
									 counter9 <= "000";
									 counter10 <= std_logic_vector(unsigned(counter10) + 1);
									 if (counter10 = "111") then
										  counter10 <= "000";
									 end if;
								else
									 counter9 <= std_logic_vector(unsigned(counter9) + 1);
								end if;
						  end if;

						  flag := (flag + 1) mod 2;

						 if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

						  
			 elsif ((xPixel >= 260 and xPixel < 276) and (yPixel >= 100 and yPixel < 108)) then
				  charAddress <= "011001";
				  fontcol <= counter11;
				  fontrow <= counter12;

				  if (flag = 1) then
						if (counter11 = "111") then
							 counter11 <= "000";
							 counter12 <= std_logic_vector(unsigned(counter12) + 1);
							 if (counter12 = "111") then
								  counter12 <= "000";
							 end if;
						else
							 counter11 <= std_logic_vector(unsigned(counter11) + 1);
						end if;
				  end if;

				  flag := (flag + 1) mod 2;

				  if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

				  
			elsif ((xPixel >= 300 and xPixel < 316) and (yPixel >= 100 and yPixel < 108)) then
				  charAddress <= "000010";
				  fontcol <= counter13;
				  fontrow <= counter14;

				  if (flag = 1) then
						if (counter13 = "111") then
							 counter13 <= "000";
							 counter14 <= std_logic_vector(unsigned(counter14) + 1);
							 if (counter14 = "111") then
								  counter14 <= "000";
							 end if;
						else
							 counter13 <= std_logic_vector(unsigned(counter13) + 1);
						end if;
				  end if;

				  flag := (flag + 1) mod 2;

				  if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

				  
	   elsif ((xPixel >= 316 and xPixel < 332) and (yPixel >= 100 and yPixel < 108)) then
						  charAddress <= "001001";
						  fontcol <= counter15;
						  fontrow <= counter16;

						  if (flag = 1) then
								if (counter15 = "111") then
									 counter15 <= "000";
									 counter16 <= std_logic_vector(unsigned(counter16) + 1);
									 if (counter16 = "111") then
										  counter16 <= "000";
									 end if;
								else
									 counter15 <= std_logic_vector(unsigned(counter15) + 1);
								end if;
						  end if;

						  flag := (flag + 1) mod 2;

						  if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

					elsif ((xPixel >= 332 and xPixel < 348) and (yPixel >= 100 and yPixel < 108)) then
						  charAddress <= "010010";
						  fontcol <= counter17;
						  fontrow <= counter18;

						  if (flag = 1) then
								if (counter17 = "111") then
									 counter17 <= "000";
									 counter18 <= std_logic_vector(unsigned(counter18) + 1);
									 if (counter18 = "111") then
										  counter18 <= "000";
									 end if;
								else
									 counter17 <= std_logic_vector(unsigned(counter17) + 1);
								end if;
						  end if;

						  flag := (flag + 1) mod 2;

						if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

						  
					elsif ((xPixel >= 348 and xPixel < 364) and (yPixel >= 100 and yPixel < 108)) then
					  charAddress <= "000100";
					  fontcol <= counter19;
					  fontrow <= counter20;

					  if (flag = 1) then
							if (counter19 = "111") then
								 counter19 <= "000";
								 counter20 <= std_logic_vector(unsigned(counter20) + 1);
								 if (counter20 = "111") then
									  counter20 <= "000";
								 end if;
							else
								 counter19 <= std_logic_vector(unsigned(counter19) + 1);
							end if;
					  end if;

					  flag := (flag + 1) mod 2;

					if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

					  
					  
			  ----TRAIN PRINTED--------
					  
				elsif ((xPixel >= 120 and xPixel < 136) and (yPixel >= 200 and yPixel < 208)) then
					  charAddress <= "010100";
					  fontcol <= counter37;
					  fontrow <= counter38;

					  if (flag = 1) then
							if (counter37 = "111") then
								 counter37 <= "000";
								 counter38 <= std_logic_vector(unsigned(counter38) + 1);
								 if (counter38 = "111") then
									  counter38 <= "000";
								 end if;
							else
								 counter37 <= std_logic_vector(unsigned(counter37) + 1);
							end if;
					  end if;

					  flag := (flag + 1) mod 2;

					 if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

					  
				elsif ((xPixel >= 136 and xPixel < 152) and (yPixel >= 200 and yPixel < 208)) then
					 charAddress <= "010010";
					 fontcol <= counter21;
					 fontrow <= counter22;

					 if (flag = 1) then
						  if (counter21 = "111") then
								counter21 <= "000";
								counter22 <= std_logic_vector(unsigned(counter22) + 1);
								if (counter22 = "111") then
									 counter22 <= "000";
								end if;
						  else
								counter21 <= std_logic_vector(unsigned(counter21) + 1);
						  end if;
					 end if;

					 flag := (flag + 1) mod 2;
if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

			elsif ((xPixel >= 152 and xPixel < 168) and (yPixel >= 200 and yPixel < 208)) then
				 charAddress <= "000001";
				 fontcol <= counter23;
				 fontrow <= counter24;

				 if (flag = 1) then
					  if (counter23 = "111") then
							counter23 <= "000";
							counter24 <= std_logic_vector(unsigned(counter24) + 1);
							if (counter24 = "111") then
								 counter24 <= "000";
							end if;
					  else
							counter23 <= std_logic_vector(unsigned(counter23) + 1);
					  end if;
				 end if;

				 flag := (flag + 1) mod 2;
if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

				 
			elsif ((xPixel >= 168 and xPixel < 184) and (yPixel >= 200 and yPixel < 208)) then
				 charAddress <= "001001";
				 fontcol <= counter25;
				 fontrow <= counter26;

				 if (flag = 1) then
					  if (counter25 = "111") then
							counter25 <= "000";
							counter26 <= std_logic_vector(unsigned(counter26) + 1);
							if (counter26 = "111") then
								 counter26 <= "000";
							end if;
					  else
							counter25 <= std_logic_vector(unsigned(counter25) + 1);
					  end if;
				 end if;

				 flag := (flag + 1) mod 2;

				if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;



					
			elsif ((xPixel >= 184 and xPixel < 200) and (yPixel >= 200 and yPixel < 208)) then
				 charAddress <= "001110";
				 fontcol <= counter27;
				 fontrow <= counter28;

				 if (flag = 1) then
					  if (counter27 = "111") then
							counter27 <= "000";
							counter28 <= std_logic_vector(unsigned(counter28) + 1);
							if (counter28 = "111") then
								 counter28 <= "000";
							end if;
					  else
							counter27 <= std_logic_vector(unsigned(counter27) + 1);
					  end if;
				 end if;

				 flag := (flag + 1) mod 2;

				 if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

				 
				 
		----PRINT GAME-----
		
		
		
		elsif ((xPixel >= 120 and xPixel < 136) and (yPixel >= 300 and yPixel < 308)) then
			 charAddress <= "000111";
			 fontcol <= counter29;
			 fontrow <= counter30;

			 if (flag = 1) then
				  if (counter29 = "111") then
						counter29 <= "000";
						counter30 <= std_logic_vector(unsigned(counter30) + 1);
						if (counter30 = "111") then
							 counter30 <= "000";
						end if;
				  else
						counter29 <= std_logic_vector(unsigned(counter29) + 1);
				  end if;
			 end if;

			 flag := (flag + 1) mod 2;
if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;


			elsif ((xPixel >= 136 and xPixel < 152) and (yPixel >= 300 and yPixel < 308)) then
				 charAddress <= "000001";
				 fontcol <= counter31;
				 fontrow <= counter32;

				 if (flag = 1) then
					  if (counter31 = "111") then
							counter31 <= "000";
							counter32 <= std_logic_vector(unsigned(counter32) + 1);
							if (counter32 = "111") then
								 counter32 <= "000";
							end if;
					  else
							counter31 <= std_logic_vector(unsigned(counter31) + 1);
					  end if;
				 end if;

				 flag := (flag + 1) mod 2;

				if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

								
			elsif ((xPixel >= 152 and xPixel < 168) and (yPixel >= 300 and yPixel < 308)) then
				 charAddress <= "001101";
				 fontcol <= counter33;
				 fontrow <= counter34;

				 if (flag = 1) then
					  if (counter33 = "111") then
							counter33 <= "000";
							counter34 <= std_logic_vector(unsigned(counter34) + 1);
							if (counter34 = "111") then
								 counter34 <= "000";
							end if;
					  else
							counter33 <= std_logic_vector(unsigned(counter33) + 1);
					  end if;
				 end if;

				 flag := (flag + 1) mod 2;
if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

								  
							 
			elsif ((xPixel >= 168 and xPixel < 184) and (yPixel >= 300 and yPixel < 308)) then
				 charAddress <= "000101";
				 fontcol <= counter35;
				 fontrow <= counter36;

				 if (flag = 1) then
					  if (counter35 = "111") then
							counter35 <= "000";
							counter36 <= std_logic_vector(unsigned(counter36) + 1);
							if (counter36 = "111") then
								 counter36 <= "000";
							end if;
					  else
							counter35 <= std_logic_vector(unsigned(counter35) + 1);
					  end if;
				 end if;

				 flag := (flag + 1) mod 2;

				if (charOUTPUT = '1') then
    paintR <= '1';
    paintG <= '1';
    paintB <= '1';
else
    paintR <= '0';
    paintG <= '0';
    paintB <= '0';
end if;

								else
						 paintR <= '0';
                   paintG <= '0';
                   paintB <= '0';
						 
						end if;
						
				else 
				
						paintR <= '1';
                   paintG <= '1';
                   paintB <= '1';
						 
						end if;
				

					

				elsif (BiDet = '1') then
                paintR <= birdR;
                paintG <= birdG;
                paintB <= birdB;
            elsif (ObDet = '1') then
                paintR <= (obsOneR or obsTwoR);
                paintG <= (obsOneG or obsTwoG);
                paintB <= (obsOneB or obsTwoB);

            else
                paintR <= '0';
                paintG <= '1';
                paintB <= '1';

            end if;

        end if;
    end process paintScreen;
	 
	 --if between 100 and 540 pixels horizontally
	 --if between 80 and 400 pixels vertically
	 -- draw a black box
	 --all the other words are in white 
	 -- all the words first and then the black box after 
	 --640x480 pixels

    ----------------------------------

    -------------SCORING--------------

    ----------------------------------

end flappy_bird;