LIBRARY ieee ;
USE ieee.std_logic_1164.all ;

-- Top-level entity
ENTITY addersubtractor IS
    GENERIC ( n : INTEGER := 16 ) ;
    PORT (A, B                    : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0) ;
        Clock, Reset, Sel, AddSub : IN STD_LOGIC ;
        Z                         : BUFFER STD_LOGIC_VECTOR(n-1 DOWNTO 0) ;
        Overflow                  : OUT STD_LOGIC ) ;
END addersubtractor ;

ARCHITECTURE Behavior OF addersubtractor IS
    SIGNAL G, H, M, Areg, Breg, Zreg, AddSubR_n : STD_LOGIC_VECTOR(n-1 DOWNTO 0) ;
    SIGNAL SelR, AddSubR, carryout, over_flow : STD_LOGIC ;
    COMPONENT mux2to1
        GENERIC ( k : INTEGER := 8 ) ;
        PORT ( V, W : IN STD_LOGIC_VECTOR(k-1 DOWNTO 0) ;
            Selm    : IN STD_LOGIC ;
            F       : OUT STD_LOGIC_VECTOR(k-1 DOWNTO 0) ) ;
    END COMPONENT ;
    COMPONENT adderk
        GENERIC ( k : INTEGER := 8 ) ;
        PORT (carryin : IN STD_LOGIC ;
            X, Y      : IN STD_LOGIC_VECTOR(k-1 DOWNTO 0) ;
            S         : OUT STD_LOGIC_VECTOR(k-1 DOWNTO 0) ;
            carryout  : OUT STD_LOGIC );
    END COMPONENT ;
BEGIN
    PROCESS ( Reset, Clock )
    BEGIN
        IF Reset = '1' THEN
        Areg <= (OTHERS => '0'); Breg <= (OTHERS => '0');
        Zreg <= (OTHERS => '0'); SelR <= '0'; AddSubR <= '0'; Overflow <= '0';
    ELSIF Clock'EVENT AND Clock = '1' THEN
        Areg <= A; Breg <= B; Zreg <= M;
        SelR <= Sel; AddSubR <= AddSub; Overflow <= over_flow;
    END IF ;
    END PROCESS ;
    nbit_adder: adderk
        GENERIC MAP ( k => n )
        PORT MAP ( AddSubR, G, H, M, carryout ) ;
    multiplexer: mux2to1
        GENERIC MAP ( k => n )
        PORT MAP ( Areg, Z, SelR, G ) ;
    AddSubR_n <= (OTHERS => AddSubR) ;
    H <= Breg XOR AddSubR_n ;
    over_flow <= carryout XOR G(n-1) XOR H(n-1) XOR M(n-1) ;
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
-- k-bit adder
LIBRARY ieee ;
USE ieee.std_logic_1164.all ;
USE ieee.std_logic_signed.all ;
ENTITY adderk IS
    GENERIC ( k : INTEGER := 8 ) ;
    PORT ( carryin : IN STD_LOGIC ;
        X, Y       : IN STD_LOGIC_VECTOR(k-1 DOWNTO 0) ;
        S          : OUT STD_LOGIC_VECTOR(k-1 DOWNTO 0) ;
        carryout   : OUT STD_LOGIC ) ;
END adderk ;

ARCHITECTURE Behavior OF adderk IS
    SIGNAL Sum : STD_LOGIC_VECTOR(k DOWNTO 0) ;
BEGIN
    Sum <= ('0'& X) + ('0'& Y) + carryin ;
    S <= Sum(k-1 DOWNTO 0) ;
    carryout <= Sum(k) ;
END Behavior ;
