LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.std_logic_signed.ALL ;

ENTITY Accumulate IS
   PORT ( KEY : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
          SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0);  
          CLOCK_50 : IN STD_LOGIC;
          LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
END ENTITY; 

ARCHITECTURE Behaviour OF Accumulate IS
   SIGNAL X, Y : STD_LOGIC_VECTOR(4 DOWNTO 0); 
   SIGNAL z : STD_LOGIC; --this is the enable
   SIGNAL Clock : STD_LOGIC;
   SIGNAL Count : STD_LOGIC_VECTOR(4 DOWNTO 0); --down counter
   SIGNAL Sum : STD_LOGIC_VECTOR(9 DOWNTO 0); --accumulation sum
   SIGNAL Resetn : STD_LOGIC;
BEGIN
   Clock <= CLOCK_50;
   X <= SW(4 DOWNTO 0);
   Y <= SW(9 DOWNTO 5);
   Resetn <= KEY(0);
   PROCESS (Clock, Resetn, z)   -- define the Sum register
   BEGIN 
      IF Resetn = '0' THEN
         Sum <= "0000000000";
      ELSIF Clock'EVENT AND Clock = '1' AND z = '1' THEN --rising edge + enable
         Sum <= Sum + ("00000" & X);
      END IF;
   END PROCESS;

   PROCESS (Clock, Resetn, Y, z)   -- define the down-counter
      BEGIN
         IF Resetn = '0' THEN
            Count <= Y;
         ELSIF Clock'EVENT AND Clock ='1' AND z = '1' THEN
            Count <= Count - "00001";
        END IF;
   END PROCESS;
   z <= Count(0) OR Count(1) OR Count(2) OR Count(3) OR Count(4);
   LEDR <= Sum(9 DOWNTO 0);
END Behaviour;
