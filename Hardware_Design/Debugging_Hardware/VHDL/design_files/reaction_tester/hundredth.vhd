LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.std_logic_unsigned.all ;
ENTITY hundredth IS
	PORT ( Clock, Load : IN STD_LOGIC ;
		pulse_500k : OUT STD_LOGIC ) ;
END hundredth ;
ARCHITECTURE hundredth_circuit OF hundredth IS
	SIGNAL count_500k : STD_LOGIC_VECTOR(19 DOWNTO 0) ;
BEGIN
	PROCESS ( Clock )
	BEGIN
		IF Clock'EVENT AND Clock = '1' THEN
			IF Load = '1' THEN
				count_500k <= X"7A120" ;
			ELSE
				count_500k <= count_500k - '1' ;
			END IF ;
		END IF ;
	END PROCESS ;
pulse_500k <= '1' WHEN (count_500k = X"00000") ELSE '0' ;
END hundredth_circuit ;