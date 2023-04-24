LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE  IEEE.STD_LOGIC_ARITH.all;
USE  IEEE.STD_LOGIC_UNSIGNED.all;

entity vga_clock is
	port(Clk : in std_logic;
	vgaClock : out std_logic);
end entity;

--We run on a 50Mhz clock on the FPGA, and the vga clock needs to be 25Mhz
--Therefore we just need to divide the clock by two. Using a latch,
--I trigger the vgaClock every two Clk cycles.

--CLK 101010101010101010101010
--LAT 001100110011001100110011
--VGA 110011001100110011001100

architecture bhv of vga_clock is
signal latch : std_logic;
begin

process(Clk)
begin

 if rising_edge(Clk) then
  if latch = '0' then
   vgaClock <= '0';
   latch <= '1';
  else
   vgaClock <= '1';
   latch <= '0';
  end if;
 end if;

end process;

end architecture bhv;