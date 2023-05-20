library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity floor is
    port (
        clk, reset : in std_logic;
        pixel_row, pixel_column : in signed(9 downto 0);
        red, green, blue, in_pixel : out std_logic);
end floor;

architecture behaviour of floor is

    signal draw_floor : std_logic;

begin

    draw_floor <= '1' when (('0' & pixel_row >= TO_SIGNED(420, 10))) else
                  '0';

    in_pixel <= draw_floor;

    red <= draw_floor;
    green <= '0';
    blue <= '0';

end behaviour;