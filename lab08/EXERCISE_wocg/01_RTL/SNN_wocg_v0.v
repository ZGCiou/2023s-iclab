module SNN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	img,
	ker,
	weight,
	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//        PARAMETER & INTEGER DECLARATION       //
//==============================================//
localparam S_IDLE = 'd0;
localparam S_IN_WEIGHT = 'd1;
localparam S_IN_KER = 'd2;
localparam S_IN_IMG_A = 'd3;
localparam S_IN_IMG_B = 'd4;
localparam S_CONV_QUANT = 'd5;
localparam S_MP_FC_QUANT = 'd6;
localparam S_L1DIS_ACT = 'd7;
localparam S_OUT = 'd8;

integer i, j;
//==============================================//
//            REG & WIRE DECLARATION            //
//==============================================//
// FSM
reg [3:0] cur_state, next_state;
reg [5:0] cnt;
reg sel_data;
// IN DATA
reg [7:0] weightReg[0:1][0:1];
reg [7:0] kerReg[0:8];
reg [7:0] imgReg_A[0:5][0:5];
reg [7:0] imgReg_B[0:5][0:5];
reg [2:0] cnt_col, cnt_row, cnt_col_d1, cnt_row_d1;
// PROCESS
// Convolution
reg [7:0] conv_indata[0:8];
wire [15:0] conv_s1[0:8];
wire [16:0] conv_s2[0:3];
wire [17:0] conv_s3_1;
wire [18:0] conv_s3_2;
wire [19:0] conv_result;
reg [19:0] conv_resultReg;
reg [7:0] conv_quant_result[0:3][0:3];
// Quantization
//reg [19:0] quant_indata;
reg [7:0] quant_result;
// Max Pooling
reg [7:0] mp_matrix[0:1][0:1];
// Fully Connect
reg [15:0] fc_s1[0:1];
reg [16:0] fc_result, fc_resultReg;
reg [7:0] mp_fc_quant_result_A[0:3], mp_fc_quant_result_B[0:3];
// L1 Distance
reg [7:0] dis[0:3];
wire [8:0] dis_s2[0:1];
wire [9:0] dis_result;
// Activation Func
reg [9:0] act_resultReg;

//==============================================//
//                     FSM                      //
//==============================================//
// Current State
always @(posedge clk or negedge rst_n) begin : proc_cur_state
	if(~rst_n)
		cur_state <= S_IDLE;
	else begin
		cur_state <= next_state;
	end
