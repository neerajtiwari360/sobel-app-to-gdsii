# Educational starting target: 50 ns = 20 MHz. Tighten after reading STA.
create_clock -name core_clk -period 50 [get_ports clk]
set_input_delay  2 -clock core_clk [get_ports {rst start pixel_in* in_valid}]
set_output_delay 2 -clock core_clk [get_ports {in_ready edge_out* out_valid done}]
