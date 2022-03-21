-- An n-bit adder
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;

ENTITY Addern IS 
   GENERIC (n : INTEGER := 16);
   PORT ( X, Y : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
          Cin  : IN STD_LOGIC;
          S    : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0);
          Cout : OUT STD_LOGIC);
END Addern;

ARCHITECTURE Behaviour OF Addern IS 
   SIGNAL Sum : STD_LOGIC_VECTOR(n DOWNTO 0);
BEGIN 
   Sum <= ('0' & X) + ('0' & Y) + Cin;
   S <= Sum(n-1 DOWNTO 0);
   Cout <= Sum(16);
END Behaviour;
