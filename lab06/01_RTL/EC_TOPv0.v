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
reg currentState, nextState;
// InData
reg [5:0] XpReg, YpReg, XqReg, YqReg, primeReg, aReg;
//
reg ptDoub;
wire [6:0] sDmr;
wire [5:0] Xminus, Yminus, sDmrMod, sDmrInv, sNmrMod, sMod, sSqrtMod, sSqrtMp, Xr, XpMr, XpMrMulsMod, Yr;
wire [11:0] XpSqrt, s ,sSqrt, XpMrMuls;
wire [13:0] XpSqrtMul3;
wire [14:0] XpSqrtPlusA, sNmr;

//wire [20:0] s;
//wire [5:0] sMod, XrMod, YrMod;
//wire [5:0] dmrPA, invDmrPA, nmrPA;
//wire [6:0] dmrPD, invDmrPD;
//wire [13:0] nmrPD;
//wire [11:0] sPA, Xr, Yr;
//wire [20:0] sPD;

// ===============================================================
// Parameter
// ===============================================================
// FSM
parameter S_idle = 'd0;
//parameter S_input = 'd1;
parameter S_out = 'd1;


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
                nextState = S_out;
            else
                nextState = S_idle;
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
assign sDmr = (ptDoub) ? (YpReg<<1) : Xminus;
assign sDmrMod = sDmr % primeReg;
INV_IP #(.IP_WIDTH(6)) DenominatorINV (.IN_1(sDmrMod), .IN_2(primeReg), .OUT_INV(sDmrInv));

// Numerator of S
assign Yminus = (YpReg>YqReg) ? (primeReg + YqReg - YpReg) : (YqReg - YpReg);
assign XpSqrt = XpReg * XpReg;
assign XpSqrtMul3 = XpSqrt * 3;
assign XpSqrtPlusA = XpSqrtMul3 + aReg;
assign sNmr = (ptDoub) ? XpSqrtPlusA : Yminus;
assign sNmrMod = sNmr % primeReg;

// S
assign s = sDmrInv * sNmrMod;
assign sMod = s % primeReg;

// Xr
assign sSqrt = sMod * sMod;
assign sSqrtMod = sSqrt % primeReg;
assign sSqrtMp = (sSqrtMod<XpReg) ? (primeReg + sSqrtMod - XpReg) : (sSqrtMod - XpReg);
assign Xr = (sSqrtMp<XqReg) ? (primeReg + sSqrtMp - XqReg) : (sSqrtMp - XqReg);

// Yr
assign XpMr = (XpReg<Xr) ? (primeReg + XpReg - Xr) : (XpReg - Xr);
assign XpMrMuls = XpMr * sMod;
assign XpMrMulsMod = XpMrMuls % primeReg;
assign Yr = (XpMrMulsMod<YpReg) ? (primeReg + XpMrMulsMod - YpReg) : (XpMrMulsMod - YpReg);







/*
// Point Addition: denominator = Xq - Xp
assign dmrPA = Xq - XpReg;
INV_IP #(.IP_WIDTH(6)) PointAddition (.IN_1(dmrPA), .IN_2(primeReg), .OUT_INV(invDmrPA));
// Point Addition: numerator = Yq - Yp
assign nmrPA = YqReg - YpReg;
// Point Doubling: denominator = 2 * Yp
assign dmrPD = 'd2 * YpReg;
INV_IP #(.IP_WIDTH(7)) PointDoubling (.IN_1(dmrPD), .IN_2(primeReg), .OUT_INV(invDmrPD));
// Point Doubling: numerator = 3 * Yp * Yp + a
assign nmrPD = 'd3 * YpReg * YpReg + aReg;
// S
assign sPA = nmrPA * invDmrPA;
assign sPD = nmrPD * invDmrPD;
assign s = (XpReg==XqReg && YpReg==YqReg) ? sPD : sPA;
assign sMod = s % primeReg;
// Xr, Yr
assign Xr = sMod * sMod - XpReg - XqReg;
assign Yr = sMod * (XpReg - Xr) - YpReg;
assign XrMod = Xr % primeReg;
assign YrMod = Yr % primeReg;
*/
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

