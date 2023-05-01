library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity bird is
    port (
        enable, pb1, pb2, clk, vert_sync : in std_logic;
        pixel_row, pixel_column : in signed(9 downto 0);
        red, inPixel, died : out std_logic);--green, blue, inPixel : out std_logic);
end bird;

architecture behavior of bird is

    signal ball_on : std_logic;
    signal size : signed(9 downto 0);
    signal ball_y_pos : signed(9 downto 0);
    signal ball_x_pos : signed(10 downto 0);
    signal ball_y_motion : signed(9 downto 0);
    signal STOPGOINGUP : std_logic;
    signal reset : std_logic;
    signal subpixel : signed(11 downto 0);

begin

    size <= TO_SIGNED(8, 10);
    -- ball_x_pos and ball_y_pos show the (x,y) for the centre of ball
    ball_x_pos <= TO_SIGNED(320, 11);

    ball_on <= '1' when (('0' & ball_x_pos <= '0' & pixel_column + size) and ('0' & pixel_column <= '0' & ball_x_pos + size) -- x_pos - size <= pixel_column <= x_pos + size
               and ('0' & ball_y_pos <= pixel_row + size) and ('0' & pixel_row <= ball_y_pos + size)) else -- y_pos - size <= pixel_row <= y_pos + size
               '0';

    -- Colours for pixel data on video signal
    -- Changing the background and ball colour by pushbuttons
    Red <= ball_on;
    inPixel <= ball_on;
    --Green <= not ball_on;
    --Blue <= not ball_on;

    Move_Ball : process (vert_sync)
    begin
        -- Move ball once every vertical sync
        if (rising_edge(vert_sync)) then
            if (enable = '1') then
                if (ball_y_pos <= 479 - size) then
                    if (pb2 = '1' and STOPGOINGUP = '0') then
                        subpixel <= TO_SIGNED(-200, 12);
                        STOPGOINGUP <= '1';
                    elsif (ball_y_motion < 10) then
                        subpixel <= (subpixel + 10);
                    elsif (ball_y_pos >= 479 - size) then
                        subpixel <= TO_SIGNED(0, 12);
                    end if;

                    if (pb2 = '0') then
                        STOPGOINGUP <= '0';
                    end if;

                    ball_y_motion <= shift_right(subpixel, 4)(11 downto 2);
                    ball_y_pos <= (ball_y_pos + ball_y_motion);
                    died <= '0';
                elsif reset = '1' then
                    ball_y_pos <= TO_SIGNED(280, 10);
                    died <= '0';
                else
                    ball_y_pos <= 480 - size;
                    died <= '1';
                end if;
            end if;
        end if;
    end process Move_Ball;

    reset <= '1' when (pb1 = '0' and ball_y_pos >= 479 - size) else
             '0';

end behavior;