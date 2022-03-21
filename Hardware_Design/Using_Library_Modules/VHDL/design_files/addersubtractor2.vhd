LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

-- Top-level entity
ENTITY addersubtractor2 IS
    GENERIC ( n : INTEGER := 16 ) ;
    PORT (A, B                    : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0) ;
        Clock, Reset, Sel, AddSub : IN STD_LOGIC ;
        Z                         : BUFFER STD_LOGIC_VECTOR(n-1 DOWNTO 0) ;
        Overflow                  : OUT STD_LOGIC ) ;
END addersubtractor2 ;

ARCHITECTURE Behavior OF addersubtractor2 IS
    SIGNAL G, M, Areg, Breg, Zreg : STD_LOGIC_VECTOR(n-1 DOWNTO 0) ;
    SIGNAL SelR, AddSubR, over_flow : STD_LOGIC ;
    COMPONENT mux2to1
        GENERIC ( k : INTEGER := 8 ) ;
        PORT ( V, W : IN STD_LOGIC_VECTOR(k-1 DOWNTO 0) ;
            Selm    : IN STD_LOGIC ;
            F       : OUT STD_LOGIC_VECTOR(k-1 DOWNTO 0) ) ;
    END COMPONENT ;
    COMPONENT megaddsub
        PORT (add_sub    : IN STD_LOGIC ;
            dataa, datab : IN STD_LOGIC_VECTOR(15 DOWNTO 0) ;
            result       : OUT STD_LOGIC_VECTOR(15 DOWNTO 0) ;
            overflow     : OUT STD_LOGIC ) ;
    END COMPONENT ;
BEGIN
-- Define flip-flops and registers
    PROCESS ( Reset, Clock )
    BEGIN
        IF Reset = '1' THEN
            Areg <= (OTHERS => '0'); Breg <= (OTHERS => '0');
            Zreg <= (OTHERS => '0'); SelR <= '0'; AddSubR <= '0'; Overflow <= '0';
        ELSIF Clock'EVENT AND Clock = '1' THEN
            Areg <= A; Breg <= B; Zreg <= M;
            SelR <= Sel; AddSubR <= NOT AddSub; Overflow <= over_flow;
        END IF ;
    END PROCESS ;
-- Define combinational circuit
    nbit_addsub: megaddsub
        PORT MAP ( AddSubR, G, Breg, M, over_flow ) ;
    multiplexer: mux2to1
        GENERIC MAP ( k => n )
        PORT MAP ( Areg, Z, SelR, G ) ;
    Z <= Zreg ;
END Behavior;
-- k-bit 2-to-1 multiplexer
LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
ENTITY mux2to1 IS
    GENERIC ( k : INTEGER := 8 ) ;
    PORT ( V, W : IN STD_LOGIC_VECTOR(k-1 DOWNTO 0) ;
        Selm    : IN STD_LOGIC ;
        F       : OUT STD_LOGIC_VECTOR(k-1 DOWNTO 0) ) ;
END mux2to1 ;
ARCHITECTURE Behavior OF mux2to1 IS
BEGIN
    PROCESS ( V, W, Selm )
    BEGIN
        IF Selm = '0' THEN
            F <= V ;
        ELSE
            F <= W ;
        END IF ;
    END PROCESS ;
END Behavior ;
-- 16-bit adder/subtractor LPM created by the MegaWizard
LIBRARY ieee;
USE ieee.std_logic_1164.all;
LIBRARY lpm;
USE lpm.lpm_components.all;
ENTITY megaddsub IS
    PORT ( add_sub : IN STD_LOGIC ;
        dataa      : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        datab      : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        result     : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        overflow   : OUT STD_LOGIC );
END megaddsub;
ARCHITECTURE SYN OF megaddsub IS
    SIGNAL sub_wire0 : STD_LOGIC ;
    SIGNAL sub_wire1 : STD_LOGIC_VECTOR (15 DOWNTO 0);
    COMPONENT lpm_add_sub
    GENERIC ( lpm_width : NATURAL;
        lpm_direction : STRING;
        lpm_type : STRING;
        lpm_hint : STRING );
    PORT ( dataa : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        add_sub  : IN STD_LOGIC ;
        datab    : IN STD_LOGIC_VECTOR (15 DOWNTO 0);
        overflow : OUT STD_LOGIC ;
        result   : OUT STD_LOGIC_VECTOR (15 DOWNTO 0) );
    END COMPONENT;
BEGIN
    overflow <= sub_wire0;
    result <= sub_wire1(15 DOWNTO 0);
    lpm_add_sub_component : lpm_add_sub
    GENERIC MAP ( lpm_width => 16,
        lpm_direction => "UNUSED",
        lpm_type => "LPM_ADD_SUB",
        lpm_hint => "ONE_INPUT_IS_CONSTANT=NO,CIN_USED=NO" )
    PORT MAP ( dataa => dataa,
        add_sub => add_sub,
        datab => datab,
        overflow => sub_wire0,
        result => sub_wire1 );
END SYN;
