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
parameter s_idle = 3'd0;
parameter s_input = 3'd1;
parameter s_cal_1 = 3'd2;
parameter s_cal_2 = 3'd3;
parameter s_out = 3'd4;
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
// FSM
reg [2:0] current_state, next_state;
reg [4:0] count;
// Input Data
reg [inst_sig_width+inst_exp_width:0] weight_U [0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] weight_W [0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] weight_V [0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] data_X [0:2][0:2];
reg [inst_sig_width+inst_exp_width:0] data_H [0:1][0:2];
// DesignWare
reg [inst_sig_width+inst_exp_width:0] mul_ux_in1, mul_ux_in2, mul_wh_in1, mul_wh_in2, mul_vh_in1, mul_vh_in2, add_acc_vh_in;
wire [inst_sig_width+inst_exp_width:0] mul_ux_out, mul_wh_out, add_uxwh_out, add_acc_uxwh_out, mul_vh_out, add_acc_vh_out;
// Data Path
reg [1:0] cal_count, cal_count_3, cal_count_9, count_v, count_v_3;
reg [3:0] count_out;
reg [inst_sig_width+inst_exp_width:0] p1Reg_xu, p1Reg_wh, p2Reg, p3Reg, p5Reg, p6Reg, acc_uxwh, acc_vy[0:2];//, cal_H[0:2];
reg [4:0] p1Reg_flag, p2Reg_flag, p3Reg_flag;
reg [3:0] p4Reg_flag;
reg [2:0] p5Reg_flag;
reg p6Reg_flag;
wire [inst_sig_width+inst_exp_width:0] relu_out, sigmoid_out;
// Output
reg [inst_sig_width+inst_exp_width:0] out_Y [0:5];
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
				next_state = s_cal_1;
			else
				next_state = s_input;
		end
		
		s_cal_1: begin
			if (count == 'd28)
				next_state = s_cal_2;
			else
				next_state = s_cal_1;
		end
		
		s_cal_2: begin
			if (count_out == 'd8)
				next_state = s_idle;
			else
				next_state = s_cal_2;
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
		count <= 'b0;
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

			s_cal_1: begin
				count <= count + 'd1;
			end

			s_cal_2: begin
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
		data_X[2][2] <= data_x;
		data_X[2][1] <= data_X[2][2];
		data_X[2][0] <= data_X[2][1];
		data_X[1][2] <= data_X[2][0];
		data_X[1][1] <= data_X[1][2];
		data_X[1][0] <= data_X[1][1];
		data_X[0][2] <= data_X[1][0];
		data_X[0][1] <= data_X[0][2];
		data_X[0][0] <= data_X[0][1];
	end
end
// data_H[0]
always @(posedge clk) begin : proc_data_H
	case (current_state)
		s_idle: begin
			if (in_valid) begin
				data_H[0][2] <= data_h;
				data_H[0][1] <= data_H[0][2];
				data_H[0][0] <= data_H[0][1];
			end
		end
		s_input: begin
			if (count < 'd2) begin
				data_H[0][2] <= data_h;
				data_H[0][1] <= data_H[0][2];
				data_H[0][0] <= data_H[0][1];
			end
		end
		
		s_cal_1: begin
			if (count == 'd8 || count == 'd18 || count == 'd28) begin
				data_H[0][0] <= data_H[1][0];
			end

			if (count == 'd9 || count == 'd19 || count == 'd29) begin
				data_H[0][1] <= data_H[1][1];
			end

			if (count == 'd11 || count == 'd21 || count == 'd30) begin
				data_H[0][2] <= relu_out;
			end
		end
		
	endcase
end

//---------------------------------------------------------------------
//   ALGORITHM
//---------------------------------------------------------------------
// cal_count
always @(posedge clk or negedge rst_n) begin : proc_cal_count
	if (~rst_n)
		cal_count <= 2'd0;
	else begin
		case (current_state)
			s_idle: cal_count <= 2'd0;
			s_cal_1: begin
				if (count == 'd10 || count == 'd20)
					cal_count <= cal_count;

				else if (cal_count == 2'd2)
					cal_count <= 2'd0;

				else
					cal_count <= cal_count + 2'd1;
			end
			s_cal_2: begin
				if (count == 'd10 || count == 'd20)
					cal_count <= cal_count;

				else if (cal_count == 2'd2)
					cal_count <= 2'd0;

				else
					cal_count <= cal_count + 2'd1;
			end

		endcase
	end
end
// cal_count_3
always @(posedge clk or negedge rst_n) begin : proc_cal_count_3
	if (~rst_n)
		cal_count_3 <= 2'd0;
	else begin
		case (current_state)
			s_idle: cal_count_3 <= 2'd0;
			s_cal_1: begin
				if (count == 'd10 || count == 'd20)
					cal_count_3 <= cal_count_3;

				else if (cal_count == 2'd2) begin
					if (cal_count_3 == 2'd2)
						cal_count_3 <= 2'd0;
					else
						cal_count_3 <= cal_count_3 + 2'd1;
				end
			end
			s_cal_2: begin
				if (count == 'd10 || count == 'd20)
					cal_count_3 <= cal_count_3;

				else if (cal_count == 2'd2) begin
					if (cal_count_3 == 2'd2)
						cal_count_3 <= 2'd0;
					else
						cal_count_3 <= cal_count_3 + 2'd1;
				end
			end
		endcase
	end
end
// cal_count_9
always @(posedge clk or negedge rst_n) begin : proc_cal_count_9
	if (~rst_n)
		cal_count_9 <= 2'd0;
	else begin
		case (current_state)
			s_idle: cal_count_9 <= 2'd0;
			s_cal_1: begin
				if (count == 'd10 || count == 'd20)
					cal_count_9 <= cal_count_9;

				else if (cal_count_3 == 2'd2 && cal_count == 2'd2) begin
					if (cal_count_9 == 2'd2)
						cal_count_9 <= 2'd0;
					else
						cal_count_9 <= cal_count_9 + 2'd1;
				end
			end
			s_cal_2: begin
				if (count == 'd10 || count == 'd20)
					cal_count_9 <= cal_count_9;

				else if (cal_count_3 == 2'd2 && cal_count == 2'd2) begin
					if (cal_count_9 == 2'd2)
						cal_count_9 <= 2'd0;
					else
						cal_count_9 <= cal_count_9 + 2'd1;
				end
			end
		endcase
	end
end

// STAGE 1
// mul_ux_in1
always @(*) begin : proc_mul_ux_in1
	case (current_state)
		s_cal_1: begin
			mul_ux_in1 = data_X[cal_count_9][cal_count];
		end		
		default : mul_ux_in1 = 'd0;
	endcase
end
// mul_ux_in2
always @(*) begin : proc_mul_ux_in2
	case (current_state)
		s_cal_1: begin
			mul_ux_in2 = weight_U[cal_count_3][cal_count];
		end		
		default : mul_ux_in2 = 'd0;
	endcase
end
// mul_wh_in1
always @(*) begin : proc_mul_wh_in1
	case (current_state)
		s_cal_1: begin
			mul_wh_in1 = data_H[0][cal_count];
		end		
		default : mul_wh_in1 = 'd0;
	endcase
end
// mul_wh_in2
always @(*) begin : proc_mul_wh_in2
	case (current_state)
		s_cal_1: begin
			mul_wh_in2 = weight_W[cal_count_3][cal_count];
		end		
		default : mul_wh_in2 = 'd0;
	endcase
end
// Mult_UX, Mult_WH
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	Mult_UX(.a(mul_ux_in1), .b(mul_ux_in2), .rnd(3'b000), .z(mul_ux_out));

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	Mult_WH(.a(mul_wh_in1), .b(mul_wh_in2), .rnd(3'b000), .z(mul_wh_out));
// Pipeline Reg 1
always @(posedge clk or negedge rst_n) begin : proc_p1Reg
	if(~rst_n) begin
		p1Reg_xu <= 'd0;
		p1Reg_wh <= 'd0;
		p1Reg_flag <= 'd0;
	end 
	else begin
		p1Reg_xu <= mul_ux_out;
		p1Reg_wh <= mul_wh_out;
		if (count == 'd10 || count == 'd20)
			p1Reg_flag[0] <= 'd1; //p1Reg_flag[1] -> stall
		else
			p1Reg_flag[0] <= 'd0;

		if (cal_count == 2'd2)
			p1Reg_flag[1] <= 'd1; //p1Reg_flag[1] -> acc clear
		else
			p1Reg_flag[1] <= 'd0;

		if (cal_count == 2'd2 && cal_count_3 == 2'd2)
			p1Reg_flag[2] <= 'd1; //p1Reg_flag[2] -> data_H updata
		else
			p1Reg_flag[2] <= 'd0;

		p1Reg_flag[4:3] <= cal_count_3;
	end
end

// STAGE 2
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
		Add_uxwh(.a(p1Reg_xu), .b(p1Reg_wh), .rnd(3'b000), .z(add_uxwh_out));
// Pipeline Reg 2
always @(posedge clk or negedge rst_n) begin : proc_p2Reg
	if(~rst_n) begin
		p2Reg <= 'd0;
		p2Reg_flag <= 'd0;
	end 
	else begin
		p2Reg <= add_uxwh_out;
		p2Reg_flag <= p1Reg_flag;
	end
end

// STAGE 3
//acc_uxwh
always @(posedge clk or negedge rst_n) begin : proc_acc_uxwh
	if(~rst_n)
		acc_uxwh <= 'd0;
	else begin
		case (current_state)
			s_cal_1: begin
				if (~p2Reg_flag[0]) begin
					if (p2Reg_flag[1])
						acc_uxwh <= 'd0;
					else
						acc_uxwh <= add_acc_uxwh_out;
				end
			end
			s_cal_2: begin
				if (~p2Reg_flag[0]) begin
					if (p2Reg_flag[1])
						acc_uxwh <= 'd0;
					else
						acc_uxwh <= add_acc_uxwh_out;
				end
			end
			
			default : acc_uxwh <= 'd0;
		endcase
	end
end
// Add_acc_uxwh
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
		Add_acc_uxwh(.a(p2Reg), .b(acc_uxwh), .rnd(3'b000), .z(add_acc_uxwh_out));
// Pipeline Reg 3
always @(posedge clk or negedge rst_n) begin : proc_p3Reg
	if(~rst_n) begin
		p3Reg <= 'd0;
		p3Reg_flag <= 'd0;
	end 
	else begin
		p3Reg <= add_acc_uxwh_out;
		p3Reg_flag <= p2Reg_flag;
	end
end

// STAGE 4
myReLU Fx(.in(p3Reg), .out(relu_out));
// Pipeline Reg 4 (data_H[0])
always @(posedge clk or negedge rst_n) begin : data_H_1
	if(~rst_n) begin
		data_H[1][0] <= 'd0;
		data_H[1][1] <= 'd0;
		data_H[1][2] <= 'd0;
	end 
	else begin
		if (~p3Reg_flag[0]) begin	
			if (p3Reg_flag[1]) begin	
				case (p3Reg_flag[4:3])
					2'd0: data_H[1][0] <= relu_out;
					2'd1: data_H[1][1] <= relu_out;
					2'd2: data_H[1][2] <= relu_out;
				endcase
				//p4Reg_flag[1] <= 1'b1; 
				//p4Reg_flag[3:2] <= p3Reg_flag[4:3];
			end
		end
	end
end
always @(posedge clk or negedge rst_n) begin : proc_p4Reg
	if(~rst_n) begin
		p4Reg_flag <= 'd0;
	end 
	else begin		
		case (current_state)
			s_idle: p4Reg_flag <= 'd0;
			default : begin
				p4Reg_flag[0] <= p3Reg_flag[0]; //stall
				if ((~p3Reg_flag[0]) && p3Reg_flag[1]) begin
					p4Reg_flag[1] <= 1'b1; 
					p4Reg_flag[3:2] <= p3Reg_flag[4:3];
				end
			end
		endcase	
	end
end

// Stage 5
DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
	Mult_VH(.a(mul_vh_in1), .b(mul_vh_in2), .rnd(3'b000), .z(mul_vh_out));
// count_v
always @(posedge clk or negedge rst_n) begin : proc_count_v
	if(~rst_n)
		count_v <= 2'd0;
	else begin
		case (current_state)
			s_idle: count_v <= 2'd0;
			default : begin
				if (p4Reg_flag[0])
					count_v <= count_v;
				else if (count_v == 2)
					count_v <= 2'd0;
				else if (p4Reg_flag[1])
					count_v <= count_v + 2'b1;
			end
		endcase	
	end
end
// mul_vh_in1
always @(*) begin : proc_mul_vh_in1
	case (current_state)
		s_cal_1: begin
			if (p4Reg_flag[1]) begin
				mul_vh_in1 = data_H[1][p4Reg_flag[3:2]];
			end	
			else begin
				mul_vh_in1 = 'd0;
			end		
		end
		s_cal_2: begin
			if (p4Reg_flag[1]) begin
				mul_vh_in1 = data_H[1][p4Reg_flag[3:2]];
			end	
			else begin
				mul_vh_in1 = 'd0;
			end		
		end

		default : mul_vh_in1 = 'd0;
	endcase
end
// mul_vh_in1
always @(*) begin : proc_mul_vh_in2
	case (current_state)
		s_cal_1: begin
			if (p4Reg_flag[1]) begin
				mul_vh_in2 = weight_V[count_v][p4Reg_flag[3:2]];
			end	
			else begin
				mul_vh_in2 = 'd0;
			end		
		end
		s_cal_2: begin
			if (p4Reg_flag[1]) begin
				mul_vh_in2 = weight_V[count_v][p4Reg_flag[3:2]];
			end	
			else begin
				mul_vh_in2 = 'd0;
			end		
		end

		default : mul_vh_in2 = 'd0;
	endcase
end
// Pipeline Reg 5
always @(posedge clk or negedge rst_n) begin : proc_p5Reg
	if(~rst_n) begin
		p5Reg <= 'd0;
		p5Reg_flag <= 'd0;
	end 
	else begin
		p5Reg <= mul_vh_out;
		p5Reg_flag[2:1] <= count_v;
		p5Reg_flag[0] <= p4Reg_flag[0]; //stall
	end
end

// Stage 6
DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance)
		Add_acc_vh(.a(p5Reg), .b(add_acc_vh_in), .rnd(3'b000), .z(add_acc_vh_out));
// add_acc_vh_in
always @(*) begin : proc_add_acc_vh_in
	case (p5Reg_flag[2:1])
		2'd0: add_acc_vh_in = acc_vy[0];
		2'd1: add_acc_vh_in = acc_vy[1];
		default: add_acc_vh_in = acc_vy[2];//2'd2
	endcase
end
// acc_vy
always @(posedge clk or negedge rst_n) begin : proc_acc_vy
	if(~rst_n) begin
		acc_vy[0] <= 'd0;
		acc_vy[1] <= 'd0;
		acc_vy[2] <= 'd0;
	end 
	else begin
		if (count_v_3 == 2'd2 && ~p5Reg_flag[0]) begin
			acc_vy[p5Reg_flag[2:1]] <= 'd0;
			acc_vy[p5Reg_flag[2:1]] <= 'd0;
			acc_vy[p5Reg_flag[2:1]] <= 'd0;
		end
		else if (~p5Reg_flag[0]) begin
			case (p5Reg_flag[2:1])
				2'd0: acc_vy[0] <= add_acc_vh_out;
				2'd1: acc_vy[1] <= add_acc_vh_out;
				2'd2: acc_vy[2] <= add_acc_vh_out;
			endcase
		end
	end
end
// count_v_3
always @(posedge clk or negedge rst_n) begin : proc_count_v_3
	if(~rst_n)
		count_v_3 <= 2'd0;
	else begin
			case (current_state)
				s_idle: count_v_3 <= 2'd0;
				default : begin
					if (~p5Reg_flag[0]) begin
						if (count_v_3 == 2'd2 && p5Reg_flag[2:1] == 2'd2)
							count_v_3 <= 2'd0;
						else if (p5Reg_flag[2:1] == 2'd2)
							count_v_3 <= count_v_3 + 2'b1;
					end
				end
			endcase		
	end
end
// Pipeline Reg 6
always @(posedge clk or negedge rst_n) begin : proc_p6Reg
	if(~rst_n) begin
		p6Reg <= 'd0;
		p6Reg_flag <= 'd0;
	end 
	else begin
		if (current_state == s_cal_1 || current_state == s_cal_2) begin
			if (~p5Reg_flag[0] && count_v_3 == 2'd2) begin
				p6Reg <= add_acc_vh_out;
			end
			
			if (count_v_3 == 2'd2 && ~p5Reg_flag[0])
				p6Reg_flag <= 1'b1;
			else
				p6Reg_flag <= 1'b0;
		end
	end
end

// Stage 7
mySigmoid Sig_vh(.in(p6Reg), .out(sigmoid_out));
// out_Y
always @(posedge clk or negedge rst_n) begin : proc_out_Y
	if(~rst_n) begin
		out_Y[0] <= 'd0;
		out_Y[1] <= 'd0;
		out_Y[2] <= 'd0;
		out_Y[3] <= 'd0;
		out_Y[4] <= 'd0;
		out_Y[5] <= 'd0;
	end 
	else begin
		if (p6Reg_flag) begin
			out_Y[0] <= out_Y[1];
			out_Y[1] <= out_Y[2];
			out_Y[2] <= out_Y[3];
			out_Y[3] <= out_Y[4];
			out_Y[4] <= out_Y[5];
			out_Y[5] <= sigmoid_out;
		end
	end
end



/*//old

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
*/
//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
// count_out
always @(posedge clk or negedge rst_n) begin : proc_count_out
	if(~rst_n)
		count_out <= 'd0;
	else begin
		case (current_state)
			s_idle: count_out <= 'd0;
			s_cal_1: begin
				if (count == 'd28)
					count_out <= count_out + 1;
			end
			default : begin
				if (out_valid) begin
					count_out <= count_out + 1;
				end
			end
		endcase	
	end
end
// Out Valid
always @(posedge clk or negedge rst_n) begin : proc_out_valid
	if(~rst_n)
		out_valid <= 1'b0;
	else begin
		case (current_state)
			s_idle: out_valid <= 1'b0;
			s_cal_1: begin
				if (count == 'd28)
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
			s_cal_1: begin
				if (count == 'd28)
					out <= out_Y[count_out];
			end

			s_cal_2: begin
				if (count_out > 5)
					out <= sigmoid_out;
				else
					out <= out_Y[count_out];
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