end
// Next State
always @(*) begin : proc_next_state
	case (cur_state)
		S_IDLE: begin
			if (in_valid)
				next_state = S_IN_WEIGHT;
			else
				next_state = S_IDLE;
		end

		S_IN_WEIGHT: begin
			if (cnt=='d3)
				next_state = S_IN_KER;
			else
				next_state = S_IN_WEIGHT;
		end

		S_IN_KER: begin
			if (cnt=='d8)
				next_state = S_IN_IMG_A;
			else
				next_state = S_IN_KER;
		end

		S_IN_IMG_A: begin
			if (cnt=='d35)
				next_state = S_IN_IMG_B;
			else
				next_state = S_IN_IMG_A;
		end

		S_IN_IMG_B: begin
			if (cnt=='d35)
				next_state = S_CONV_QUANT;
			else
				next_state = S_IN_IMG_B;
		end
		
		S_CONV_QUANT: begin
			if (cnt_col_d1=='d3 && cnt_row_d1=='d3)
				next_state = S_MP_FC_QUANT;
			else
				next_state = S_CONV_QUANT;
		end
		
		S_MP_FC_QUANT: begin
			if (cnt_col_d1=='d1 && cnt_row_d1=='d1) begin
				if (~sel_data)
					next_state = S_CONV_QUANT;
				else
					next_state = S_L1DIS_ACT;
			end
			else
				next_state = S_MP_FC_QUANT;
		end

		S_L1DIS_ACT: begin
			next_state = S_OUT;
		end

		S_OUT: begin
			next_state = S_IDLE;
		end

		default : next_state = cur_state;
	endcase
end
// Counter
always @(posedge clk or negedge rst_n) begin : proc_cnt
	if(~rst_n)
		cnt <= 'd0;
	else begin
		case (cur_state)
			S_IDLE: begin
				if (in_valid)
					cnt <= cnt + 'd1;
			end

			S_IN_WEIGHT: begin
				cnt <= cnt + 'd1;
			end

			S_IN_KER: begin
				cnt <= cnt + 'd1;
			end

			S_IN_IMG_A: begin
				if (next_state==S_IN_IMG_B)
					cnt <= 'd0;
				else
					cnt <= cnt + 'd1;
			end

			S_IN_IMG_B: begin
				if (next_state==S_CONV_QUANT)
					cnt <= 'd0;
				else
					cnt <= cnt + 'd1;
			end

			default : cnt <= 'd0;
		endcase
	end
end
// Select A or B
always @(posedge clk or negedge rst_n) begin : proc_sel_data
	if(~rst_n)
		sel_data <= 1'b0;
	else begin
		if (cur_state==S_MP_FC_QUANT) begin
			if (next_state!=S_MP_FC_QUANT && ~sel_data)
				sel_data <= 1'b1;
		end
		else if (cur_state==S_IDLE) begin
			sel_data <= 1'b0;
		end
	end
end

//==============================================//
//                    INPUT                     //
//==============================================//
// Weight
always @(posedge clk or negedge rst_n) begin : proc_weightReg
	if(~rst_n) begin
		for (i=0; i<2; i=i+1) begin
			for (j=0; j<2; j=j+1) begin
				weightReg[i][j] <= 8'd0;
			end
		end
	end 
	else begin
		case (cur_state)
			S_IDLE: begin
				if (in_valid)
					weightReg[0][0] <= weight;
			end

			S_IN_WEIGHT: begin
				weightReg[cnt[1]][cnt[0]] <= weight;
			end
		endcase
	end
end
// Kernal
always @(posedge clk or negedge rst_n) begin : proc_kerReg
	if(~rst_n) begin
		for (i=0; i<9; i=i+1) begin
			kerReg[i] <= 8'd0;
		end
	end 
	else begin
		if (cur_state==S_IDLE && in_valid) begin
			kerReg[0] <= ker;
		end
		else if (cur_state==S_IN_WEIGHT || cur_state==S_IN_KER) begin
			kerReg[cnt[3:0]] <= ker;
		end
	end
end
// Image A
always @(posedge clk or negedge rst_n) begin : proc_imgReg_A
	if(~rst_n) begin
		for (i=0; i<6; i=i+1) begin
			for (j=0; j<6; j=j+1) begin
				imgReg_A[i][j] <= 8'd0;
			end
		end
	end 
	else begin
		if (cur_state==S_IDLE && in_valid) begin
			imgReg_A[0][0] <= img;
		end
		else if (in_valid && (cur_state==S_IDLE || cur_state==S_IN_WEIGHT || cur_state==S_IN_KER || cur_state==S_IN_IMG_A))
			imgReg_A[cnt_row][cnt_col] <= img;
	end
end
// Image B
always @(posedge clk or negedge rst_n) begin : proc_imgReg_B
	if(~rst_n) begin
		for (i=0; i<6; i=i+1) begin
			for (j=0; j<6; j=j+1) begin
				imgReg_B[i][j] <= 8'd0;
			end
		end
	end 
	else begin
		if (cur_state==S_IN_IMG_B) begin
			imgReg_B[cnt_row][cnt_col] <= img;
		end
	end
end
// Col, Row Counter
// cnt_col
always @(posedge clk or negedge rst_n) begin : proc_cnt_col
	if(~rst_n)
		cnt_col <= 'd0;
	else begin
		if (cur_state==S_CONV_QUANT) begin
			if (cnt_col=='d3 || next_state==S_MP_FC_QUANT)
				cnt_col <= 'd0;
			else
				cnt_col <= cnt_col + 'd1;
		end

		else if (cur_state==S_MP_FC_QUANT) begin
			if (cnt_col=='d1 || next_state==S_CONV_QUANT)
				cnt_col <= 'd0;
			else
				cnt_col <= cnt_col + 'd1;
		end

		else if (cur_state==S_IDLE && in_valid) begin
			cnt_col <= 'd1;
		end
		
		else if (cur_state==S_IN_WEIGHT || cur_state==S_IN_KER || cur_state==S_IN_IMG_A || cur_state==S_IN_IMG_B) begin
			if (cnt_col=='d5)
				cnt_col <= 'd0;
			else
				cnt_col <= cnt_col + 'd1;
		end
		
		else
			cnt_col <= 'd0;
	end
end
// cnt_row
always @(posedge clk or negedge rst_n) begin : proc_cnt_row
	if(~rst_n)
		cnt_row <= 'd0;
	else begin
		if (cur_state==S_CONV_QUANT) begin
			if (cnt_col=='d3) begin
				if (cnt_row=='d3)
					cnt_row  <= 'd0;
				else
					cnt_row <= cnt_row + 'd1;
			end
		end

		else if (cur_state==S_MP_FC_QUANT) begin
			if (cnt_col=='d1) begin
				if (cnt_row=='d1)
					cnt_row  <= 'd0;
				else
					cnt_row <= cnt_row + 'd1;
			end
		end

		else if (cur_state==S_IN_WEIGHT || cur_state==S_IN_KER || cur_state==S_IN_IMG_A || cur_state==S_IN_IMG_B) begin
			if (cnt_col=='d5) begin
				if (cnt_row=='d5)
					cnt_row  <= 'd0;
				else
					cnt_row <= cnt_row + 'd1;
			end
		end
	end
end
//==============================================//
//                    DESIGN                    //
//==============================================//
// Stage 1 -> Convolution and Quantization
always @(*) begin : proc_conv_indata
	case (cur_state)
		S_CONV_QUANT: begin
			if (~sel_data) begin
				conv_indata[0] = imgReg_A[cnt_row][cnt_col];
				conv_indata[1] = imgReg_A[cnt_row][cnt_col + 'd1];
				conv_indata[2] = imgReg_A[cnt_row][cnt_col + 'd2];
				conv_indata[3] = imgReg_A[cnt_row + 'd1][cnt_col];
				conv_indata[4] = imgReg_A[cnt_row + 'd1][cnt_col + 'd1];
				conv_indata[5] = imgReg_A[cnt_row + 'd1][cnt_col + 'd2];
				conv_indata[6] = imgReg_A[cnt_row + 'd2][cnt_col];
				conv_indata[7] = imgReg_A[cnt_row + 'd2][cnt_col + 'd1];
				conv_indata[8] = imgReg_A[cnt_row + 'd2][cnt_col + 'd2];
			end
			else begin
				conv_indata[0] = imgReg_B[cnt_row][cnt_col];
				conv_indata[1] = imgReg_B[cnt_row][cnt_col + 'd1];
				conv_indata[2] = imgReg_B[cnt_row][cnt_col + 'd2];
				conv_indata[3] = imgReg_B[cnt_row + 'd1][cnt_col];
				conv_indata[4] = imgReg_B[cnt_row + 'd1][cnt_col + 'd1];
				conv_indata[5] = imgReg_B[cnt_row + 'd1][cnt_col + 'd2];
				conv_indata[6] = imgReg_B[cnt_row + 'd2][cnt_col];
				conv_indata[7] = imgReg_B[cnt_row + 'd2][cnt_col + 'd1];
				conv_indata[8] = imgReg_B[cnt_row + 'd2][cnt_col + 'd2];
			end
		end
		default : begin
			for (i=0; i<9; i=i+1) begin
				conv_indata[i] = 'd0;
			end
		end
	endcase
end
// Convolution process
//s1
assign conv_s1[0] = conv_indata[0] * kerReg[0]; 
assign conv_s1[1] = conv_indata[1] * kerReg[1]; 
assign conv_s1[2] = conv_indata[2] * kerReg[2]; 
assign conv_s1[3] = conv_indata[3] * kerReg[3]; 
assign conv_s1[4] = conv_indata[4] * kerReg[4]; 
assign conv_s1[5] = conv_indata[5] * kerReg[5]; 
assign conv_s1[6] = conv_indata[6] * kerReg[6]; 
assign conv_s1[7] = conv_indata[7] * kerReg[7]; 
assign conv_s1[8] = conv_indata[8] * kerReg[8];
//s2
assign conv_s2[0] = conv_s1[0] + conv_s1[1];
assign conv_s2[1] = conv_s1[2] + conv_s1[3];
assign conv_s2[2] = conv_s1[4] + conv_s1[5];
assign conv_s2[3] = conv_s1[6] + conv_s1[7];
//s3
assign conv_s3_1 = conv_s2[0] + conv_s2[1];
assign conv_s3_2 = conv_s2[2] + conv_s2[3] + conv_s1[8];
//result
assign conv_result = conv_s3_1 + conv_s3_2;

always @(posedge clk or negedge rst_n) begin : proc_conv_resultReg_pipeReg
	if(~rst_n) begin
		conv_resultReg <= 'd0;
		cnt_col_d1 <= 'd0;
		cnt_row_d1 <= 'd0;
	end 
	else begin
		conv_resultReg <= conv_result;
		cnt_col_d1 <= cnt_col;
		cnt_row_d1 <= cnt_row;
	end
end

// Stage1 result: Conv and Quant Result Register
always @(posedge clk or negedge rst_n) begin : proc_conv_quant_result
	if(~rst_n) begin
		for (i=0; i<4; i=i+1) begin
			for (j=0; j<4; j=j+1) begin
				conv_quant_result[i][j] <= 8'd0;
			end
		end
	end 
	else begin
		case (cur_state)
			S_CONV_QUANT: begin
				conv_quant_result[cnt_row][cnt_col] <= quant_result;
			end
		endcase
	end
end

// Quantiztaion
// quant_indata
always @(*) begin : proc_quant_result
	case (cur_state)
		S_CONV_QUANT: begin
			quant_result = conv_result / 'd2295;
		end

		S_MP_FC_QUANT: begin
			quant_result = fc_resultReg / 'd510;
		end

		default : quant_result = 'd0;
	endcase
end

//--------------------------------------------------------//

// Stage 2 -> Max-Pooling, Fully-Connect and Quantization
// Max pooling
generate
	genvar idx, jdx;
	for (idx=0; idx<2; idx=idx+1) begin : max_pooling_row
		for (jdx=0; jdx<2; jdx=jdx+1) begin : max_pooling_col
			reg [7:0] c1, c2;
			always @(*) begin : proc_mp_matrix
				if (cur_state==S_MP_FC_QUANT) begin
					c1 = (conv_quant_result[idx*2][jdx*2]>conv_quant_result[idx*2][jdx*2 + 1'd1]) ? conv_quant_result[idx*2][jdx*2] : conv_quant_result[idx*2][jdx*2 + 1'd1];
					c2 = (conv_quant_result[idx*2 + 1'd1][jdx*2]>conv_quant_result[idx*2 + 1'd1][jdx*2 + 1'd1]) ? conv_quant_result[idx*2 + 1'd1][jdx*2] : conv_quant_result[idx*2 + 1'd1][jdx*2 + 1'd1];
					mp_matrix[idx][jdx] = (c1>c2) ? c1 : c2;
				end
				else
					mp_matrix[idx][jdx] = 'd0;
			end
		end
	end
endgenerate
// Fully Connect
always @(*) begin : proc_fc_result
	if (cur_state==S_MP_FC_QUANT) begin
		fc_s1[0] = mp_matrix[cnt_row][0] * weightReg[0][cnt_col];
		fc_s1[1] = mp_matrix[cnt_row][1] * weightReg[1][cnt_col];
		fc_result = fc_s1[0] + fc_s1[1];
	end
	else begin
		fc_s1[0] = 'd0;
		fc_s1[1] = 'd0;
		fc_result = fc_s1[0] + fc_s1[1];
	end
end

always @(posedge clk or negedge rst_n) begin : proc_fc_resultReg_pipeReg
	if(~rst_n) begin
		fc_resultReg <= 'd0;
	end 
	else begin
		fc_resultReg <= fc_result;
	end
end

// Stage2 result: MP and FC and Quant Result Register
always @(posedge clk or negedge rst_n) begin : proc_mp_fc_quant_result
	if(~rst_n) begin
		mp_fc_quant_result_A[0] <= 'd0;
		mp_fc_quant_result_A[1] <= 'd0;
		mp_fc_quant_result_A[2] <= 'd0;
		mp_fc_quant_result_A[3] <= 'd0;
		mp_fc_quant_result_B[0] <= 'd0;
		mp_fc_quant_result_B[1] <= 'd0;
		mp_fc_quant_result_B[2] <= 'd0;
		mp_fc_quant_result_B[3] <= 'd0;
	end 
	else begin
		if (cur_state==S_MP_FC_QUANT) begin
			if (~sel_data)
				mp_fc_quant_result_A[{cnt_row_d1[0], cnt_col_d1[0]}] <= quant_result;
			else
				mp_fc_quant_result_B[{cnt_row_d1[0], cnt_col_d1[0]}] <= quant_result;
		end
	end
end

//--------------------------------------------------------//

// Stage 3 -> L1 Distance and Activation Function
// L1 Distance
generate
	genvar dis_idx;
	for (dis_idx=0; dis_idx<4; dis_idx=dis_idx+1) begin : l1_dis
		reg [8:0] dis_s1;
		always @(*) begin : proc_dis
			if (cur_state==S_L1DIS_ACT) begin
				dis_s1 = {1'b0, mp_fc_quant_result_A[dis_idx]} - {1'b0, mp_fc_quant_result_B[dis_idx]};
				dis[dis_idx] = (dis_s1[8]) ? (~dis_s1[7:0] + 1'd1) : dis_s1[7:0];
			end
			else begin
				dis_s1 = 'd0;
				dis[dis_idx] = 'd0;
			end
		end
	end
endgenerate
assign dis_s2[0] = dis[0] + dis[1];
assign dis_s2[1] = dis[2] + dis[3];
assign dis_result = dis_s2[0] + dis_s2[1];
// Stage3 result: Activation Function Register
always @(posedge clk or negedge rst_n) begin : proc_act_resultReg
	if(~rst_n)
		act_resultReg <= 'd0;
	else begin
		if (cur_state==S_L1DIS_ACT) begin
			if (dis_result<'d16)
				act_resultReg <= 'd0;
			else
				act_resultReg <= dis_result;
		end
	end
end

//==============================================//
//                    OUTPUT                    //
//==============================================//
// Out Valid
always @(*) begin : proc_out_valid
	case (cur_state)
		S_OUT: begin
			out_valid = 1'b1;
		end
		default : out_valid = 1'b0;
	endcase
end
//Out
always @(*) begin : proc_out
	case (cur_state)
		S_OUT: begin
			out_data = act_resultReg;
		end
		default : out_data = 'b0;
	endcase
end


endmodule