library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity score_counter is
	port(Clk, Enable : in std_logic;
	Reset : in std_logic_vector(3 downto 0);
	Q_Out : out std_logic_vector(5 downto 0)); -- MAX SCORE 50 AT THE MOMENT
end entity score_counter;

architecture bhv of score_counter is
begin

 process(Clk)

 variable t_Q : std_logic_vector(5 downto 0);

 begin
  if rising_edge(Clk) then
    
    if (Enable = '1' or Reset(0) = '0') then
     if (Reset(0) = '0') then
      t_Q := "000000";
     elsif (t_Q /= "110010") then
      t_Q := t_Q + 1;
     else
      t_Q := "000000";
     end if;
    end if;

  end if;
  Q_Out <= t_Q;
 end process;
end architecture bhv;
