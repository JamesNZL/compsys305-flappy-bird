library ieee;
use ieee.std_logic_1164.all;

entity lfsr is
    port (
        clk, reset, enable : in std_logic;
        seed : in std_logic_vector(8 downto 1);
        lfsr_out : out std_logic_vector(7 downto 0));
end lfsr;

architecture galois of lfsr is

    signal current_state : std_logic_vector(8 downto 1) := seed;

begin
    lfsr_out <= current_state(8 downto 1);

    run_lfsr : process (clk, reset)
    begin
        if (reset = '1') then
            current_state <= seed;
        elsif rising_edge(clk) then
            if (enable = '1') then
                -- Perform shifts with taps at 1, 2, 3, and 7
                current_state(8) <= current_state(1);
                current_state(7) <= current_state(2);
                current_state(6) <= current_state(3);
                current_state(5) <= current_state(7) xor current_state(5);
                current_state(4) <= current_state(5);
                current_state(3) <= current_state(4);
                current_state(2) <= current_state(3);
                current_state(1) <= current_state(2);
            end if;
        end if;
    end process run_lfsr;

end architecture galois;