-- Copyright (C) 2018  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel FPGA IP License Agreement, or other applicable license
-- agreement, including, without limitation, that your use is for
-- the sole purpose of programming logic devices manufactured by
-- Intel and sold by Intel or its authorized distributors.  Please
-- refer to the applicable agreement for further details.

-- PROGRAM		"Quartus Prime"
-- VERSION		"Version 18.1.0 Build 625 09/12/2018 SJ Standard Edition"
-- CREATED		"Sat Apr 29 15:09:55 2023"

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;

entity main is
    port (
        ref_clk : in std_logic;
        key0, key1, key2, key3 : in std_logic;
        red_out : out std_logic;
        green_out : out std_logic;
        blue_out : out std_logic;
        horiz_sync_out : out std_logic;
        vert_sync_out : out std_logic;
        PS2_CLK : inout std_logic;
        PS2_DAT : inout std_logic;
        HEX1 : out std_logic_vector(6 downto 0);
        HEX0 : out std_logic_vector(6 downto 0));
end main;

architecture flappy_bird of main is

    component pll
        port (
            refclk : in std_logic;
            rst : in std_logic;
            outclk_0 : out std_logic;
            locked : out std_logic);
    end component;

    component vga_sync
        port (
            clock_25Mhz : in std_logic;
            red : in std_logic;
            green : in std_logic;
            blue : in std_logic;
            red_out : out std_logic;
            green_out : out std_logic;
            blue_out : out std_logic;
            horiz_sync_out : out std_logic;
            vert_sync_out : out std_logic;
            pixel_column : out signed(9 downto 0);
            pixel_row : out signed(9 downto 0));
    end component;

    component fsm
        port (
            clk, reset_input : in std_logic;
            menu_navigator_1, menu_navigator_2 : in std_logic;
            mouse_right, mouse_left : in std_logic;
            obs_one_hit, obs_two_hit : in std_logic;

            -- bird states
            hit_floor : in std_logic;
            bird_hovering : out std_logic;

            lives_out : out unsigned(1 downto 0);
            heart_display : out std_logic;
            level_display : out std_logic;
            menu_enable : out std_logic;
            reset : out std_logic;

            movement_enable : out std_logic);
    end component;

    component mouse
        port (
            clock_25Mhz, reset : in std_logic;
            mouse_data : inout std_logic;
            mouse_clk : inout std_logic;
            mouse_left, mouse_right : out std_logic;
            mouse_cursor_row : out signed(9 downto 0);
            mouse_cursor_column : out signed(9 downto 0));
    end component;

    component bird
        port (
            clk, reset, enable, flap, hovering : in std_logic;
            pixel_row, pixel_column : in signed(9 downto 0);
            red, green, blue, in_pixel, hit_floor : out std_logic);
    end component;

    component floor is
        port (
            clk, reset : in std_logic;
            pixel_row, pixel_column : in signed(9 downto 0);
            red, green, blue, in_pixel : out std_logic);
    end component;

    component obstacle is
        port (
            clk, reset, enable : in std_logic;
            lfsr_seed : in std_logic_vector(8 downto 1);
            start_x_pos : in signed(10 downto 0);
            x_velocity : in signed(9 downto 0);
            pixel_row, pixel_column : in signed(9 downto 0);
            red, green, blue, in_pixel, score_tick, collision_tick : out std_logic);
    end component;

    component coin is
        port (
            clk, reset, enable, draw_enable : in std_logic;
            lfsr_seed : in std_logic_vector(8 downto 1);
            start_x_pos : in signed(10 downto 0);
            x_velocity : in signed(9 downto 0);
            pixel_row, pixel_column : in signed(9 downto 0);
            red, green, blue, in_pixel, coin_gone : out std_logic);
    end component;

    component score_counter is
        port (
            clk, reset, tick : in std_logic;
            set_next_digit : out std_logic;
            score_out : out std_logic_vector(3 downto 0));
    end component;

    component bcd_to_seven_seg is
        port (
            bcd_digit : in std_logic_vector(3 downto 0);
            seven_seg_out : out std_logic_vector(6 downto 0));
    end component;

    component char_rom is
        port (
            clk : in std_logic;
            character_address : in std_logic_vector (5 downto 0);
            font_row, font_col : in std_logic_vector (2 downto 0);
            rom_mux_output : out std_logic);
    end component;

    signal character_address : std_logic_vector(5 downto 0);
    signal font_row, font_col : std_logic_vector (2 downto 0);
    signal character_output : std_logic;

    signal clk : std_logic;
    signal reset : std_logic;

    signal vert_sync : std_logic;
    signal x_pixel, y_pixel : signed(9 downto 0);
    signal paint_r, paint_g, paint_b : std_logic;

    signal mouse_left_event, mouse_right_event : std_logic;
    signal mouse_row, mouse_column : signed(9 downto 0);

    signal menu_enable : std_logic;
    signal menu_r, menu_g, menu_b : std_logic;

    signal movement_enable : std_logic;
    signal obs_one_hit, obs_two_hit, hit_floor : std_logic := '0';

    signal bird_r, bird_g, bird_b : std_logic;
    signal bird_hovering : std_logic;
    signal bird_det : std_logic;
    signal bird_hit_floor : std_logic := '0';
    signal current_lives : unsigned(1 downto 0);

    signal floor_r, floor_g, floor_b : std_logic;
    signal floor_det : std_logic;

    signal obs_one_r, obs_one_g, obs_one_b : std_logic;
    signal obs_two_r, obs_two_g, obs_two_b : std_logic;
    signal obs_one_det, obs_two_det, obs_det : std_logic;
    signal obs_one_tick, obs_two_tick : std_logic;
    signal obs_one_pass, obs_two_pass : std_logic;

    signal obs_one_hit_flag : std_logic := '0';
    signal obs_two_hit_flag : std_logic := '0';

    signal coin_enable, coin_gone : std_logic;
    signal coin_r, coin_g, coin_b : std_logic;
    signal coin_det : std_logic;
    signal coin_tick : std_logic := '0';

    signal heart_r, heart_g, heart_b : std_logic;
    signal heart_det : std_logic;
    signal display_heart : std_logic;

    signal score_tens_tick, score_hundreds_tick : std_logic;
    signal score_ones, score_tens : std_logic_vector(3 downto 0);
    signal score_colour_r, score_colour_g, score_colour_b : std_logic;
    signal score_r, score_g, score_b : std_logic;
    signal score_det : std_logic;

    signal level : unsigned(2 downto 0);
    signal level_r, level_g, level_b : std_logic;
    signal level_det : std_logic;
    signal display_level : std_logic;
    signal velocity_x : signed(9 downto 0);
    signal high_score_ones, high_score_tens : unsigned(3 downto 0);

