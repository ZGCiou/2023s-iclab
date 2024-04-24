//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : INV_IP.v
//   	Module Name : INV_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module INV_IP #(parameter IP_WIDTH = 6) (
    // Input signals
    IN_1, IN_2,
    // Output signals
    OUT_INV
);

// ===============================================================
// Declaration
// ===============================================================
input  [IP_WIDTH-1:0] IN_1, IN_2;
output [IP_WIDTH-1:0] OUT_INV;

// ===============================================================
// Design
// ===============================================================
localparam maxIterWidth5 = 5;
localparam maxIterWidth6 = 6;
localparam maxIterWidth7 = 8;

generate
    genvar idx;
    // Wire and Reg
    wire [IP_WIDTH-1:0] prime, number;
    reg signed [IP_WIDTH-1:0] mqResult, invNum;

    // Compare input: Big->Prime, Small->Number
    assign prime = (IN_1>IN_2) ? IN_1 : IN_2;
    assign number = (IN_1>IN_2) ? IN_2 : IN_1;

    if (IP_WIDTH==6) begin : Width6
        // Wire and Reg
        wire signed [IP_WIDTH-1:0] mqIter[1:IP_WIDTH];
        wire [IP_WIDTH-1:1] sel;

        for (idx=1; idx<IP_WIDTH+1; idx=idx+1) begin : Iter
            // Wire
            //wire [IP_WIDTH-1:0] divN, divR, q, r;
            wire signed [IP_WIDTH-1:0] mqH, mqL, mq;

            if (idx==1) begin : Iter1
                // Wire
                wire [IP_WIDTH-1:0] divN, divR;
                wire [IP_WIDTH-2:0] q, r;
                // Div
                assign divN = prime;
                assign divR = number;
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = 'd0;
                assign mqL = 'd1;
                assign mq = -($signed({1'b0, q}));
                assign mqIter[idx] = mq;
            end

            else if (idx==2) begin : Iter2
                // Wire
                wire [IP_WIDTH+1-idx:0] divN;
                wire [IP_WIDTH-idx:0] divR, q, r;
                // Div
                assign divN = Width6.Iter[idx-1].Iter1.divR;
                assign divR = Width6.Iter[idx-1].Iter1.r; 
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = Width6.Iter[idx-1].mqL;
                assign mqL = Width6.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed({1'b0, q}));
                assign mqIter[idx] = mq;
            end

            else if (idx==3) begin : Iter3
                // Wire
                wire [IP_WIDTH+1-idx:0] divN, divR;
                wire [IP_WIDTH-idx:0] q, r;
                // Div
                assign divN = Width6.Iter[idx-1].Iter2.divR;
                assign divR = Width6.Iter[idx-1].Iter2.r; 
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = Width6.Iter[idx-1].mqL;
                assign mqL = Width6.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed({1'b0, q}));
                assign mqIter[idx] = mq;
            end

            else if (idx==4) begin : Iter4
                // Wire
                wire [IP_WIDTH+2-idx:0] divN, q;
                wire [IP_WIDTH+1-idx:0] divR;
                wire [IP_WIDTH-idx:0] r;
                // Div
                assign divN = Width6.Iter[idx-1].Iter3.divR;
                assign divR = Width6.Iter[idx-1].Iter3.r; 
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = Width6.Iter[idx-1].mqL;
                assign mqL = Width6.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed({1'b0, q}));
                assign mqIter[idx] = mq;
            end

            else if (idx==5) begin : Iter5
                // Wire
                wire [IP_WIDTH+2-idx:0] divN;
                wire [IP_WIDTH+1-idx:0] divR, q;
                wire [IP_WIDTH-idx:0] r;
                // Div
                assign divN = Width6.Iter[idx-1].Iter4.divR;
                assign divR = Width6.Iter[idx-1].Iter4.r; 
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = Width6.Iter[idx-1].mqL;
                assign mqL = Width6.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed({1'b0, q}));
                assign mqIter[idx] = mq;
            end

            else begin : Iter6
                // Wire
                wire [IP_WIDTH+2-idx:0] divN;
                wire [IP_WIDTH+1-idx:0] divR;
                wire [IP_WIDTH-idx:0] q, r;
                // Div
                assign divN = Width6.Iter[idx-1].Iter5.divR;
                assign divR = Width6.Iter[idx-1].Iter5.r;
                assign q = divN / divR;
                // Mul
                assign mqH = Width6.Iter[idx-1].mqL;
                assign mqL = Width6.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed({1'b0, q}));
                assign mqIter[idx] = mq;
            end


            /*
            else if (idx==IP_WIDTH) begin : lastIter
                // Wire
                wire [IP_WIDTH+1-idx:0] divN;
                wire [IP_WIDTH-idx:0] divR, q, r;
                // Div
                assign divN = Width6.Iter[idx-1].midIter.divR;
                assign divR = Width6.Iter[idx-1].midIter.r;
                assign q = divN / divR;
                // Mul
                assign mqH = Width6.Iter[idx-1].mqL;
                assign mqL = Width6.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end

            else begin : midIter
                // Wire
                wire [IP_WIDTH+1-idx:0] divN;
                wire [IP_WIDTH-idx:0] divR, q, r;
                // Div
                if (idx==2) begin
                    assign divN = Width6.Iter[idx-1].firstIter.divR;
                    assign divR = Width6.Iter[idx-1].firstIter.r; 
                end
                else begin
                    assign divN = Width6.Iter[idx-1].midIter.divR;
                    assign divR = Width6.Iter[idx-1].midIter.r; 
                end
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = Width6.Iter[idx-1].mqL;
                assign mqL = Width6.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end
            */
        end
    end

    else if (IP_WIDTH==5) begin : Width5
        // Wire and Reg
        wire signed [IP_WIDTH-1:0] mqIter[1:IP_WIDTH];
        wire [IP_WIDTH-1:1] sel;

        for (idx=1; idx<IP_WIDTH+1; idx=idx+1) begin : Iter
            // Wire
            wire [IP_WIDTH-1:0] divN, divR, q, r;
            wire signed [IP_WIDTH-1:0] mqH, mqL, mq;

            if (idx==1) begin : firstIter
                // Div
                assign divN = prime;
                assign divR = number;
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = 'd0;
                assign mqL = 'd1;
                assign mq = -($signed(q));
                assign mqIter[idx] = mq;
            end

            else if (idx==IP_WIDTH) begin : lastIter
                // Div
                assign divN = Width5.Iter[idx-1].divR;
                assign divR = Width5.Iter[idx-1].r; 
                assign q = divN / divR;
                // Mul
                assign mqH = Width5.Iter[idx-1].mqL;
                assign mqL = Width5.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end

            else begin : midIter
                // Div
                assign divN = Width5.Iter[idx-1].divR;
                assign divR = Width5.Iter[idx-1].r; 
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = Width5.Iter[idx-1].mqL;
                assign mqL = Width5.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end
        end
    end

    else begin : Width7
        // Wire and Reg
        wire signed [IP_WIDTH-1:0] mqIter[1:maxIterWidth7];
        wire [maxIterWidth7-1:1] sel;

        for (idx=1; idx<maxIterWidth7+1; idx=idx+1) begin : Iter
            // Wire
            wire [IP_WIDTH-1:0] divN, divR, q, r;
            wire signed [IP_WIDTH-1:0] mqH, mqL, mq;

            if (idx==1) begin : firstIter
                // Div
                assign divN = prime;
                assign divR = number;
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = 'd0;
                assign mqL = 'd1;
                assign mq = -($signed(q));
                assign mqIter[idx] = mq;
            end

            else if (idx==maxIterWidth7) begin : lastIter
                // Div
                assign divN = Width7.Iter[idx-1].divR;
                assign divR = Width7.Iter[idx-1].r; 
                assign q = divN / divR;
                // Mul
                assign mqH = Width7.Iter[idx-1].mqL;
                assign mqL = Width7.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end

            else begin : midIter
                // Div
                assign divN = Width7.Iter[idx-1].divR;
                assign divR = Width7.Iter[idx-1].r; 
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = Width7.Iter[idx-1].mqL;
                assign mqL = Width7.Iter[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end
        end
    end

    // Select which iteration complete calculate
    case (IP_WIDTH)
        5: begin
            always @(*) begin : proc_mqResult
                if (Width5.sel[1]) mqResult = Width5.mqIter[1];
                else begin
                    if (Width5.sel[2]) mqResult = Width5.mqIter[2];
                    else begin
                        if (Width5.sel[3]) mqResult = Width5.mqIter[3];
                        else begin
                            if (Width5.sel[4]) mqResult = Width5.mqIter[4];
                            else mqResult = Width5.mqIter[5];
                        end
                    end
                end
            end
        end

        6: begin
            always @(*) begin : proc_mqResult
                if (Width6.sel[1]) mqResult = Width6.mqIter[1];
                else begin
                    if (Width6.sel[2]) mqResult = Width6.mqIter[2];
                    else begin
                        if (Width6.sel[3]) mqResult = Width6.mqIter[3];
                        else begin
                            if (Width6.sel[4]) mqResult = Width6.mqIter[4];
                            else begin
                                if (Width6.sel[5]) mqResult = Width6.mqIter[5];
                                else mqResult = Width6.mqIter[6];
                            end
                        end
                    end
                end
            end
        end

        default : begin
            always @(*) begin : proc_mqResult
                if (Width7.sel[1]) mqResult = Width7.mqIter[1];
                else begin
                    if (Width7.sel[2]) mqResult = Width7.mqIter[2];
                    else begin
                        if (Width7.sel[3]) mqResult = Width7.mqIter[3];
                        else begin
                            if (Width7.sel[4]) mqResult = Width7.mqIter[4];
                            else begin
                                if (Width7.sel[5]) mqResult = Width7.mqIter[5];
                                else begin
                                    if (Width7.sel[6]) mqResult = Width7.mqIter[6];
                                    else begin
                                        if (Width7.sel[7]) mqResult = Width7.mqIter[7];
                                        else mqResult = Width7.mqIter[8];
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    endcase
    // if Negative -> +Prime
    always @(*) begin : proc_invNum
        if (number=='d1)
           invNum = 'd1;
       else begin
           invNum = (mqResult[IP_WIDTH-1]) ? (mqResult+prime) : mqResult;
       end
    end
    assign OUT_INV = invNum;

endgenerate






/*
generate
    genvar idx;
    // Wire and Reg
    wire [IP_WIDTH-1:0] prime, number;
    reg signed [IP_WIDTH-1:0] mqResult, invNum;

    // Compare input: Big->Prime, Small->Number
    assign prime = (IN_1>IN_2) ? IN_1 : IN_2;
    assign number = (IN_1>IN_2) ? IN_2 : IN_1;

    if (IP_WIDTH==5) begin : width5
        wire [maxIterWidth5-1:1] sel;
        wire signed [IP_WIDTH-1:0] mqIter[1:maxIterWidth5];
        for (idx=1; idx<maxIterWidth5+1; idx=idx+1) begin : Iter5
            // Wire
            wire [IP_WIDTH-1:0] divN, divR, q, r;
            wire signed [IP_WIDTH-1:0] mqH, mqL, mq;

            if (idx==1) begin : i1 // First iteration: set divN, divR ,mqH=0, mqL=1
                // Wire
                //wire [IP_WIDTH-1:0] divN, divR, q, r;
                //wire mqH, mqL;
                // Div
                assign divN = prime;
                assign divR = number;
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = 'd0;
                assign mqL = 'd1;
                assign mq = -($signed(q));
                assign mqIter[idx] = mq;
            end

            else if (idx==maxIterWidth5) begin : iMax// Last iteration: No r(must be 1), No sel
                // Wire
                //wire [IP_WIDTH-1:0] divN, divR, q;
                //wire signed [IP_WIDTH-1:0] mqH, mqL, mq;
                // Div
                assign divN = width5.Iter5[idx-1].divR;
                assign divR = width5.Iter5[idx-1].r;
                assign q = divN / divR;
                // Mul
                assign mqH = width5.Iter5[idx-1].mqL;
                assign mqL = width5.Iter5[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end

            else begin : iter
                // Wire
                //wire [IP_WIDTH-1:0] divN, divR, q, r;
                //wire signed [IP_WIDTH-1:0] mqH, mqL, mq;
                // Div
                assign divN = width5.Iter5[idx-1].divR;
                assign divR = width5.Iter5[idx-1].r;
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = width5.Iter5[idx-1].mqL;
                assign mqL = width5.Iter5[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end
        end //for loop

        // Select which iteration complete calculate
        always @(*) begin : proc_mqResult
            if (sel[1]) mqResult = mqIter[1];
            else begin
                if (sel[2]) mqResult = mqIter[2];
                else begin
                    if (sel[3]) mqResult = mqIter[3];
                    else begin
                        if (sel[4]) mqResult = mqIter[4];
                        else mqResult = mqIter[5];
                    end
                end
            end
        end
    end // if

    else if (IP_WIDTH==6) begin : width6
        wire [maxIterWidth6-1:1] sel;
        wire signed [IP_WIDTH-1:0] mqIter[1:maxIterWidth6];

        for (idx=1; idx<maxIterWidth6+1; idx=idx+1) begin : Iter6
            // Wire
            wire [IP_WIDTH-1:0] divN, divR, q, r;
            wire signed [IP_WIDTH-1:0] mqH, mqL, mq;

            if (idx==1) begin // First iteration: set divN, divR ,mqH=0, mqL=1
                // Wire
                //wire [IP_WIDTH-1:0] divN, divR, q, r;
                //wire mqH, mqL;
                // Div
                assign divN = prime;
                assign divR = number;
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = 'd0;
                assign mqL = 'd1;
                assign mq = -($signed(q));
                assign mqIter[idx] = mq;
            end

            else if (idx==maxIterWidth6) begin // Last iteration: No r(must be 1), No sel
                // Wire
                //wire [IP_WIDTH-1:0] divN, divR, q;
                //wire signed [IP_WIDTH-1:0] mqH, mqL, mq;
                // Div
                assign divN = width6.Iter6[idx-1].divR;
                assign divR = width6.Iter6[idx-1].r;
                assign q = divN / divR;
                // Mul
                assign mqH = width6.Iter6[idx-1].mqL;
                assign mqL = width6.Iter6[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end

            else begin
                // Wire
                //wire [IP_WIDTH-1:0] divN, divR, q, r;
                //wire signed [IP_WIDTH-1:0] mqH, mqL, mq;
                // Div
                assign divN = width6.Iter6[idx-1].divR;
                assign divR = width6.Iter6[idx-1].r;
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = width6.Iter6[idx-1].mqL;
                assign mqL = width6.Iter6[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end
        end // for loop

        // Select which iteration complete calculate
        always @(*) begin : proc_mqResult
            if (sel[1]) mqResult = mqIter[1];
            else begin
                if (sel[2]) mqResult = mqIter[2];
                else begin
                    if (sel[3]) mqResult = mqIter[3];
                    else begin
                        if (sel[4]) mqResult = mqIter[4];
                        else begin
                            if (sel[5]) mqResult = mqIter[5];
                            else mqResult = mqIter[6];
                        end
                    end
                end
            end
        end
    end // if

    else begin : width8
        wire [maxIterWidth7-1:1] sel;
        wire signed [IP_WIDTH-1:0] mqIter[1:maxIterWidth7];
        for (idx=1; idx<maxIterWidth7+1; idx=idx+1) begin : Iter8
            // Wire
            wire [IP_WIDTH-1:0] divN, divR, q, r;
            wire signed [IP_WIDTH-1:0] mqH, mqL, mq;
            
            if (idx==1) begin // First iteration: set divN, divR ,mqH=0, mqL=1
                // Wire
                //wire [IP_WIDTH-1:0] divN, divR, q, r;
                //wire mqH, mqL;
                // Div
                assign divN = prime;
                assign divR = number;
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = 'd0;
                assign mqL = 'd1;
                assign mq = -($signed(q));
                assign mqIter[idx] = mq;
            end

            else if (idx==maxIterWidth7) begin // Last iteration: No r(must be 1), No sel
                // Wire
                //wire [IP_WIDTH-1:0] divN, divR, q;
                //wire signed [IP_WIDTH-1:0] mqH, mqL, mq;
                // Div
                assign divN = width8.Iter8[idx-1].divR;
                assign divR = width8.Iter8[idx-1].r;
                assign q = divN / divR;
                // Mul
                assign mqH = width8.Iter8[idx-1].mqL;
                assign mqL = width8.Iter8[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end

            else begin
                // Wire
                //wire [IP_WIDTH-1:0] divN, divR, q, r;
                //wire signed [IP_WIDTH-1:0] mqH, mqL, mq;
                // Div
                assign divN = width8.Iter8[idx-1].divR;
                assign divR = width8.Iter8[idx-1].r;
                assign q = divN / divR;
                assign r = divN % divR;
                assign sel[idx] = (r=='d1) ? 1'b1 : 1'b0;
                // Mul
                assign mqH = width8.Iter8[idx-1].mqL;
                assign mqL = width8.Iter8[idx-1].mq;
                assign mq = mqH - (mqL * $signed(q));
                assign mqIter[idx] = mq;
            end
        end // for loop

        // Select which iteration complete calculate
        always @(*) begin : proc_mqResult
            if (sel[1]) mqResult = mqIter[1];
            else begin
                if (sel[2]) mqResult = mqIter[2];
                else begin
                    if (sel[3]) mqResult = mqIter[3];
                    else begin
                        if (sel[4]) mqResult = mqIter[4];
                        else begin
                            if (sel[5]) mqResult = mqIter[5];
                            else begin
                                if (sel[6]) mqResult = mqIter[6];
                                else begin
                                    if (sel[7]) mqResult = mqIter[7];
                                    else mqResult = mqIter[8];
                                end
                            end
                        end
                    end
                end
            end
        end
    end // if

    always @(*) begin : proc_invNum
        if (number=='d1)
           invNum = 'd1;
       else begin
           invNum = (mqResult[IP_WIDTH-1]) ? (mqResult+prime) : mqResult;
       end
    end
    assign OUT_INV = invNum;

endgenerate
*/
endmodule