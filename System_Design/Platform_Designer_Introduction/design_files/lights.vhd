-------------------------------------------------------------------------------
--                                                                           --
-- Top-level module for Qsys tutorial                                                --
--                                                                           --
-------------------------------------------------------------------------------


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY lights IS

-------------------------------------------------------------------------------
--                             Port Declarations                             --
-------------------------------------------------------------------------------
PORT (
	-- Inputs
	CLOCK_50             : IN STD_LOGIC;
	KEY                  : IN STD_LOGIC_VECTOR (0 DOWNTO 0);

	SW	               : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
	
	-- Outputs
	LEDG                 : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END lights;


ARCHITECTURE lights_rtl OF lights IS

	COMPONENT nios_system
		PORT (
              -- 1) global signals:
                 SIGNAL clk_clk		: IN STD_LOGIC;
                 SIGNAL reset_reset_n	: IN STD_LOGIC;

              -- slider switches
                 SIGNAL switches_export	: IN STD_LOGIC_VECTOR (7 DOWNTO 0);

              -- the_green_LEDs
                 SIGNAL leds_export		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
              );
	END COMPONENT;

BEGIN
	
-------------------------------------------------------------------------------
--                              Internal Module                              --
-------------------------------------------------------------------------------

NiosII : nios_system
	PORT MAP(
		clk_clk			=> CLOCK_50,
		reset_reset_n		=> KEY(0),
		switches_export		=> SW(7 DOWNTO 0),
		leds_export			=> LEDG(7 DOWNTO 0)
		);
	
END lights_rtl;

