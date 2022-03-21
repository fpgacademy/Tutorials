module tse_tutorial(
	// Clock
	input         CLOCK_50,
	
	// KEY
	input  [0: 0] KEY,
	
	// Ethernet 0
	output        ENET0_MDC,
	inout         ENET0_MDIO,
	output        ENET0_RESET_N,
	
	// Ethernet 1
	output        ENET1_GTX_CLK,
	output        ENET1_MDC,
	inout         ENET1_MDIO,
	output        ENET1_RESET_N,
	input         ENET1_RX_CLK,
	input  [3: 0] ENET1_RX_DATA,
	input         ENET1_RX_DV,
	output [3: 0] ENET1_TX_DATA,
	output        ENET1_TX_EN
);

	wire sys_clk, clk_125, clk_25, clk_2p5, tx_clk;
	wire core_reset_n;
	wire mdc, mdio_in, mdio_oen, mdio_out;
	wire eth_mode, ena_10;

	assign mdio_in   = ENET1_MDIO;
	assign ENET0_MDC  = mdc;
	assign ENET1_MDC  = mdc;
	assign ENET0_MDIO = mdio_oen ? 1'bz : mdio_out;
	assign ENET1_MDIO = mdio_oen ? 1'bz : mdio_out;
	
	assign ENET0_RESET_N = core_reset_n;
	assign ENET1_RESET_N = core_reset_n;
	
	my_pll pll_inst(
		.rst	(~KEY[0]),
		.refclk	(CLOCK_50),
		.outclk_0		(sys_clk),
		.outclk_1		(clk_125),
		.outclk_2		(clk_25),
		.outclk_3		(clk_2p5),
		.locked	(core_reset_n)
	); 
	
	assign tx_clk = eth_mode ? clk_125 :       // GbE Mode   = 125MHz clock
	                ena_10   ? clk_2p5 :       // 10Mb Mode  = 2.5MHz clock
	                           clk_25;         // 100Mb Mode = 25 MHz clock
	
	my_ddio_out ddio_out_inst(
		.datain_h(1'b1),
		.datain_l(1'b0),
		.outclock(tx_clk),
		.dataout(ENET1_GTX_CLK)
	);

	
    nios_system system_inst (
        .clk_clk                                   (sys_clk),           //                                   clk.clk
        .reset_reset_n                             (core_reset_n),      //                                 reset.reset_n
        .tse_pcs_mac_tx_clock_connection_clk 		(tx_clk), 				// eth_tse_0_pcs_mac_tx_clock_connection.clk
        .tse_pcs_mac_rx_clock_connection_clk 		(ENET1_RX_CLK), 		// eth_tse_0_pcs_mac_rx_clock_connection.clk
        .tse_mac_mdio_connection_mdc               (mdc),             	//               tse_mac_mdio_connection.mdc
        .tse_mac_mdio_connection_mdio_in           (mdio_in),           //                                      .mdio_in
        .tse_mac_mdio_connection_mdio_out          (mdio_out),          //                                      .mdio_out
        .tse_mac_mdio_connection_mdio_oen          (mdio_oen),          //                                      .mdio_oen
        .tse_mac_rgmii_connection_rgmii_in         (ENET1_RX_DATA),     //              tse_mac_rgmii_connection.rgmii_in
        .tse_mac_rgmii_connection_rgmii_out        (ENET1_TX_DATA),     //                                      .rgmii_out
        .tse_mac_rgmii_connection_rx_control       (ENET1_RX_DV),       //                                      .rx_control
        .tse_mac_rgmii_connection_tx_control       (ENET1_TX_EN),       //                                      .tx_control

        .tse_mac_status_connection_eth_mode        (eth_mode),        	//                                      .eth_mode
        .tse_mac_status_connection_ena_10          (ena_10),          	//                                      .ena_10	  
    );	

endmodule 