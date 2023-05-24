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
            locked : out std_logic
        );
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
            pixel_row : out signed(9 downto 0)
        );
    end component;

    component fsm
        port (
            clk, reset : in std_logic;
            menu_navigator_1, menu_navigator_2 : in std_logic;
            mouse_right, mouse_left : in std_logic;
            obs_one_hit, obs_two_hit : in std_logic;

            -- bird states
            hit_floor : in std_logic;
            bird_hovering : out std_logic;

            lives_out : out unsigned(1 downto 0);
            menu_enable : out std_logic;

            movement_enable : out std_logic);
    end component;

    component coin is
        port (
            enable, coinEnable, pb1, clk, vert_sync : in std_logic;
            lfsrSeed : in std_logic_vector(8 downto 1);
            start_xPos : in signed(10 downto 0);
            pixel_row, pixel_column : in signed(9 downto 0);
            red, green, blue, inPixel, coinLeft : out std_logic);
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
            pixel_row, pixel_column : in signed(9 downto 0);
            red, green, blue, in_pixel, score_tick, collision_tick : out std_logic);
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

    signal heartR, heartG, heartB : std_logic;
    signal scoreR, scoreG, scoreB : std_logic;
    signal coinR, coinG, coinB : std_logic;
    signal coinEnable, coinGone : std_logic;
    signal coinDet : std_logic;
    signal coinTick : std_logic := '0';
    signal inHeart, inScore : std_logic;
    signal charAddress : std_logic_vector(5 downto 0);
    signal fontrow, fontcol : std_logic_vector (2 downto 0);
    signal charOUTPUT : std_logic;
    signal homescreenEnable : std_logic := '0';
    signal trainingMode : std_logic := '0';

    signal clk : std_logic;

    signal vert_sync : std_logic;
    signal x_pixel, y_pixel : signed(9 downto 0);
    signal paint_r, paint_g, paint_b : std_logic;

    signal mouse_left_event, mouse_right_event : std_logic;
    signal mouse_row, mouse_column : signed(9 downto 0);

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

    signal score_tens_tick, score_hundreds_tick : std_logic;
    signal score_ones, score_tens : std_logic_vector(3 downto 0);

