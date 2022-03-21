LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.std_logic_unsigned.all ;
ENTITY reaction_tester IS
	PORT ( CLOCK_50 : IN STD_LOGIC ;
		KEY : IN STD_LOGIC_VECTOR(2 DOWNTO 0) ;
		HEX3, HEX2, HEX1, HEX0 : OUT STD_LOGIC_VECTOR(0 TO 6) ;
		LEDG : OUT STD_LOGIC_VECTOR(0 DOWNTO 0) ) ;
END reaction_tester ;
ARCHITECTURE top_level OF reaction_tester IS
	SIGNAL reset, request_test, stop_test, clear, sec_100th : STD_LOGIC ;
	SIGNAL run, start_test, test_active, enable_bcd : STD_LOGIC ;
	SIGNAL BCD3, BCD2, BCD1, BCD0 : STD_LOGIC_VECTOR(3 DOWNTO 0) ;
	COMPONENT control_ff
		PORT ( Clock, ff_in, Clear : IN STD_LOGIC ;
			Q : BUFFER STD_LOGIC ) ;
	END COMPONENT ;
	COMPONENT hundredth
		PORT ( Clock, Load : IN STD_LOGIC ;
			pulse_500k : OUT STD_LOGIC ) ;
	END COMPONENT ;
	COMPONENT delay_counter
		PORT ( Clock, Clear, Enable : IN STD_LOGIC ;
			Start : OUT STD_LOGIC ) ;
	END COMPONENT ;
	COMPONENT BCD_counter
		PORT ( Clock, Clear, Enable : IN STD_LOGIC ;
			BCD3, BCD2, BCD1, BCD0 : BUFFER STD_LOGIC_VECTOR(3 DOWNTO 0) ) ;
	END COMPONENT ;
	COMPONENT bcd7seg
		PORT ( bcd : IN STD_LOGIC_VECTOR(3 DOWNTO 0) ;
			display : OUT STD_LOGIC_VECTOR(0 TO 6) ) ;
END COMPONENT ;
BEGIN
	reset <= NOT (KEY(0)) ;
	request_test <= NOT (KEY(1)) ;
	stop_test <= NOT (KEY(2)) ;
	clear <= reset OR stop_test ;
	enable_bcd <= test_active AND sec_100th ;
	LEDG(0) <= test_active ;
	run_signal: control_ff PORT MAP(CLOCK_50, request_test, clear, run) ;
	test_signal: control_ff PORT MAP(CLOCK_50, start_test, clear, test_active) ;
	hundredth_sec: hundredth PORT MAP(CLOCK_50, enable_bcd, sec_100th) ;
	foursec_delay: delay_counter PORT MAP(CLOCK_50, clear, run, start_test) ;
	bcdcount: BCD_counter PORT MAP(CLOCK_50, request_test, enable_bcd, BCD3, BCD2, BCD1, BCD0) ;
	digit3: bcd7seg PORT MAP(BCD3, HEX3) ;
	digit2: bcd7seg PORT MAP(BCD2, HEX2) ;
	digit1: bcd7seg PORT MAP(BCD1, HEX1) ;
	digit0: bcd7seg PORT MAP(BCD0, HEX0) ;
END top_level ;