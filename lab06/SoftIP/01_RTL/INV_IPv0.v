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


//generate
//    genvar idx, maxIter;
//    case (IP_WIDTH)
//        5: maxIter = maxIterWidth5;
//        6: maxIter = maxIterWidth6;
//        7: maxIter = maxIterWidth7;
//        default : maxIter = maxIterWidth7;
//    endcase
//
//    wire [IP_WIDTH-1:0] prime, number;
//    reg signed [IP_WIDTH-1:0] mqResult, invNum;
//    wire [maxIter-2:0] sel;
//    assign prime = (IN_1>IN_2) ? IN_1 : IN_2;
//    assign number = (IN_1>IN_2) ? IN_2 : IN_1;
//
//    for (idx=1; idx<maxIter+1; idx=idx+1) begin : Iteration
//        if (idx==1) begin
//            wire [IP_WIDTH-1:0] divN, divR, q, r;
//            wire mqH, mqL;
//            wire signed [IP_WIDTH-1:0] mq;
//            /* bit optimization
//            wire [IP_WIDTH-1:0] divR, divN;
//            wire [IP_WIDTH-2:0] q, r;
//            */
//            assign divN = prime;
//            assign divR = number;
//            assign q = divN / divR;
//            assign r = divN % divR;
//            assign sel[idx-1] = (r=='d1) ? 1'b1 : 1'b0;
//
//            assign mqH = 'd0;
//            assign mqL = 'd1;
//            assign mq = -($signed(q));
//
//        end
//        else if (idx==maxIter) begin
//            wire [IP_WIDTH-1:0] divN, divR, q;
//            wire signed [IP_WIDTH-1:0] mqH, mqL, mq;
//            /* bit optimization
//            wire [IP_WIDTH-1:0] divN;
//            wire [IP_WIDTH-i:0] divR, q;
//            */
//            assign divN = Iteration[idx-1].divR;
//            assign divR = Iteration[idx-1].r;
//            assign q = divN / divR;
//
//            assign mqH = Iteration[idx-1].mqL;
//            assign mqL = Iteration[idx-1].mq;
//            assign mq = mqH - (mqL * q);
//        end
//        else begin
//            wire [IP_WIDTH-1:0] divN, divR, q, r;
//            wire signed [IP_WIDTH-1:0] mqH, mqL, mq;
//            /* bit optimization
//            wire [IP_WIDTH-1:0] divN;
//            wire [IP_WIDTH-i:0] divR, q;
//            wire [IP_WIDTH-i-1:0] r;
//            */
//            assign divN = Iteration[idx-1].divR;
//            assign divR = Iteration[idx-1].r;
//            assign q = divN / divR;
//            assign r = divN % divR;
//            assign sel[idx-1] = (r=='d1) ? 1'b1 : 1'b0;
//
//            assign mqH = Iteration[idx-1].mqL;
//            assign mqL = Iteration[idx-1].mq;
//            assign mq = mqH - (mqL * q);
//        end
//    end
//
//    always @(*) begin : proc_mqResult
//        if ()
//    end
//
//endgenerate


endmodule