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

    signal drawBird : std_logic;
    signal size : signed(9 downto 0);
    signal yPos : signed(9 downto 0);
    signal xPos : signed(10 downto 0);
    signal yVelocity : signed(9 downto 0);
    signal STOPGOINGUP : std_logic; -- TODO: do we still need this?
    signal reset : std_logic;
    signal subpixel : signed(11 downto 0);

begin

    size <= TO_SIGNED(8, 10);
    -- xPos and yPos show the (x,y) for the centre of bird
    xPos <= TO_SIGNED(320, 11);

    drawBird <= '1' when (('0' & xPos <= '0' & pixel_column + size) and ('0' & pixel_column <= '0' & xPos + size) and ('0' & yPos <= pixel_row + size) and ('0' & pixel_row <= yPos + size)) else -- x_pos - size <= pixel_column <= x_pos + size
                '0'; -- y_pos - size <= pixel_row <= y_pos + size

    -- Colours for pixel data on video signal
    inPixel <= drawBird;

    red <= drawBird;
    green <= drawBird;
    blue <= '0';

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