library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FSM is
    type gameMode is (DrawMenu, TrainingMode, HardMode, Paused);
    port(
        menuNavigator1, menuNavigator2 : in std_logic;
        Reset : in std_logic;
        mode : gameMode; --GAME STATES
        isFlying, hitObstacle, hitFloor, scoreUp : out std_logic; --BIRD STATES
        colectCoin, collectGift : out std_logic; --BIRD HARDMODE STATES
        
        );
end entity FSM;

architecture stateDriver of FSM is
begin

end stateDriver;