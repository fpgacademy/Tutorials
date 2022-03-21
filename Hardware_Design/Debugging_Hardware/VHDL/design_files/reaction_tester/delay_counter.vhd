LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.std_logic_unsigned.all ;
ENTITY delay_counter IS
	PORT ( Clock, Clear, Enable : IN STD_LOGIC ;
		Start : OUT STD_LOGIC ) ;
END delay_counter ;
ARCHITECTURE delay_circuit OF delay_counter IS
	SIGNAL delay_count : STD_LOGIC_VECTOR(27 DOWNTO 0) ;
BEGIN
	PROCESS ( Clock )
	BEGIN
		IF Clock'EVENT AND Clock = '1' THEN
			IF Clear = '1' THEN
				delay_count <= (OTHERS => '0') ;
			ELSIF Enable = '1' THEN
				delay_count <= delay_count + '1' ;
			END IF ;
		END IF ;
	END PROCESS ;
	Start <= delay_count(27) ;
END delay_circuit ;