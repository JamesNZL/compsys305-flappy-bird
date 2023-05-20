library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fsm is
    port (
        clk, reset : in std_logic;
        menu_navigator_1, menu_navigator_2 : in std_logic;
        mouse_right, mouse_left : in std_logic;

        -- bird states
        hit_obstacle, hit_floor : in std_logic;
        bird_hovering : out std_logic;

        lives_out : out signed(1 downto 0);
        menu_enable : out std_logic;

        movement_enable : out std_logic);
end entity fsm;

architecture state_driver of fsm is
    type game_state is (DrawMenu, TrainingModeInit, HardModeInit, Gaming, Paused, Invincible, Dead);
    type mode_memory is (TrainingMode, HardMode);
    signal state, next_state : game_state;
    signal difficulty : mode_memory;
    signal bird_died : std_logic;
    signal bird_invincible : std_logic;
    signal lives : signed(1 downto 0) := TO_SIGNED(3, 2);
begin

    lives_out <= lives;

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

    decode_output : process (state, menu_navigator_1, menu_navigator_2, mouse_right, mouse_left, lives, hit_obstacle, hit_floor)
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
                bird_invincible <= '0';
                if (difficulty = TrainingMode) then
                    if (hit_obstacle = '1') then
                        if (lives = 0) then
                            bird_died <= '1';
                        elsif (bird_invincible = '0') then
                            lives <= lives - 1;
                            bird_invincible <= '1'; --TODO: For 2 seconds
                        end if;
                    elsif (hit_floor = '1') then
                        bird_died <= '1';
                    end if;
                else
                    if ((hit_obstacle = '1') or (hit_floor = '1')) then
                        bird_died <= '1';
                    end if;
                end if;

            when Paused =>

                movement_enable <= '0';
                menu_enable <= '0';

            when Invincible =>
                movement_enable <= '1';
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
                elsif (bird_invincible = '1') then
                    next_state <= Invincible;
                end if;

            when Paused =>

                next_state <= Paused;

                if (mouse_left = '1') then
                    next_state <= Gaming;
                end if;

            when Invincible =>

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