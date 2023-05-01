library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity obstacle is
    port (
        enable, pb1, clk, vert_sync : in std_logic;
        pixel_row, pixel_column : in signed(9 downto 0);
        green, inPixel : out std_logic);--red, green, blue, inPixel : out std_logic);
end obstacle;

architecture behavior of obstacle is

    signal obstacle_on : std_logic;
    signal gapSize : signed(9 downto 0);
    signal pipeWidth : signed(9 downto 0);
    signal gapCenter : signed(9 downto 0);
    signal xPos : signed(10 downto 0) := TO_SIGNED(640, 11);
    signal xVelocity : signed(9 downto 0) := TO_SIGNED(5, 10);
    signal reset : std_logic;
    signal drawObstacle : std_logic;

begin

    gapSize <= TO_SIGNED(25, 10);
    gapCenter <= TO_SIGNED(280, 10);
    pipeWidth <= TO_SIGNED(25, 10);

    drawObstacle <= '1' when (('0' & xPos <= '0' & pixel_row + pipeWidth) and ('0' & pixel_row <= '0' & xPos + pipeWidth)
                    and (('0' & gapCenter >= pixel_column + gapSize) or ('0' & pixel_column >= gapCenter + gapSize))) else
                    '0';

    Green <= drawObstacle;

    move_obstacle : process (vert_sync)
    begin
        if (rising_edge(vert_sync)) then

            if (reset = '0') then
                xPos <= xPos - xVelocity;
            else
                xPos <= TO_SIGNED(640, 11);
            end if;

        end if;
    end process move_obstacle;

    reset <= '1' when (pb1 = '0') else
             '0';

    inPixel <= drawObstacle;

end behavior;