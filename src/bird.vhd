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

    signal bird_on : std_logic;
    signal size : signed(9 downto 0);
    signal bird_y_pos : signed(9 downto 0);
    signal bird_x_pos : signed(10 downto 0);
    signal bird_y_motion : signed(9 downto 0);
    signal STOPGOINGUP : std_logic;
    signal reset : std_logic;
    signal subpixel : signed(11 downto 0);

begin

    size <= TO_SIGNED(8, 10);
    -- bird_x_pos and bird_y_pos show the (x,y) for the centre of bird
    bird_x_pos <= TO_SIGNED(320, 11);

    bird_on <= '1' when (('0' & bird_x_pos <= '0' & pixel_column + size) and ('0' & pixel_column <= '0' & bird_x_pos + size) and ('0' & bird_y_pos <= pixel_row + size) and ('0' & pixel_row <= bird_y_pos + size)) else -- x_pos - size <= pixel_column <= x_pos + size
               '0'; -- y_pos - size <= pixel_row <= y_pos + size

    -- Colours for pixel data on video signal
    inPixel <= bird_on;

    red <= bird_on;
    green <= bird_on;
    blue <= '0';

    moveBird : process (vert_sync)
    begin
        -- Move bird once every vertical sync
        if (rising_edge(vert_sync)) then
            if (enable = '1') then
                if (bird_y_pos <= 479 - size) then
                    if (pb2 = '1' and STOPGOINGUP = '0') then
                        subpixel <= TO_SIGNED(-200, 12);
                        STOPGOINGUP <= '1';
                    elsif (bird_y_motion < 10) then
                        subpixel <= (subpixel + 10);
                    elsif (bird_y_pos >= 479 - size) then
                        subpixel <= TO_SIGNED(0, 12);
                    end if;

                    if (pb2 = '0') then
                        STOPGOINGUP <= '0';
                    end if;

                    bird_y_motion <= shift_right(subpixel, 4)(11 downto 2);
                    bird_y_pos <= (bird_y_pos + bird_y_motion);
                    died <= '0';
                elsif reset = '1' then
                    bird_y_pos <= TO_SIGNED(280, 10);
                    died <= '0';
                else
                    bird_y_pos <= 480 - size;
                    died <= '1';
                end if;
            end if;
        end if;
    end process moveBird;

    reset <= '1' when (pb1 = '0' and bird_y_pos >= 479 - size) else
             '0';

end behavior;