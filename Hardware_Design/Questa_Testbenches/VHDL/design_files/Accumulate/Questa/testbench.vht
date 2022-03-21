LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
 
ENTITY testbench IS
END testbench;
 
ARCHITECTURE Behavior OF testbench IS

   COMPONENT Accumulate
      PORT ( KEY : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
             SW : IN STD_LOGIC_VECTOR(9 DOWNTO 0);  
             CLOCK_50 : IN STD_LOGIC;
             LEDR : OUT STD_LOGIC_VECTOR(9 DOWNTO 0));
   END COMPONENT;

	SIGNAL CLOCK_50 : STD_LOGIC;
	SIGNAL KEY : STD_LOGIC_VECTOR(0 DOWNTO 0);
	SIGNAL SW : STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL LEDR : STD_LOGIC_VECTOR(9 DOWNTO 0);
BEGIN
   U1: Accumulate PORT MAP (KEY, SW, CLOCK_50, LEDR);

   clock_process: PROCESS
	BEGIN
	   CLOCK_50 <= '0';
	   WAIT FOR 10 ns;
	   CLOCK_50 <= '1';
	   WAIT FOR 10 ns;
	END PROCESS;

	vectors: PROCESS
	BEGIN
		KEY(0) <= '0'; SW <= "0000000000"; 
		WAIT FOR 20 ns;
		SW(9 DOWNTO 5) <= "01010";
		WAIT FOR 20 ns;
		SW(4 DOWNTO 0) <= "11110"; 
		KEY(0) <= '1';
		WAIT;
	END PROCESS;
END;
