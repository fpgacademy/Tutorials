module tse_tutorial(
	// Clock
	input          OSC_50_BANK2,
	
	// KEY
	input  [ 0 :0] BUTTON,
		
	// Ethernet
	input  [ 1: 1] ETH_RX_p,
	output [ 1: 1] ETH_TX_p,	
	output         ETH_RST_n,
	output [ 1: 0] ETH_MDC,
	inout  [ 1: 0] ETH_MDIO
);

	wire sys_clk, clk_125, core_reset_n;
	wire mdc, mdio_in, mdio_oen, mdio_out;

	assign mdio_in     = ETH_MDIO[1];
	assign ETH_MDC[0]  = mdc;
	assign ETH_MDC[1]  = mdc;
	assign ETH_MDIO[0] = mdio_oen ? 1'bz : mdio_out;
	assign ETH_MDIO[1] = mdio_oen ? 1'bz : mdio_out;
	
	assign ETH_RST_n = core_reset_n;
	
	my_pll pll_inst(
		.rst	(~BUTTON[0]),
		.refclk	(OSC_50_BANK2),
		.outclk_0		(sys_clk),
		.outclk_1		(clk_125),
		.locked	(core_reset_n)
	);
		
    nios_system nios_system_inst(
        .clk_clk                              (sys_clk),       //                              clk.clk
        .reset_reset_n                        (core_reset_n),  //                            reset.reset_n

        .tse_serial_connection_txp            (ETH_TX_p[1]),   //            tse_serial_connection.txp
        .tse_serial_connection_rxp            (ETH_RX_p[1]),   //                                 .rxp
        .tse_pcs_ref_clk_clock_connection_clk (clk_125),			// tse_pcs_ref_clk_clock_connection.clk
        .tse_mac_mdio_connection_mdc          (mdc),          	//          tse_mac_mdio_connection.mdc
        .tse_mac_mdio_connection_mdio_in      (mdio_in),      	//                                 .mdio_in
        .tse_mac_mdio_connection_mdio_out     (mdio_out),     	//                                 .mdio_out
        .tse_mac_mdio_connection_mdio_oen     (mdio_oen)      	//                                 .mdio_oen
    );		
	
endmodule 