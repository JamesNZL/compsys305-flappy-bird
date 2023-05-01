library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity ball is
    port (
        clk : in std_logic;
        pixel_row, pixel_column : in std_logic_vector(9 downto 0);
        red, green, blue : out std_logic);
end ball;

architecture behavior of ball is

    signal ball_on : std_logic;
    signal size : std_logic_vector(9 downto 0);
    signal ball_y_pos, ball_x_pos : std_logic_vector(9 downto 0);

begin

    size <= CONV_STD_LOGIC_VECTOR(8, 10);
    -- ball_x_pos and ball_y_pos show the (x,y) for the centre of ball
    ball_x_pos <= CONV_STD_LOGIC_VECTOR(100, 10);
    ball_y_pos <= CONV_STD_LOGIC_VECTOR(350, 10);

    ball_on <= '1' when (('0' & ball_x_pos <= pixel_column + size) and ('0' & pixel_column <= ball_x_pos + size) -- x_pos - size <= pixel_column <= x_pos + size
               and ('0' & ball_y_pos <= pixel_row + size) and ('0' & pixel_row <= ball_y_pos + size)) else -- y_pos - size <= pixel_row <= y_pos + size
               '0';

    -- Colours for pixel data on video signal
    -- Keeping background white and square in red
    Red <= '1';
    -- Turn off Green and Blue when displaying square
    Green <= not ball_on;
    Blue <= not ball_on;

end behavior;