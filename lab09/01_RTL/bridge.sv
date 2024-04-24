//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   2023 ICLAB Spring Course
//   Lab09		 : Online Shopping Platform Simulation (OS)
//   Author    	 : Zheng-Gang Ciou (nycu311511022.ee11@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : bridge.sv
//   Module Name : bridge
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################ 

module bridge(
	input clk, 
	INF.bridge_inf inf
);
//---------------------------------------------------------------------
//   Port in INF.sv
//=====================================================================
//	// PATTERN
//	logic 	rst_n ; 
//	
//	// BRIDGE
//	logic [7:0]  C_addr;
//	logic [63:0] C_data_w;
//	logic [63:0] C_data_r;
//	logic C_in_valid;
//	logic C_out_valid;
//	logic C_r_wb;
//	
//	// DRAM
//	logic  AR_READY, R_VALID, AW_READY, W_READY, B_VALID, AR_VALID, R_READY, AW_VALID, W_VALID, B_READY;
//	logic [1:0]	 R_RESP, B_RESP;
//  logic [63:0] R_DATA, W_DATA;
//	logic [16:0] AW_ADDR, AR_ADDR;
//
//	modport bridge_inf(
//		input  
//		// Pattern
//			rst_n,
//		// Bridge
//			C_addr, C_data_w, C_in_valid, C_r_wb, 
//		// DRAM
//			AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,
//
//		output 
//		// Bridge
//			C_out_valid, C_data_r, 
//		// DRAM
//			AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY
//	);
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
localparam S_IDLE = 'd0;
localparam S_READ_WAIT_ADDR_READY = 'd1;
localparam S_READ_WAIT_DATA_VALID = 'd2;
localparam S_WRITE_WAIT_ADDR_READY = 'd3;
localparam S_WRITE_WAIT_DATA_READY = 'd4;
localparam S_WRITE_WAIT_RESP_VALID = 'd5;
localparam S_OUTPUT = 'd6;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [2:0] cur_state, next_state;
reg [7:0] addrReg;
reg [63:0] dataReg;
reg readReg;

//---------------------------------------------------------------------
//   Finite-State Mechine                                          
//---------------------------------------------------------------------
// Current State
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_cur_state
	if(~inf.rst_n)
		cur_state <= S_IDLE;
	else begin
		cur_state <= next_state;
	end
end
// Next State
always_comb begin : proc_next_state
	case (cur_state)
		S_IDLE: begin
			if (inf.C_in_valid) begin
				if (inf.C_r_wb)	//1=Read
					next_state = S_READ_WAIT_ADDR_READY;
				else			//0=Write
					next_state = S_WRITE_WAIT_ADDR_READY;
			end
			else
				next_state = S_IDLE;
		end

		S_READ_WAIT_ADDR_READY: begin
			if (inf.AR_READY)
				next_state = S_READ_WAIT_DATA_VALID;
			else
				next_state = S_READ_WAIT_ADDR_READY;
		end

		S_READ_WAIT_DATA_VALID: begin
			if (inf.R_VALID)
				next_state = S_OUTPUT;
			else
				next_state = S_READ_WAIT_DATA_VALID;
		end

		S_WRITE_WAIT_ADDR_READY: begin
			if (inf.AW_READY)
				next_state = S_WRITE_WAIT_DATA_READY;
			else
				next_state = S_WRITE_WAIT_ADDR_READY;
		end

		S_WRITE_WAIT_DATA_READY: begin
			if (inf.W_READY)
				next_state = S_WRITE_WAIT_RESP_VALID;
			else
				next_state = S_WRITE_WAIT_DATA_READY;
		end

		S_WRITE_WAIT_RESP_VALID: begin
			if (inf.B_VALID)
				next_state = S_OUTPUT;
			else
				next_state = S_WRITE_WAIT_RESP_VALID;
		end

		S_OUTPUT: begin
			next_state = S_IDLE;
		end

		default : next_state = cur_state;
	endcase
end

//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
// Address
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_addrReg
	if(~inf.rst_n)
		addrReg <= 'd0;
	else begin
		if (inf.C_in_valid)
			addrReg <= inf.C_addr;
	end
end
// Data Write
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_dataReg
	if(~inf.rst_n)
		dataReg <= 'd0;
	else begin
		case (cur_state)
			S_IDLE: begin
				if (inf.C_in_valid && ~inf.C_r_wb)
					dataReg <= inf.C_data_w;
			end

			S_READ_WAIT_DATA_VALID: begin
				if (inf.R_VALID)
					dataReg <= inf.R_DATA;
			end
		endcase
	end
end
// read or Write
always_ff @(posedge clk or negedge inf.rst_n) begin : proc_readReg
	if(~inf.rst_n)
		readReg <= 1'b0;
	else begin
		if (inf.C_in_valid)
			readReg <= inf.C_r_wb;
	end
end
//---------------------------------------------------------------------
//   AXI4 Lite
//---------------------------------------------------------------------
//=========================== Read ====================================
// AXI read address channel
assign inf.AR_ADDR = (cur_state==S_READ_WAIT_ADDR_READY) ? {6'b100000, addrReg, 3'b0} : 'd0;
assign inf.AR_VALID = (cur_state==S_READ_WAIT_ADDR_READY);

// AXI read data channel
assign inf.R_READY = (cur_state==S_READ_WAIT_DATA_VALID);

//=========================== Write ===================================
// AXI write address channel
assign inf.AW_ADDR = (cur_state==S_WRITE_WAIT_ADDR_READY) ? {6'b100000, addrReg, 3'b0} : 'd0;
assign inf.AW_VALID = (cur_state==S_WRITE_WAIT_ADDR_READY);

// AXI write data channel
assign inf.W_VALID = (cur_state==S_WRITE_WAIT_DATA_READY);
assign inf.W_DATA = (cur_state==S_WRITE_WAIT_DATA_READY) ? dataReg : 'd0;

// AXI write Response channel
assign inf.B_READY = (cur_state==S_WRITE_WAIT_RESP_VALID);

//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always_comb begin
	case (cur_state)
		S_OUTPUT: begin
			inf.C_out_valid = 1'b1;
			inf.C_data_r = (readReg) ? dataReg : 'd0;
		end

		default : begin
			inf.C_out_valid = 1'b0;
			inf.C_data_r = 'b0;
		end
	endcase
end

endmodule