#======================================================
#
# Synopsys Synthesis Scripts (Design Vision dctcl mode)
#
#======================================================

#======================================================
#  Set Libraries
#======================================================

set search_path {./../01_RTL \
                   ./../04_MEM \
                   ~iclabta01/umc018/Synthesis/ \
                   /usr/synthesis/libraries/syn/ \
                   /usr/synthesis/dw/ }

set synthetic_library {dw_foundation.sldb}
set link_library {* dw_foundation.sldb standard.sldb slow.db RA1SH_256_16.db RA1SH_64_16.db}
set target_library {slow.db}

#report_lib slow
#======================================================
#  Global Parameters
#======================================================
set DESIGN "CPU"
set CYCLE 3.9

#set IN_DLY [expr 0.5*$CLK_period]
#set OUT_DLY [expr 0.5*$CLK_period]


#======================================================
#  Read RTL Code
#======================================================
#set hdlin_auto_save_templates TRUE


read_sverilog $DESIGN.v
current_design $DESIGN

#======================================================
#  Global Setting
#======================================================
set_wire_load_mode top
#======================================================
#  Set Design Constraints
#======================================================

#set_dont_touch core_register_reg[*]
set_dont_touch core_r0[*]
set_dont_touch core_r1[*]
set_dont_touch core_r2[*]
set_dont_touch core_r3[*]
set_dont_touch core_r4[*]
set_dont_touch core_r5[*]
set_dont_touch core_r6[*]
set_dont_touch core_r7[*]
set_dont_touch core_r8[*]
set_dont_touch core_r9[*]
set_dont_touch core_r10[*]
set_dont_touch core_r11[*]
set_dont_touch core_r12[*]
set_dont_touch core_r13[*]
set_dont_touch core_r14[*]
set_dont_touch core_r15[*]

create_clock -name "clk" -period $CYCLE clk
#set_input_delay  [ expr $CYCLE*0.5 ] -clock clk [all_inputs]
#set_output_delay [ expr $CYCLE*0.5 ] -clock clk [all_outputs]
set_input_delay  0 -clock clk [all_inputs]
set_output_delay 0 -clock clk [all_outputs]

set_output_delay [ expr $CYCLE*0.5 ] -clock clk IO_stall

set_input_delay 0 -clock clk clk

set_input_delay 0 -clock clk rst_n

set_load 0.05 [all_outputs]

set_dont_use slow/JKFF*

#set hdlin_ff_always_sync_set_reset true
#report_clock -skew clk
#======================================================
#  Optimization
#======================================================


check_design > Report/$DESIGN\.check
set_fix_multiple_port_nets -all -buffer_constants
#set_fix_hold [all_clocks]
compile_ultra

#compile
#======================================================
#  Output Reports 
#======================================================
report_timing -max_paths 5 >  Report/$DESIGN\.timing
report_area -designware >  Report/$DESIGN\.area
report_resource >  Report/$DESIGN\.resource
report_cell > Report/$DESIGN\.cell
report_power > Report/$DESIGN\.power

#======================================================
#  Change Naming Rule
#======================================================
set bus_inference_style "%s\[%d\]"
set bus_naming_style "%s\[%d\]"
set hdlout_internal_busses true
change_names -hierarchy -rule verilog
define_name_rules name_rule -allowed "a-z A-Z 0-9 _" -max_length 255 -type cell
define_name_rules name_rule -allowed "a-z A-Z 0-9 _[]" -max_length 255 -type net
define_name_rules name_rule -map {{"\\*cell\\*" "cell"}}
change_names -hierarchy -rules name_rule

#======================================================
#  Output Results
#======================================================

set verilogout_higher_designs_first true

write -format verilog -output Netlist/$DESIGN\_SYN.v -hierarchy

write_sdf -version 3.0 -context verilog -load_delay cell Netlist/$DESIGN\_SYN.sdf -significant_digits 6

#======================================================
#  Finish and Quit
#======================================================
report_area
report_timing
write_sdc CHIP.sdc
exit


