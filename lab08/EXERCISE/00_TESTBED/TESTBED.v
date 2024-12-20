/**************************************************************************/
// Copyright (c) 2023, OASIS Lab
// MODULE: TESTBED
// FILE NAME: TESTBED.v
// VERSRION: 1.0
// DATE: Mar 31, 2023
// AUTHOR: Kuan-Wei Chen, NYCU IEE
// CODE TYPE: RTL or Behavioral Level (Verilog)
// DESCRIPTION: 2023 Spring IC Lab / Exercise Lab08 / SNN
// MODIFICATION HISTORY:
// Date                 Description
// 
/**************************************************************************/

`timescale 1ns/10ps

// PATTERN
`ifdef CG
	`include /*../00_TESTBED/PATTERN_iclab2023spring_Lab08_v2_CG.v"*/ "../00_TESTBED/PATTERN_CG1_stu.v"
`elsif NCG
	`include /*"../00_TESTBED/PATTERN_iclab2023spring_Lab08_v2.v"*/ "../00_TESTBED/PATTERN_CG0_stu.v"
`endif

// DESIGN
`ifdef RTL
	`include "SNN.v"
`elsif GATE
	`include "SNN_SYN.v"
`endif


module TESTBED();
	wire clk, rst_n, in_valid, cg_en;
	wire [7:0] img;
	wire [7:0] ker;
	wire [7:0] weight;
	wire out_valid;
	wire [9:0] out_data;	

initial begin
 	`ifdef RTL
    	`ifdef CG
        	$fsdbDumpfile("SNN_CG.fsdb");
    	`elsif NCG
    		$fsdbDumpfile("SNN.fsdb");
    	`endif
		$fsdbDumpvars(0,"+mda");
	`elsif GATE
		`ifdef CG
			$fsdbDumpfile("SNN_SYN_CG.fsdb");
		`elsif NCG
			$fsdbDumpfile("SNN_SYN.fsdb");
		`endif
		$fsdbDumpvars(0,"+mda");
		$sdf_annotate("SNN_SYN.sdf",I_SNN); 
	`endif
end

SNN I_SNN
(
	// Input signals
	.clk(clk),
	.rst_n(rst_n),
	.cg_en(cg_en),
	.in_valid(in_valid),
	.img(img),
	.ker(ker),
	.weight(weight),

	// Output signals
	.out_valid(out_valid),
	.out_data(out_data)
);


PATTERN I_PATTERN
(
	// Output signals
	.clk(clk),
	.rst_n(rst_n),
	.cg_en(cg_en),
	.in_valid(in_valid),
	.img(img),
	.ker(ker),
	.weight(weight),

	// Input signals
	.out_valid(out_valid),
	.out_data(out_data)
);

endmodule
