LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.std_logic_unsigned.all ;
ENTITY BCD_counter IS
	PORT ( Clock, Clear, Enable : IN STD_LOGIC ;
		BCD3, BCD2, BCD1, BCD0 : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0) ) ;
END BCD_counter ;
ARCHITECTURE four_digits OF BCD_counter IS
	SIGNAL Carry : STD_LOGIC_VECTOR(4 DOWNTO 1) ;
	COMPONENT BCD_stage
		PORT ( Clock, Clear, Ecount : IN STD_LOGIC ;
			BCDq : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) ;
			Value9 : OUT STD_LOGIC ) ;
	END COMPONENT ;
BEGIN
	stage0: BCD_stage PORT MAP(Clock, Clear, Enable, BCD0, Carry(1)) ;
	stage1: BCD_stage PORT MAP(Clock, Clear, (Carry(1) AND Enable), BCD1, Carry(2)) ;
	stage2: BCD_stage PORT MAP(Clock, Clear, (Carry(2) AND Carry(1) AND Enable), BCD2, Carry(3)) ;
	stage3: BCD_stage PORT MAP(Clock, Clear, (Carry(3) AND Carry(2) AND Carry(1) AND Enable), BCD3, Carry(4)) ;
END four_digits ;
LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.std_logic_unsigned.all ;
ENTITY BCD_stage IS
	PORT ( Clock, Clear, Ecount : IN STD_LOGIC ;
		BCDq : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0) ;
		Value9 : OUT STD_LOGIC ) ;
END BCD_stage ;
ARCHITECTURE digit OF BCD_stage IS
BEGIN
	PROCESS ( Clock )
	BEGIN
		IF Clock'EVENT AND Clock = '1' THEN
			IF Clear = '1' THEN BCDq <= "0000" ;
			ELSIF Ecount = '1' THEN
				IF BCDq = "1001" THEN BCDq <= "0000" ;
				ELSE BCDq <= BCDq + '1' ;
				END IF ;
			END IF ;
		END IF ;
	END PROCESS ;
	PROCESS ( BCDq )
	BEGIN
		IF BCDq = "1001" THEN Value9 <= '1' ;
		ELSE Value9 <= '0' ;
		END IF ;
	END PROCESS ;
END digit ;