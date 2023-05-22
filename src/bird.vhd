library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity bird is
    port (
        clk, reset, enable, flap, hovering : in std_logic;
        pixel_row, pixel_column : in signed(9 downto 0);
        red, green, blue, in_pixel, hit_floor : out std_logic);
end bird;

architecture behaviour of bird is

    signal draw_bird : std_logic;

    signal size : signed(9 downto 0);

    signal y_pos : signed(9 downto 0);
    signal x_pos : signed(10 downto 0);
    signal y_velocity : signed(9 downto 0);
    signal sub_pixel : signed(11 downto 0) := TO_SIGNED(0, 12);

    signal flapped_flag : std_logic;

begin

    size <= TO_SIGNED(8, 10);
    -- x_pos and y_pos show the (x,y) for the centre of bird
    x_pos <= TO_SIGNED(320, 11);

    draw_bird <= '1' when (('0' & x_pos <= '0' & pixel_column + size) and ('0' & pixel_column <= '0' & x_pos + size) and ('0' & y_pos <= pixel_row + size) and ('0' & pixel_row <= y_pos + size)) else -- x_pos - size <= pixel_column <= x_pos + size
                 '0'; -- y_pos - size <= pixel_row <= y_pos + size

    -- Colours for pixel data on video signal
    in_pixel <= draw_bird;

    red <= draw_bird;
    green <= draw_bird;
    blue <= '0';

    move_bird : process (clk)
    begin
        -- Move bird once every vertical sync
        if (rising_edge(clk)) then
            if (reset = '1') then
                sub_pixel <= TO_SIGNED(0, 12);
                y_pos <= TO_SIGNED(280, 10);
                hit_floor <= '0';
            elsif (hovering = '1') then
                if (y_pos >= 300) then
                    sub_pixel <= (sub_pixel - 8);
                elsif (y_pos <= 260) then
                    sub_pixel <= (sub_pixel + 8);
                end if;

                y_velocity <= shift_right(sub_pixel, 4)(11 downto 2);
                y_pos <= (y_pos + y_velocity);

            elsif (enable = '1') then
                if (y_pos <= 479 - size) then
                    if (flap = '1' and flapped_flag = '0') then
                        sub_pixel <= TO_SIGNED(-200, 12);
                        flapped_flag <= '1';
                    elsif (y_velocity < 10) then
                        sub_pixel <= (sub_pixel + 10);
                    elsif (y_pos >= 479 - size) then
                        sub_pixel <= TO_SIGNED(0, 12);
                    end if;

                    if (flap = '0') then
                        flapped_flag <= '0';
                    end if;

                    y_velocity <= shift_right(sub_pixel, 4)(11 downto 2);
                    y_pos <= (y_pos + y_velocity);
                    hit_floor <= '0';
                else
                    y_pos <= 480 - size;
                    hit_floor <= '1';
                end if;
            end if;
        end if;
    end process move_bird;

end behaviour;