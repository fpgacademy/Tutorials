LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY add_three_numbers IS
	PORT (	clock		: IN	STD_LOGIC;
				A, B, C	: IN	STD_LOGIC_VECTOR(7 DOWNTO 0);
				sum		: OUT	STD_LOGIC_VECTOR(9 DOWNTO 0));
END add_three_numbers;
	
ARCHITECTURE Behavior OF add_three_numbers IS
	-- Registers
	SIGNAL reg_A, reg_B, reg_C	: STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL reg_sum 				: STD_LOGIC_VECTOR(9 DOWNTO 0);
	ATTRIBUTE keep : boolean;
	ATTRIBUTE keep OF reg_A, reg_B, reg_C, reg_sum : SIGNAL IS true;
BEGIN
	PROCESS ( clock )
	BEGIN
		IF (clock'EVENT AND clock = '1') THEN
			reg_A <= A;
			reg_B <= B;
			reg_C <= C;
			reg_sum <= ("00" & reg_A) + ("00" & reg_B) + ("00" & reg_C);
		END IF;
	END PROCESS;
	
	sum <= reg_sum;
END Behavior;