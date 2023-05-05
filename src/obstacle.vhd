library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity obstacle is
    port (
        enable, pb1, clk, vert_sync : in std_logic; -- TODO: we probably don't need clk in these entities
        lfsrSeed : in std_logic_vector(8 downto 1);
        start_xPos : in signed(10 downto 0);
        pixel_row, pixel_column : in signed(9 downto 0);
        red, green, blue, inPixel : out std_logic);
end obstacle;

architecture behavior of obstacle is

    component lfsr is
        port (
            clk, reset, enable : in std_logic;
            seed : std_logic_vector(8 downto 1);
            lfsrOutput : out std_logic_vector (7 downto 0));
    end component;

    signal obstacle_on : std_logic;
    signal gapSize : signed(9 downto 0);
    signal pipeWidth : signed(9 downto 0);
    signal lfsrClock : std_logic := '0';
    signal lfsrOutput : std_logic_vector(7 downto 0);
    signal gapCentre : signed(9 downto 0);
    signal xPos : signed(10 downto 0) := start_xPos;
    signal xVelocity : signed(9 downto 0) := TO_SIGNED(3, 10); -- TODO: increase over course of game
    signal reset : std_logic;
    signal drawObstacle : std_logic;

begin

    shifty : lfsr
    port map(
        clk => lfsrClock,
        reset => pb1,
        enable => enable,
        seed => lfsrSeed,
        lfsrOutput => lfsrOutput);

    gapSize <= TO_SIGNED(35, 10);
    pipeWidth <= TO_SIGNED(25, 10);

    -- Use a 7-bit LFSR with 255 loop size to generate a signed offset about the middle of the screen
    -- This ensures all gapCentres will be valid, with a reasonable (112px) buffer from the top/bottom
    gapCentre <= signed(lfsrOutput) + TO_SIGNED(240, 10);

    drawObstacle <= '1' when (('0' & xPos <= '0' & pixel_column + pipeWidth) and ('0' & pixel_column <= '0' & xPos + pipeWidth) and (('0' & gapCentre >= pixel_row + gapSize) or ('0' & pixel_row >= gapCentre + gapSize))) else
                    '1' when ((xPos <= pixel_column + pipeWidth) and (pixel_column <= xPos + pipeWidth) and ((gapCentre >= pixel_row + gapSize) or (pixel_row >= gapCentre + gapSize))) else
                    '0';

    inPixel <= drawObstacle;

    red <= '0';
    green <= drawObstacle;
    blue <= '0';

    moveObstacle : process (vert_sync)
    begin
        if (rising_edge(vert_sync)) then
            if (enable = '1') then

                if ((reset = '0') and (xPos > (-pipeWidth))) then -- TODO: does this need a '0' concatenated in front?
                    xPos <= xPos - xVelocity;
                    lfsrClock <= '0';
                elsif (reset = '1') then
                    xPos <= start_xPos + pipeWidth;
                    lfsrClock <= '0';
                else
                    -- Wrap around
                    xPos <= TO_SIGNED(639, 11) + pipeWidth;
                    lfsrClock <= '1';
                end if;

            end if;
        end if;
    end process moveObstacle;

    reset <= '1' when (pb1 = '0') else
             '0';

end behavior;