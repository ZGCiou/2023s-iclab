`include "AFIFO.v"

module CDC #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Input Port
	rst_n,
	clk1,
    clk2,
	in_valid,
    doraemon_id,
    size,
    iq_score,
    eq_score,
    size_weight,
    iq_weight,
    eq_weight,
    //Output Port
	ready,
    out_valid,
	out,
    
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
output reg  [7:0] out;
output reg	out_valid,ready;

input rst_n, clk1, clk2, in_valid;
input  [4:0]doraemon_id;
input  [7:0]size;
input  [7:0]iq_score;
input  [7:0]eq_score;
input [2:0]size_weight,iq_weight,eq_weight;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
// FSM
reg [1:0] cs_clk1, ns_clk1;
reg [1:0] cnt_clk1;
reg [12:0] cnt_cal;

// Input Data
reg [4:0] inReg_id;
reg [7:0] inReg_size, inReg_iq, inReg_eq;
reg [2:0] inReg_sw, inReg_iqw, inReg_eqw;
reg [28:0] doraReg[0:4]; //{id,size,iq,eq} id->28:24, size->23:16, iq->15:8, eq->7:0
reg [4:0] doraReg_id[0:4];
reg [7:0] doraReg_size[0:4], doraReg_iq[0:4], doraReg_eq[0:4];
reg [2:0] size_weightReg, iq_weightReg, eq_weightReg;

// Calculate
// score
reg [10:0] weighted_size[0:4], weighted_iq[0:4], weighted_eq[0:4];
reg [12:0] score[0:4];
// sort
wire [15:0] door_score[0:4], compare[0:8][0:1], sort_door_score[0:4];
wire [12:0] sort_score[0:4];
wire [3:0] sort_door[0:4];
// out
wire [7:0] cal_out;
wire [3:0] cal_out_door;
wire [4:0] cal_out_id;
// FIFO
reg wfifo;
wire wfull ,rfifo, rempty;
wire [7:0] wdata_size, wdata_iq, wdata_eq, wdata_id_sw, wdata_iqw_eqw;
wire [7:0] rdata_size, rdata_iq, rdata_eq, rdata_id_sw, rdata_iqw_eqw;
wire wfull_size, wfull_iq, wfull_eq, wfull_id_sw, wfull_iqw_eqw;
wire rempty_size, rempty_iq, rempty_eq, rempty_id_sw, rempty_iqw_eqw;
// Output
reg [12:0] cnt_clk2;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter S_IDLE = 'd0;
parameter S_IN = 'd1;
parameter S_CAL = 'd2;

integer i;
//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
// Current State
always @(posedge clk1 or negedge rst_n) begin : proc_cs_clk1
    if(~rst_n)
        cs_clk1 <= S_IDLE;
    else begin
        cs_clk1 <= ns_clk1;
    end
end
// Next State
always @(*) begin : proc_ns_clk1
    case (cs_clk1)
        S_IDLE: begin
            if (in_valid)
                ns_clk1 = S_IN;
            else
                ns_clk1 = S_IDLE;
        end

        S_IN: begin
            if (cnt_clk1=='d3)
                ns_clk1 = S_CAL;
            else
                ns_clk1 = S_IN;
        end
        default : ns_clk1 = cs_clk1;
    endcase
end
// Counter clk1
always @(posedge clk1 or negedge rst_n) begin : proc_cnt_clk1
    if(~rst_n)
        cnt_clk1 <= 'd0;
    else begin
        case (cs_clk1)
            
            S_IDLE: begin
                if (in_valid)
                    cnt_clk1 <= cnt_clk1 + 'd1;
            end
            
            S_IN: begin
                if (cnt_clk1=='d3)
                    cnt_clk1 <= 'd0;
                else
                    cnt_clk1 <= cnt_clk1 + 'd1;
            end
            
            S_CAL: begin
                cnt_clk1 <= 'd1;
            end
            
            //default:
        endcase
    end
end
// Count cal


//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
// Doraemon register
always @(posedge clk1 or negedge rst_n) begin : proc_inReg
    if(~rst_n) begin
        inReg_id <= 'd0;
        inReg_size <= 'd0;
        inReg_iq <= 'd0;
        inReg_eq <= 'd0;
        inReg_sw <= 'd0;
        inReg_iqw <= 'd0;
        inReg_eqw <= 'd0;
    end
    else begin
        case (cs_clk1)
            S_IDLE: begin
                if (in_valid) begin
                    inReg_id <= doraemon_id;
                    inReg_size <= size;
                    inReg_iq <= iq_score;
                    inReg_eq <= eq_score;
                    //doraReg[0] <= {doraemon_id, size, iq_score, eq_score};
                end
            end

            S_IN: begin
                //doraReg[cnt_clk1] <= {doraemon_id, size, iq_score, eq_score};
                inReg_id <= doraemon_id;
                inReg_size <= size;
                inReg_iq <= iq_score;
                inReg_eq <= eq_score;
            end
            
            S_CAL: begin
                if (in_valid)begin
                    inReg_id <= doraemon_id;
                    inReg_size <= size;
                    inReg_iq <= iq_score;
                    inReg_eq <= eq_score;
                    inReg_sw <= size_weight;
                    inReg_iqw <= iq_weight;
                    inReg_eqw <= eq_weight;
                    /*
                    if (cnt_clk1=='d0)
                        doraReg[4] <= {doraemon_id, size, iq_score, eq_score};
                    else
                        doraReg[sort_door[0]] <= {doraemon_id, size, iq_score, eq_score};
                    */
                end
            end
            
        endcase
    end
end

// ready
always @(*) begin : proc_ready
    case (cs_clk1)
        S_IDLE: begin
            ready = 1'b0;
        end

        S_IN: begin
            ready = 1'b1;
        end
        
        S_CAL: begin
            if (cnt_cal=='d5995)
                ready = 'b0;
            else
                ready = ~wfull;
        end

        default : ready = 1'b0;
    endcase
end

//---------------------------------------------------------------------
//   FIFO
//---------------------------------------------------------------------
AFIFO SIZE_FIFO
    (.rst_n(rst_n), .wclk(clk1), .winc(wfifo), .wdata(wdata_size), .wfull(wfull_size), .rclk(clk2), .rinc(rfifo), .rdata(rdata_size), .rempty(rempty_size));

AFIFO IQ_FIFO
    (.rst_n(rst_n), .wclk(clk1), .winc(wfifo), .wdata(wdata_iq), .wfull(wfull_iq), .rclk(clk2), .rinc(rfifo), .rdata(rdata_iq), .rempty(rempty_iq));

AFIFO EQ_FIFO
    (.rst_n(rst_n), .wclk(clk1), .winc(wfifo), .wdata(wdata_eq), .wfull(wfull_eq), .rclk(clk2), .rinc(rfifo), .rdata(rdata_eq), .rempty(rempty_eq));

AFIFO ID_and_SW_FIFO
    (.rst_n(rst_n), .wclk(clk1), .winc(wfifo), .wdata(wdata_id_sw), .wfull(wfull_id_sw), .rclk(clk2), .rinc(rfifo), .rdata(rdata_id_sw), .rempty(rempty_id_sw));

AFIFO IQW_and_EQW_FIFO
    (.rst_n(rst_n), .wclk(clk1), .winc(wfifo), .wdata(wdata_iqw_eqw), .wfull(wfull_iqw_eqw), .rclk(clk2), .rinc(rfifo), .rdata(rdata_iqw_eqw), .rempty(rempty_iqw_eqw));

assign wfull = wfull_size | wfull_iq | wfull_eq | wfull_id_sw | wfull_iqw_eqw;
assign rempty = rempty_size | rempty_iq | rempty_eq | rempty_id_sw | rempty_iqw_eqw;

assign wdata_size = inReg_size;
assign wdata_iq = inReg_iq;
assign wdata_eq = inReg_eq;
assign wdata_id_sw = {inReg_id, inReg_sw};
assign wdata_iqw_eqw = {2'b0, inReg_iqw, inReg_eqw};

// Write FIFO -> clk1
always @(posedge clk1 or negedge rst_n) begin : proc_wfifo
    if(~rst_n)
        wfifo <= 1'b0;
    else begin
        if (in_valid || wfull)
            wfifo <= 1'b1;
        else
            wfifo <= 1'b0;
    end
end

// Read FIFO -> clk2
assign rfifo = ~rempty;

//---------------------------------------------------------------------
//   CALCULATE
//---------------------------------------------------------------------
// Counter clk2
always @(posedge clk2 or negedge rst_n) begin : proc_cnt_clk2
    if(~rst_n)
        cnt_clk2 <= 'd0;
    else begin
        if (rfifo || cnt_clk2=='d6000)
            cnt_clk2 <= cnt_clk2 + 'd1;
    end
end


// Doraemon register
always @(posedge clk2 or negedge rst_n) begin : proc_doraReg
    if(~rst_n) begin
        doraReg[0] <= 'd0;
        doraReg[1] <= 'd0;
        doraReg[2] <= 'd0;
        doraReg[3] <= 'd0;
        doraReg[4] <= 'd0;
        size_weightReg <= 'd0;
        iq_weightReg <= 'd0;
        eq_weightReg <= 'd0;
    end
    
    else begin
        if (rfifo) begin
            if (cnt_clk2<'d5) begin
                doraReg[cnt_clk2] <= {rdata_id_sw[7:3], rdata_size, rdata_iq, rdata_eq};
                size_weightReg <= rdata_id_sw[2:0];
                iq_weightReg <= rdata_iqw_eqw[5:3];
                eq_weightReg <= rdata_iqw_eqw[2:0];
            end
            else begin
                doraReg[sort_door[0]] <= {rdata_id_sw[7:3], rdata_size, rdata_iq, rdata_eq};
                size_weightReg <= rdata_id_sw[2:0];
                iq_weightReg <= rdata_iqw_eqw[5:3];
                eq_weightReg <= rdata_iqw_eqw[2:0];
            end
        end
    end 
end
always @(*) begin
    for (i=0; i<5; i=i+1) begin
        doraReg_id[i] = doraReg[i][28:24];
        doraReg_size[i] = doraReg[i][23:16];
        doraReg_iq[i] = doraReg[i][15:8];
        doraReg_eq[i] = doraReg[i][7:0];
    end
end

// Score

always @(*) begin : proc_score
    for (i=0; i<5; i=i+1) begin
        weighted_size[i] = doraReg_size[i] * size_weightReg;
        weighted_iq[i] = doraReg_iq[i] * iq_weightReg;
        weighted_eq[i] = doraReg_eq[i] * eq_weightReg;
        score[i] = weighted_size[i] + weighted_iq[i] + weighted_eq[i];
    end
end
// Sort
assign door_score[0] = {3'd0, score[0]};
assign door_score[1] = {3'd1, score[1]};
assign door_score[2] = {3'd2, score[2]};
assign door_score[3] = {3'd3, score[3]};
assign door_score[4] = {3'd4, score[4]};

assign compare[0][0] = (door_score[0][12:0]<door_score[1][12:0]) ? door_score[1] : door_score[0];
assign compare[0][1] = (door_score[0][12:0]<door_score[1][12:0]) ? door_score[0] : door_score[1];

assign compare[1][0] = (door_score[2][12:0]<door_score[3][12:0]) ? door_score[3] : door_score[2];
assign compare[1][1] = (door_score[2][12:0]<door_score[3][12:0]) ? door_score[2] : door_score[3];

assign compare[2][0] = (compare[1][1][12:0]<door_score[4][12:0]) ? door_score[4] : compare[1][1];
assign compare[2][1] = (compare[1][1][12:0]<door_score[4][12:0]) ? compare[1][1] : door_score[4];

assign compare[3][0] = (compare[1][0][12:0]<compare[2][0][12:0]) ? compare[2][0] : compare[1][0];
assign compare[3][1] = (compare[1][0][12:0]<compare[2][0][12:0]) ? compare[1][0] : compare[2][0];

assign compare[4][0] = (compare[0][0][12:0]<compare[3][0][12:0]) ? compare[3][0] : compare[0][0];
assign compare[4][1] = (compare[0][0][12:0]<compare[3][0][12:0]) ? compare[0][0] : compare[3][0];
assign sort_door_score[0] = compare[4][0];

assign compare[5][0] = (compare[0][1][12:0]<compare[2][1][12:0]) ? compare[2][1] : compare[0][1];
assign compare[5][1] = (compare[0][1][12:0]<compare[2][1][12:0]) ? compare[0][1] : compare[2][1];
assign sort_door_score[4] = compare[5][1];

assign compare[6][0] = (compare[4][1][12:0]<compare[3][1][12:0]) ? compare[3][1] : compare[4][1];
assign compare[6][1] = (compare[4][1][12:0]<compare[3][1][12:0]) ? compare[4][1] : compare[3][1];

assign compare[7][0] = (compare[6][1][12:0]>compare[5][0][12:0]) ? compare[6][1] : compare[5][0];
assign compare[7][1] = (compare[6][1][12:0]>compare[5][0][12:0]) ? compare[5][0] : compare[6][1];
assign sort_door_score[3] = compare[7][1];

assign compare[8][0] = (compare[6][0][12:0]>compare[7][0][12:0]) ? compare[6][0] : compare[7][0];
assign compare[8][1] = (compare[6][0][12:0]>compare[7][0][12:0]) ? compare[7][0] : compare[6][0];
assign sort_door_score[1] = compare[8][0];
assign sort_door_score[2] = compare[8][1];

assign sort_score[0] = sort_door_score[0][12:0];
assign sort_score[1] = sort_door_score[1][12:0];
assign sort_score[2] = sort_door_score[2][12:0];
assign sort_score[3] = sort_door_score[3][12:0];
assign sort_score[4] = sort_door_score[4][12:0];

assign sort_door[0] = sort_door_score[0][15:13];
assign sort_door[1] = sort_door_score[1][15:13];
assign sort_door[2] = sort_door_score[2][15:13];
assign sort_door[3] = sort_door_score[3][15:13];
assign sort_door[4] = sort_door_score[4][15:13];

// Calculate out
assign cal_out = {sort_door[0], doraReg_id[sort_door[0]]};
assign cal_out_door = sort_door[0];
assign cal_out_id = doraReg_id[sort_door[0]];

//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------

// Out Valid
always @(posedge clk2 or negedge rst_n) begin : proc_out_valid
    if(~rst_n)
        out_valid <= 1'b0;
    else begin
        if (rfifo && cnt_clk2>'d4 || cnt_clk2=='d6000)
            out_valid <= 1'b1;
        else
            out_valid <= 1'b0;
    end
end
// Out
always @(posedge clk2 or negedge rst_n) begin : proc_out
    if(~rst_n)
        out <= 'd0;
    else begin
        if (rfifo && cnt_clk2>'d4 || cnt_clk2=='d6000)
            out <= cal_out;
        else
            out <= 'd0;
    end
end

endmodule