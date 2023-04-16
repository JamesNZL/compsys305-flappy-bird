--Skeleton Code laying out tasks to be completed
--Nicholas Wolf

--TASKS
--Display score [Drive enable with obstable pass, slice output score into proper portions and concatenate with 0s to reach required 7seg form, map Reset to push button, send to HEX]
--Background [Convert a 640x480 image of 12 bit colour {RRRR;GGGG;BBBB} into ROM in BRAM and initialise this MIF with a component like char_rom]
--Mouse [Use the provided PS/2 handler and come up with an efficient way to detect mouse collisions with buttons --> check x,y pos coinciding a region]
--Physics [The bird will fly in one dimension: y, and will flap to mouse clicks]
--Obstacles [Obstacles will move in the x direction and upon collision will hurt the bird]
--Gifts [Gifts float in the air in the gap between obstacles and give various rewards]
--Home Screen [Upon reset, a home screen will display, prompting you to use the switch to toggle modes]
--Pause [A push button in the logic vector KEY must pause the game]
--VGA [Display background, and draw obstacles, bird, and gifts on the top, make the decision for a static or slowly moving background. Keep in mind refresh rate 60Hz and pixel rate 25MHz]
--Difficulty [The game must get more difficult as time progresses. We can create our own game clock that can be dynamically sped up, and indicate this with LEDs, or find a better solution]

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity main is
	port(Clk : in std_logic; --> CLOCK_50
	Mode : in std_logic_vector(9 downto 0); --> SW
	ResetAndPause : in std_logic_vector(3 downto 0); --> KEY
	Difficulty : out std_logic_vector(9 downto 0); --> LEDR
	scoreTens : out std_logic_vector(6 downto 0); --> HEX1
	scoreOnes : out std_logic_vector(6 downto 0); --> HEX0
	HighScore : out std_logic_vector(5 downto 0));
end entity main;

architecture bhv of main is
signal score_Ones, score_Tens : std_logic_vector(3 downto 0);
signal scoreAll : std_logic_vector(5 downto 0);
signal sseg_ones_OUT : std_logic_vector(6 downto 0);
signal sseg_tens_OUT : std_logic_vector(6 downto 0);
signal obstaclePassed : std_logic;

component MOUSE is
	port(clock_25Mhz, reset : in std_logic;
        mouse_data : inout std_logic;
        mouse_clk : inout std_logic;
        left_button, right_button : out std_logic;
	mouse_cursor_row : out std_logic_vector(9 downto 0); 
	mouse_cursor_column : out std_logic_vector(9 downto 0));       	
end component;

component score_counter is
	port(Clk, Enable : in std_logic;
	Reset : in std_logic_vector(3 downto 0);
	Q_Out : out std_logic_vector(5 downto 0));
end component;

component char_rom is
	PORT(character_address : in std_logic_vector(5 downto 0);
	font_row, font_col : in std_logic_vector(2 downto 0);
	clock : in std_logic;
	rom_mux_output : out std_logic);
end component;

component VGA_SYNC is
	port(clock_25Mhz, red, green, blue : in	std_logic;
	red_out, green_out, blue_out, horiz_sync_out, vert_sync_out : out std_logic;
	pixel_row, pixel_column : out std_logic_vector(9 downto 0));
end component;

component BCD_to_SevenSeg is
	port (BCD_digit : in std_logic_vector(3 downto 0);
        SevenSeg_out : out std_logic_vector(6 downto 0));
end component;


begin
score : score_counter port map(Clk, scoreUP, Reset, scoreAll);

sseg_ones : BCD_to_SevenSeg port map(score_Ones, sseg_ones_OUT);
sseg_tens : BCD_to_SevenSeg port map(score_Tens, sseg_tens_OUT);

scoreUP <= '1' when obstaclePassed = '1' else '0';

score_Ones <= '0' & scoreAll(2 downto 0);
score_Tens <= '0' & scoreAll(5 downto 3);

HighScore <= scoreAll if (scoreAll > HighScore);
HEX1 <= sseg_tens_OUT;
HEX0 <= sseg_ones_OUT;
end architecture bhv;