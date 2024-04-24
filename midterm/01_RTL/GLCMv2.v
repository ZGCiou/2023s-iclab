//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NCTU ED415
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 spring
//   Midterm Proejct            : GLCM 
//   Author                     : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : GLCM.v
//   Module Name : GLCM
//   Release version : V1.0 (Release Date: 2023-04)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module GLCM(
				clk,	
			  rst_n,	
	
			in_addr_M,
			in_addr_G,
			in_dir,
			in_dis,
			in_valid,
			out_valid,
	

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 
);
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32;
input			  clk,rst_n;



// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
	   therefore I declared output of AXI as wire in Poly_Ring
*/
   
// -----------------------------
// IO port
input [ADDR_WIDTH-1:0]      in_addr_M;
input [ADDR_WIDTH-1:0]      in_addr_G;
input [1:0]  	  		in_dir;
input [3:0]	    		in_dis;
input 			    	in_valid;
output reg 	              out_valid;
// -----------------------------


// axi write address channel 
output  wire [ID_WIDTH-1:0]        awid_m_inf;
output  wire [ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [2:0]            awsize_m_inf;
output  wire [1:0]           awburst_m_inf;
output  wire [3:0]             awlen_m_inf;
output  wire                 awvalid_m_inf;
input   wire                 awready_m_inf;
// axi write data channel 
output  wire [DATA_WIDTH-1:0]     wdata_m_inf;
output  wire                   wlast_m_inf;
output  wire                  wvalid_m_inf;
input   wire                  wready_m_inf;
// axi write response channel
input   wire [ID_WIDTH-1:0]         bid_m_inf;
input   wire [1:0]             bresp_m_inf;
input   wire              	   bvalid_m_inf;
output  wire                  bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]       arid_m_inf;
output  wire [ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [3:0]            arlen_m_inf;
output  wire [2:0]           arsize_m_inf;
output  wire [1:0]          arburst_m_inf;
output  wire                arvalid_m_inf;
input   wire               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [ID_WIDTH-1:0]         rid_m_inf;
input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [1:0]             rresp_m_inf;
input   wire                   rlast_m_inf;
input   wire                  rvalid_m_inf;
output  wire                  rready_m_inf;
// -----------------------------

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
localparam S_IDLE = 'd0;
localparam S_READ_ADDR_WAIT = 'd1;
localparam S_READ_DATA = 'd2;
localparam S_CAL = 'd3;
localparam S_WRITE = 'd4;
localparam S_WRITE_ADDR_WAIT = 'd5;
localparam S_OUT = 'd6;

integer i,j;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
// FSM
reg [4:0] currentState, nextState;
reg [6:0] count;
// In Data
reg [31:0] addrReg_G, addrReg_M;
wire [31:0] addr_M_b0, addr_M_b1, addr_M_b2, addr_M_b3, addr_M_b4;
wire [5:0] blockAddr_M_b0, blockAddr_M_b1, blockAddr_M_b2, blockAddr_M_b3, blockAddr_M_b4;
wire [5:0] blockOffset_M_b0;
//wire []
reg [1:0] dirReg;
reg [3:0] disReg;
// Cache
reg [63:0] block_valid;
reg [4:0] blockHit, blockHit_in;
wire cacheMiss, cacheMiss_in;
// SRAM
reg sramWrite, sramWrite_d1, sramWrite_d2, sramWrite_d3, sramWrite_d4, sramWrite_d5;
reg [9:0] sramAddr;
reg [19:0] sramWriteData;
wire [4:0] sramDataTranslate[0:3];
wire [19:0] sramReadData;
// SRAM GLCM
reg sramWrite_GLCM;
reg [7:0] sramAddr_GLCM;
reg [31:0] sramWriteData_GLCM;
//wire [4:0] sramDataTranslate_GLCM[0:3];
wire [31:0] sramReadData_GLCM;
// DRAM
//------Read------
reg readAddr_valid;
reg [31:0] readAddr, readAddrReg, nextAddr, curAddrReg;
wire [4:0] dramDataTranslate[0:3];
//------Write-----
reg writeReadyReg;
reg writeAddr_valid, writeData_valid;
wire writeData_last;
reg [31:0] writeAddr, writeAddr_next;
// Calculate
wire [3:0] offset_Row, offset_Col;
//new
reg [3:0] curRow, curCol;
wire [3:0] curRow_offset, curCol_offset;
wire [11:0] sramFirstAddr_M;
wire [11:0] calAddr, calAddr_offset;
reg [1:0] calOffsetReg, calOffsetReg_offset, calOffsetReg2_offset;
reg [4:0] col_GLCM, row_GLCM;
reg [9:0] glcmAddr;
reg cal_last;
reg cal_finish;
reg cal_last_d1, cal_last_d2, cal_last_d3, cal_last_d4, cal_last_d5, cal_last_d6;

//old
reg [4:0] xBuffer[0:7], yBuffer[0:7];
reg [4:0] xReg[0:3], yRewg[0:3];
//reg [9:0] calAddr, calAddr_offset;
reg [1:0] first_sramOffset, offset_sramOffset;
reg [11:0] firstElement_sramAddr;
reg nextRow;
wire buffer_start, buffer_valid;
reg [4:0] accGLCM_x[0:3], accGLCM_y[0:3];


// GLCM
wire [1:0] glcmOffset;
reg [0:31] glcm_dirty[0:31];
reg dirty_d1;
wire dirty, dirty_write[0:3];
reg dirtyReg_write[0:3];
reg [7:0] acc_GLCM;
wire [9:0] glcmAddr_write;
reg [31:0] glcmData_writeback;
wire [7:0] glcmData_writeback_translate[0:3];
wire [4:0] glcm_coor[0:1];
// Write back
reg burstCount_row;
//---------------------------------------------------------------------
//   Finite-State Mechine                                          
//---------------------------------------------------------------------
// Current State
always @(posedge clk or negedge rst_n) begin : proc_currentState
  if(~rst_n)
    currentState <= S_IDLE;
  else begin
    currentState <= nextState;
  end
end
// Next State
always @(*) begin : proc_nextState
  case (currentState)
    S_IDLE: begin
      if (in_valid) begin
        if (cacheMiss_in)
          nextState = S_READ_ADDR_WAIT;
        else
          nextState = S_CAL;
      end
      else
        nextState = S_IDLE;
    end

    S_READ_ADDR_WAIT: begin
      if (arready_m_inf)
        nextState = S_READ_DATA;
      else
        nextState = S_READ_ADDR_WAIT;
    end

    S_READ_DATA: begin
      if (rlast_m_inf) begin
        if (cacheMiss)
          nextState = S_READ_ADDR_WAIT;
        else
          nextState = S_CAL;
      end
      else
        nextState = S_READ_DATA;
    end

    S_CAL: begin
      if (cal_last_d6)
        nextState = S_WRITE;
      else
        nextState = S_CAL;
    end
    
    S_WRITE: begin
      if (bvalid_m_inf) begin
        if (row_GLCM=='d31)
          nextState = S_OUT;
        else
          nextState = S_WRITE_ADDR_WAIT;
      end
      else
        nextState = S_WRITE;
    end
    
    S_WRITE_ADDR_WAIT: begin
      if (awready_m_inf)
        nextState = S_WRITE;
      else
        nextState = S_WRITE_ADDR_WAIT;
    end

    S_OUT: begin
      nextState = S_IDLE;
    end

    default : nextState = currentState;
  endcase
end

// Counter
always @(posedge clk or negedge rst_n) begin : proc_count
  if(~rst_n)
    count <= 'd0;
  else begin
    case (currentState)
      S_READ_ADDR_WAIT: begin
        count <= 'd1;
      end

      S_CAL: begin
        if (nextState==S_CAL) begin
          if (count<'d4)
            count <= count + 'd1;
          else
            count[0] <= ~count[0];
        end
        else
          count <= 'd0;
      end

      S_WRITE: begin
        if (nextState==S_WRITE)
          count <= count + 'd1;
        else
          count <= 'd0;
      end

      default : count <= 'd0;
    endcase
  end
end

//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin : proc_inData
  if(~rst_n) begin
    addrReg_G <= 32'd0;
    addrReg_M <= 23'd0;
    dirReg <= 2'd0;
    disReg <= 4'd0;
  end 
  else begin
    case (currentState)
      S_IDLE: begin
        if (in_valid) begin
          addrReg_G <= in_addr_G;
          addrReg_M <= in_addr_M;
          dirReg <= in_dir;
          disReg <= in_dis;
        end
      end
    endcase
  end
end

assign blockOffset_M_b0 = addrReg_M[5:0];

assign blockAddr_M_b0 = addrReg_M[11:6];
assign blockAddr_M_b1 = addrReg_M[11:6] + 'd1;
assign blockAddr_M_b2 = addrReg_M[11:6] + 'd2;
assign blockAddr_M_b3 = addrReg_M[11:6] + 'd3;
assign blockAddr_M_b4 = addrReg_M[11:6] + 'd4;

assign addr_M_b0 = {addrReg_M[31:12], blockAddr_M_b0, 6'b0};
assign addr_M_b1 = {addrReg_M[31:12], blockAddr_M_b1, 6'b0};
assign addr_M_b2 = {addrReg_M[31:12], blockAddr_M_b2, 6'b0};
assign addr_M_b3 = {addrReg_M[31:12], blockAddr_M_b3, 6'b0};
assign addr_M_b4 = {addrReg_M[31:12], blockAddr_M_b4, 6'b0};

//---------------------------------------------------------------------
//   Calculate
//---------------------------------------------------------------------
// block_valid
always @(posedge clk or negedge rst_n) begin : proc_block_valid
  if(~rst_n)
    block_valid <= 'd0;
  else begin
    case (currentState)
      S_READ_ADDR_WAIT: begin
        if (arready_m_inf)
          block_valid[nextAddr[11:6]] <= 1'b1;
      end
    endcase
  end
end
// blockHit
always @(*) begin : proc_blockHit
	blockHit[0] = block_valid[blockAddr_M_b0];
	blockHit[1] = block_valid[blockAddr_M_b1];
	blockHit[2] = block_valid[blockAddr_M_b2];
	blockHit[3] = block_valid[blockAddr_M_b3];
	blockHit[4] = (~|blockOffset_M_b0) ? 1'b1 : block_valid[blockAddr_M_b4];
end
assign cacheMiss = ~&blockHit;
// cacheMiss
always @(*) begin : proc_blockHit_in
	if (in_valid) begin
		blockHit_in[0] = block_valid[in_addr_M[11:6]];
		blockHit_in[1] = block_valid[in_addr_M[11:6] + 'd1];
		blockHit_in[2] = block_valid[in_addr_M[11:6] + 'd2];
		blockHit_in[3] = block_valid[in_addr_M[11:6] + 'd3];
		blockHit_in[4] = (~|in_addr_M[5:0]) ? 1'b1 : block_valid[in_addr_M[11:6] + 'd4];
	end
	else begin
		blockHit_in = 'd0;
	end
end
assign cacheMiss_in = ~&blockHit_in;

// GLCM Offset
assign offset_Col = (dirReg[1]) ? disReg : 4'd0;
assign offset_Row = (dirReg[0]) ? disReg : 4'd0;

// Current Column, Row
always @(posedge clk or negedge rst_n) begin : proc_curCol
  if(~rst_n)
    curCol <= 0;
  else begin
    case (currentState)
      S_IDLE: begin
        curCol <= 'd0;
      end

      S_CAL: begin
        if (~cal_finish) begin
          if (~count[0]) begin
            if (curCol_offset=='d15)
              curCol <= 'd0;
            else
              curCol <= curCol + 1'd1;
          end
        end
      end

      default: curCol <= 0;
    endcase
  end
end
always @(posedge clk or negedge rst_n) begin : proc_curRow
  if(~rst_n)
    curRow <= 0;
  else begin
    case (currentState)
      S_IDLE: begin
        curRow <= 'd0;
      end

      S_CAL: begin
        if (~cal_finish) begin
          if (~count[0]) begin
            if (curCol_offset=='d15)
              if (curRow_offset=='d15)
                curRow <= curRow;
              else
                curRow <= curRow + 1'd1;
          end
        end
      end

      default: curRow <= 'd0;
    endcase
  end
end
assign curCol_offset = curCol + offset_Col; 
assign  curRow_offset = curRow + offset_Row;
// Input Matrix Address
assign sramFirstAddr_M = addrReg_M[11:0];
assign calAddr = sramFirstAddr_M + curCol + {curRow, 4'b0000}; // 
assign calAddr_offset = sramFirstAddr_M + curCol_offset + {curRow_offset, 4'b0000}; //
always @(posedge clk or negedge rst_n) begin : proc_calOffset
  if(~rst_n) begin
    calOffsetReg <= 'd0;
    calOffsetReg_offset <= 'd0;
    calOffsetReg2_offset <= 'd0;
  end 
  else begin
    case (currentState)
      S_CAL: begin
        calOffsetReg <= calAddr[1:0];
        calOffsetReg_offset <= calAddr_offset[1:0];
        calOffsetReg2_offset <= calOffsetReg_offset;
      end
      default : begin
        calOffsetReg <= 'd0;
        calOffsetReg_offset <= 'd0;
        calOffsetReg2_offset <= 'd0;
      end
    endcase
  end
end
// GLCM cooridation
always @(posedge clk or negedge rst_n) begin : proc_col_GLCM
  if(~rst_n)
    col_GLCM <= 'd0;
  else begin
    case (currentState)
      S_CAL: begin
        if (~cal_last_d6) begin
          if(~count[0]) begin
            case (calOffsetReg2_offset)
              'd0: col_GLCM <= sramReadData[4:0];
              'd1: col_GLCM <= sramReadData[9:5];
              'd2: col_GLCM <= sramReadData[14:10];
              'd3: col_GLCM <= sramReadData[19:15];
            endcase
          end
        end
        else
          col_GLCM <= 'd0;
      end

      S_WRITE: begin
        if (count>'d1) begin
          if (col_GLCM=='d28) begin
            if (burstCount_row)
              col_GLCM <= col_GLCM;
            else
              col_GLCM <= 'd0;
          end
          else
            col_GLCM <= col_GLCM + 'd4;
        end
      end

      S_WRITE_ADDR_WAIT: begin
        if (nextState==S_WRITE)
          col_GLCM <= 'd0; 
        else
          col_GLCM <= col_GLCM;
      end

      default : col_GLCM <= 'd0;
    endcase
  end
end
always @(posedge clk or negedge rst_n) begin : proc_row_GLCM
  if(~rst_n)
    row_GLCM <= 'd0;
  else begin
    case (currentState)
      S_CAL: begin
        if (~cal_last_d6) begin
          if(count[0]) begin
            case (calOffsetReg)
              'd0: row_GLCM <= sramReadData[4:0];
              'd1: row_GLCM <= sramReadData[9:5];
              'd2: row_GLCM <= sramReadData[14:10];
              'd3: row_GLCM <= sramReadData[19:15];
            endcase
          end
        end
        else
          row_GLCM <= 'd0;
      end

      S_WRITE: begin
          if (col_GLCM=='d28) begin
            if (burstCount_row)
              row_GLCM <= row_GLCM;
            else
              row_GLCM <= row_GLCM + 1'd1;
          end
      end

      S_WRITE_ADDR_WAIT: begin
        if (nextState==S_WRITE)
          row_GLCM <= row_GLCM + 1'd1;
        else
          row_GLCM <= row_GLCM;
      end

      default : row_GLCM <= 'd0;
    endcase
  end
end
always @(*) begin : proc_cal_last
  case (currentState)
    S_CAL: begin
      if (curCol_offset=='d15 && curRow_offset=='d15)
        cal_last = 1'b1;
      else
        cal_last = 1'b0;
    end
    default : cal_last = 1'b0;
  endcase
end

//assign cal_last = (curCol_offset=='d15 && curRow_offset=='d15) ? 1'b1 : 1'b0;
always @(posedge clk or negedge rst_n) begin : proc_cal_finish
  if(~rst_n)
    cal_finish <= 1'b0;
  else begin
    case (currentState)
      S_CAL: begin
        if (cal_last)
          cal_finish <= 1'b1;
      end
      default : cal_finish <= 1'b0;
    endcase
  end
end
always @(posedge clk or negedge rst_n) begin : proc_cal_last_d
  if(~rst_n) begin
    cal_last_d1 <= 'd0;
    cal_last_d2 <= 'd0;
    cal_last_d3 <= 'd0;
    cal_last_d4 <= 'd0;
    cal_last_d5 <= 'd0;
    cal_last_d6 <= 'd0;
  end 
  else begin
    cal_last_d1 <= cal_last;
    cal_last_d2 <= cal_last_d1;
    cal_last_d3 <= cal_last_d2;
    cal_last_d4 <= cal_last_d3;
    cal_last_d5 <= cal_last_d4;
    cal_last_d6 <= cal_last_d5;
  end
end

// GLCM Address
always @(posedge clk or negedge rst_n) begin : proc_glcmAddr
  if(~rst_n)
    glcmAddr <= 'd0;
  else begin
    case (currentState)
      S_CAL: begin
        if (count[0])
          glcmAddr <= {row_GLCM, col_GLCM};
      end

      S_WRITE: begin
        glcmAddr <= {row_GLCM, col_GLCM};
      end

      default : glcmAddr <= 'd0;
    endcase
  end
end
assign glcmOffset = glcmAddr[1:0];
assign glcm_coor[0] = glcmAddr[9:5];
assign glcm_coor[1] = glcmAddr[4:0];

// GLCM
always @(posedge clk or negedge rst_n) begin : proc_glcm_dirty
  if(~rst_n) begin
    for (i=0; i<32; i=i+1) begin
      glcm_dirty[i] <= 'b0;
    end
  end 
  else begin
    case (currentState)
      S_IDLE: begin
        for (i=0; i<32; i=i+1) begin
          glcm_dirty[i] <= 'b0;
        end
      end

      S_CAL: begin
        if (count>'d3)
          glcm_dirty[glcmAddr[9:5]][glcmAddr[4:0]] <= 1'b1;
      end
    endcase
  end
end
assign dirty = glcm_dirty[glcmAddr[9:5]][glcmAddr[4:0]];
always @(posedge clk or negedge rst_n) begin : proc_dirty_d1
  if(~rst_n)
    dirty_d1 <= 1'd1;
  else begin
    dirty_d1 <= dirty;
  end
end

always @(*) begin : proc_acc_GLCM
  case (currentState)
    S_CAL: begin
      if (~sramWrite_GLCM) begin
        if (~dirty_d1)
          acc_GLCM = 'd1;
        else
          case (glcmOffset)
            'd0: acc_GLCM = sramReadData_GLCM[7:0] + 1'd1;
            'd1: acc_GLCM = sramReadData_GLCM[15:8] + 1'd1;
            'd2: acc_GLCM = sramReadData_GLCM[23:16] + 1'd1;
            default : acc_GLCM = sramReadData_GLCM[31:24] + 1'd1; //'d3
          endcase
      end
      else begin
        acc_GLCM = 'd0;
      end
    end
    default : acc_GLCM = 'd0;
  endcase
end
always @(*) begin : proc_sramWriteData_GLCM
  if (~sramWrite_GLCM)
    case (glcmOffset)
      'd0: sramWriteData_GLCM = {sramReadData_GLCM[31:8], acc_GLCM};
      'd1: sramWriteData_GLCM = {sramReadData_GLCM[31:16], acc_GLCM, sramReadData_GLCM[7:0]};
      'd2: sramWriteData_GLCM = {sramReadData_GLCM[31:24], acc_GLCM, sramReadData_GLCM[15:0]};
      default : sramWriteData_GLCM = {acc_GLCM, sramReadData_GLCM[23:0]}; //'d3
    endcase
  else
    sramWriteData_GLCM = 'd0;
end

//---------------------------------------------------------------------
//   SRAM
//---------------------------------------------------------------------
// Input Matrix
RA1SH CACHE_M_1024_20(.A(sramAddr), .D(sramWriteData), .CLK(clk), .CEN(1'b0), .WEN(sramWrite), .OEN(1'b0), .Q(sramReadData));
assign sramDataTranslate[0] = sramReadData[4:0];
assign sramDataTranslate[1] = sramReadData[9:5];
assign sramDataTranslate[2] = sramReadData[14:10];
assign sramDataTranslate[3] = sramReadData[19:15];
always @(posedge clk or negedge rst_n) begin : proc_sramAddr
  if(~rst_n)
    sramAddr <= 'd0;
  else begin
    case (currentState)
      S_IDLE: begin
        if (in_valid) begin
          if (~cacheMiss_in)
            sramAddr <= in_addr_M[11:2];
        end
      end

      S_READ_ADDR_WAIT: begin
        sramAddr <= araddr_m_inf[11:2];
      end

      S_READ_DATA: begin
        if (rvalid_m_inf) begin
          if (~rlast_m_inf)
            sramAddr <= sramAddr + 1'd1;
          else begin
            if (~cacheMiss)
              sramAddr <= calAddr[11:2];
          end
        end
      end

      S_CAL: begin
        //sramAddr <= sramAddr + 1'b1;
        if (count[0]=='d1)
          sramAddr <= calAddr[11:2];
        else if (count[0]=='d0)
          sramAddr <= calAddr_offset[11:2];
      end

      S_WRITE: begin
        sramAddr <= 'd0;
      end

    endcase
  end
end

always @(*) begin : proc_sramWriteData
  case (currentState)
    S_READ_DATA: begin
      if (rvalid_m_inf) begin
        sramWrite = 1'b0;
        sramWriteData = {rdata_m_inf[28:24], rdata_m_inf[20:16], rdata_m_inf[12:8], rdata_m_inf[4:0]};
      end
      else begin
        sramWrite = 1'b1;
        sramWriteData = 'd0;
      end
    end

    S_WRITE: begin
      sramWrite = 1'b1;
      sramWriteData = 'd0;
    end

    default : begin
      sramWrite = 1'b1;
      sramWriteData = 'd0;
    end
  endcase
end

// GLCM Matrix SRAM
RA1SH_256_32 GLCM(.A(sramAddr_GLCM), .D(sramWriteData_GLCM), .CLK(clk), .CEN(1'b0), .WEN(sramWrite_GLCM), .OEN(1'b0), .Q(sramReadData_GLCM));

always @(*) begin : proc_sramAddr_GLCM
  case (currentState)
    S_CAL: begin
      if (count>'d3)
        sramAddr_GLCM = glcmAddr[9:2];
      else
        sramAddr_GLCM = 'd0;
    end
    
    S_WRITE: begin
      sramAddr_GLCM = glcmAddr_write[9:2];
    end
    
    default : sramAddr_GLCM = 'd0;
  endcase
end

always @(*) begin : proc_sramWrite_GLCM
  case (currentState)
    S_CAL: begin
      if (count>'d3)
        sramWrite_GLCM = ~count[0];
      else
        sramWrite_GLCM = 1'b1;
    end
    default : sramWrite_GLCM = 1'b1;
  endcase
end

// Write Back
assign glcmAddr_write = {row_GLCM, col_GLCM};
assign dirty_write[0] = (glcm_dirty[row_GLCM][{col_GLCM[4:2], 2'd0}]);
assign dirty_write[1] = (glcm_dirty[row_GLCM][{col_GLCM[4:2], 2'd1}]);
assign dirty_write[2] = (glcm_dirty[row_GLCM][{col_GLCM[4:2], 2'd2}]);
assign dirty_write[3] = (glcm_dirty[row_GLCM][{col_GLCM[4:2], 2'd3}]);

always @(posedge clk or negedge rst_n) begin : proc_dirtyReg_write
  if(~rst_n) begin
    dirtyReg_write[0] <= 'd0;
    dirtyReg_write[1] <= 'd0;
    dirtyReg_write[2] <= 'd0;
    dirtyReg_write[3] <= 'd0;
  end 
  else begin
    case (currentState)
      S_WRITE: begin
        dirtyReg_write[0] <= dirty_write[0];
        dirtyReg_write[1] <= dirty_write[1];
        dirtyReg_write[2] <= dirty_write[2];
        dirtyReg_write[3] <= dirty_write[3];
      end
      default : begin
        dirtyReg_write[0] <= 'd0;
        dirtyReg_write[1] <= 'd0;
        dirtyReg_write[2] <= 'd0;
        dirtyReg_write[3] <= 'd0;
      end
    endcase
  end
end

always @(posedge clk or negedge rst_n) begin : proc_glcmData_writeback
  if(~rst_n)
    glcmData_writeback <= 'd0;
  else begin
    case (currentState)
      S_WRITE: begin
        glcmData_writeback[7:0] <= (dirtyReg_write[0]) ? sramReadData_GLCM[7:0] : 'd0;
        glcmData_writeback[15:8] <= (dirtyReg_write[1]) ? sramReadData_GLCM[15:8] : 'd0;
        glcmData_writeback[23:16] <= (dirtyReg_write[2]) ? sramReadData_GLCM[23:16] : 'd0;
        glcmData_writeback[31:24] <= (dirtyReg_write[3]) ? sramReadData_GLCM[31:24] : 'd0;
      end
      default : glcmData_writeback <= 'd0;
    endcase
  end
end
assign glcmData_writeback_translate[0] = glcmData_writeback[7:0];
assign glcmData_writeback_translate[1] = glcmData_writeback[15:8];
assign glcmData_writeback_translate[2] = glcmData_writeback[23:16];
assign glcmData_writeback_translate[3] = glcmData_writeback[31:24];


// Burst Row count
always @(posedge clk or negedge rst_n) begin : proc_burstCount_row
  if(~rst_n)
    burstCount_row <= 'd0;
  else begin
    case (currentState)
      S_WRITE: begin
        if (burstCount_row)
          burstCount_row <= burstCount_row;
        else if (col_GLCM=='d28)
          burstCount_row <= burstCount_row + 'd1;
      end
      default : burstCount_row <= 'd0;
    endcase
  end
end


//---------------------------------------------------------------------
//   AXI4
//---------------------------------------------------------------------
//----------------------------Read-------------------------------------
// axi read address channel
assign arid_m_inf = 'd0;
assign arlen_m_inf = 4'd15;
assign arsize_m_inf = 3'b010;
assign arburst_m_inf = 2'b01;

always @(*) begin : proc_nextAddr
  if (~blockHit[0]) nextAddr = addr_M_b0;
  else if (~blockHit[1]) nextAddr = addr_M_b1;
  else if (~blockHit[2]) nextAddr = addr_M_b2;
  else if (~blockHit[3]) nextAddr = addr_M_b3;
  else if (~blockHit[4]) nextAddr = addr_M_b4;
  else nextAddr = 'd0;
end

always @(*) begin : proc_readAddr
	case (currentState)
		S_READ_ADDR_WAIT: begin
      //readAddr_valid = 1'b1;
      readAddr = nextAddr;
		end

		default: begin
      //readAddr_valid = 1'b0;
			readAddr = 'd0;
		end
	endcase
end
always @(posedge clk or negedge rst_n) begin : proc_readAddrReg
  if(~rst_n)
    readAddrReg <= 'd0;
  else begin
    readAddrReg <= readAddr;
  end
end
always @(*) begin : proc_raedAddr_valid
  case (currentState)
    S_READ_ADDR_WAIT: begin
      if (count=='d1)
        readAddr_valid = 1'b1;
      else
        readAddr_valid = 1'b0;
    end
    default : readAddr_valid = 1'b0;
  endcase
end
assign arvalid_m_inf = readAddr_valid;
assign araddr_m_inf = readAddrReg;

always @(posedge clk or negedge rst_n) begin : proc_curAddrReg
  if(~rst_n)
    curAddrReg <= 'd0;
  else begin
    case (currentState)
      S_READ_ADDR_WAIT: begin
        if (arready_m_inf)
          curAddrReg <= araddr_m_inf;
      end
    endcase
  end
end
// axi read data channel
assign dramDataTranslate[0] = rdata_m_inf[4:0];
assign dramDataTranslate[1] = rdata_m_inf[12:8];
assign dramDataTranslate[2] = rdata_m_inf[20:16];
assign dramDataTranslate[3] = rdata_m_inf[28:24];
// Read Ready
assign rready_m_inf = (currentState==S_READ_DATA) ? 1'b1 : 1'b0;
//----------------------------Write------------------------------------
// axi write address channel
assign awid_m_inf = 'd0;
assign awburst_m_inf = 2'b01;
assign awlen_m_inf = 4'd15;
assign awsize_m_inf = 3'b010;

always @(posedge clk or negedge rst_n) begin : proc_writeReadyReg
  if(~rst_n)
    writeReadyReg <= 1'b0;
  else begin
    case (currentState)
      S_CAL: begin
        if (awready_m_inf)
          writeReadyReg <= 1'b1;
      end

      default : writeReadyReg <= 1'b0;
    endcase
  end
end

always @(posedge clk or negedge rst_n) begin : proc_writeAddr_next
  if(~rst_n)
    writeAddr_next <= 'd0;
  else begin
    case (currentState)
      S_WRITE: begin
        writeAddr_next <= addrReg_G + {row_GLCM+1'd1, 5'b0};
      end
    endcase
  end
end

always @(*) begin : proc_writeAddr
  case (currentState)
    S_CAL: begin
      if (~writeReadyReg) begin
        writeAddr_valid = 1'b1;
        writeAddr = addrReg_G;
      end
      else begin
        writeAddr_valid = 1'b0;
        writeAddr = 'd0;
      end
    end
    
    S_WRITE_ADDR_WAIT: begin
      writeAddr_valid = 1'b1;
      writeAddr = writeAddr_next;/*addrReg_G + {row_GLCM+1'd1, 5'b0};*/
    end

    default : begin
      writeAddr_valid = 1'b0;
      writeAddr = 'd0;
    end
  endcase
end

assign awvalid_m_inf = writeAddr_valid;
assign awaddr_m_inf = writeAddr;

// axi write data channel
always @(posedge clk or negedge rst_n) begin : proc_writeData_valid
  if(~rst_n)
    writeData_valid <= 1'b0;
  else begin
    case (currentState)
      S_WRITE: begin
        if (count=='d1)
          writeData_valid <= 1'b1;
        else if (wlast_m_inf)
          writeData_valid <= 1'b0;
      end
      default : writeData_valid <= 1'b0;
    endcase
  end
end
assign wvalid_m_inf = writeData_valid;
assign wdata_m_inf = glcmData_writeback;
assign wlast_m_inf = (count=='d19) ? 1'b1 : 1'b0;

// axi write Response channel
assign bready_m_inf = (currentState==S_WRITE) ? 1'b1 : 1'b0;

//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always @(*) begin : proc_out_valid
  case (currentState)
    S_OUT: out_valid = 1'b1;
    default : out_valid = 1'b0;
  endcase
end



endmodule








