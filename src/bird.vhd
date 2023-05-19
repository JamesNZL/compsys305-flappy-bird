library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity bird is
    port (
        enable, pb1, pb2, clk, vert_sync : in std_logic;
        pixel_row, pixel_column : in signed(9 downto 0);
        red, green, blue, inPixel, died : out std_logic);
end bird;

architecture behavior of bird is

    signal drawBirdYellow : std_logic;
	 signal drawBirdWhite : std_logic;
	 signal drawBirdBlack : std_logic;
    signal size1 : signed(9 downto 0);
	 signal size : signed(9 downto 0);
    signal yPos : signed(9 downto 0);
    signal xPos1 : signed(10 downto 0);
	 signal size2 : signed(9 downto 0);
	 signal size3 : signed(9 downto 0);
	 signal size4 : signed(9 downto 0);
    signal xPos2 : signed(10 downto 0);
	 signal xPos3 : signed(10 downto 0);
	 signal xPos4 : signed(10 downto 0);
    signal yVelocity : signed(9 downto 0);
    signal STOPGOINGUP : std_logic; -- TODO: do we still need this?
    signal reset : std_logic;
    signal subpixel : signed(11 downto 0);

begin

size <= TO_SIGNED(24, 10);
--    -- xPos and yPos show the (x,y) for the centre of bird
--    xPos <= TO_SIGNED(320, 11);
	 
	 size1 <= TO_SIGNED(3, 10);
	 size2 <= TO_SIGNED(4, 10);
	 size3 <= TO_SIGNED(5, 10);
	 size4 <= TO_SIGNED(6, 10);



    xPos1 <= TO_SIGNED(323, 11);
	 

    xPos2 <= TO_SIGNED(326, 11);
	 
	 xPos3 <= TO_SIGNED(324, 11);
	 
	 xPos4 <= TO_SIGNED(314, 11);
	 

	 
	 

--    drawBird <= '1' when (('0' & xPos <= '0' & pixel_column + size) and ('0' & pixel_column <= '0' & xPos + size) and ('0' & yPos <= pixel_row + size) and ('0' & pixel_row <= yPos + size)) else -- x_pos - size <= pixel_column <= x_pos + size
--                '0'; -- y_pos - size <= pixel_row <= y_pos + size
--					 
drawBirdYellow <= '1' when (
  (('0' & xPos1) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos1 + size1) and ('0' & yPos) = pixel_row) or
  (('0' & xPos1) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos1 + size1) and ('0' & (yPos + 1)) = pixel_row) or
  
  (('0' & xPos3) <= ('0' & pixel_column + size2) and ('0' & pixel_column <= '0' & xPos3 + size2) and ('0' & (yPos + 2)) = pixel_row) or
 
  (('0' & xPos2) <= ('0' & pixel_column + size3) and ('0' & pixel_column <= '0' & xPos2 + size3) and ('0' & (yPos + 3)) = pixel_row) or
  (('0' & xPos1) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos1 + size1) and ('0' & (yPos + 4)) = pixel_row) or
  (('0' & xPos1) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos1 + size1) and ('0' & (yPos + 5)) = pixel_row) or
  
  (('0' & xPos4) <= ('0' & pixel_column + size2) and ('0' & pixel_column <= '0' & xPos4 + size2) and ('0' & (yPos + 6)) = pixel_row) or
  (('0' & xPos4) <= ('0' & pixel_column + size3) and ('0' & pixel_column <= '0' & xPos4 + size3) and ('0' & (yPos + 7)) = pixel_row) or
  (('0' & xPos4) <= ('0' & pixel_column + size4) and ('0' & pixel_column <= '0' & xPos4 + size4) and ('0' & (yPos + 8)) = pixel_row) or
  (('0' & xPos4) <= ('0' & pixel_column + size4) and ('0' & pixel_column <= '0' & xPos4 + size4) and ('0' & (yPos + 9)) = pixel_row) or
  (('0' & xPos4) <= ('0' & pixel_column + size4) and ('0' & pixel_column <= '0' & xPos4 + size4) and ('0' & (yPos + 10)) = pixel_row) or
  (('0' & xPos4) <= ('0' & pixel_column + size4) and ('0' & pixel_column <= '0' & xPos4 + size4) and ('0' & (yPos + 11)) = pixel_row) or
  (('0' & xPos4) <= ('0' & pixel_column + size4) and ('0' & pixel_column <= '0' & xPos4 + size4) and ('0' & (yPos + 12)) = pixel_row) or
  (('0' & xPos4) <= ('0' & pixel_column + size4) and ('0' & pixel_column <= '0' & xPos4 + size4) and ('0' & (yPos + 13)) = pixel_row) or
  (('0' & xPos4) <= ('0' & pixel_column + size4) and ('0' & pixel_column <= '0' & xPos4 + size4) and ('0' & (yPos + 14)) = pixel_row) or
  (('0' & xPos4) <= ('0' & pixel_column + size3) and ('0' & pixel_column <= '0' & xPos4 + size3) and ('0' & (yPos + 15)) = pixel_row) or
  (('0' & xPos4) <= ('0' & pixel_column + size2) and ('0' & pixel_column <= '0' & xPos4 + size2) and ('0' & (yPos + 16)) = pixel_row)

)
else
  '0';
  
drawBirdWhite <= '1' when ( (('0' & xPos3) = ('0' & pixel_column)) and ('0' & (yPos+2) = pixel_row))
else 
'0';




    -- Colours for pixel data on video signal
    inPixel <= drawBirdYellow;
	 
	 red <= drawBirdYellow;
	 green <= drawBirdYellow;
	 blue <= '0';
	 
--	colourbird: process (clk)
--	begin
--	 if (drawBirdYellow = '1') then 
--	
--      red <= '1';
--      green <= '1';
--      blue <= '0';
--		
--	elsif (drawBirdWhite = '1') then
--	
--	   red <= '1';
--      green <= '1';
--      blue <= '1';
--		
--	elsif (drawBirdBlack = '1') then 
--		
--		red <= '0';
--      green <= '0';
--      blue <= '0';
--		
--	end if;
--	end process colourbird;

      


    moveBird : process (vert_sync)
    begin
        -- Move bird once every vertical sync
        if (rising_edge(vert_sync)) then
            if (enable = '1') then
                if (yPos <= 479 - size) then
                    if (pb2 = '1' and STOPGOINGUP = '0') then
                        subpixel <= TO_SIGNED(-200, 12);
                        STOPGOINGUP <= '1';
                    elsif (yVelocity < 10) then
                        subpixel <= (subpixel + 10);
                    elsif (yPos >= 479 - size) then
                        subpixel <= TO_SIGNED(0, 12);
                    end if;

                    if (pb2 = '0') then
                        STOPGOINGUP <= '0';
                    end if;

                    yVelocity <= shift_right(subpixel, 4)(11 downto 2);
                    yPos <= (yPos + yVelocity);
                    died <= '0';
                elsif reset = '1' then
                    yPos <= TO_SIGNED(280, 10);
                    died <= '0';
                else
                    yPos <= 480 - size;
                    died <= '1';
                end if;
            end if;
        end if;
    end process moveBird;

    reset <= '1' when (pb1 = '0' and yPos >= 479 - size) else
             '0';

end behavior;