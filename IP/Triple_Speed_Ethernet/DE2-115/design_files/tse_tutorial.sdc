create_clock -period 20 [get_ports CLOCK_50]
derive_pll_clocks
derive_clock_uncertainty
set_clock_groups -exclusive -group [get_clocks pll_inst|altpll_component|auto_generated|pll1|clk[0]] -group [get_clocks pll_inst|altpll_component|auto_generated|pll1|clk[1]] -group [get_clocks pll_inst|altpll_component|auto_generated|pll1|clk[2]] -group [get_clocks pll_inst|altpll_component|auto_generated|pll1|clk[3]]
