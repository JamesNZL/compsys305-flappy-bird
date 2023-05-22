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
	 
	  component coin is
        port (
            enable, coinEnable, pb1, clk, vert_sync          : in  std_logic;
            lfsrSeed                             : in  std_logic_vector(8 downto 1);
            start_xPos                           : in  signed(10 downto 0);
            pixel_row, pixel_column              : in  signed(9 downto 0);
            red, green, blue, inPixel, coinLeft : out std_logic);
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
	 signal heartR, heartG, heartB                       : std_logic;
    signal scoreR, scoreG, scoreB                       : std_logic;
	 signal coinR, coinG, coinB                          : std_logic;
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
	 signal coinEnable, coinGone                         : std_logic;
	 signal coinDet                                      : std_logic;
	 signal coinTick                                     : std_logic := '0';
    signal ObOneTick, ObTwoTick, tensTick, hundredsTick : std_logic;
    signal scoreOnes, scoreTens                         : std_logic_vector(3 downto 0);
    signal BiDet, inHeart, inScore                      : std_logic;
    signal BiDied                                       : std_logic := '0';
    signal charAddress                                  : std_logic_vector(5 downto 0);
    signal fontrow, fontcol                             : std_logic_vector (2 downto 0);
    signal charOUTPUT                                   : std_logic;
	 signal homescreenEnable                             : std_logic := '0';
	 signal trainingMode                                 : std_logic := '0';
    signal counter                                      : std_logic_vector(2 downto 0) := "000";
    
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
		  
	 coin_one : coin
    port map(
        enable       => movementEnable,
		  coinEnable   => coinEnable,
        pb1          => pb1,
        clk          => vgaClk,
        vert_sync    => vsync,
        lfsrSeed     => std_logic_vector(xPixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_xPos   => TO_SIGNED(800, 11),
        pixel_row    => yPixel,
        pixel_column => xPixel,
        red          => coinR,
        green        => coinG,
        blue         => coinB,
        inPixel      => coinDet,
		  coinLeft     => coinGone);

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
        Tick         => (ObOneTick or ObTwoTick or coinTick),
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
	 
	 
	 detectCoin : process (vgaClk)
	 variable flag : std_logic := '1';
	 variable flag1 : std_logic := '1';
    begin
        if rising_edge(vgaClk) then

            if (BiDet = '1' and coinDet = '1' and flag1 = '1') then
					 coinTick <= '1';
					 flag := '0';
					 flag1 := '0';
            elsif (coinGone = '1') then
                flag := '1';
					 flag1 := '1';
				elsif (flag1 = '0') then
					coinTick <= '0';
            end if;
				
				if (flag = '0') then
					coinEnable <= '0';
				else
					coinEnable <= '1';

        end if;
		  end if;
    end process detectCoin;

    ----------------------------------

    -------------DRAWING--------------

    paintScreen : process (vgaClk)
	 

    begin
        if (rising_edge(vgaClk)) then
		  
		  
		  ---BOX PRINTED
		  if (homescreenEnable = '1') then 
		  
		   if ((xPixel >= 180 and xPixel < 460) and (yPixel >= 140 and yPixel < 340)) then
		  

          
            if ((xPixel >= 185  and xPixel < 455) and (yPixel >= 145 and yPixel < 335)) then
				
				---FLAPPYBIRD PRINTED
				    if ((xPixel >= 200 and xPixel < 216) and (yPixel >= 150 and yPixel < 166)) then 
					 

						 charAddress <= "000110";
						
            fontcol <= std_logic_vector(xPixel - 200)(3 downto 1);
				fontrow <= std_logic_vector(yPixel - 150)(3 downto 1);

					if (charOUTPUT = '1') then
						 paintR <= '1';
						 paintG <= '1';
						 paintB <= '1';
					else
						 paintR <= '0';
						 paintG <= '0';
						 paintB <= '0';
					end if;

					 
					 elsif ((xPixel >= 216 and xPixel < 232) and (yPixel >= 150 and yPixel < 166)) then
						 charAddress <= "001100";

						 fontcol <= std_logic_vector(xPixel - 216)(3 downto 1);
				       fontrow <= std_logic_vector(yPixel - 150)(3 downto 1);


						if (charOUTPUT = '1') then
							 paintR <= '1';
							 paintG <= '1';
							 paintB <= '1';
						else
							 paintR <= '0';
							 paintG <= '0';
							 paintB <= '0';
						end if;

						 
					elsif ((xPixel >= 232 and xPixel < 248) and (yPixel >= 150 and yPixel < 166)) then
						 
						 charAddress <= "000001";

						fontcol <= std_logic_vector(xPixel - 232)(3 downto 1);
				      fontrow <= std_logic_vector(yPixel - 150)(3 downto 1);
						 

						 if (charOUTPUT = '1') then
					 paintR <= '1';
					 paintG <= '1';
					 paintB <= '1';
				else
					 paintR <= '0';
					 paintG <= '0';
					 paintB <= '0';
				end if;


						 
					
						
				elsif ((xPixel >= 248 and xPixel < 264) and (yPixel >= 150 and yPixel < 166)) then
					  charAddress <= "010000";
					  
					  fontcol <= std_logic_vector(xPixel - 248)(3 downto 1);
				     fontrow <= std_logic_vector(yPixel - 150)(3 downto 1);

					if (charOUTPUT = '1') then
					 paintR <= '1';
					 paintG <= '1';
					 paintB <= '1';
				else
					 paintR <= '0';
					 paintG <= '0';
					 paintB <= '0';
				end if;

					  
				elsif ((xPixel >= 264 and xPixel < 280) and (yPixel >= 150 and yPixel < 166)) then
						  charAddress <= "010000";
						 
						 fontcol <= std_logic_vector(xPixel - 264)(3 downto 1);
				       fontrow <= std_logic_vector(yPixel - 150)(3 downto 1);

						 if (charOUTPUT = '1') then
					 paintR <= '1';
					 paintG <= '1';
					 paintB <= '1';
				else
					 paintR <= '0';
					 paintG <= '0';
					 paintB <= '0';
				end if;

						  
			 elsif ((xPixel >= 280 and xPixel < 296) and (yPixel >= 150 and yPixel < 166)) then
				  charAddress <= "011001";
				  
				  fontcol <= std_logic_vector(xPixel - 280)(3 downto 1);
				  fontrow <= std_logic_vector(yPixel - 150)(3 downto 1);

				  if (charOUTPUT = '1') then
					 paintR <= '1';
					 paintG <= '1';
					 paintB <= '1';
				else
					 paintR <= '0';
					 paintG <= '0';
					 paintB <= '0';
				end if;

				  
			elsif ((xPixel >= 320 and xPixel < 336) and (yPixel >= 150 and yPixel < 166)) then
				  charAddress <= "000010";
				  
				  fontcol <= std_logic_vector(xPixel - 320)(3 downto 1);
				  fontrow <= std_logic_vector(yPixel - 150)(3 downto 1);

				  if (charOUTPUT = '1') then
					 paintR <= '1';
					 paintG <= '1';
					 paintB <= '1';
				else
					 paintR <= '0';
					 paintG <= '0';
					 paintB <= '0';
				end if;

				  
	   elsif ((xPixel >= 336 and xPixel < 352) and (yPixel >= 150 and yPixel < 166)) then
						  charAddress <= "001001";
						 
						 fontcol <= std_logic_vector(xPixel - 336)(3 downto 1);
				       fontrow <= std_logic_vector(yPixel - 150)(3 downto 1);

						  if (charOUTPUT = '1') then
					 paintR <= '1';
					 paintG <= '1';
					 paintB <= '1';
				else
					 paintR <= '0';
					 paintG <= '0';
					 paintB <= '0';
				end if;

					elsif ((xPixel >= 352 and xPixel < 368) and (yPixel >= 150 and yPixel < 166)) then
						  charAddress <= "010010";
						 
						 fontcol <= std_logic_vector(xPixel - 368)(3 downto 1);
				       fontrow <= std_logic_vector(yPixel - 150)(3 downto 1);

						if (charOUTPUT = '1') then
					 paintR <= '1';
					 paintG <= '1';
					 paintB <= '1';
				else
					 paintR <= '0';
					 paintG <= '0';
					 paintB <= '0';
				end if;

						  
					elsif ((xPixel >= 368 and xPixel < 384) and (yPixel >= 150 and yPixel < 166)) then
					  charAddress <= "000100";
					 fontcol <= std_logic_vector(xPixel - 368)(3 downto 1);
				    fontrow <= std_logic_vector(yPixel - 150)(3 downto 1);

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
					  
				elsif ((xPixel >= 190 and xPixel < 206) and (yPixel >= 200 and yPixel < 216)) then
					  charAddress <= "010100";
					 
					 fontcol <= std_logic_vector(xPixel - 190)(3 downto 1);
				    fontrow <= std_logic_vector(yPixel - 200)(3 downto 1);

					 if (charOUTPUT = '1') then
					 paintR <= '1';
					 paintG <= '1';
					 paintB <= '1';
				else
					 paintR <= '0';
					 paintG <= '0';
					 paintB <= '0';
				end if;

					  
				elsif ((xPixel >= 206 and xPixel < 222) and (yPixel >= 200 and yPixel < 216)) then
					 charAddress <= "010010";
					
					 
					 fontcol <= std_logic_vector(xPixel - 206)(3 downto 1);
				    fontrow <= std_logic_vector(yPixel - 200)(3 downto 1);

			if (charOUTPUT = '1') then
				 paintR <= '1';
				 paintG <= '1';
				 paintB <= '1';
			else
				 paintR <= '0';
				 paintG <= '0';
				 paintB <= '0';
			end if;

			elsif ((xPixel >= 222 and xPixel < 238) and (yPixel >= 200 and yPixel < 216)) then
				 charAddress <= "000001";
				 
					 fontcol <= std_logic_vector(xPixel - 222)(3 downto 1);
				    fontrow <= std_logic_vector(yPixel - 200)(3 downto 1);

			if (charOUTPUT = '1') then
				 paintR <= '1';
				 paintG <= '1';
				 paintB <= '1';
			else
				 paintR <= '0';
				 paintG <= '0';
				 paintB <= '0';
			end if;

				 
			elsif ((xPixel >= 238 and xPixel < 254) and (yPixel >= 200 and yPixel < 216)) then
				 charAddress <= "001001";
			 
					 fontcol <= std_logic_vector(xPixel - 238)(3 downto 1);
				    fontrow <= std_logic_vector(yPixel - 200)(3 downto 1);


				if (charOUTPUT = '1') then
				 paintR <= '1';
				 paintG <= '1';
				 paintB <= '1';
			else
				 paintR <= '0';
				 paintG <= '0';
				 paintB <= '0';
			end if;



					
			elsif ((xPixel >= 254 and xPixel < 270) and (yPixel >= 200 and yPixel < 216)) then
				 charAddress <= "001110";
				 
					 fontcol <= std_logic_vector(xPixel - 254)(3 downto 1);
				    fontrow <= std_logic_vector(yPixel - 200)(3 downto 1);

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
		
		
		
		elsif ((xPixel >= 190 and xPixel < 206) and (yPixel >= 250 and yPixel < 268)) then
			 charAddress <= "000111";
			 
					 fontcol <= std_logic_vector(xPixel - 190)(3 downto 1);
				    fontrow <= std_logic_vector(yPixel - 250)(3 downto 1);



			if (charOUTPUT = '1') then
				 paintR <= '1';
				 paintG <= '1';
				 paintB <= '1';
			else
				 paintR <= '0';
				 paintG <= '0';
				 paintB <= '0';
			end if;


			elsif ((xPixel >= 206 and xPixel < 222) and (yPixel >= 250 and yPixel < 268)) then
				 charAddress <= "000001";
				
				 fontcol <= std_logic_vector(xPixel - 206)(3 downto 1);
				 fontrow <= std_logic_vector(yPixel - 250)(3 downto 1);

				if (charOUTPUT = '1') then
				 paintR <= '1';
				 paintG <= '1';
				 paintB <= '1';
			else
				 paintR <= '0';
				 paintG <= '0';
				 paintB <= '0';
			end if;

								
			elsif ((xPixel >= 222 and xPixel < 238) and (yPixel >= 250 and yPixel < 268)) then
				 charAddress <= "001101";
				
				 fontcol <= std_logic_vector(xPixel - 222)(3 downto 1);
				 fontrow <= std_logic_vector(yPixel - 250)(3 downto 1);
					 
				if (charOUTPUT = '1') then
					 paintR <= '1';
					 paintG <= '1';
					 paintB <= '1';
				else
					 paintR <= '0';
					 paintG <= '0';
					 paintB <= '0';
				end if;

								  
							 
			elsif ((xPixel >= 238 and xPixel < 254) and (yPixel >= 250 and yPixel < 268)) then
				 charAddress <= "000101";
			
			 fontcol <= std_logic_vector(xPixel - 238)(3 downto 1);
			 fontrow <= std_logic_vector(yPixel - 250)(3 downto 1);

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
			
			else 
			


				if (BiDet = '1') then
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
				
		  else
		  
		  if (inHeart = '1') then
                paintR <= heartR;
                paintG <= heartG;
                paintB <= heartB;
					 
			elsif (inScore = '1') then
                paintR <= ScoreR;
                paintG <= ScoreG;
                paintB <= ScoreB;
			

				elsif (BiDet = '1') then
                paintR <= birdR;
                paintG <= birdG;
                paintB <= birdB;
				
				elsif(coinDet = '1' and coinEnable = '1') then
				    paintR <= coinR;
                paintG <= coinG;
                paintB <= coinB;
					
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
				
			end if;

    end process paintScreen;
	 
hearts: process (vgaClk)
variable int_value : integer;

    begin
	 
	 if (homescreenEnable = '0') then 
	 
        if (rising_edge(vgaClk)) then
		  
		  if ((xPixel >= 10 and xPixel < 42) and (yPixel >= 10 and yPixel < 42)) then
				
				charAddress <= "000000";
				
				fontcol <= std_logic_vector(xPixel - 10)(4 downto 2);
				fontrow <= std_logic_vector(yPixel - 10)(4 downto 2);

				
				 heartR <= charOUTPUT;
				 heartG <= '0';
				 heartB <= '0';
				 
				 inHeart <= charOUTPUT;
			
				 
			
			elsif ((xPixel >= 45 and xPixel < 77) and (yPixel >= 10 and yPixel < 42)) then
				
				charAddress <= "000000";
				
				fontcol <= std_logic_vector(xPixel - 45)(4 downto 2);
				fontrow <= std_logic_vector(yPixel - 10)(4 downto 2);

				
				 heartR <= charOUTPUT;
				 heartG <= '0';
				 heartB <= '0';
				 
				inHeart <= charOUTPUT;
			
			
			 elsif ((xPixel >= 80 and xPixel < 112) and (yPixel >= 10 and yPixel < 42)) then
				
				charAddress <= "000000";
				
				fontcol <= std_logic_vector(xPixel - 80)(4 downto 2);
				fontrow <= std_logic_vector(yPixel - 10)(4 downto 2);

				
				 heartR <= charOUTPUT;
				 heartG <= '0';
				 heartB <= '0';
	
				 inHeart <= charOUTPUT;
				 
			 elsif ((xPixel >= 120  and xPixel < 152) and (yPixel >= 10 and yPixel < 42)) then

               
                int_value := to_integer(unsigned(scoreTens)) + 48;
                charAddress <= std_logic_vector(to_unsigned(int_value, 6));
					 
					 fontcol <= std_logic_vector(xPixel - 120)(4 downto 2);
			       fontrow <= std_logic_vector(yPixel - 10)(4 downto 2);
					


                if (charOUTPUT = '1') then
                    scoreR <= '0';
                    scoreG <= '0';
                    scoreB <= '0';
						  
						  end if;
						  
					inScore <= charOUTPUT;
               
					 
			    elsif ((xPixel >= 155 and xPixel < 187) and (yPixel >= 10 and yPixel < 42)) then
                
                int_value := to_integer(unsigned(scoreOnes)) + 48;
                charAddress <= std_logic_vector(to_unsigned(int_value, 6));

                fontcol <= std_logic_vector(xPixel - 155)(4 downto 2);
			       fontrow <= std_logic_vector(yPixel - 10)(4 downto 2);
					

                if (charOUTPUT = '1') then
                    scoreR <= '0';
                    scoreG <= '0';
                    scoreB <= '0'; 
						  
						  end if;
						  
					inScore <= charOUTPUT;
						  
						  
              
			
			else 
			inHeart <= '0';
			inscore <= '0';
			
			end if;
			
			
			end if;
			
			end if;
			
			end process;
	 
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