LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
 
ENTITY testbench IS
END testbench;
 
ARCHITECTURE Behavior OF testbench IS
    COMPONENT display
        PORT (  KEY   : IN   STD_LOGIC_VECTOR(0 DOWNTO 0);
                SW    : IN   STD_LOGIC_VECTOR(0 DOWNTO 0);
                HEX0  : OUT  STD_LOGIC_VECTOR(6 DOWNTO 0);
                LEDR  : OUT  STD_LOGIC_VECTOR(9 DOWNTO 0));
    END COMPONENT;

    SIGNAL KEY : STD_LOGIC_VECTOR(0 DOWNTO 0);
    SIGNAL SW : STD_LOGIC_VECTOR(0 DOWNTO 0);
    SIGNAL HEX0 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL LEDR : STD_LOGIC_VECTOR(9 DOWNTO 0);
BEGIN
    U1: display PORT MAP (KEY, SW, HEX0, LEDR);

    clock_process: PROCESS
    BEGIN
        KEY(0) <= '0';
        WAIT FOR 10 ns;
        KEY(0) <= '1';
        WAIT FOR 10 ns;
    END PROCESS;    
    
    vectors: PROCESS
    BEGIN
        SW(0) <= '0';       -- Resetn = 0
        WAIT FOR 20 ns;     
        SW(0) <= '1';       -- Resetn = 1
        WAIT;
    END PROCESS;
END;
