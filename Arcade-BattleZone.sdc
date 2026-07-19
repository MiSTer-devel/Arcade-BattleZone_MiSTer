# Core PLL outputs are used as separate clock domains.
# The system SDC groups them together because they come from the same PLL, so
# explicitly declare them asynchronous to match the renderer CDC structure.

set emu_clk_50  [get_clocks {emu|pll|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
set emu_clk_12  [get_clocks {emu|pll|pll_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}]
set emu_clk_6   [get_clocks {emu|pll|pll_inst|altera_pll_i|general[2].gpll~PLL_OUTPUT_COUNTER|divclk}]
set emu_clk_125 [get_clocks {emu|pll|pll_inst|altera_pll_i|general[3].gpll~PLL_OUTPUT_COUNTER|divclk}]

set_clock_groups -asynchronous \
   -group $emu_clk_50 \
   -group $emu_clk_12 \
   -group $emu_clk_6 \
   -group $emu_clk_125
