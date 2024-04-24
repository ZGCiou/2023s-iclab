//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : EC_TOP.v
//   	Module Name : EC_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "INV_IP.v"
//synopsys translate_on

module EC_TOP(
    // Input signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Output signals
    out_valid, out_Rx, out_Ry
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [6-1:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
output reg out_valid;
output reg [6-1:0] out_Rx, out_Ry;

// ===============================================================
// Wire & Reg Declaration
// ===============================================================
// FSM
reg [1:0] currentState, nextState;
// InData
reg [5:0] XpReg, YpReg, XqReg, YqReg, primeReg, aReg;
//
reg ptDoub;
wire [6:0] sDmr;
wire [5:0] Xminus, Yminus, sDmrMod, sDmrInv, sNmrMod, /*sMod,*/ sSqrtMod, sSqrtMp, Xr, XpMr, XpMrMulsMod, Yr;
reg  [5:0] sModReg;
wire [11:0] XpSqrt, s ,sSqrt, XpMrMuls;
wire [13:0] XpSqrtMul3;
wire [14:0] XpSqrtPlusA, sNmr;

// ===============================================================
// Parameter
// ===============================================================
// FSM
parameter S_idle = 'd0;
parameter S_cal = 'd1;
parameter S_out = 'd2;

// ===============================================================
// Finite State Machine
// ===============================================================
// Current State
always @(posedge clk or negedge rst_n) begin : proc_currentState
    if(~rst_n)
        currentState <= S_idle;
    else begin
        currentState <= nextState;
    end
end
// Next State
always @(*) begin : proc_nextState
    case (currentState)
        S_idle: begin
            if (in_valid)
                nextState = S_cal;
            else
                nextState = S_idle;
        end

        S_cal: begin
            nextState = S_out;
        end

        S_out: begin
            nextState = S_idle;
        end
        default : nextState = currentState;
    endcase
end

// ===============================================================
// Input
// ===============================================================
// inData
always @(posedge clk) begin : inData
    if (in_valid) begin
        XpReg <= in_Px;
        YpReg <= in_Py;
        XqReg <= in_Qx;
        YqReg <= in_Qy;
        primeReg <= in_prime;
        aReg <= in_a;
    end
end

// ===============================================================
// Calculate
// ===============================================================
// Select Point Addition or Point Doubling
always @(*) begin : proc_sel
    if (XpReg==XqReg && YpReg==YqReg)
        ptDoub = 1'b1;
    else
        ptDoub = 1'b0;
end

// Denominator of S
assign Xminus = (XpReg>XqReg) ? (primeReg + XqReg - XpReg) : (XqReg - XpReg);
assign sDmrMod = (ptDoub) ? ({YpReg, 1'b0} % primeReg) : Xminus;
//assign sDmrMod = sDmr % primeReg;
INV_IP #(.IP_WIDTH(6)) DenominatorINV (.IN_1(sDmrMod), .IN_2(primeReg), .OUT_INV(sDmrInv));

// Numerator of S
assign Yminus = (YpReg>YqReg) ? (primeReg + YqReg - YpReg) : (YqReg - YpReg);
assign XpSqrt = XpReg * XpReg;
assign XpSqrtMul3 = XpSqrt * 3;
assign XpSqrtPlusA = XpSqrtMul3 + aReg;
assign sNmrMod = (ptDoub) ? (XpSqrtPlusA % primeReg) : Yminus;
//assign sNmrMod = sNmr % primeReg;

// S
assign s = sDmrInv * sNmrMod;
//assign sMod = s % primeReg;
always @(posedge clk or negedge rst_n) begin : proc_sModReg
    if(~rst_n)
        sModReg <= 'd0;
    else begin
        if (currentState==S_cal)
            sModReg <= s % primeReg;
    end
end

// Xr
assign sSqrt = sModReg * sModReg;
assign sSqrtMod = sSqrt % primeReg;
assign sSqrtMp = (sSqrtMod<XpReg) ? (primeReg + sSqrtMod - XpReg) : (sSqrtMod - XpReg);
assign Xr = (sSqrtMp<XqReg) ? (primeReg + sSqrtMp - XqReg) : (sSqrtMp - XqReg);

// Yr
assign XpMr = (XpReg<Xr) ? (primeReg + XpReg - Xr) : (XpReg - Xr);
assign XpMrMuls = XpMr * sModReg;
assign XpMrMulsMod = XpMrMuls % primeReg;
assign Yr = (XpMrMulsMod<YpReg) ? (primeReg + XpMrMulsMod - YpReg) : (XpMrMulsMod - YpReg);

// ===============================================================
// Output
// ===============================================================
// out_valid
always @(posedge clk or negedge rst_n) begin : proc_out_valid
    if (~rst_n)
        out_valid <= 1'b0;
    else begin
        if (currentState==S_out)
            out_valid <= 1'b1;
        else
            out_valid <= 'b0;
    end
end
// out
always @(posedge clk or negedge rst_n) begin : proc_out
    if(~rst_n) begin
        out_Rx <= 'd0;
        out_Ry <= 'd0;
    end
    else begin
        if (currentState==S_out) begin
            out_Rx <= Xr;
            out_Ry <= Yr;
        end
        else begin
            out_Rx <= 'd0;
            out_Ry <= 'd0;
        end
    end
end


endmodule

