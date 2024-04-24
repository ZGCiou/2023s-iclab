//++++++++++++++ Include DesignWare++++++++++++++++++
//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_fp_mult.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_add.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_sum3.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_exp.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_div.v"
//synopsys translate_on
//+++++++++++++++++++++++++++++++++++++++++++++++++++
module NN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	data_h,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter s_idle = 2'd0;
parameter s_input = 2'd1;
parameter s_cal = 2'd2;
parameter s_out = 2'd3;
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;
parameter arch_type = 0;

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x,data_h;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [1:0] current_state, next_state;
reg [3:0] count;
// Input Data
reg [inst_sig_width+inst_exp_width:0] weight_U [0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] weight_W [0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] weight_V [0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] data_X [1:3][0:2];
reg [inst_sig_width+inst_exp_width:0] data_H [0:2];
// DesignWare
reg [inst_sig_width+inst_exp_width:0] mul1_in1[0:2], mul1_in2[0:2], mul2_in1[0:2], mul2_in2[0:2], mul3_in1[0:2], mul3_in2[0:2];
wire [inst_sig_width+inst_exp_width:0] mul1_out[0:2], mul2_out[0:2], add_out[0:2], mul3_out[0:2], add_vh_out;
// Data Path
reg [1:0] cal_count, cal_data_count;
reg [inst_sig_width+inst_exp_width:0] acc[0:2], cal_H[0:2];
wire [inst_sig_width+inst_exp_width:0] relu_result[0:2], sigmoid_result;
//---------------------------------------------------------------------
//   Finite-State Mechine                                          
//---------------------------------------------------------------------
// Current State
always @(posedge clk or negedge rst_n) begin : proc_current_state
	if(~rst_n)
		current_state <= s_idle;
	else begin
		current_state <= next_state;
	end
