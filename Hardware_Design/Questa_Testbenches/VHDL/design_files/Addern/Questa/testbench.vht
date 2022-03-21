LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                
USE ieee.std_logic_signed.all;

ENTITY testbench IS
END testbench;

ARCHITECTURE Behavior OF testbench IS

   COMPONENT Addern
      PORT ( X, Y : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		       Cin  : IN STD_LOGIC;
             S    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
             Cout : OUT STD_LOGIC );
   END COMPONENT;

   SIGNAL Cin : STD_LOGIC;
   SIGNAL X : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL Y : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL S : STD_LOGIC_VECTOR(15 DOWNTO 0);
   SIGNAL Cout : STD_LOGIC;
BEGIN
   vectors: PROCESS           
	BEGIN
      X <= X"0000"; Y <= X"0000"; Cin <= '0';
      WAIT FOR 20 ns;
      Y <= X"000A"; Cin <= '0';
      WAIT FOR 20 ns;
      X <= X"000A"; Cin <= '0';
      WAIT FOR 20 ns;
      Cin <= '1';
      WAIT FOR 20 ns;
      X <= X"FFF0"; Y <= X"000F"; Cin <= '0';
      WAIT FOR 20 ns;
      Cin <= '1';
		WAIT;
   END PROCESS;                                          

   U1: Addern PORT MAP (X, Y, Cin, S, Cout);
END;
