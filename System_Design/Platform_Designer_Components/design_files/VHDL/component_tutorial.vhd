LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY component_tutorial IS
PORT ( CLOCK_50 : IN STD_LOGIC;
KEY : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
HEX0 : OUT STD_LOGIC_VECTOR(0 TO 6);
HEX1 : OUT STD_LOGIC_VECTOR(0 TO 6);
HEX2 : OUT STD_LOGIC_VECTOR(0 TO 6);
HEX3 : OUT STD_LOGIC_VECTOR(0 TO 6));
END component_tutorial;
ARCHITECTURE Structure OF component_tutorial IS
SIGNAL to_HEX : STD_LOGIC_VECTOR(31 DOWNTO 0);
COMPONENT embedded_system IS
PORT ( clk_clk : IN STD_LOGIC;
resetn_reset_n : IN STD_LOGIC;
to_hex_readdata : OUT STD_LOGIC_VECTOR (31 DOWNTO 0) );
END COMPONENT embedded_system;
COMPONENT hex7seg IS
PORT ( hex : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
display : OUT STD_LOGIC_VECTOR(0 TO 6) );
END COMPONENT hex7seg;
BEGIN
U0: embedded_system PORT MAP (
clk_clk => CLOCK_50,
resetn_reset_n => KEY(0),
to_hex_readdata => to_HEX );
h0: hex7seg PORT MAP (to_HEX(3 DOWNTO 0), HEX0);
h1: hex7seg PORT MAP (to_HEX(7 DOWNTO 4), HEX1);
h2: hex7seg PORT MAP (to_HEX(11 DOWNTO 8), HEX2);
h3: hex7seg PORT MAP (to_HEX(15 DOWNTO 12), HEX3);
END Structure;
LIBRARY ieee;
USE ieee.std_logic_1164.all;
ENTITY hex7seg IS
PORT ( hex : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
display : OUT STD_LOGIC_VECTOR(0 TO 6) );
END hex7seg;
ARCHITECTURE Behavior OF hex7seg IS
BEGIN

PROCESS (hex)
BEGIN
CASE hex IS
WHEN "0000" => display <= "0000001";
WHEN "0001" => display <= "1001111";
WHEN "0010" => display <= "0010010";
WHEN "0011" => display <= "0000110";
WHEN "0100" => display <= "1001100";
WHEN "0101" => display <= "0100100";
WHEN "0110" => display <= "0100000";
WHEN "0111" => display <= "0001111";
WHEN "1000" => display <= "0000000";
WHEN "1001" => display <= "0001100";
WHEN "1010" => display <= "0001000";
WHEN "1011" => display <= "1100000";
WHEN "1100" => display <= "0110001";
WHEN "1101" => display <= "1000010";
WHEN "1110" => display <= "0110000";
WHEN "1111" => display <= "0111000";
END CASE;
END PROCESS;
END Behavior;