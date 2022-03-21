-- Reset with SW[0]. Clock counter and memory with KEY[0]
-- Each clock cycle reads a character from memory and shows it on the HEX display
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY display IS
   PORT ( KEY : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
          SW : IN STD_LOGIC_VECTOR(0 DOWNTO 0);  
          HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
          LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0) );
END ENTITY; 

ARCHITECTURE Behavior OF display IS
   COMPONENT inst_mem 
      PORT ( address   : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
             clock     : IN STD_LOGIC ;
             q         : OUT STD_LOGIC_VECTOR (7 DOWNTO 0));
   END COMPONENT;
   COMPONENT count3
      PORT ( Resetn, Clock   : IN   STD_LOGIC;
             Q               : OUT  STD_LOGIC_VECTOR(2 DOWNTO 0));
   END COMPONENT;

    CONSTANT A : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"41";
    CONSTANT b : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"62";
    CONSTANT C : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"43";
    CONSTANT d : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"64";
    CONSTANT E : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"45";
    CONSTANT F : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"46";
    CONSTANT g : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"67";
    CONSTANT h : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"68";
    SIGNAL Resetn, Clock : STD_LOGIC;
    SIGNAL Count : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL Address : STD_LOGIC_VECTOR(4 DOWNTO 0);
    SIGNAL char : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN 
    Resetn <= SW(0);
    Clock <= KEY(0);

    U1: count3 PORT MAP (Resetn, Clock, Count);
    Address <= "00" & Count;
    U2: inst_mem PORT MAP (Address, Clock, char);
    LEDR <= "00" & char;
    
    HEX0 <= "0001000" WHEN char = A ELSE
            "0000011" WHEN char = b ELSE
            "1000110" WHEN char = C ELSE
            "0100001" WHEN char = d ELSE
            "0000110" WHEN char = E ELSE
            "0001110" WHEN char = F ELSE
            "0010000" WHEN char = g ELSE
            "0001011" WHEN char = h ELSE
            "1111111";
END Behavior;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY count3 IS 
    PORT ( Resetn, Clock   : IN   STD_LOGIC;
           Q               : OUT  STD_LOGIC_VECTOR(2 DOWNTO 0));
END count3;

ARCHITECTURE Behavior OF count3 IS
   SIGNAL Count : STD_LOGIC_VECTOR(2 DOWNTO 0); 
BEGIN
   PROCESS (Clock, Resetn)
   BEGIN
         IF (Resetn = '0') THEN
            Count <= "000";
         ELSIF (rising_edge(Clock)) THEN
            Count <= Count + '1';
         END IF;
   END PROCESS;
   Q <= Count;
END Behavior;
