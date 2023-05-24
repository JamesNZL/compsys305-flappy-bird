library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity score_counter is
    port (
        clk, reset, tick : in std_logic;
        set_next_digit : out std_logic;
        score_out : out std_logic_vector(3 downto 0));
end entity score_counter;

architecture behaviour of score_counter is

    signal flag : std_logic := '0';

begin

    process (clk)
        variable t_Q : std_logic_vector(3 downto 0);
    begin
        if rising_edge(clk) then

            if (reset = '1') then
                t_Q := "0000";
            elsif ((tick = '1') and (flag = '0')) then
                flag <= '1';
                if (t_Q /= "1001") then
                    set_next_digit <= '0';
                    t_Q := t_Q + 1;
                else
                    set_next_digit <= '1';
                    t_Q := "0000";
                end if;
            elsif (tick = '0') then
                flag <= '0';
            end if;

        end if;
        score_out <= t_Q;
    end process;

end architecture behaviour;