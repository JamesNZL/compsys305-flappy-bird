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
    signal size1 : signed(9 downto 0);
    signal size2 : signed(9 downto 0);
    signal size3 : signed(9 downto 0);
    signal size4 : signed(9 downto 0);
    signal size5 : signed(9 downto 0);
    signal size6 : signed(9 downto 0);
    signal size7 : signed(9 downto 0);

    signal xPos323 : signed(10 downto 0);
    signal xPos324 : signed(10 downto 0);
    signal xPos326 : signed(10 downto 0);
    signal xPos311 : signed(10 downto 0);
    signal xPos313 : signed(10 downto 0);
    signal xPos314 : signed(10 downto 0);
    signal xPos315 : signed(10 downto 0);
    signal xPos316 : signed(10 downto 0);

    signal y_pos : signed(9 downto 0);
    signal y_velocity : signed(9 downto 0);
    signal sub_pixel : signed(11 downto 0);

    signal flapped_flag : std_logic;

begin

    size <= TO_SIGNED(25, 10);
    --    -- xPos and y_pos show the (x,y) for the centre of bird
    --    xPos <= TO_SIGNED(320, 11);

    size1 <= TO_SIGNED(1, 10);
    size2 <= TO_SIGNED(2, 10);
    size3 <= TO_SIGNED(3, 10);
    size4 <= TO_SIGNED(4, 10);
    size5 <= TO_SIGNED(5, 10);
    size6 <= TO_SIGNED(6, 10);
    size7 <= TO_SIGNED(7, 10);

    xPos323 <= TO_SIGNED(323, 11);
    xPos324 <= TO_SIGNED(324, 11);
    xPos326 <= TO_SIGNED(326, 11);

    xPos311 <= TO_SIGNED(315, 11);
    xPos313 <= TO_SIGNED(317, 11);
    xPos314 <= TO_SIGNED(318, 11);
    xPos315 <= TO_SIGNED(319, 11);
    xPos316 <= TO_SIGNED(320, 11);

    --    drawBird <= '1' when (('0' & xPos <= '0' & pixel_column + size) and ('0' & pixel_column <= '0' & xPos + size) and ('0' & y_pos <= pixel_row + size) and ('0' & pixel_row <= y_pos + size)) else -- x_pos - size <= pixel_column <= x_pos + size
    --                '0'; -- y_pos - size <= pixel_row <= y_pos + size
    --					 
    draw_bird <= '1' when (
                 --head
                 (('0' & xPos323) <= ('0' & pixel_column + size2) and ('0' & pixel_column <= '0' & xPos323 + size2) and ('0' & y_pos) = pixel_row) or
                 (('0' & xPos323) <= ('0' & pixel_column + size3) and ('0' & pixel_column <= '0' & xPos323 + size3) and ('0' & (y_pos + 1)) = pixel_row) or
                 (('0' & xPos323) <= ('0' & pixel_column + size3) and ('0' & pixel_column <= '0' & xPos323 + size3) and ('0' & (y_pos + 2)) = pixel_row) or
                 
                 (('0' & xPos324) <= ('0' & pixel_column + size4) and ('0' & pixel_column <= '0' & xPos324 + size4) and ('0' & (y_pos + 3)) = pixel_row) or
                 (('0' & xPos324) <= ('0' & pixel_column + size4) and ('0' & pixel_column <= '0' & xPos324 + size4) and ('0' & (y_pos + 4)) = pixel_row) or
                 
                 (('0' & xPos326) <= ('0' & pixel_column + size6) and ('0' & pixel_column <= '0' & xPos326 + size6) and ('0' & (y_pos + 5)) = pixel_row) or
                 (('0' & xPos326) <= ('0' & pixel_column + size6) and ('0' & pixel_column <= '0' & xPos326 + size6) and ('0' & (y_pos + 6)) = pixel_row) or
                 (('0' & xPos323) <= ('0' & pixel_column + size3) and ('0' & pixel_column <= '0' & xPos323 + size3) and ('0' & (y_pos + 7)) = pixel_row) or
                 (('0' & xPos323) <= ('0' & pixel_column + size3) and ('0' & pixel_column <= '0' & xPos323 + size3) and ('0' & (y_pos + 8)) = pixel_row) or
                 (('0' & xPos323) <= ('0' & pixel_column + size2) and ('0' & pixel_column <= '0' & xPos323 + size2) and ('0' & (y_pos + 9)) = pixel_row) or
                 (('0' & xPos323) <= ('0' & pixel_column + size2) and ('0' & pixel_column <= '0' & xPos323 + size2) and ('0' & (y_pos + 10)) = pixel_row) or
                 
                 --body
                 (('0' & xPos315) <= ('0' & pixel_column + size5) and ('0' & pixel_column <= '0' & xPos315 + size5) and ('0' & (y_pos + 11)) = pixel_row) or
                 (('0' & xPos314) <= ('0' & pixel_column + size6) and ('0' & pixel_column <= '0' & xPos314 + size6) and ('0' & (y_pos + 12)) = pixel_row) or
                 (('0' & xPos313) <= ('0' & pixel_column + size7) and ('0' & pixel_column <= '0' & xPos313 + size7) and ('0' & (y_pos + 13)) = pixel_row) or
                 
                 (('0' & xPos313) <= ('0' & pixel_column + size7) and ('0' & pixel_column <= '0' & xPos313 + size7) and ('0' & (y_pos + 14)) = pixel_row) or
                 (('0' & xPos313) <= ('0' & pixel_column + size7) and ('0' & pixel_column <= '0' & xPos313 + size7) and ('0' & (y_pos + 15)) = pixel_row) or
                 (('0' & xPos313) <= ('0' & pixel_column + size7) and ('0' & pixel_column <= '0' & xPos313 + size7) and ('0' & (y_pos + 16)) = pixel_row) or
                 (('0' & xPos313) <= ('0' & pixel_column + size7) and ('0' & pixel_column <= '0' & xPos313 + size7) and ('0' & (y_pos + 17)) = pixel_row) or
                 (('0' & xPos313) <= ('0' & pixel_column + size7) and ('0' & pixel_column <= '0' & xPos313 + size7) and ('0' & (y_pos + 18)) = pixel_row) or
                 (('0' & xPos313) <= ('0' & pixel_column + size7) and ('0' & pixel_column <= '0' & xPos313 + size7) and ('0' & (y_pos + 19)) = pixel_row) or
                 
                 (('0' & xPos313) <= ('0' & pixel_column + size6) and ('0' & pixel_column <= '0' & xPos313 + size6) and ('0' & (y_pos + 20)) = pixel_row) or
                 (('0' & xPos313) <= ('0' & pixel_column + size5) and ('0' & pixel_column <= '0' & xPos313 + size5) and ('0' & (y_pos + 21)) = pixel_row) or
                 
                 --feet
                 
                 (('0' & xPos311) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos311 + size1) and ('0' & (y_pos + 22)) = pixel_row) or
                 (('0' & xPos316) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos316 + size1) and ('0' & (y_pos + 22)) = pixel_row) or
                 
                 (('0' & xPos311) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos311 + size1) and ('0' & (y_pos + 23)) = pixel_row) or
                 (('0' & xPos316) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos316 + size1) and ('0' & (y_pos + 23)) = pixel_row) or
                 
                 (('0' & xPos311) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos311 + size1) and ('0' & (y_pos + 24)) = pixel_row) or
                 (('0' & xPos316) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos316 + size1) and ('0' & (y_pos + 24)) = pixel_row) or
                 
                 (('0' & xPos311) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos311 + size1) and ('0' & (y_pos + 25)) = pixel_row) or
                 (('0' & xPos316) <= ('0' & pixel_column + size1) and ('0' & pixel_column <= '0' & xPos316 + size1) and ('0' & (y_pos + 25)) = pixel_row)
                 
                 ) else
                 '0';

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