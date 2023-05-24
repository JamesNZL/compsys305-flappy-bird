library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity coin is
    port (
        clk, reset, enable, draw_enable : in std_logic;
        lfsr_seed : in std_logic_vector(8 downto 1);
        start_x_pos : in signed(10 downto 0);
        x_velocity : in signed(9 downto 0);
        pixel_row, pixel_column : in signed(9 downto 0);
        red, green, blue, in_pixel, coin_gone : out std_logic);
end coin;

architecture behaviour of coin is

    component lfsr is
        port (
            clk, reset, enable : in std_logic;
            seed : std_logic_vector(8 downto 1);
            lfsr_out : out std_logic_vector (7 downto 0));
    end component;

    signal lfsr_clk : std_logic := '0';
    signal lfsr_out : std_logic_vector(7 downto 0);

    signal draw_coin : std_logic;

    signal coin_width : signed(9 downto 0);

    signal y_pos : signed(9 downto 0);
    signal x_pos : signed(10 downto 0) := start_x_pos;

begin

    shifty : lfsr
    port map(
        clk => lfsr_clk,
        reset => reset,
        enable => enable,
        seed => lfsr_seed,
        lfsr_out => lfsr_out);

    coin_width <= TO_SIGNED(10, 10);

    -- Use a 7-bit LFSR with 255 loop size to generate a signed offset about the middle of the screen
    -- This ensures all gapCentres will be valid, with a reasonable (112px) buffer from the top/bottom
    y_pos <= signed(lfsr_out) + TO_SIGNED(150, 10);

    draw_coin <= '0' when (reset = '1') else
                 '1' when (('0' & x_pos <= '0' & pixel_column + coin_width) and ('0' & pixel_column <= '0' & x_pos + coin_width) and (('0' & y_pos <= pixel_row + coin_width) and ('0' & pixel_row <= y_pos + coin_width))) else
                 '0';

    in_pixel <= draw_coin;

    red <= draw_coin;
    green <= draw_coin;
    blue <= '0';

    move_coin : process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                x_pos <= start_x_pos + coin_width;
                lfsr_clk <= '0';
            elsif (enable = '1') then

                if ((reset = '0') and (x_pos > (-coin_width))) then
                    x_pos <= x_pos - x_velocity;
                    lfsr_clk <= '0';
                    coin_gone <= '0';
                else
                    -- Wrap around
                    x_pos <= TO_SIGNED(639, 11) + coin_width;
                    lfsr_clk <= '1';
                    coin_gone <= '1';
                end if;

            end if;
        end if;
    end process move_coin;

end behaviour;