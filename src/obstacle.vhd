library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity obstacle is
    port (
        clk, reset, enable : in std_logic;
        lfsr_seed : in std_logic_vector(8 downto 1);
        start_x_pos : in signed(10 downto 0);
        x_velocity : in signed(9 downto 0);
        pixel_row, pixel_column : in signed(9 downto 0);
        red, green, blue, in_pixel, score_tick, collision_tick : out std_logic);
end obstacle;

architecture behaviour of obstacle is

    component lfsr is
        port (
            clk, reset, enable : in std_logic;
            seed : std_logic_vector(8 downto 1);
            lfsr_out : out std_logic_vector (7 downto 0));
    end component;

    signal lfsr_clk : std_logic := '0';
    signal lfsr_out : std_logic_vector(7 downto 0);

    signal draw_obs : std_logic;

    signal pipe_width : signed(9 downto 0);
    signal gap_size : signed(9 downto 0);
    signal gap_centre : signed(9 downto 0);

    signal x_pos : signed(10 downto 0) := start_x_pos;

begin

    shifty : lfsr
    port map(
        clk => lfsr_clk,
        reset => reset,
        enable => enable,
        seed => lfsr_seed,
        lfsr_out => lfsr_out);

    gap_size <= TO_SIGNED(35, 10);
    pipe_width <= TO_SIGNED(25, 10);

    -- Use a 7-bit LFSR with 255 loop size to generate a signed offset about the middle of the screen
    -- This ensures all gap_centres will be valid, with a reasonable (112px) buffer from the top/bottom
    gap_centre <= signed(lfsr_out) + TO_SIGNED(240, 10);

    draw_obs <= '0' when (reset = '1') else
                '1' when (('0' & x_pos <= '0' & pixel_column + pipe_width) and ('0' & pixel_column <= '0' & x_pos + pipe_width) and (('0' & gap_centre >= pixel_row + gap_size) or ('0' & pixel_row >= gap_centre + gap_size))) else
                '1' when ((x_pos <= pixel_column + pipe_width) and (pixel_column <= x_pos + pipe_width) and ((gap_centre >= pixel_row + gap_size) or (pixel_row >= gap_centre + gap_size))) else
                '0';

    score_tick <= '1' when ((x_pos >= 300) and (x_pos <= 340)) else
                  '0';

    collision_tick <= '1' when ((x_pos >= 200) and (x_pos <= 240)) else
                      '0';

    in_pixel <= draw_obs;

    red <= '0';
    green <= draw_obs;
    blue <= '0';

    move_obstacle : process (clk)
    begin
        if (rising_edge(clk)) then
            if (reset = '1') then
                x_pos <= start_x_pos + pipe_width;
                lfsr_clk <= '0';
            elsif (enable = '1') then

                if ((reset = '0') and (x_pos > (-pipe_width))) then
                    x_pos <= x_pos - x_velocity;
                    lfsr_clk <= '0';
                else
                    -- Wrap around
                    x_pos <= TO_SIGNED(639, 11) + pipe_width;
                    lfsr_clk <= '1';
                end if;

            end if;
        end if;
    end process move_obstacle;

end behaviour;