LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY lpm;
USE lpm.all;
ENTITY megaddsub IS
    PORT ( add_sub : IN STD_LOGIC ;
        dataa      : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        datab      : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        overflow   : OUT STD_LOGIC;
        result     : OUT STD_LOGIC_VECTOR (15 DOWNTO 0) );
END megaddsub;
ARCHITECTURE SYN OF megaddsub IS
    SIGNAL sub_wire0 : STD_LOGIC ;
    SIGNAL sub_wire1 : STD_LOGIC_VECTOR (15 DOWNTO 0);
    COMPONENT lpm_add_sub
    GENERIC ( lpm_direction : STRING;
        lpm_hint : STRING;
        lpm_representation : STRING;
        lpm_type : STRING;
        lpm_width : NATURAL );
    PORT (
        dataa    : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        add_sub  : IN STD_LOGIC ;
        datab    : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        overflow : OUT STD_LOGIC ;
        result   : OUT STD_LOGIC_VECTOR (15 DOWNTO 0) );
    END COMPONENT;

BEGIN
    overflow <= sub_wire0;
    result <= sub_wire1(15 DOWNTO 0);
    lpm_add_sub_component : lpm_add_sub
    GENERIC MAP ( lpm_direction => "UNUSED",
        lpm_hint => "ONE_INPUT_IS_CONSTANT=NO,CIN_USED=NO",
        lpm_representation => "SIGNED",
        lpm_type => "LPM_ADD_SUB",
        lpm_width => 16 )
    PORT MAP ( dataa => dataa,
        add_sub => add_sub,
        datab => datab,
        overflow => sub_wire0,
        result => sub_wire1 );
END SYN;
