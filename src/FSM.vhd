library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
    port (
        clk, reset : in std_logic;
        menu_navigator_1, menu_navigator_2 : in std_logic;
        mouse_right, mouse_left : in std_logic;
        ob_1_hit, ob_2_hit, ob_1_pass, ob_2_pass : in std_logic;

        -- bird states
        hit_floor : in std_logic;
        bird_hovering : out std_logic;

        lives_out : out signed(1 downto 0);
        menu_enable : out std_logic;

        movement_enable : out std_logic);
end entity fsm;

architecture state_driver of fsm is
    type game_state is (DrawMenu, TrainingModeInit, HardModeInit, Gaming, Paused, Dead);
    type mode_memory is (TrainingMode, HardMode);
    signal state, next_state : game_state;
    signal difficulty : mode_memory;
    signal bird_died : std_logic;
    signal last_seen : std_logic;
    signal lives : signed(1 downto 0) := TO_SIGNED(3, 2);
begin

    lives_out <= lives;

    -- last_seen <= '0' when ((ob_1_hit = '1' or last_seen = '0' or ob_1_pass = '1') and (ob_2_pass = '0' and ob_2_hit = '0'))
    --              else
    --              '1' when ((ob_2_hit = '1' or last_seen = '1' or ob_2_pass = '1') and (ob_2_pass = '0' and ob_2_hit = '0'));

    lives_calculator : process (ob_1_hit, ob_2_hit, ob_1_pass, ob_2_pass, reset)
    begin
        if ((ob_1_hit = '1' or last_seen = '0' or ob_1_pass = '1') and (ob_2_pass = '0' and ob_2_hit = '0')) then
            last_seen <= '0';
        elsif ((ob_2_hit = '1' or last_seen = '1' or ob_2_pass = '1') and (ob_1_pass = '0' and ob_1_hit = '0')) then
            last_seen <= '1';
        end if;

        if (reset = '1') then
            lives <= TO_SIGNED(3, 2);
        elsif ((ob_1_hit = '1' and last_seen /= '0') or (ob_2_hit = '1' and last_seen /= '1')) then
            lives <= lives - 1;
        end if;
    end process;

    sync_proc : process (clk)
    begin
        if rising_edge(clk) then
            if (Reset = '1') then
                state <= DrawMenu;
            else
                state <= next_state;
            end if;
        end if;
    end process;

    decode_output : process (state, menu_navigator_1, menu_navigator_2, mouse_right, mouse_left, lives, ob_1_hit, ob_2_hit, hit_floor)
    begin

        bird_hovering <= '0';
        case state is
            when DrawMenu =>

                bird_died <= '0';
                menu_enable <= '1';
                movement_enable <= '0';

            when TrainingModeInit =>

                bird_hovering <= '1';
                movement_enable <= '0';
                menu_enable <= '0';

            when HardModeInit =>

                bird_hovering <= '1';
                movement_enable <= '0';
                menu_enable <= '0';

            when Gaming =>

                menu_enable <= '0';
                movement_enable <= '1';
                if (difficulty = TrainingMode) then
                    if (lives = 0) then
                        bird_died <= '1';
                    elsif (hit_floor = '1') then
                        bird_died <= '1';
                    end if;
                else
                    if (ob_1_hit = '1' or ob_2_hit = '1' or hit_floor = '1') then
                        bird_died <= '1';
                    end if;
                end if;

            when Paused =>

                movement_enable <= '0';
                menu_enable <= '0';

            when Dead =>

                movement_enable <= '0';
                menu_enable <= '0';

            when others =>

                movement_enable <= '0';
                menu_enable <= '0';

        end case;
    end process;

    decode_next_state : process (state, menu_navigator_1, menu_navigator_2, mouse_right, mouse_left, bird_died)
    begin
        case state is
            when DrawMenu =>

                next_state <= DrawMenu;

                if (menu_navigator_1 = '1') then
                    difficulty <= TrainingMode;
                    next_state <= TrainingModeInit;
                elsif (menu_navigator_2 = '1') then
                    difficulty <= HardMode;
                    next_state <= HardModeInit;
                end if;

            when TrainingModeInit =>

                next_state <= TrainingModeInit;

                if (mouse_left = '1') then
                    next_state <= Gaming;
                end if;

            when HardModeInit =>

                next_state <= HardModeInit;

                if (mouse_left = '1') then
                    next_state <= Gaming;
                end if;

            when Gaming =>

                next_state <= Gaming;

                if (bird_died = '1') then
                    next_state <= Dead;
                elsif (mouse_right = '1') then
                    next_state <= Paused;
                end if;

            when Paused =>

                next_state <= Paused;

                if (mouse_left = '1') then
                    next_state <= Gaming;
                end if;

            when Dead =>

                next_state <= Dead;

                if (mouse_left = '1') then
                    next_state <= DrawMenu;
                end if;

            when others =>

                next_state <= DrawMenu;

        end case;
    end process;

end state_driver;