begin

    vert_sync_out <= vert_sync;

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
        reset => not key0,
        menu_navigator_1 => not key3,
        menu_navigator_2 => not key2,
        mouse_right => mouse_right_event,
        mouse_left => mouse_left_event,
        obs_one_hit => obs_one_hit,
        obs_two_hit => obs_two_hit,
        hit_floor => hit_floor,
        bird_hovering => bird_hovering,
        lives_out => current_lives,
        -- menu_enable => null,
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
        reset => not key0,
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
        reset => not key0,
        pixel_row => y_pixel,
        pixel_column => x_pixel,
        red => floor_r,
        green => floor_g,
        blue => floor_b,
        in_pixel => floor_det);

    obstacle_one : obstacle
    port map(
        clk => vert_sync,
        reset => not key0,
        enable => movement_enable,
        lfsr_seed => std_logic_vector(x_pixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_x_pos => TO_SIGNED(640, 11),
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
        reset => not key0,
        enable => movement_enable,
        lfsr_seed => std_logic_vector(y_pixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_x_pos => TO_SIGNED(960, 11),
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
        clk => clk,
        enable => movement_enable,
        coinEnable => coinEnable,
        pb1 => pb1,
        vert_sync => vert_sync,
        lfsrSeed => std_logic_vector(x_pixel(7 downto 0)) or "0000001", -- or to ensure seed is never 0
        start_xPos => TO_SIGNED(800, 11),
        pixel_row => y_pixel,
        pixel_column => x_pixel,
        red => coinR,
        green => coinG,
        blue => coinB,
        inPixel => coinDet,
        coinLeft => coinGone);

    score_display : char_rom
    port map(
        clock => clk,
        character_address => charAddress,
        font_row => fontrow,
        font_col => fontcol,
        rom_mux_output => charOUTPUT);

    score_counter_ones : score_counter
    port map(
        clk => clk,
        reset => not key0,
        tick => (obs_one_tick or obs_two_tick),
        set_next_digit => score_tens_tick,
        score_out => score_ones);

    score_counter_tens : score_counter
    port map(
        clk => clk,
        reset => not key0,
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

            if (bird_det = '1' and coinDet = '1' and flag1 = '1') then
                coinTick <= '1';
                flag := '0';
                flag1 := '0';
            elsif (coinGone = '1') then
                flag := '1';
                flag1 := '1';
            elsif (flag1 = '0') then
                coinTick <= '0';
            end if;

            if (flag = '0') then
                coinEnable <= '0';
            else
                coinEnable <= '1';

            end if;
        end if;
    end process detect_coin;

    ----------------------------------

    -------------DRAWING--------------

    paint_screen : process (clk)
    begin
        if (rising_edge(clk)) then

            ---BOX PRINTED
            if (homescreenEnable = '1') then

                if ((x_pixel >= 180 and x_pixel < 460) and (y_pixel >= 140 and y_pixel < 340)) then

                    if ((x_pixel >= 185 and x_pixel < 455) and (y_pixel >= 145 and y_pixel < 335)) then

                        ---FLAPPYBIRD PRINTED
                        if ((x_pixel >= 200 and x_pixel < 216) and (y_pixel >= 150 and y_pixel < 166)) then

                            charAddress <= "000110";

                            fontcol <= std_logic_vector(x_pixel - 200)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 216 and x_pixel < 232) and (y_pixel >= 150 and y_pixel < 166)) then
                            charAddress <= "001100";

                            fontcol <= std_logic_vector(x_pixel - 216)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 232 and x_pixel < 248) and (y_pixel >= 150 and y_pixel < 166)) then

                            charAddress <= "000001";

                            fontcol <= std_logic_vector(x_pixel - 232)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 248 and x_pixel < 264) and (y_pixel >= 150 and y_pixel < 166)) then

                            charAddress <= "010000";

                            fontcol <= std_logic_vector(x_pixel - 248)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 264 and x_pixel < 280) and (y_pixel >= 150 and y_pixel < 166)) then

                            charAddress <= "010000";

                            fontcol <= std_logic_vector(x_pixel - 264)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 280 and x_pixel < 296) and (y_pixel >= 150 and y_pixel < 166)) then

                            charAddress <= "011001";

                            fontcol <= std_logic_vector(x_pixel - 280)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 320 and x_pixel < 336) and (y_pixel >= 150 and y_pixel < 166)) then
                            charAddress <= "000010";

                            fontcol <= std_logic_vector(x_pixel - 320)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 336 and x_pixel < 352) and (y_pixel >= 150 and y_pixel < 166)) then

                            charAddress <= "001001";

                            fontcol <= std_logic_vector(x_pixel - 336)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 352 and x_pixel < 368) and (y_pixel >= 150 and y_pixel < 166)) then

                            charAddress <= "010010";

                            fontcol <= std_logic_vector(x_pixel - 368)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 368 and x_pixel < 384) and (y_pixel >= 150 and y_pixel < 166)) then

                            charAddress <= "000100";

                            fontcol <= std_logic_vector(x_pixel - 368)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 150)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                            ----TRAIN PRINTED--------

                        elsif ((x_pixel >= 190 and x_pixel < 206) and (y_pixel >= 200 and y_pixel < 216)) then
                            charAddress <= "010100";

                            fontcol <= std_logic_vector(x_pixel - 190)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 200)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 206 and x_pixel < 222) and (y_pixel >= 200 and y_pixel < 216)) then
                            charAddress <= "010010";

                            fontcol <= std_logic_vector(x_pixel - 206)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 200)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 222 and x_pixel < 238) and (y_pixel >= 200 and y_pixel < 216)) then
                            charAddress <= "000001";

                            fontcol <= std_logic_vector(x_pixel - 222)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 200)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 238 and x_pixel < 254) and (y_pixel >= 200 and y_pixel < 216)) then
                            charAddress <= "001001";

                            fontcol <= std_logic_vector(x_pixel - 238)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 200)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 254 and x_pixel < 270) and (y_pixel >= 200 and y_pixel < 216)) then
                            charAddress <= "001110";

                            fontcol <= std_logic_vector(x_pixel - 254)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 200)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                            ----PRINT GAME-----

                        elsif ((x_pixel >= 190 and x_pixel < 206) and (y_pixel >= 250 and y_pixel < 268)) then
                            charAddress <= "000111";

                            fontcol <= std_logic_vector(x_pixel - 190)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 250)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 206 and x_pixel < 222) and (y_pixel >= 250 and y_pixel < 268)) then
                            charAddress <= "000001";

                            fontcol <= std_logic_vector(x_pixel - 206)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 250)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 222 and x_pixel < 238) and (y_pixel >= 250 and y_pixel < 268)) then
                            charAddress <= "001101";

                            fontcol <= std_logic_vector(x_pixel - 222)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 250)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        elsif ((x_pixel >= 238 and x_pixel < 254) and (y_pixel >= 250 and y_pixel < 268)) then
                            charAddress <= "000101";

                            fontcol <= std_logic_vector(x_pixel - 238)(3 downto 1);
                            fontrow <= std_logic_vector(y_pixel - 250)(3 downto 1);

                            if (charOUTPUT = '1') then
                                paint_r <= '1';
                                paint_g <= '1';
                                paint_b <= '1';
                            else
                                paint_r <= '0';
                                paint_g <= '0';
                                paint_b <= '0';
                            end if;

                        else
                            paint_r <= '0';
                            paint_g <= '0';
                            paint_b <= '0';

                        end if;

                    else

                        paint_r <= '1';
                        paint_g <= '1';
                        paint_b <= '1';

                    end if;

                else

                    if (bird_det = '1') then
                        paint_r <= birdR;
                        paint_g <= birdG;
                        paint_b <= birdB;
                    elsif (obs_det = '1') then
                        paint_r <= (obs_one_r or obs_two_r);
                        paint_g <= (obs_one_g or obs_two_g);
                        paint_b <= (obs_one_b or obs_two_b);

                    else
                        paint_r <= '0';
                        paint_g <= '1';
                        paint_b <= '1';

                    end if;

                end if;

            else

                if (inHeart = '1') then
                    paint_r <= heartR;
                    paint_g <= heartG;
                    paint_b <= heartB;

                elsif (inScore = '1') then
                    paint_r <= ScoreR;
                    paint_g <= ScoreG;
                    paint_b <= ScoreB;

                elsif (bird_det = '1') then
                    paint_r <= birdR;
                    paint_g <= birdG;
                    paint_b <= birdB;

                elsif (coinDet = '1' and coinEnable = '1') then
                    paint_r <= coinR;
                    paint_g <= coinG;
                    paint_b <= coinB;

                elsif (floor_det = '1') then
                    paint_r <= floor_r;
                    paint_g <= floor_g;
                    paint_b <= floor_b;

                elsif (obs_det = '1') then
                    paint_r <= (obs_one_r or obs_two_r);
                    paint_g <= (obs_one_g or obs_two_g);
                    paint_b <= (obs_one_b or obs_two_b);

                else
                    paint_r <= '0';
                    paint_g <= '1';
                    paint_b <= '1';

                end if;

            end if;

        end if;
    end process paint_screen;

    hearts : process (clk)
        variable int_value : integer;

    begin

        if (homescreenEnable = '0') then

            if (rising_edge(clk)) then

                if ((x_pixel >= 10 and x_pixel < 42) and (y_pixel >= 10 and y_pixel < 42)) then

                    charAddress <= "000000";

                    fontcol <= std_logic_vector(x_pixel - 10)(4 downto 2);
                    fontrow <= std_logic_vector(y_pixel - 10)(4 downto 2);

                    heartR <= charOUTPUT;
                    heartG <= '0';
                    heartB <= '0';

                    inHeart <= charOUTPUT;

                elsif ((x_pixel >= 45 and x_pixel < 77) and (y_pixel >= 10 and y_pixel < 42)) then

                    charAddress <= "000000";

                    fontcol <= std_logic_vector(x_pixel - 45)(4 downto 2);
                    fontrow <= std_logic_vector(y_pixel - 10)(4 downto 2);

                    heartR <= charOUTPUT;
                    heartG <= '0';
                    heartB <= '0';

                    inHeart <= charOUTPUT;

                elsif ((x_pixel >= 80 and x_pixel < 112) and (y_pixel >= 10 and y_pixel < 42)) then

                    charAddress <= "000000";

                    fontcol <= std_logic_vector(x_pixel - 80)(4 downto 2);
                    fontrow <= std_logic_vector(y_pixel - 10)(4 downto 2);

                    heartR <= charOUTPUT;
                    heartG <= '0';
                    heartB <= '0';

                    inHeart <= charOUTPUT;

                elsif ((x_pixel >= 120 and x_pixel < 152) and (y_pixel >= 10 and y_pixel < 42)) then

                    int_value := to_integer(unsigned(scoreTens)) + 48;
                    charAddress <= std_logic_vector(to_unsigned(int_value, 6));

                    fontcol <= std_logic_vector(x_pixel - 120)(4 downto 2);
                    fontrow <= std_logic_vector(y_pixel - 10)(4 downto 2);

                    if (charOUTPUT = '1') then
                        scoreR <= '0';
                        scoreG <= '0';
                        scoreB <= '0';

                    end if;

                    inScore <= charOUTPUT;

                elsif ((x_pixel >= 155 and x_pixel < 187) and (y_pixel >= 10 and y_pixel < 42)) then

                    int_value := to_integer(unsigned(scoreOnes)) + 48;
                    charAddress <= std_logic_vector(to_unsigned(int_value, 6));

                    fontcol <= std_logic_vector(x_pixel - 155)(4 downto 2);
                    fontrow <= std_logic_vector(y_pixel - 10)(4 downto 2);

                    if (charOUTPUT = '1') then
                        scoreR <= '0';
                        scoreG <= '0';
                        scoreB <= '0';

                    end if;

                    inScore <= charOUTPUT;

                else
                    inHeart <= '0';
                    inscore <= '0';

                end if;

            end if;

        end if;

    end process;

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