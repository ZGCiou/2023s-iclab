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
reg [1:0] currentState, nextState;
reg [12:0] count;
// Calculate
reg [28:0] doraReg[0:4]; //{id,size,iq,eq} id->28:24, size->23:16, iq->15:8, eq->7:0
reg [4:0] doraReg_id[0:4];
reg [7:0] doraReg_size[0:4], doraReg_iq[0:4], doraReg_eq[0:4];
reg [2:0] size_weightReg, iq_weightReg, eq_weightReg;
reg [10:0] weighted_size[0:4], weighted_iq[0:4], weighted_eq[0:4];
reg [12:0] score[0:4];
wire [15:0] door_score[0:4], compare[0:8][0:1], sort_door_score[0:4];
wire [12:0] sort_score[0:4];
wire [3:0] sort_door[0:4];
wire [7:0] cal_out;
wire [3:0] cal_out_door;
wire [4:0] cal_out_id;
// FIFO
reg wfifo, rfifo;
wire wfull, rempty;
wire [7:0] fifo_out;
wire [3:0] fifo_out_door;
wire [4:0] fifo_out_id;
// Output
reg [12:0] count_out;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter S_IDLE = 'd0;
parameter S_IN = 'd1;
parameter S_CAL = 'd2;
parameter S_OUT = 'd3;

integer i;
//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
// Current State
always @(posedge clk1 or negedge rst_n) begin : proc_currentState
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
            if (in_valid)
                nextState = S_IN;
            else
                nextState = S_IDLE;
        end

        S_IN: begin
            if (count=='d3)
                nextState = S_CAL;
            else
                nextState = S_IN;
        end
        default : nextState = currentState;
    endcase
end
// Counter
always @(posedge clk1 or negedge rst_n) begin : proc_count
    if(~rst_n)
        count <= 'd0;
    else begin
        case (currentState)
            
            S_IDLE: begin
                if (in_valid)
                    count <= count + 'd1;
            end
            
            S_IN: begin
                if (count=='d3)
                    count <= 'd0;
                else
                    count <= count + 'd1;
            end

            S_CAL: begin
                if (in_valid)
                    count <= count + 'd1;
            end

            //default:
        endcase
    end
end

//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
// Doraemon
always @(posedge clk1 or negedge rst_n) begin : proc_doraReg
    if(~rst_n) begin
        doraReg[0] <= 'd0;
        doraReg[1] <= 'd0;
        doraReg[2] <= 'd0;
        doraReg[3] <= 'd0;
        doraReg[4] <= 'd0;
    end
    else begin
        case (currentState)
            S_IDLE: begin
                if (in_valid)
                    doraReg[0] <= {doraemon_id, size, iq_score, eq_score};
            end

            S_IN: begin
                doraReg[count] <= {doraemon_id, size, iq_score, eq_score};
            end

            S_CAL: begin
                if (in_valid)begin
                    if (count=='d0)
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
        case (currentState)
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
    case (currentState)
        S_IDLE: begin
            ready = 1'b0;
        end

        S_IN: begin
            ready = 1'b1;
        end

        S_CAL: begin
            if (count<'d5996)
                ready = ~wfull;
            else
                ready = 'b0;
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

// Write FIFO
always @(*) begin : proc_wfifo
    case (currentState)
        S_CAL: begin
            if (count>'d0 && count_out<count)
                wfifo = ~wfull;
            else
                wfifo = 1'b0;
        end
        default : wfifo = 1'b0;
    endcase
end
// Read FIFO
always @(*) begin : proc_rfifo
    case (currentState)
        S_CAL: begin
            if (~rempty)
                rfifo = 1'b1;
            else
                rfifo = 1'b0;
        end
        default : rfifo = 1'b0;
    endcase
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
always @(posedge clk2 or negedge rst_n) begin : proc_count_out
    if(~rst_n)
        count_out <= 'd0;
    else begin
        case (currentState)
            S_CAL: begin
                if (out_valid)
                    count_out <= count_out + 'd1;
            end
            default : /* default */;
        endcase
    end
end

always @(*) begin : proc_out_valid
    case (currentState)
        S_CAL: begin
            if (count_out<'d5996 && count_out<count)
                out_valid = rfifo;
            else
                out_valid = 1'b0;
        end
        default : out_valid = 1'b0;
    endcase
end

always @(*) begin : proc_out
    case (currentState)
        S_CAL: begin
            if (rfifo && count_out<'d5996)
                out = fifo_out;
            else
                out = 'd0;
        end
        default : out = 'd0;
    endcase
end

endmodule