begin

    vert_sync_out <= vert_sync;
    -- reset <= not key0;

    clock_div : pll
    port map(
        refclk => ref_clk,
        rst => '0',
        outclk_0 => clk);

    vga : vga_sync
    port map(
        clock_25Mhz => clk,
        red => paint_r,
        green => paint_g,
        blue => paint_b,
        red_out => red_out,
        green_out => green_out,
        blue_out => blue_out,
        horiz_sync_out => horiz_sync_out,
        vert_sync_out => vert_sync,
        pixel_column => x_pixel,
        pixel_row => y_pixel);

    state_machine : fsm
    port map(
        clk => vert_sync,
        reset_input => not key0,
        menu_navigator_1 => not key3,
        menu_navigator_2 => not key2,
        mouse_right => mouse_right_event,
        mouse_left => mouse_left_event,
        obs_one_hit => obs_one_hit,
        obs_two_hit => obs_two_hit,
        hit_floor => hit_floor,
        bird_hovering => bird_hovering,
        lives_out => current_lives,
        menu_enable => menu_enable,
        heart_display => display_heart,
        level_display => display_level,
        reset => reset,
        movement_enable => movement_enable);

    mousey_mouse : mouse
    port map(
        clock_25Mhz => clk,
        reset => '0',
        mouse_data => PS2_DAT,
        mouse_clk => PS2_CLK,
        mouse_left => mouse_left_event,
        mouse_right => mouse_right_event,
        mouse_cursor_row => mouse_row,
        mouse_cursor_column => mouse_column);

    elon : bird
    port map(
        clk => vert_sync,
        reset => reset,
        enable => movement_enable,
        flap => mouse_left_event,
        hovering => bird_hovering,
        pixel_row => y_pixel,
        pixel_column => x_pixel,
        red => bird_r,
        green => bird_g,
        blue => bird_b,
        in_pixel => bird_det,
        hit_floor => bird_hit_floor);

    gnd : floor
    port map(
        clk => clk,
        reset => reset,
        pixel_row => y_pixel,
        pixel_column => x_pixel,
        red => floor_r,
        green => floor_g,
        blue => floor_b,
        in_pixel => floor_det);

    obstacle_one : obstacle
    port map(
        clk => vert_sync,
        reset => reset,
        enable => movement_enable,
        lfsr_seed => std_logic_vector(x_pixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_x_pos => TO_SIGNED(640, 11),
        x_velocity => velocity_x,
        pixel_row => y_pixel,
        pixel_column => x_pixel,
        red => obs_one_r,
        green => obs_one_g,
        blue => obs_one_b,
        in_pixel => obs_one_det,
        score_tick => obs_one_tick,
        collision_tick => obs_one_pass);

    obstacle_two : obstacle
    port map(
        clk => vert_sync,
        reset => reset,
        enable => movement_enable,
        lfsr_seed => std_logic_vector(y_pixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_x_pos => TO_SIGNED(960, 11),
        x_velocity => velocity_x,
        pixel_row => y_pixel,
        pixel_column => x_pixel,
        red => obs_two_r,
        green => obs_two_g,
        blue => obs_two_b,
        in_pixel => obs_two_det,
        score_tick => obs_two_tick,
        collision_tick => obs_two_pass);

    coin_one : coin
    port map(
        clk => vert_sync,
        reset => reset,
        enable => movement_enable,
        draw_enable => coin_enable,
        lfsr_seed => std_logic_vector(x_pixel(7 downto 0) xor y_pixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_x_pos => TO_SIGNED(830, 11),
        x_velocity => velocity_x,
        pixel_row => y_pixel,
        pixel_column => x_pixel,
        red => coin_r,
        green => coin_g,
        blue => coin_b,
        in_pixel => coin_det,
        coin_gone => coin_gone);

    score_display : char_rom
    port map(
        clk => clk,
        character_address => character_address,
        font_row => font_row,
        font_col => font_col,
        rom_mux_output => character_output);

    score_counter_ones : score_counter
    port map(
        clk => clk,
        reset => reset,
        tick => (obs_one_tick or obs_two_tick or coin_tick),
        set_next_digit => score_tens_tick,
        score_out => score_ones);

    score_counter_tens : score_counter
    port map(
        clk => clk,
        reset => reset,
        tick => score_tens_tick,
        set_next_digit => score_hundreds_tick,
        score_out => score_tens);

    seven_seg_ones : bcd_to_seven_seg
    port map(
        bcd_digit => score_ones,
        seven_seg_out => HEX0);

    seven_seg_tens : bcd_to_seven_seg
    port map(
        bcd_digit => score_tens,
        seven_seg_out => HEX1);

    ----------------LEVEL----------------

    level <= unsigned(score_tens)(2 downto 0);
    high_score_ones <= TO_UNSIGNED(0, 4) when (score_tens_tick = '1') else
                       unsigned(score_ones) when (high_score_ones < unsigned(score_ones)) else
                       high_score_ones;
    high_score_tens <= unsigned(score_tens) when (high_score_tens < unsigned(score_tens)) else
                       high_score_tens;

    with level select
        score_colour_r <= '0' when TO_UNSIGNED(0, 3), -- black
        '0' when TO_UNSIGNED(1, 3), -- blue
        '1' when TO_UNSIGNED(2, 3), -- magenta
        '1' when TO_UNSIGNED(3, 3), -- red
        '1' when TO_UNSIGNED(4, 3), -- white
        '1' when others; --white
    with level select
        score_colour_g <= '0' when TO_UNSIGNED(0, 3), -- black
        '0' when TO_UNSIGNED(1, 3), -- blue
        '0' when TO_UNSIGNED(2, 3), -- magenta
        '0' when TO_UNSIGNED(3, 3), -- red
        '1' when TO_UNSIGNED(4, 3), -- white
        '1' when others; --white
    with level select
        score_colour_b <= '0' when TO_UNSIGNED(0, 3), -- black
        '1' when TO_UNSIGNED(1, 3), -- blue
        '1' when TO_UNSIGNED(2, 3), -- magenta
        '0' when TO_UNSIGNED(3, 3), -- red
        '1' when TO_UNSIGNED(4, 3), -- white
        '1' when others; --white

    velocity_x <= ("000000" & signed(score_tens)) + 2 when (display_level = '1') else
        "0000000010";

    -------------------------------------

    -------------COLLISIONS--------------

    obs_det <= (obs_one_det or obs_two_det);

    detect_collisions : process (clk)
    begin
        if rising_edge(clk) then

            -- OBSTACLE ONE DETECTION

            if (key0 = '0') then
                obs_one_hit <= '0';
                obs_one_hit_flag <= '0';
            elsif (obs_one_pass = '1') then
                obs_one_hit <= '0';
                obs_one_hit_flag <= '0';
            elsif (bird_det = '1' and obs_one_det = '1' and obs_one_hit_flag = '0') then
                obs_one_hit <= '1';
                obs_one_hit_flag <= '1';
            end if;

            -- OBSTACLE TWO DETECTION

            if (key0 = '0') then
                obs_two_hit <= '0';
                obs_two_hit_flag <= '0';
            elsif (obs_two_pass = '1') then
                obs_two_hit <= '0';
                obs_two_hit_flag <= '0';
            elsif (bird_det = '1' and obs_two_det = '1' and obs_two_hit_flag = '0') then
                obs_two_hit <= '1';
                obs_two_hit_flag <= '1';
            end if;

            -- FLOOR DETECTION

            if (bird_det = '1' and floor_det = '1') then
                hit_floor <= '1';
            else
                hit_floor <= '0';
            end if;
        end if;

    end process detect_collisions;

    detect_coin : process (clk)
        variable flag : std_logic := '1';
        variable flag1 : std_logic := '1';
    begin
        if rising_edge(clk) then

            if (bird_det = '1' and coin_det = '1' and flag1 = '1') then
                coin_tick <= '1';
                flag := '0';
                flag1 := '0';
            elsif (coin_gone = '1') then
                flag := '1';
                flag1 := '1';
            elsif (flag1 = '0') then
                coin_tick <= '0';
            end if;

            if (flag = '0') then
                coin_enable <= '0';
            else
                coin_enable <= '1';

            end if;
        end if;
    end process detect_coin;

    ----------------------------------

    -------------DRAWING--------------

    paint_screen : process (clk)
    begin
        if (rising_edge(clk)) then

            ---BOX PRINTED
            if (menu_enable = '1') then

                paint_r <= menu_r;
                paint_g <= menu_g;
                paint_b <= menu_b;

            elsif (score_det = '1') then
                paint_r <= score_r;
                paint_g <= score_g;
                paint_b <= score_b;

            elsif (heart_det = '1') then
                paint_r <= heart_r;
                paint_g <= heart_g;
                paint_b <= heart_b;

            elsif (level_det = '1') then

                paint_r <= level_r;
                paint_g <= level_g;
                paint_b <= level_b;

            elsif (bird_det = '1') then
                paint_r <= bird_r;
                paint_g <= bird_g;
                paint_b <= bird_b;

            elsif (floor_det = '1') then
                paint_r <= floor_r;
                paint_g <= floor_g;
                paint_b <= floor_b;

            elsif (obs_det = '1') then
                paint_r <= (obs_one_r or obs_two_r);
                paint_g <= (obs_one_g or obs_two_g);
                paint_b <= (obs_one_b or obs_two_b);

            elsif (coin_det = '1' and coin_enable = '1') then
                paint_r <= coin_r;
                paint_g <= coin_g;
                paint_b <= coin_b;

            else
                paint_r <= '0';
                paint_g <= '1';
                paint_b <= '1';

            end if;
        end if;
    end process paint_screen;

    get_characters : process (clk)
        variable int_value : integer;
        variable ones_score : integer;
        variable tens_score : integer;
    begin

        if (rising_edge(clk)) then

            if (menu_enable = '1') then

                -- Drawing the menu
                if ((x_pixel >= 170 and x_pixel < 470) and (y_pixel >= 130 and y_pixel < 350)) then

                    if ((x_pixel >= 175 and x_pixel < 465) and (y_pixel >= 135 and y_pixel < 345)) then

                        ---FLAPPYBIRD PRINTED
                        if ((x_pixel >= 225 and x_pixel < 241) and (y_pixel >= 150 and y_pixel < 166)) then

                            character_address <= "000110";

                            font_col <= std_logic_vector(x_pixel - 225)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 241 and x_pixel < 257) and (y_pixel >= 150 and y_pixel < 166)) then
                            character_address <= "001100";

                            font_col <= std_logic_vector(x_pixel - 241)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 257 and x_pixel < 273) and (y_pixel >= 150 and y_pixel < 166)) then

                            character_address <= "000001";

                            font_col <= std_logic_vector(x_pixel - 257)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 273 and x_pixel < 289) and (y_pixel >= 150 and y_pixel < 166)) then

                            character_address <= "010000";

                            font_col <= std_logic_vector(x_pixel - 273)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 289 and x_pixel < 305) and (y_pixel >= 150 and y_pixel < 166)) then

                            character_address <= "010000";

                            font_col <= std_logic_vector(x_pixel - 289)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 305 and x_pixel < 321) and (y_pixel >= 150 and y_pixel < 166)) then

                            character_address <= "011001";

                            font_col <= std_logic_vector(x_pixel - 305)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 345 and x_pixel < 361) and (y_pixel >= 150 and y_pixel < 166)) then
                            character_address <= "000010";

                            font_col <= std_logic_vector(x_pixel - 345)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 361 and x_pixel < 377) and (y_pixel >= 150 and y_pixel < 166)) then

                            character_address <= "001001";

                            font_col <= std_logic_vector(x_pixel - 361)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 377 and x_pixel < 393) and (y_pixel >= 150 and y_pixel < 166)) then

                            character_address <= "010010";

                            font_col <= std_logic_vector(x_pixel - 377)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 393 and x_pixel < 409) and (y_pixel >= 150 and y_pixel < 166)) then

                            character_address <= "000100";

                            font_col <= std_logic_vector(x_pixel - 393)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                            ---HIGHSCORE------

                        elsif ((x_pixel >= 225 and x_pixel < 241) and (y_pixel >= 180 and y_pixel < 196)) then

                            character_address <= "001000";

                            font_col <= std_logic_vector(x_pixel - 225)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 241 and x_pixel < 257) and (y_pixel >= 180 and y_pixel < 196)) then
                            character_address <= "001001";

                            font_col <= std_logic_vector(x_pixel - 241)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 257 and x_pixel < 273) and (y_pixel >= 180 and y_pixel < 196)) then

                            character_address <= "000111";

                            font_col <= std_logic_vector(x_pixel - 257)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 273 and x_pixel < 289) and (y_pixel >= 180 and y_pixel < 196)) then

                            character_address <= "001000";

                            font_col <= std_logic_vector(x_pixel - 273)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 289 and x_pixel < 305) and (y_pixel >= 180 and y_pixel < 196)) then

                            character_address <= "010011";

                            font_col <= std_logic_vector(x_pixel - 289)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 305 and x_pixel < 321) and (y_pixel >= 180 and y_pixel < 196)) then

                            character_address <= "000011";

                            font_col <= std_logic_vector(x_pixel - 305)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 321 and x_pixel < 337) and (y_pixel >= 180 and y_pixel < 196)) then
                            character_address <= "001111";

                            font_col <= std_logic_vector(x_pixel - 321)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 337 and x_pixel < 353) and (y_pixel >= 180 and y_pixel < 196)) then

                            character_address <= "010010";

                            font_col <= std_logic_vector(x_pixel - 337)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 353 and x_pixel < 369) and (y_pixel >= 180 and y_pixel < 196)) then

                            character_address <= "000101";

                            font_col <= std_logic_vector(x_pixel - 353)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                            ---NUMBERS

                        elsif ((x_pixel >= 393 and x_pixel < 409) and (y_pixel >= 180 and y_pixel < 196)) then

                            ones_score := to_integer(high_score_tens) + 48;

                            character_address <= std_logic_vector(to_unsigned(ones_score, 6));

                            font_col <= std_logic_vector(x_pixel - 393)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 409 and x_pixel < 425) and (y_pixel >= 180 and y_pixel < 196)) then

                            tens_score := to_integer(high_score_ones) + 48;

                            character_address <= std_logic_vector(to_unsigned(tens_score, 6));

                            font_col <= std_logic_vector(x_pixel - 409)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 180)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                            ----TRAIN PRINTED--------

                        elsif ((x_pixel >= 190 and x_pixel < 206) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "010100";

                            font_col <= std_logic_vector(x_pixel - 190)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 206 and x_pixel < 222) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "010010";

                            font_col <= std_logic_vector(x_pixel - 206)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 222 and x_pixel < 238) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "000001";

                            font_col <= std_logic_vector(x_pixel - 222)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 238 and x_pixel < 254) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "001001";

                            font_col <= std_logic_vector(x_pixel - 238)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 254 and x_pixel < 270) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "001110";

                            font_col <= std_logic_vector(x_pixel - 254)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                            ----PRINY[KEY3]------

                        elsif ((x_pixel >= 354 and x_pixel < 370) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "011011";

                            font_col <= std_logic_vector(x_pixel - 354)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 370 and x_pixel < 386) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "001011";

                            font_col <= std_logic_vector(x_pixel - 370)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 386 and x_pixel < 402) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "000101";

                            font_col <= std_logic_vector(x_pixel - 386)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 402 and x_pixel < 418) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "011001";

                            font_col <= std_logic_vector(x_pixel - 402)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 418 and x_pixel < 434) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "110011";

                            font_col <= std_logic_vector(x_pixel - 418)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 434 and x_pixel < 450) and (y_pixel >= 215 and y_pixel < 231)) then
                            character_address <= "011101";

                            font_col <= std_logic_vector(x_pixel - 434)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 215)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                            ----PRINT GAME-----

                        elsif ((x_pixel >= 190 and x_pixel < 206) and (y_pixel >= 280 and y_pixel < 296)) then
                            character_address <= "010000";

                            font_col <= std_logic_vector(x_pixel - 190)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 280)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 206 and x_pixel < 222) and (y_pixel >= 280 and y_pixel < 296)) then
                            character_address <= "001100";

                            font_col <= std_logic_vector(x_pixel - 206)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 280)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 222 and x_pixel < 238) and (y_pixel >= 280 and y_pixel < 296)) then
                            character_address <= "000001";

                            font_col <= std_logic_vector(x_pixel - 222)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 280)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 238 and x_pixel < 254) and (y_pixel >= 280 and y_pixel < 296)) then
                            character_address <= "011001";

                            font_col <= std_logic_vector(x_pixel - 238)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 280)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;
                            -----PRINT [KEY2]------

                        elsif ((x_pixel >= 354 and x_pixel < 370) and (y_pixel >= 280 and y_pixel < 296)) then
                            character_address <= "011011";

                            font_col <= std_logic_vector(x_pixel - 354)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 280)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 370 and x_pixel < 386) and (y_pixel >= 280 and y_pixel < 296)) then
                            character_address <= "001011";

                            font_col <= std_logic_vector(x_pixel - 370)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 280)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 386 and x_pixel < 402) and (y_pixel >= 280 and y_pixel < 296)) then
                            character_address <= "000101";

                            font_col <= std_logic_vector(x_pixel - 386)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 280)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 402 and x_pixel < 418) and (y_pixel >= 280 and y_pixel < 296)) then
                            character_address <= "011001";

                            font_col <= std_logic_vector(x_pixel - 402)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 280)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 418 and x_pixel < 434) and (y_pixel >= 280 and y_pixel < 296)) then
                            character_address <= "110010";

                            font_col <= std_logic_vector(x_pixel - 418)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 280)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        elsif ((x_pixel >= 434 and x_pixel < 450) and (y_pixel >= 280 and y_pixel < 296)) then
                            character_address <= "011101";

                            font_col <= std_logic_vector(x_pixel - 434)(3 downto 1);
                            font_row <= std_logic_vector(y_pixel - 280)(3 downto 1);

                            if (character_output = '1') then
                                menu_r <= '1';
                                menu_g <= '1';
                                menu_b <= '1';
                            else
                                menu_r <= '0';
                                menu_g <= '0';
                                menu_b <= '0';
                            end if;

                        else
                            menu_r <= '0';
                            menu_g <= '0';
                            menu_b <= '0';

                        end if;

                    else

                        menu_r <= '1';
                        menu_g <= '1';
                        menu_b <= '1';

                    end if;

                else
                    menu_r <= '0';
                    menu_g <= '1';
                    menu_b <= '1';
                end if;

            else
                -- Drawing the score (tens)
                if ((x_pixel >= 10 and x_pixel < 42) and (y_pixel >= 10 and y_pixel < 42)) then

                    int_value := to_integer(unsigned(score_tens)) + 48;
                    character_address <= std_logic_vector(to_unsigned(int_value, 6));

                    font_col <= std_logic_vector(x_pixel - 10)(4 downto 2);
                    font_row <= std_logic_vector(y_pixel - 10)(4 downto 2);

                    if (character_output = '1') then
                        score_r <= score_colour_r;
                        score_g <= score_colour_g;
                        score_b <= score_colour_b;
                    end if;

                    score_det <= character_output;

                    -- Drawing the score (ones)
                elsif ((x_pixel >= 45 and x_pixel < 77) and (y_pixel >= 10 and y_pixel < 42)) then

                    int_value := to_integer(unsigned(score_ones)) + 48;
                    character_address <= std_logic_vector(to_unsigned(int_value, 6));

                    font_col <= std_logic_vector(x_pixel - 45)(4 downto 2);
                    font_row <= std_logic_vector(y_pixel - 10)(4 downto 2);

                    if (character_output = '1') then
                        score_r <= score_colour_r;
                        score_g <= score_colour_g;
                        score_b <= score_colour_b;
                    end if;

                    score_det <= character_output;

                    ---print level--------

                elsif ((x_pixel >= 10 and x_pixel < 26) and (y_pixel >= 442 and y_pixel < 458) and (display_level = '1')) then
                    character_address <= "001100";

                    font_col <= std_logic_vector(x_pixel - 10)(3 downto 1);
                    font_row <= std_logic_vector(y_pixel - 442)(3 downto 1);

                    if (character_output = '1') then
                        level_r <= '1';
                        level_g <= '1';
                        level_b <= '1';
                    end if;

                    level_det <= character_output;

                elsif ((x_pixel >= 26 and x_pixel < 42) and (y_pixel >= 442 and y_pixel < 458) and (display_level = '1')) then
                    character_address <= "000101";

                    font_col <= std_logic_vector(x_pixel - 26)(3 downto 1);
                    font_row <= std_logic_vector(y_pixel - 442)(3 downto 1);

                    if (character_output = '1') then
                        level_r <= '1';
                        level_g <= '1';
                        level_b <= '1';
                    end if;

                    level_det <= character_output;

                elsif ((x_pixel >= 42 and x_pixel < 58) and (y_pixel >= 442 and y_pixel < 458) and (display_level = '1')) then
                    character_address <= "010110";

                    font_col <= std_logic_vector(x_pixel - 42)(3 downto 1);
                    font_row <= std_logic_vector(y_pixel - 442)(3 downto 1);

                    if (character_output = '1') then
                        level_r <= '1';
                        level_g <= '1';
                        level_b <= '1';
                    end if;

                    level_det <= character_output;

                elsif ((x_pixel >= 58 and x_pixel < 74) and (y_pixel >= 442 and y_pixel < 458) and (display_level = '1')) then
                    character_address <= "000101";

                    font_col <= std_logic_vector(x_pixel - 58)(3 downto 1);
                    font_row <= std_logic_vector(y_pixel - 442)(3 downto 1);

                    if (character_output = '1') then
                        level_r <= '1';
                        level_g <= '1';
                        level_b <= '1';
                    end if;

                    level_det <= character_output;

                elsif ((x_pixel >= 74 and x_pixel < 90) and (y_pixel >= 442 and y_pixel < 458) and (display_level = '1')) then
                    character_address <= "001100";

                    font_col <= std_logic_vector(x_pixel - 74)(3 downto 1);
                    font_row <= std_logic_vector(y_pixel - 442)(3 downto 1);

                    if (character_output = '1') then
                        level_r <= '1';
                        level_g <= '1';
                        level_b <= '1';
                    end if;

                    level_det <= character_output;

                    ---LEVEL ---- 

                elsif ((x_pixel >= 106 and x_pixel < 122) and (y_pixel >= 442 and y_pixel < 458) and (display_level = '1')) then

                    if (level = 0) then
                        character_address <= "110001";
                    elsif (level = 1) then
                        character_address <= "110010";
                    elsif (level = 2) then
                        character_address <= "110011";
                    elsif (level = 3) then
                        character_address <= "110100";
                    elsif (level = 4) then
                        character_address <= "110101";
                    end if;

                    font_col <= std_logic_vector(x_pixel - 106)(3 downto 1);
                    font_row <= std_logic_vector(y_pixel - 442)(3 downto 1);

                    if (character_output = '1') then
                        level_r <= '1';
                        level_g <= '1';
                        level_b <= '1';
                    end if;

                    level_det <= character_output;

                    -- Heart 1
                elsif ((x_pixel >= 85 and x_pixel < 117) and (y_pixel >= 10 and y_pixel < 42) and (display_heart = '1' and current_lives > 0)) then
                    character_address <= "000000";

                    font_col <= std_logic_vector(x_pixel - 85)(4 downto 2);
                    font_row <= std_logic_vector(y_pixel - 10)(4 downto 2);

                    heart_r <= character_output;
                    heart_g <= '0';
                    heart_b <= '0';

                    heart_det <= character_output;

                    -- Heart 2
                elsif ((x_pixel >= 120 and x_pixel < 152) and (y_pixel >= 10 and y_pixel < 42) and (display_heart = '1' and current_lives > 1)) then
                    character_address <= "000000";

                    font_col <= std_logic_vector(x_pixel - 120)(4 downto 2);
                    font_row <= std_logic_vector(y_pixel - 10)(4 downto 2);

                    heart_r <= character_output;
                    heart_g <= '0';
                    heart_b <= '0';

                    heart_det <= character_output;

                    -- Heart 3
                elsif ((x_pixel >= 155 and x_pixel < 187) and (y_pixel >= 10 and y_pixel < 42) and (display_heart = '1' and current_lives > 2)) then
                    character_address <= "000000";

                    font_col <= std_logic_vector(x_pixel - 155)(4 downto 2);
                    font_row <= std_logic_vector(y_pixel - 10)(4 downto 2);

                    heart_r <= character_output;
                    heart_g <= '0';
                    heart_b <= '0';

                    heart_det <= character_output;

                else
                    heart_det <= '0';
                    score_det <= '0';
                end if;
            end if;
        end if;

    end process get_characters;

    --if between 100 and 540 pixels horizontally
    --if between 80 and 400 pixels vertically
    -- draw a black box
    --all the other words are in white 
    -- all the words first and then the black box after 
    --640x480 pixels

    ----------------------------------

    -------------SCORING--------------

    ----------------------------------

end flappy_bird;