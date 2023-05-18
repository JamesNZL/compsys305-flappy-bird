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
        bird_hovering, bird_invincible : out std_logic;

        movement_enable : out std_logic);
end entity fsm;

architecture state_driver of fsm is
    type game_state is (DrawMenu, TrainingModeInit, HardModeInit, Gaming, Paused, Dead);
    type mode_memory is (TrainingMode, HardMode);
    signal state, next_state : game_state;
    signal difficulty : mode_memory;
    signal bird_collides : std_logic;
    signal menu_enable : std_logic;
    signal lives : signed(1 downto 0) := TO_SIGNED(3, 2);
begin

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

    decide_output : process (state, menu_navigator_1, menu_navigator_2, mouse_right, mouse_left)
    begin
        bird_flying <= '0';
        menu_enable <= '0';
        obstacle_movement <= '0';

        case state is
            when DrawMenu =>
                menu_enable <= '1';
            when TrainingModeInit =>
                bird_hovering <= '1';
            when HardModeInit =>
                bird_hovering <= '1';
            when Gaming =>
                bird_flying <= '1';
                if (difficulty = TrainingMode) then
                    if (hit_obstacle = '1') then
                        if (lives /= 0) then
                            lives <= lives - 1;
                            bird_invincible <= '1'; --TODO: For 2 seconds
                        else
                            bird_collides <= '1';
                        end if;
                    elsif (hit_floor = '1') then
                        bird_collides <= '1';
                    end if;
                else
                    if ((hit_obstacle = '1') or (hit_floor = '1')) then
                        bird_collides <= '1';
                    end if;
                end if;
            when Paused =>
                bird_flying <= '0';
                obstacle_movement <= '0';
            when Dead =>
                bird_flying <= '0';
                obstacle_movement <= '0';
            when others =>
                bird_flying <= '0';
                obstacle_movement <= '0';
        end case;
    end process;

    decide_next_state : process (state, menu_navigator_1, menu_navigator_2, mouse_right, mouse_left)
    begin
        next_state <= DrawMenu;
        case state is
            when DrawMenu =>
                if (menu_navigator_1 = '1') then
                    difficulty <= TrainingMode;
                    next_state <= TrainingModeInit;
                elsif (menu_navigator_2 = '1') then
                    difficulty <= HardMode;
                    next_state <= HardModeInit;
                end if;
            when TrainingModeInit =>
                if (mouse_left = '1') then
                    next_state <= Gaming;
                end if;
            when HardModeInit =>
                if (mouse_left = '1') then
                    next_state <= Gaming;
                end if;
            when Gaming =>
                if (bird_collides = '1') then --dummy variable
                    next_state <= Dead;
                end if;
                if (mouse_right = '1') then
                    next_state <= Paused;
                end if;
            when Paused =>
                if (mouse_right = '1') then
                    next_state <= Gaming;
                end if;
            when Dead =>
                if (mouse_left = '1') then
                    next_state <= DrawMenu;
                end if;
            when others =>
                next_state <= DrawMenu;
        end case;
    end process;

end state_driver;