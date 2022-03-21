LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
ENTITY control_ff IS
	PORT ( Clock, ff_in, Clear : IN STD_LOGIC ;
		Q : BUFFER STD_LOGIC ) ;
END control_ff ;
ARCHITECTURE control_circuit OF control_ff IS
BEGIN
	PROCESS ( Clock )
	BEGIN
		IF Clock'EVENT AND Clock = '1' THEN
			IF Clear = '1' THEN
				Q <= '0' ;
			ELSE
				Q <= ff_in OR Q ;
			END IF ;
		END IF ;
	END PROCESS ;
END control_circuit ;