library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity scoreCounter is
	port(Clk, Tick : in std_logic;
	Reset : in std_logic;
    setNextDigit : out std_logic;
	Q_Out : out std_logic_vector(3 downto 0));
end entity scoreCounter;

architecture bhv of scoreCounter is
    signal flag : std_logic := '0';
begin

 process(Clk)

 variable t_Q : std_logic_vector(3 downto 0);

 begin
  if rising_edge(Clk) then

    if (((Tick = '1') and (flag = '0')) or (Reset = '0')) then
        flag <= '1';
        if (Reset = '0') then
            t_Q := "0000";
        elsif (t_Q /= "1001") then
            setNextDigit <= '0';
            t_Q := t_Q + 1;
        else
            setNextDigit <= '1';
            t_Q := "0000";
        end if;
    elsif (Tick = '0') then
        flag <= '0';
    end if;

  end if;
  Q_Out <= t_Q;
 end process;
end architecture bhv;