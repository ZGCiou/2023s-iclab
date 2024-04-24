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
reg wfifo, rfifo;
wire wfull, rempty;
wire [7:0] fifo_out;
wire [3:0] fifo_out_door;
wire [4:0] fifo_out_id;
reg [7:0] fifo_outReg;
reg wfail;
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
always @(posedge clk1 or negedge rst_n) begin : proc_cnt_cal
    if(~rst_n)
        cnt_cal <= 'd0;
    else begin
        case (cs_clk1)
            S_CAL: begin
                if (in_valid && cnt_clk1=='d1)
                    cnt_cal <= cnt_cal + 'd1;
            end
        endcase
    end
end
/*
// Write fail
always @(posedge clk1 or negedge rst_n) begin : proc_wfail
    if(~rst_n)
        wfail <= 1'b0;
    else begin
        if (wfull)
            wfail <= 1'b1;
        else
            wfail <= 1'b0;
    end
end
*/
//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
// Doraemon register
always @(posedge clk1 or negedge rst_n) begin : proc_doraReg
    if(~rst_n) begin
        doraReg[0] <= 'd0;
        doraReg[1] <= 'd0;
        doraReg[2] <= 'd0;
        doraReg[3] <= 'd0;
        doraReg[4] <= 'd0;
    end
    else begin
        case (cs_clk1)
            S_IDLE: begin
                if (in_valid)
                    doraReg[0] <= {doraemon_id, size, iq_score, eq_score};
            end

            S_IN: begin
                doraReg[cnt_clk1] <= {doraemon_id, size, iq_score, eq_score};
            end

            S_CAL: begin
                if (in_valid)begin
                    if (cnt_clk1=='d0)
                        doraReg[4] <= {doraemon_id, size, iq_score, eq_score};
                    else
                        doraReg[sort_door[0]] <= {doraemon_id, size, iq_score, eq_score};
                end
            end
            //default : /* default */;
        endcase
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
// Weight
always @(posedge clk1 or negedge rst_n) begin : proc_weight
    if(~rst_n) begin
        size_weightReg <= 'd0;
        iq_weightReg <= 'd0;
        eq_weightReg <= 'd0;
    end
    else begin
        case (cs_clk1)
            S_CAL: begin
                if (in_valid) begin
                    size_weightReg <= size_weight;
                    iq_weightReg <= iq_weight;
                    eq_weightReg <= eq_weight;
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
AFIFO OUT_FIFO(.rst_n(rst_n), .wclk(clk1), .winc(wfifo), .wdata(cal_out), .wfull(wfull), .rclk(clk2), .rinc(rfifo), .rdata(fifo_out), .rempty(rempty));
assign fifo_out_door = fifo_out[7:5];
assign fifo_out_id = fifo_out[4:0];

always @(posedge clk1 or negedge rst_n) begin : proc_fifo_outReg
    if(~rst_n)
        fifo_outReg <= 'd0;
    else begin
        fifo_outReg <= fifo_out;
    end
end

// Write FIFO -> clk1
always @(posedge clk1 or negedge rst_n) begin : proc_wfifo
    if(~rst_n)
        wfifo <= 1'b0;
    else begin
        case (cs_clk1)
            S_CAL: begin
                if (in_valid || wfull) //
                    wfifo <= 1'b1;
                else
                    wfifo <= 1'b0;
            end
            default : wfifo <= 1'b0;
        endcase
    end
end


/*
always @(*) begin : proc_wfifo
    case (cs_clk1)
        S_CAL: begin
            if (cnt_clk1>'d0)// && count_out<count) // !!!!!!!!!
                wfifo = ~wfull;
            else
                wfifo = 1'b0;
        end
        default : wfifo = 1'b0;
    endcase
end */
// Read FIFO -> clk2



always @(*) begin : proc_rfifo
    rfifo = ~rempty;
end
//---------------------------------------------------------------------
//   CALCULATE
//---------------------------------------------------------------------
// Score
always @(*) begin : proc_score
    for (i=0; i<5; i=i+1) begin
        weighted_size[i] = doraReg_size[i] * size_weightReg;
        weighted_iq[i] = doraReg_iq[i] * iq_weightReg;
        weighted_eq[i] = doraReg_eq[i] * eq_weightReg;
        score[i] = weighted_size[i] + weighted_iq[i] + weighted_eq[i];
    end
end

//TEST
//assign score[0] = 'd0;
//assign score[1] = 'd1;
//assign score[2] = 'd1;
//assign score[3] = 'd0;
//assign score[4] = 'd0;

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
// clk2
// Counter clk2
always @(posedge clk2 or negedge rst_n) begin : proc_cnt_clk2
    if(~rst_n)
        cnt_clk2 <= 'd0;
    else begin
        if (out_valid)
            cnt_clk2 <= cnt_clk2 + 'd1;
    end
end
// Out Valid
/*
always @(posedge clk1 or negedge rst_n) begin : proc_out
    if(~rst_n) begin
        out_valid <= 0;
        out <= 'd0;
    end 

end 
*/
/*
//comb
always @(*) begin : proc_out_valid
    if (cnt_clk2<'d5996)
        out_valid = rfifo;
    else
        out_valid = 1'b0;
end

always @(*) begin : proc_out
    if (rfifo && cnt_clk2<'d5996)
        out = fifo_out;
    else
        out = 'd0;
end
*/

always @(posedge clk2 or negedge rst_n) begin : proc_out_valid
    if(~rst_n)
        out_valid <= 1'b0;
    else begin
        if (cnt_clk2<'d5995)
            out_valid <= rfifo;
        else
            out_valid <= 1'b0;
        end
end
always @(posedge clk2 or negedge rst_n) begin : proc_out
    if(~rst_n)
        out <= 'd0;
    else begin
        if (rfifo && cnt_clk2<'d5996)
            out <= fifo_out;
        else
            out <= 'd0;
        end
end


endmodule