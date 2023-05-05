library ieee;
use ieee.std_logic_1164.all;

entity lfsr is
    port (
        clk, reset, enable : in std_logic;
        seed : in std_logic_vector(8 downto 1);
        lfsrOutput : out std_logic_vector(7 downto 0));
end lfsr;

architecture galois of lfsr is

    signal currentState : std_logic_vector(8 downto 1) := seed;

begin
    lfsrOutput <= currentState(8 downto 1);

    runLFSR : process (clk, reset)
    begin
        if (reset = '0') then
            currentState <= seed;
        elsif rising_edge(clk) then
            if (enable = '1') then
                -- Perform shifts with taps at 1, 2, 3, and 7
                currentState(8) <= currentState(1);
                currentState(7) <= currentState(2);
                currentState(6) <= currentState(3);
                currentState(5) <= currentState(7) xor currentState(5);
                currentState(4) <= currentState(5);
                currentState(3) <= currentState(4);
                currentState(2) <= currentState(3);
                currentState(1) <= currentState(2);
            end if;
        end if;
    end process runLFSR;

end architecture galois;