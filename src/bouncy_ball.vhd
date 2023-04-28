library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_SIGNED.all;

entity bouncy_ball is
    port (
        pb1, pb2, clk, vert_sync : in std_logic;
        pixel_row, pixel_column : in std_logic_vector(9 downto 0);
        red, green, blue : out std_logic);
end bouncy_ball;

architecture behavior of bouncy_ball is

    signal ball_on : std_logic;
    signal size : std_logic_vector(9 downto 0);
    signal ball_y_pos : std_logic_vector(9 downto 0);
    signal ball_x_pos : std_logic_vector(10 downto 0);
    signal ball_y_motion : std_logic_vector(9 downto 0);
	 signal STOPGOINGUP : std_logic;
	 signal reset : std_logic;

begin

    size <= CONV_STD_LOGIC_VECTOR(8, 10);
    -- ball_x_pos and ball_y_pos show the (x,y) for the centre of ball
    ball_x_pos <= CONV_STD_LOGIC_VECTOR(320, 11);

    ball_on <= '1' when (('0' & ball_x_pos <= '0' & pixel_column + size) and ('0' & pixel_column <= '0' & ball_x_pos + size) -- x_pos - size <= pixel_column <= x_pos + size
               and ('0' & ball_y_pos <= pixel_row + size) and ('0' & pixel_row <= ball_y_pos + size)) else -- y_pos - size <= pixel_row <= y_pos + size
               '0';

    -- Colours for pixel data on video signal
    -- Changing the background and ball colour by pushbuttons
    Red <= '0';
    Green <= not ball_on;
    Blue <= not ball_on;
	 
--('0' & ball_y_pos >= CONV_STD_LOGIC_VECTOR(479,10) - size) ) then
--elsif ( pb2 = '0' ) then--ball_y_pos <= size) then 
--ball_y_motion <= CONV_STD_LOGIC_VECTOR(2,10);

    Move_Ball : process (vert_sync)
    begin
        -- Move ball once every vertical sync
        if (rising_edge(vert_sync)) then
		  
            if (pb2 = '0' and STOPGOINGUP = '0') then
                ball_y_motion <= -CONV_STD_LOGIC_VECTOR(15, 10);
					 STOPGOINGUP <= '1';
				elsif (ball_y_motion < 10) then
                ball_y_motion <= (ball_y_motion + 1);
				--elsif (ball_y_pos >= CONV_STD_LOGIC_VECTOR(479, 10) - size) then
					--ball_y_motion <= CONV_STD_LOGIC_VECTOR(0,10);
				end if;
				
				if (pb2 = '1') then
					STOPGOINGUP <= '0';
				end if;
				
				--if ((ball_y_pos > 300)) then--CONV_STD_LOGIC_VECTOR(480, 10) - size) or (ball_y_pos < size+1)) then
					 --ball_y_pos <= CONV_STD_LOGIC_VECTOR(280,10);
				--else
					-- Compute next ball Y position
				if reset = '0' then
					ball_y_pos <= (ball_y_pos + ball_y_motion);
				else
					ball_y_pos <= CONV_STD_LOGIC_VECTOR(280,10);
				end if;
				
				
				
        end if;
    end process Move_Ball;
	 
	 reset <= '1' when (pb1 = '0' and ball_y_pos >= CONV_STD_LOGIC_VECTOR(479,10)-size) else '0';

end behavior;