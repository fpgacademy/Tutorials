LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY reg16 IS
	PORT (	clock, resetn : IN STD_LOGIC;
				D : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
				byteenable : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
				Q : OUT STD_LOGIC_VECTOR(15 DOWNTO 0) );
END reg16;

ARCHITECTURE Behavior OF reg16 IS
BEGIN
	PROCESS
	BEGIN
		WAIT UNTIL clock'EVENT AND clock = '1';
		IF resetn = '0' THEN
			Q <= "0000000000000000";
		ELSE
			IF byteenable(0) = '1' THEN
				Q(7 DOWNTO 0) <= D(7 DOWNTO 0); END IF;
			IF byteenable(1) = '1' THEN
				Q(15 DOWNTO 8) <= D(15 DOWNTO 8); END IF;
		END IF;
	END PROCESS;
END Behavior;
