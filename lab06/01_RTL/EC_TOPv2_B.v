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
reg [2:0] currentState, nextState;
// InData
reg [5:0] XpReg, YpReg, XqReg, YqReg, primeReg, aReg;
//
reg ptDoub;
wire [5:0] sDmr, sDmrInv, sNmr;
wire [7:0] XpSqrtMul3;
wire [8:0] XpSqrtPlusA;
wire [11:0] XpSqrt;
reg [5:0] sDmrReg, sNmrReg, sReg, XrReg;
// PE
reg [5:0] in1_Minus1, in2_Minus1, in1_Minus2, in2_Minus2, in1_Mul1, in2_Mul1, in1_Mul2, in2_Mul2;
wire [5:0] out_Minus1, out_Minus2, out_Mul1, out_Mul2;


//wire [6:0] sDmr;
//wire [5:0] Xminus, Yminus, sDmrMod, sDmrInv, sNmrMod, /*sMod,*/ sSqrtMod, sSqrtMp, Xr, XpMr, XpMrMulsMod, Yr;
//reg  [5:0] sModReg;
//wire [11:0] XpSqrt, s ,sSqrt, XpMrMuls;
//wire [13:0] XpSqrtMul3;
//wire [14:0] XpSqrtPlusA, sNmr;

// ===============================================================
// Parameter
// ===============================================================
// FSM
parameter S_idle = 'd0;
parameter S_cal1 = 'd1;
parameter S_cal2 = 'd2;
parameter S_cal3 = 'd3;
parameter S_out = 'd4;

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
                nextState = S_cal1;
            else
                nextState = S_idle;
        end
        
        S_cal1: begin
            nextState = S_cal2;
        end

        S_cal2: begin
            nextState = S_cal3;
        end

        S_cal3: begin
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

// PE
PF_MINUS MINUS_1(.pNumA(in1_Minus1), .pNumB(in2_Minus1), .prime(primeReg), .pNumOut(out_Minus1));
PF_MINUS MINUS_2(.pNumA(in1_Minus2), .pNumB(in2_Minus2), .prime(primeReg), .pNumOut(out_Minus2));
PF_MUL MUL_1(.pNumA(in1_Mul1), .pNumB(in2_Mul1), .prime(primeReg), .pNumOut(out_Mul1));
//PF_MUL MUL_2(.pNumA(in1_Mul2), .pNumB(in2_Mul2), .prime(primeReg), .pNumOut(out_Mul2));

// MINUS_1
always @(*) begin : proc_in_Minus1
    case (currentState)
        S_cal1: begin
            in1_Minus1 = XqReg;
            in2_Minus1 = XpReg;
        end

        S_cal3: begin
            in1_Minus1 = out_Mul1;
            in2_Minus1 = XpReg;
        end

        S_out: begin
            in1_Minus1 = XpReg;
            in2_Minus1 = XrReg;
        end

        default : begin
            in1_Minus1 = 'd0;
            in2_Minus1 = 'd0;
        end
    endcase
end

// MINUS_2
always @(*) begin : proc_in_Minus2
    case (currentState)
        S_cal1: begin
            in1_Minus2 = YqReg;
            in2_Minus2 = YpReg;
        end

        S_cal3: begin
            in1_Minus2 = out_Minus1;
            in2_Minus2 = XqReg;
        end

        S_out: begin
            in1_Minus2 = out_Mul1;
            in2_Minus2 = YpReg;
        end

        default : begin
            in1_Minus2 = 'd0;
            in2_Minus2 = 'd0;
        end
    endcase
end

// MUL_1
always @(*) begin : proc_in_Mul1
    case (currentState)
        S_cal2: begin
            in1_Mul1 = sDmrInv;
            in2_Mul1 = sNmrReg;
        end

        S_cal3: begin
            in1_Mul1 = sReg;
            in2_Mul1 = sReg;
        end

        S_out: begin
            in1_Mul1 = out_Minus1;
            in2_Mul1 = sReg;
        end

        default : begin
            in1_Mul1 = 'd0;
            in2_Mul1 = 'd0;
        end
    endcase
end

// Denominator of S
assign sDmr = (ptDoub) ? ({YpReg, 1'b0} % primeReg) : out_Minus1;
INV_IP #(.IP_WIDTH(6)) DenominatorINV (.IN_1(sDmrReg), .IN_2(primeReg), .OUT_INV(sDmrInv));

// Numerator of S
assign XpSqrt = XpReg * XpReg;
assign XpSqrtMul3 = (XpSqrt % primeReg) * 2'd3;
assign XpSqrtPlusA = XpSqrtMul3 + aReg;
assign sNmr = (ptDoub) ? (XpSqrtPlusA % primeReg) : out_Minus2;

//sDmrReg, sNmuReg
always @(posedge clk or negedge rst_n) begin : proc_sDNReg
    if(~rst_n) begin
        sDmrReg <= 'd0;
        sNmrReg <= 'd0;
    end 
    else begin
        if (currentState==S_cal1) begin
            sDmrReg <= sDmr;
            sNmrReg <= sNmr;
        end
    end
end

// sReg
always @(posedge clk or negedge rst_n) begin : proc_sReg
    if(~rst_n)
        sReg <= 'd0;
    else begin
        if (currentState==S_cal2)
            sReg <= out_Mul1;
    end
end

//XrReg
always @(posedge clk or negedge rst_n) begin : proc_XrReg
    if(~rst_n)
        XrReg <= 'd0;
    else begin
        if (currentState==S_cal3)
            XrReg <= out_Minus2;
    end
end

/*
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
            out_Rx <= XrReg;
            out_Ry <= out_Minus2;
        end
        else begin
            out_Rx <= 'd0;
            out_Ry <= 'd0;
        end
    end
end


endmodule

// ===============================================================
// Sub Module
// ===============================================================
module PF_MINUS (
    input [5:0] pNumA, pNumB, prime,
    output [5:0] pNumOut
);
    wire [5:0] minus, plusp;
    
    assign minus = pNumA - pNumB;
    assign plusp = (pNumA<pNumB) ? prime : 6'd0;
    assign pNumOut = minus + plusp;

endmodule

module PF_MUL (
    input [5:0] pNumA, pNumB, prime,
    output [5:0] pNumOut
);
    wire [11:0] mul;

    assign mul = pNumA * pNumB;
    assign pNumOut = mul % prime;
    
endmodule