end
// Next State
always @(*) begin : proc_next_state
	case (current_state)
		s_idle: begin
			if (in_valid)
				next_state = s_input;
			else
				next_state = s_idle;
		end
		
		s_input: begin
			if (count == 'd7)
				next_state = s_cal;
			else
				next_state = s_input;
		end
		
		s_cal: begin
			if (count == 'd11)
				next_state = s_idle;
			else
				next_state = s_cal;
		end
		/*
		s_out: begin
			if (count == 'd9)
				next_state = s_idle;
			else
				next_state = s_out;
		end
		*/
		default : next_state = current_state;
	endcase
end
// Count
always @(posedge clk or negedge rst_n) begin : proc_count
	if(~rst_n)
		count <= 4'b0;
	else begin
		case (current_state)
			s_idle: begin
				count <= 'd0;
			end

			s_input: begin
				if (count == 'd7)
					count <= 'd0;
				else
					count <= count + 'd1;
			end

			s_cal: begin
				count <= count + 'd1;
			end
			/*
			s_out: begin
				if (count == 'd9)
					count <= 'd0;
				else
					count <= count + 'd1;
			end
			*/
		endcase
	end
end

//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
// weight_U
always @(posedge clk) begin : proc_weight_U
	if (in_valid) begin
		weight_U[2][2] <= weight_u;
		weight_U[2][1] <= weight_U[2][2];
		weight_U[2][0] <= weight_U[2][1];
		weight_U[1][2] <= weight_U[2][0];
		weight_U[1][1] <= weight_U[1][2];
		weight_U[1][0] <= weight_U[1][1];
		weight_U[0][2] <= weight_U[1][0];
		weight_U[0][1] <= weight_U[0][2];
		weight_U[0][0] <= weight_U[0][1];
	end
end
// weight_W
always @(posedge clk) begin : proc_weight_W
	if (in_valid) begin
		weight_W[2][2] <= weight_w;
		weight_W[2][1] <= weight_W[2][2];
		weight_W[2][0] <= weight_W[2][1];
		weight_W[1][2] <= weight_W[2][0];
		weight_W[1][1] <= weight_W[1][2];
		weight_W[1][0] <= weight_W[1][1];
		weight_W[0][2] <= weight_W[1][0];
		weight_W[0][1] <= weight_W[0][2];
		weight_W[0][0] <= weight_W[0][1];
	end
end
// weight_V
always @(posedge clk) begin : proc_weight_V
	if (in_valid) begin
		weight_V[2][2] <= weight_v;
		weight_V[2][1] <= weight_V[2][2];
		weight_V[2][0] <= weight_V[2][1];
		weight_V[1][2] <= weight_V[2][0];
		weight_V[1][1] <= weight_V[1][2];
		weight_V[1][0] <= weight_V[1][1];
		weight_V[0][2] <= weight_V[1][0];
		weight_V[0][1] <= weight_V[0][2];
		weight_V[0][0] <= weight_V[0][1];
	end
end
// data_X
always @(posedge clk) begin : proc_data_X
	if (in_valid) begin
		data_X[3][2] <= data_x;
		data_X[3][1] <= data_X[3][2];
		data_X[3][0] <= data_X[3][1];
		data_X[2][2] <= data_X[3][0];
		data_X[2][1] <= data_X[2][2];
		data_X[2][0] <= data_X[2][1];
		data_X[1][2] <= data_X[2][0];
		data_X[1][1] <= data_X[1][2];
		data_X[1][0] <= data_X[1][1];
	end
end
// data_H
always @(posedge clk) begin : proc_data_H
	case (current_state)
		s_idle: begin
			if (in_valid) begin
				data_H[2] <= data_h;
				data_H[1] <= data_H[2];
				data_H[0] <= data_H[1];
			end
		end

		s_input: begin
			if (count < 'd2) begin
				data_H[2] <= data_h;
				data_H[1] <= data_H[2];
				data_H[0] <= data_H[1];
			end
		end

		s_cal: begin
			if (cal_count == 2'd2) begin
				data_H[2] <= relu_result[2];
				data_H[1] <= relu_result[1];
				data_H[0] <= relu_result[0];
			end
		end
	endcase
end

//---------------------------------------------------------------------
//   ALGORITHM
//---------------------------------------------------------------------
// cal_count
always @(posedge clk) begin : proc_cal_count
	case (current_state)
		s_idle: cal_count <= 2'd0;
		s_cal: begin
			if (cal_count == 2'd2)
				cal_count <= 2'd0;
			else
				cal_count <= cal_count + 2'd1;
		end
	endcase
end
// cal_data_count
always @(posedge clk) begin : proc_cal_data_count
	case (current_state)
		s_idle: cal_data_count <= 2'd1;
		s_cal: begin
			if (cal_count == 2'd2)
				cal_data_count <= cal_data_count + 2'd1;
		end
	endcase
end
// Stage 1
generate
	genvar idx;
	for (idx=0; idx<3; idx=idx+1) begin : stage_1
		//mul1_in1 -> x0, x1, x2 in sequence
		always @(*) begin
			case (current_state)
				s_cal: begin
					mul1_in1[idx] = data_X[cal_data_count][cal_count];
				end
				default : mul1_in1[idx] = 'd0;
			endcase
		end
		//mul1_in2 -> weight_U col[idx]
		always @(*) begin
			case (current_state)
				s_cal: begin
					mul1_in2[idx] = weight_U[idx][cal_count];
				end

				default : mul1_in2[idx] = 'd0;
			endcase
		end
		//mul2_in1 -> h0, h1, h2 in sequence
		always @(*) begin
			case (current_state)
				s_cal: begin
					mul2_in1[idx] = data_H[cal_count];
				end
				default : mul2_in1[idx] = 'd0;
			endcase
		end
		//mul2_in2 -> weight_W col[idx]
		always @(*) begin
			case (current_state)
				s_cal: begin
					mul2_in2[idx] = weight_W[idx][cal_count];
				end

				default : mul2_in2[idx] = 'd0;
			endcase
		end
		//designWare
		DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
			M_ux (.a(mul1_in1[idx]), .b(mul1_in2[idx]), .rnd(3'b000), .z(mul1_out[idx]));

		DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
			M_wh (.a(mul2_in1[idx]), .b(mul2_in2[idx]), .rnd(3'b000), .z(mul2_out[idx]));

		DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, arch_type) 
			S3_ux_wh (.a(mul1_out[idx]), .b(mul2_out[idx]), .c(acc[idx]), .rnd(3'b000), .z(add_out[idx]));

		myReLU R_ux_wh(.in(add_out[idx]), .out(relu_result[idx]));
		//acc
		always @(posedge clk) begin : proc_acc
			if(~rst_n)
				acc[idx] <= 'd0;
			else begin
				case (current_state)
					s_cal: begin
						if (cal_count == 2'd2)
							acc[idx] <= 'd0;
						else
							acc[idx] <= add_out[idx];
						end
					default : acc[idx] <= 'd0;
				endcase
			end
		end
	end
endgenerate

// Stage 2
generate
	genvar jdx;
	for (jdx=0; jdx<3; jdx=jdx+1) begin : stage_2
		// cal_H
		always @(posedge clk or negedge rst_n) begin : proc_cal_H
			if(~rst_n)
				cal_H[jdx] <= 'd0;
			else begin
				if (cal_count == 2'd2)
					cal_H[jdx] <= relu_result[jdx];
			end
		end
		//mul3_in1 -> cal_H
		always @(*) begin
			mul3_in1[jdx] = cal_H[jdx];
		end
		//mul3_in2 -> V row[jdx]
		always @(*) begin
			case (current_state)
				s_cal: begin
					mul3_in2[jdx] = weight_V[cal_count][jdx];
				end

				default : mul3_in2[jdx] = 'd0;
			endcase
		end
		//designWare
		DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
			M_vh (.a(mul3_in1[jdx]), .b(mul3_in2[jdx]), .rnd(3'b000), .z(mul3_out[jdx]));
	end
endgenerate

DW_fp_sum3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, arch_type) 
	S3_vh (.a(mul3_out[0]), .b(mul3_out[1]), .c(mul3_out[2]), .rnd(3'b000), .z(add_vh_out));

// Sigmoid
mySigmoid Sig_vh(.in(add_vh_out), .out(sigmoid_result));

//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
// Out Valid
always @(posedge clk or negedge rst_n) begin : proc_out_valid
	if(~rst_n)
		out_valid <= 1'b0;
	else begin
		case (current_state)
			s_idle: out_valid <= 1'b0;
			s_cal: begin
				if (count == 4'd3)
					out_valid <= 1'b1;
			end
		endcase
	end
end
// Out
always @(posedge clk or negedge rst_n) begin : proc_out
	if(~rst_n)
		out <= 0;
	else begin
		case (current_state)
			s_cal: begin
				if (count > 4'd2)	
					out <= sigmoid_result;
			end

			default : out <= 'd0;
		endcase
	end
end



endmodule

//---------------------------------------------------------------------
//   SUB MODULE
//---------------------------------------------------------------------
// ReLU
module myReLU #(
	parameter inst_sig_width = 23,
	parameter inst_exp_width = 8,
	parameter inst_ieee_compliance = 0
) (
	input [inst_sig_width+inst_exp_width:0] in,
	output [inst_sig_width+inst_exp_width:0] out
);
	wire [inst_sig_width+inst_exp_width:0] z;
	
	DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) 
		M0(.a(in), .b(32'h3DCCCCCD), .rnd(3'b000), .z(z)); 

	assign out = (in[inst_sig_width+inst_exp_width]) ? z : in;

endmodule
// Sigmoid
module mySigmoid #(
	parameter inst_sig_width = 23,
	parameter inst_exp_width = 8,
	parameter inst_ieee_compliance = 0,
	parameter arch = 0,
	parameter faithful_round = 0
)(
	input [inst_sig_width+inst_exp_width:0] in,
	output [inst_sig_width+inst_exp_width:0] out
);
	wire [inst_sig_width+inst_exp_width:0] in_n, exp_out, add_out;

	assign in_n = {~in[inst_sig_width+inst_exp_width], in[inst_sig_width+inst_exp_width-1:0]};

	DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, arch)
		E0(.a(in_n), .z(exp_out));
	
	DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
		A0(.a(exp_out), .b(32'h3F800000), .rnd(3'b000), .z(add_out));
	
	DW_fp_div #(inst_sig_width, inst_exp_width, inst_ieee_compliance, faithful_round)
		D0(.a(32'h3F800000), .b(add_out), .rnd(3'b000), .z(out));

endmodule
