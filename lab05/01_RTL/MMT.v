module MMT(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [7:0] matrix;
input [1:0]  matrix_size, mode;
input [4:0]  matrix_idx;

output reg       	     out_valid;
output reg signed [49:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter S_idle = 'd0;
parameter S_in1 = 'd1;
parameter S_in2 = 'd2;
parameter S_cal_t = 'd3;
parameter S_cal_nt = 'd4;
parameter S_output = 'd5;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
// FSM
reg  [2:0] currentState, nextState;
reg  [7:0] count;
// SRAM 1
reg        dataWrite;
wire [8:0] dataAddr;
reg  [8:0] dataAddrSram, dataAddrReg;
// SRAM 2
reg        calWrite;
reg  [7:0] calAddr;
reg  signed [19:0] calTemp;
wire signed [19:0] readTemp;
//reg  [8:0] dataAddrSram, dataAddrReg;
//reg  [7:0] countElement;
reg  [3:0] countRow, countCol;
reg  [4:0] countMatrix;
// INDATA
reg in_valid_Reg;
reg  [1:0] sizeReg, modeReg;
reg  [3:0] sizeD;
reg  [4:0] AidxReg, BidxReg, CidxReg;
reg  signed [7:0] inRowBuffer[0:15];
wire [127:0] inRow, readRow;
// CALCULATE
reg  [5:0] countCal, countCalRow, countCalRowD1;
reg  [4:0] countAcc, countAccRow, countAccD1;
reg  completeFlag, completeFlagD1, completeFlagD2, completeFlagD3, accComplete, accCompleteD1, accCompleteD2;
reg uReadFlag, vReadFlag, wReadFlag, uReadFlagD1, vReadFlagD1, vReadFlagD2, vReadFlagD3;
wire [2:0] readSel;
reg  [3:0] uRow, vRow, wRow, vRowD1, vRowD2, vRowD3;
wire [3:0] uRowM;
reg  [8:0] uAddr, vAddr, wAddr;
reg  signed [7:0] uReg[0:15], uCal;
reg  signed [7:0] vData[0:15];
reg  signed [7:0] wReg[0:15];
reg  signed [15:0] pe1PipeReg[0:15];
reg  signed [19:0] pe1Acc[0:15];
reg  signed [19:0] uvAccReg[0:15];
reg  signed [19:0] uvReg, uvCal;
wire signed [19:0] accResult[0:15];
wire signed [16:0] uvPtSum1[0:7];
wire signed [17:0] uvPtSum2[0:3];
wire signed [18:0] uvPtSum3[0:2];
wire signed [19:0] uvDP;
reg  signed [7:0]  wCal;
reg  signed [27:0] pe2PipeReg;
reg  signed [35:0] pe2Acc;

//---------------------------------------------------------------------
//   Finite-State Mechine                                          
//---------------------------------------------------------------------
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
                nextState = S_in1;
            else if (in_valid2) begin
                nextState = S_in2;
                /*
                case (mode)
                    'd1: nextState = S_cal_t;
                    'd2: nextState = S_in2;
                    'd3: nextState = S_in2;
                    default : nextState = S_cal_nt;// mode0
                endcase
                */
            end
            else
                nextState = S_idle;
        end

        S_in1: begin
            if (~in_valid)
                nextState = S_idle;
            else
                nextState = S_in1;
        end

        S_in2: begin
            case (modeReg)
                2'd0: begin
                    if (count == 'd1) nextState = S_cal_nt;
                    else nextState = S_in2;
                end
                /*
                2'd1: begin
                    nextState = S_cal_t;
                end

                2'd2: begin
                    nextState = S_cal_t;
                    
                    //if (count == 'd0) nextState = S_cal_t;
                    //else nextState = S_in2;
                    
                end
                */
                2'd3: begin
                    if (count == 'd1) nextState = S_cal_t;
                    else nextState = S_in2;
                end

                default : nextState = S_cal_t; //mode 1, 2
            endcase
        end
        
        S_cal_t: begin
            if (out_valid)
                nextState = S_idle;
            else
                nextState = S_cal_t;
        end

        S_cal_nt: begin
            if (out_valid)
                nextState = S_idle;
            else
                nextState = S_cal_nt;
        end
        /*
        S_output: begin

        end
        */
        default : nextState = currentState;
    endcase
end
// count
always @(posedge clk or negedge rst_n) begin : proc_count
    if(~rst_n)
        count <= 'd0;
    else begin
        case (currentState)
            
            S_idle: begin
                if (in_valid)
                    count <= count + 'd1;
                else
                    count <= 'd0;
            end
            
            S_in1: begin
                if (nextState != S_in1)
                    count <= 'd0;
                else
                    count <= count + 'd1;
            end

            S_in2: begin
                if (nextState != S_in2)
                    count <= 'd0;
                else
                    count <= count + 'd1;
            end

            
            S_cal_t: begin
                if (nextState != S_cal_t)
                    count <= 'd0;
                else
                    count <= count + 'd1;
            end

            S_cal_nt: begin
                if (nextState != S_cal_nt)
                    count <= 'd0;
                else
                    count <= count + 'd1;
            end
            

            default : count <= 'd0;
        endcase
    end
end

//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
// sizeReg
always @(posedge clk or negedge rst_n) begin : proc_size
    if(~rst_n)
        sizeReg <= 2'd0;
    else begin
        case (currentState)
            S_idle: begin
                if (in_valid)
                    sizeReg <= matrix_size;
            end

        endcase
    end
end
always @(*) begin : proc_sizeD
    case (sizeReg)
        'd1: sizeD = 'd3;
        'd2: sizeD = 'd7;
        'd3: sizeD = 'd15;
        default : sizeD = 'd1;
    endcase
end

// dataMatrix, dataWrite
// inRowBuffer
always @(posedge clk or negedge rst_n) begin : proc_inRowBuffer
    if (!rst_n) begin
        inRowBuffer[0] <= 'd0;
        inRowBuffer[1] <= 'd0;
        inRowBuffer[2] <= 'd0;
        inRowBuffer[3] <= 'd0;
        inRowBuffer[4] <= 'd0;
        inRowBuffer[5] <= 'd0;
        inRowBuffer[6] <= 'd0;
        inRowBuffer[7] <= 'd0;
        inRowBuffer[8] <= 'd0;
        inRowBuffer[9] <= 'd0;
        inRowBuffer[10] <= 'd0;
        inRowBuffer[11] <= 'd0;
        inRowBuffer[12] <= 'd0;
        inRowBuffer[13] <= 'd0;
        inRowBuffer[14] <= 'd0;
        inRowBuffer[15] <= 'd0;
    end
    else begin
        case (currentState)
            S_idle: begin
                if (in_valid)
                    inRowBuffer[countCol] <= matrix;
                else begin
                    inRowBuffer[0] <= 'd0;
                    inRowBuffer[1] <= 'd0;
                    inRowBuffer[2] <= 'd0;
                    inRowBuffer[3] <= 'd0;
                    inRowBuffer[4] <= 'd0;
                    inRowBuffer[5] <= 'd0;
                    inRowBuffer[6] <= 'd0;
                    inRowBuffer[7] <= 'd0;
                    inRowBuffer[8] <= 'd0;
                    inRowBuffer[9] <= 'd0;
                    inRowBuffer[10] <= 'd0;
                    inRowBuffer[11] <= 'd0;
                    inRowBuffer[12] <= 'd0;
                    inRowBuffer[13] <= 'd0;
                    inRowBuffer[14] <= 'd0;
                    inRowBuffer[15] <= 'd0;
                end
            end

            S_in1: begin
                if (in_valid) begin
                    inRowBuffer[countCol] <= matrix;
                end
            end
        endcase
    end
end
assign inRow = {inRowBuffer[0], inRowBuffer[1], inRowBuffer[2], inRowBuffer[3], inRowBuffer[4], inRowBuffer[5], inRowBuffer[6], inRowBuffer[7],
                inRowBuffer[8], inRowBuffer[9], inRowBuffer[10], inRowBuffer[11], inRowBuffer[12], inRowBuffer[13], inRowBuffer[14], inRowBuffer[15]};
// SRAM
RA1SH dataMatrix (.A(dataAddrSram), .D(inRow), .CLK(clk), .CEN(1'b0), .WEN(dataWrite), .OEN(1'b0), .Q(readRow));
// dataAddr
assign dataAddr = {countMatrix, countRow};
// dataAddrReg -> Delay 1 cycle to SRAm
always @(posedge clk or negedge rst_n) begin : proc_dataAddr
    if(~rst_n)
        dataAddrReg <= 'd0;
    else begin
        dataAddrReg <= dataAddr;
    end
end
// readSel
assign readSel = {uReadFlag, vReadFlag, wReadFlag};
// dataAddrSram
always @(*) begin : proc_dataAddrSram
    case (currentState)
        S_idle: begin
            /*
            if (in_valid2) begin
                case (mode)
                    'd0: dataAddrSram = {matrix_idx, 4'd0};
                    'd1: dataAddrSram = {matrix_idx, 4'd0};
                    default : dataAddrSram = 'd0;
                endcase
            end
            else*/
                dataAddrSram = 'd0;
        end

        S_in1: begin
            dataAddrSram = dataAddrReg;
        end

        S_in2: begin
            case (modeReg)
                'd1: dataAddrSram = {AidxReg, 4'd0};
                //'d2: dataAddrSram = {matrix_idx, 4'd0};
                //'d3: dataAddrSram = {matrix_idx, 4'd0};
                default : dataAddrSram = {matrix_idx, 4'd0}; //mode 0, 2, 3
            endcase
            //dataAddrSram = {matrix_idx, 4'd0};
            /*
            case (modeReg[0])
                'd0: dataAddrSram = matrix_idx;// mode 2 -> Read  B first
                default : dataAddrSram = matrix_idx; //mode 3 -> Read C first
            endcase
            */
        end

        S_cal_t: begin
            case (readSel)
                3'b100: dataAddrSram = uAddr;
                3'b010: dataAddrSram = vAddr;
                3'b001: dataAddrSram = wAddr;
                default : dataAddrSram = 'd0;
            endcase
        end
        
        S_cal_nt: begin
            case (readSel)
                3'b100: dataAddrSram = uAddr;
                3'b010: dataAddrSram = vAddr;
                3'b001: dataAddrSram = wAddr;
                default : dataAddrSram = 'd0;
            endcase
        end

        default : dataAddrSram = 'd0;
    endcase
end
// dataWrite
always @(*) begin : proc_dataWrite
    if (in_valid_Reg) begin
        if (countCol == 'd0)
            dataWrite = 1'b0;
        else
            dataWrite = 1'b1;
    end
    else
        dataWrite = 1'b1;
end
// in_valid_Reg
always @(posedge clk or negedge rst_n) begin : proc_in_valid_Reg
    if(~rst_n)
        in_valid_Reg <= 1'b0;
    else begin
        if (in_valid)
            in_valid_Reg <= 1'b1;
        else
            in_valid_Reg <= 1'b0;
    end
end
/*
generate
    genvar bank_idx;
    for (bank_idx=0; bank_idx<255; bank_idx=bank_idx+1) begin : dataMatrix_bank //!!!change to 2D!!!
        RA1SH dataMatrix (.A(addr), .D(matrix), .CLK(clk), .CEN(1'b0), .WEN(write[bank_idx]), .OEN(1'b0), .Q(readMatrix[bank_idx]));
        always @(*) begin : proc_write
            if (in_valid) begin
                if (countElement == bank_idx)
                    write[bank_idx] = 1'b0;
                else
                    write[bank_idx] = 1'b1;
            end
            else
                write[bank_idx] = 1'b1;
        end
    end
endgenerate
*/

// COUNTER
// countCol
always @(*) begin : proc_countCol
    case (currentState)
        S_in1: begin
            case (sizeReg)
                'd1: countCol = count[1:0]; //4*4
                'd2: countCol = count[2:0]; //8*8
                'd3: countCol = count[3:0]; //16*16
                default : countCol = count[0]; //'d0 -> 2*2 -> col=0,1
            endcase
        end
        default : countCol = 'd0;
    endcase
end
/*old
always @(posedge clk or negedge rst_n) begin : proc_countCol
    if(~rst_n)
        countCol <= 'd0;
    else begin
        case (currentState)
            S_idle: begin
                if (in_valid)
                    countCol <= countCol + 1;
                else
                    countCol <= 'd0;
            end

            S_in1: begin
                case (sizeReg)
                    'd0: begin
                        if (countCol == 'd1)
                            countCol <= 'd0;
                        else
                            countCol <= countCol + 'd1;
                    end

                    'd1: begin
                        if (countCol == 'd3)
                            countCol <= 'd0;
                        else
                            countCol <= countCol + 'd1;
                    end

                    'd2: begin
                        if (countCol == 'd7)
                            countCol <= 'd0;
                        else
                            countCol <= countCol + 'd1;
                    end

                    'd3: begin
                        countCol <= countCol + 'd1;
                    end
                endcase
            end
        endcase
    end
end
*/
// countRow
always @(*) begin : proc_countRow
    case (currentState)
        S_in1: begin
            case (sizeReg)
                'd1: countRow = count[3:2]; //4*4
                'd2: countRow = count[5:3]; //8*8
                'd3: countRow = count[7:4]; //16*16
                default : countRow = count[1]; //'d0 -> 2*2 -> col=0,1
            endcase
        end
        default : countRow = 'd0;
    endcase
end
/* old
always @(posedge clk or negedge rst_n) begin : proc_countRow
    if(~rst_n)
        countRow <= 'd0;
    else begin
        case (currentState)
            S_in1: begin
                case (sizeReg)
                    'd0: begin
                        if (countCol == 'd1) begin
                            if (countRow == 'd1)
                                countRow <= 'd0;
                            else
                                countRow <= countRow + 'd1;
                        end
                    end

                    'd1: begin
                        if (countCol == 'd3) begin
                            if (countRow == 'd3)
                                countRow <= 'd0;
                            else
                                countRow <= countRow + 'd1;
                        end
                    end

                    'd2: begin
                        if (countCol == 'd7) begin
                            if (countRow == 'd7)
                                countRow <= 'd0;
                            else
                                countRow <= countRow + 'd1;
                        end
                    end

                    'd3: begin
                        if (countCol == 'd15) begin
                            if (countRow == 'd15)
                                countRow <= 'd0;
                            else
                                countRow <= countRow + 'd1;
                        end
                    end
                endcase
            end
            default : countRow <= 'd0;
        endcase
    end
end
*/
/*
// countElement
always @(posedge clk or negedge rst_n) begin : proc_countElement
    if(~rst_n)
        countElement <= 'd0;
    else begin
        case (currentState)
            S_idle: begin
                if (in_valid)
                    countElement <= countElement + 1;
                else
                    countElement <= 'd0;
            end

            S_in1: begin
                case (sizeReg)
                    'd0: begin
                        if (countElement == 'd3)
                            countElement <= 'd0;
                        else
                            countElement <= countElement + 'd1;
                    end

                    'd1: begin
                        if (countElement == 'd15)
                            countElement <= 'd0;
                        else
                            countElement <= countElement + 'd1;
                    end

                    'd2: begin
                        if (countElement == 'd63)
                            countElement <= 'd0;
                        else
                            countElement <= countElement + 'd1;
                    end

                    'd3: begin
                        countElement <= countElement + 'd1;
                    end
                endcase
            end
        endcase
    end
end
*/
// countMatrix
always @(posedge clk or negedge rst_n) begin : proc_countMatrix
    if(~rst_n)
        countMatrix <= 'd0;
    else begin
        case (currentState)
            S_in1: begin
                case (sizeReg)
                    'd0: begin //2*2
                        if (countCol == 'd1 && countRow == 'd1)
                            countMatrix <= countMatrix + 'd1;
                    end

                    'd1: begin //4*4
                        if (countCol == 'd3 && countRow == 'd3)
                            countMatrix <= countMatrix + 'd1;
                    end

                    'd2: begin //8*8
                        if (countCol == 'd7 && countRow == 'd7)
                            countMatrix <= countMatrix + 'd1;
                    end

                    'd3: begin //16*16
                        if (countCol == 'd15 && countRow == 'd15)
                            countMatrix <= countMatrix + 'd1;
                    end
                endcase
            end
            default : countMatrix <= 'd0;
        endcase
    end
end
/* old
always @(posedge clk or negedge rst_n) begin : proc_countMatrix
    if(~rst_n)
        countMatrix <= 'd0;
    else begin
        case (currentState)
            S_in1: begin
                case (sizeReg)
                    'd0: begin
                        if (countElement == 'd3)
                            countMatrix <= countMatrix + 'd1;
                    end

                    'd1: begin
                        if (countElement == 'd15)
                            countMatrix <= countMatrix + 'd1;
                    end

                    'd2: begin
                        if (countElement == 'd63)
                            countMatrix <= countMatrix + 'd1;
                    end

                    'd3: begin
                        if (countElement == 'd255)
                            countMatrix <= countMatrix + 'd1;
                    end
                endcase
            end
            default : countMatrix <= 'd0;
        endcase
    end
end
*/
// IN DATA 2
// idxReg
always @(posedge clk or negedge rst_n) begin : proc_idxMatrix
    if (~rst_n) begin
        AidxReg <= 5'd0;
        BidxReg <= 5'd0;
        CidxReg <= 5'd0;
    end
    else begin
        case (currentState)
            S_idle: begin
                if (in_valid2)
                    AidxReg <= matrix_idx;
            end

            S_in2: begin
                case (count)
                    'd0: BidxReg <= matrix_idx;
                    'd1: CidxReg <= matrix_idx;
                endcase
            end

            S_cal_t: begin
                case (modeReg)
                    'd1: begin
                        if (in_valid2/*count == 'd0*/)
                            CidxReg <= matrix_idx;
                    end

                    'd2: begin
                        if (in_valid2/*count == 'd0*/)
                            CidxReg <= matrix_idx;
                    end
                endcase
            end
            /*
            S_cal_nt: begin
                if (count == 'd0)
                    CidxReg <= matrix_idx;
            end
            */
        endcase
    end
end
// modeReg
always @(posedge clk or negedge rst_n) begin : proc_modeReg
    if(~rst_n)
        modeReg <= 2'd0;
    else begin
        case (currentState)
            S_idle: begin
                if (in_valid2)
                    modeReg <= mode;
            end
        endcase
    end
end

//---------------------------------------------------------------------
//   Calculate
//---------------------------------------------------------------------
// countCal
always @(posedge clk or negedge rst_n) begin : proc_countCal
    if(~rst_n)
        countCal <= 'd0;
    else begin
        case (currentState)
            S_cal_t: begin
                if (countCal == sizeD + 'd2)
                    countCal <= 'd0;
                else
                    countCal <= countCal + 'd1;
            end

            S_cal_nt: begin
                if (countCal > sizeD)
                    countCal <= 'd0;
                else
                    countCal <= countCal + 'd1;
            end

            default : countCal <= sizeD + 'd2;
        endcase
    end
end
// countCalRow
always @(posedge clk or negedge rst_n) begin : proc_countCalRow
    if(~rst_n)
        countCalRow <= 'd0;
    else begin
        case (currentState)
            S_cal_t: begin
                if (vRow == sizeD)
                    countCalRow <= countCalRow + 'd1;
            end

            S_cal_nt: begin
                if (vRow == sizeD)
                    countCalRow <= countCalRow + 'd1;
            end

            default : countCalRow <= 'd0;
        endcase
    end
end
// countAcc
always @(posedge clk or negedge rst_n) begin : proc_countAcc
    if(~rst_n)
        countAcc <= 'd0;
    else begin
        case (currentState)
            S_cal_nt: begin
                if (countAcc == sizeD + 'd1 || uReadFlagD1)
                    countAcc <= 'd0;
                else if (countCalRowD1 != 'd0)
                    countAcc <= countAcc + 'd1;
            end
            default : countAcc <= 'd0;
        endcase
    end
end
always @(posedge clk or negedge rst_n) begin : proc_countAccD1
    if(~rst_n)
        countAccD1 <= 'd0;
    else begin
        countAccD1 <= countAcc;
    end
end
// countAccRow
always @(posedge clk or negedge rst_n) begin : proc_countAccRow
    if(~rst_n)
        countAccRow <= 'd0;//sizeD;
    else begin
        case (currentState)
            S_cal_nt: begin
                if (countAcc == sizeD && count > 'd3)
                    if (countAccRow == sizeD)
                        countAccRow <= 'd0;
                    else
                        countAccRow <= countAccRow + 'd1;
                /*
                if (uReadFlagD1)
                    if (countAccRow == sizeD)
                        countAccRow = 'd0;
                    else
                        countAccRow <= countAccRow + 'd1;
                */
            end
            default : countAccRow <= 'd0;//sizeD;
        endcase
    end
end
// completeFlag
always @(posedge clk or negedge rst_n) begin : proc_completeFlag
    if(~rst_n) begin
        completeFlag <= 1'b0;
    end 
    else begin
        case (currentState)
            S_cal_t: begin
                if (countCalRow == sizeD && vRow == sizeD)
                    completeFlag <= 1'b1;
                else
                    completeFlag <= 1'b0;
            end
            
            S_cal_nt: begin
                if (accComplete && countAcc == sizeD && countAccRow == sizeD)
                    completeFlag <= 1'b1;
                else
                    completeFlag <= 1'b0;
            end
            
            default: completeFlag <= 1'b0;
        endcase
            
    end
end
// accComplete
always @(posedge clk or negedge rst_n) begin : proc_accComplete
    if(~rst_n)
        accComplete <= 1'b0;
    else begin
        case (currentState)
            S_cal_nt: begin
                if (countAcc == sizeD && countAccRow == sizeD)
                    accComplete <= 1'b1;
            end
            default : accComplete <= 1'b0;
        endcase
    end
end
// uReadFlag
always @(*) begin : proc_uReadFlag
    case (currentState)
        S_cal_nt: begin
            if (countCalRow > sizeD + 'd2)
                uReadFlag = 1'b0;
            else if (countCal == sizeD + 'd1)
                uReadFlag = 1'b1;
            else
                uReadFlag = 1'b0;
                end
        default : begin
            if (countCalRow > sizeD)
                uReadFlag = 1'b0;
            else if (countCal == sizeD + 'd1)
                uReadFlag = 1'b1;
            else
                uReadFlag = 1'b0;
        end
    endcase
end
// vReadFlag
always @(*) begin : proc_vReadFlag
    case (currentState)
        S_cal_nt: begin
            if (countCalRow > sizeD + 'd1)
                vReadFlag = 1'b0;
            else if (~uReadFlag && ~wReadFlag)
                vReadFlag = 1'b1;
            else
                vReadFlag = 1'b0;
        end
        default : begin
            if (countCalRow > sizeD)
                vReadFlag = 1'b0;
            else if (~uReadFlag && ~wReadFlag)
                vReadFlag = 1'b1;
            else
                vReadFlag = 1'b0;
        end
    endcase
end
// wReadFlag
always @(*) begin : proc_wReadFlag
    case (currentState)
        S_cal_nt: begin
            if (accComplete && countAcc == sizeD + 'd1)
                wReadFlag = 1'b1;
            else
                wReadFlag = 1'b0;
        end
        default : begin
            if (countCalRow > sizeD)
                wReadFlag = 1'b0;
            else if (countCal == sizeD + 'd2)
                wReadFlag = 1'b1;
            else
                wReadFlag = 1'b0;
        end
    endcase
end
// uRow
always @(posedge clk or negedge rst_n) begin : proc_uRow
    if(~rst_n)
        uRow <= 'd0;
    else begin
        case (currentState)
            S_cal_t: begin
                if (uRow == sizeD)
                    uRow <= uRow;
                else if (vRow == sizeD)
                    uRow <= uRow + 'd1;
            end

            S_cal_nt: begin
                if (uRow == sizeD)
                    uRow <= uRow;
                else if (vRow == sizeD)
                    uRow <= uRow + 'd1;
            end
            default : uRow <= 'd0;
        endcase
    end
end
// vRow
always @(*) begin : proc_vRow
    if (countCal < sizeD + 'd1)
        vRow = countCal;
    else
        vRow = 'd0;
end
// wRow
always @(*) begin : proc_wRow
    case (currentState)
        S_cal_t: begin
            wRow = uRow;
        end

        S_cal_nt: begin
            if (~accComplete)
                wRow = 'd0;
            else begin
                wRow = uRow;
            end
        end
        default : wRow = 'd0;
    endcase
end
// uAddr
always @(*) begin : proc_uAddr
    case (currentState)
        S_cal_t: begin
            case (modeReg)
                'd1: uAddr = {AidxReg, uRow};
                'd2: uAddr = {BidxReg, uRow};
                default : uAddr = {CidxReg, uRow}; //'d3
            endcase
        end

        S_cal_nt: begin
            uAddr = {CidxReg, uRow};
        end
        default : uAddr = 'd0;
    endcase
end
// vAddr
always @(*) begin : proc_vAddr
    case (currentState)
        S_cal_t: begin
            case (modeReg)
                'd1: vAddr = {CidxReg, vRow};
                'd2: vAddr = {AidxReg, vRow};
                default : vAddr = {BidxReg, vRow}; //'d3
            endcase
        end

        S_cal_nt: begin
            vAddr = {AidxReg, vRow};
        end
        default : vAddr = 'd0;
    endcase
end
// wAddr
always @(*) begin : proc_wAddr
    case (currentState)
        S_cal_t: begin
            case (modeReg)
                'd1: wAddr = {BidxReg, wRow};
                'd2: begin 
                    if (count == 'd0)
                        wAddr = {matrix_idx, wRow};
                    else
                        wAddr = {CidxReg, wRow};
                end
                default : wAddr = {AidxReg, wRow}; //'d3
            endcase
        end

        S_cal_nt: begin
            wAddr = {BidxReg, countAccRow[3:0]};
        end
        default : wAddr = 'd0;
    endcase
end
// uReg
always @(posedge clk or negedge rst_n) begin : proc_uReg
    if(~rst_n) begin
        uReg[0] <= 0;
        uReg[1] <= 0;
        uReg[2] <= 0;
        uReg[3] <= 0;
        uReg[4] <= 0;
        uReg[5] <= 0;
        uReg[6] <= 0;
        uReg[7] <= 0;
        uReg[8] <= 0;
        uReg[9] <= 0;
        uReg[10] <= 0;
        uReg[11] <= 0;
        uReg[12] <= 0;
        uReg[13] <= 0;
        uReg[14] <= 0;
        uReg[15] <= 0;
    end 
    else begin
        case (currentState)
            S_cal_t: begin
                if (wReadFlag) begin // wReadFlag -> Delay 1 cycle to uReadFalg
                    uReg[0] <= readRow[127:120];
                    uReg[1] <= readRow[119:112];
                    uReg[2] <= readRow[111:104];
                    uReg[3] <= readRow[103:96];
                    uReg[4] <= readRow[95:88];
                    uReg[5] <= readRow[87:80];
                    uReg[6] <= readRow[79:72];
                    uReg[7] <= readRow[71:64];
                    uReg[8] <= readRow[63:56];
                    uReg[9] <= readRow[55:48];
                    uReg[10] <= readRow[47:40];
                    uReg[11] <= readRow[39:32];
                    uReg[12] <= readRow[31:24];
                    uReg[13] <= readRow[23:16];
                    uReg[14] <= readRow[15:8];
                    uReg[15] <= readRow[7:0];
                end
            end

            S_cal_nt: begin
                if (uReadFlagD1 || count == 'd0) begin // wReadFlag -> Delay 1 cycle to uReadFalg
                    uReg[0] <= readRow[127:120];
                    uReg[1] <= readRow[119:112];
                    uReg[2] <= readRow[111:104];
                    uReg[3] <= readRow[103:96];
                    uReg[4] <= readRow[95:88];
                    uReg[5] <= readRow[87:80];
                    uReg[6] <= readRow[79:72];
                    uReg[7] <= readRow[71:64];
                    uReg[8] <= readRow[63:56];
                    uReg[9] <= readRow[55:48];
                    uReg[10] <= readRow[47:40];
                    uReg[11] <= readRow[39:32];
                    uReg[12] <= readRow[31:24];
                    uReg[13] <= readRow[23:16];
                    uReg[14] <= readRow[15:8];
                    uReg[15] <= readRow[7:0];
                end
            end

            default: begin
                uReg[0] <= 0;
                uReg[1] <= 0;
                uReg[2] <= 0;
                uReg[3] <= 0;
                uReg[4] <= 0;
                uReg[5] <= 0;
                uReg[6] <= 0;
                uReg[7] <= 0;
                uReg[8] <= 0;
                uReg[9] <= 0;
                uReg[10] <= 0;
                uReg[11] <= 0;
                uReg[12] <= 0;
                uReg[13] <= 0;
                uReg[14] <= 0;
                uReg[15] <= 0;
            end
        endcase
    end
end
// wReg
always @(posedge clk or negedge rst_n) begin : proc_wReg
    if(~rst_n) begin
        wReg[0] <= 0;
        wReg[1] <= 0;
        wReg[2] <= 0;
        wReg[3] <= 0;
        wReg[4] <= 0;
        wReg[5] <= 0;
        wReg[6] <= 0;
        wReg[7] <= 0;
        wReg[8] <= 0;
        wReg[9] <= 0;
        wReg[10] <= 0;
        wReg[11] <= 0;
        wReg[12] <= 0;
        wReg[13] <= 0;
        wReg[14] <= 0;
        wReg[15] <= 0;
    end 
    else begin
        case (currentState)
            S_cal_t: begin
                if (countCal == 'd0) begin // countCal=0 -> Delay 1 cycle to wReadFalg
                    wReg[0] <= readRow[127:120];
                    wReg[1] <= readRow[119:112];
                    wReg[2] <= readRow[111:104];
                    wReg[3] <= readRow[103:96];
                    wReg[4] <= readRow[95:88];
                    wReg[5] <= readRow[87:80];
                    wReg[6] <= readRow[79:72];
                    wReg[7] <= readRow[71:64];
                    wReg[8] <= readRow[63:56];
                    wReg[9] <= readRow[55:48];
                    wReg[10] <= readRow[47:40];
                    wReg[11] <= readRow[39:32];
                    wReg[12] <= readRow[31:24];
                    wReg[13] <= readRow[23:16];
                    wReg[14] <= readRow[15:8];
                    wReg[15] <= readRow[7:0];
                end
            end

            S_cal_nt: begin
                if (countAcc == 'd0) begin // countAcc=0 -> Delay 1 cycle to wReadFalg
                    wReg[0] <= readRow[127:120];
                    wReg[1] <= readRow[119:112];
                    wReg[2] <= readRow[111:104];
                    wReg[3] <= readRow[103:96];
                    wReg[4] <= readRow[95:88];
                    wReg[5] <= readRow[87:80];
                    wReg[6] <= readRow[79:72];
                    wReg[7] <= readRow[71:64];
                    wReg[8] <= readRow[63:56];
                    wReg[9] <= readRow[55:48];
                    wReg[10] <= readRow[47:40];
                    wReg[11] <= readRow[39:32];
                    wReg[12] <= readRow[31:24];
                    wReg[13] <= readRow[23:16];
                    wReg[14] <= readRow[15:8];
                    wReg[15] <= readRow[7:0];
                end
            end
        endcase
    end
end


// PE1
// Stage 1
// uCal
always @(*) begin : proc_uCal
    if (countCal != 'd0)
        uCal = uReg[vRowD1];
    else
        uCal = 'd0;
end
generate
    genvar PE_idx;
    for (PE_idx=0; PE_idx<16; PE_idx=PE_idx+1) begin : PE1
        //pe1PipeReg
        always @(posedge clk or negedge rst_n) begin : proc_pe1PipeReg
            if(~rst_n)
                pe1PipeReg[PE_idx] <= 'd0;
            else begin
                case (currentState)
                    S_cal_t: begin
                        pe1PipeReg[PE_idx] <= uReg[PE_idx] * vData[PE_idx];
                    end

                    S_cal_nt: begin
                        pe1PipeReg[PE_idx] <= uCal/*uReg[PE_idx]*/ * vData[PE_idx];
                    end
                    default: pe1PipeReg[PE_idx] <= 'd0;
                endcase
            end
        end
        always @(*) begin : proc_vData
            case (currentState)
                S_cal_t: begin
                    if (vReadFlagD1)
                        vData[PE_idx] = readRow[ 127-PE_idx*8 : 120-PE_idx*8];
                    else
                        vData[PE_idx] = 'd0;
                end

                S_cal_nt: begin
                    if (vReadFlagD1)
                        vData[PE_idx] = readRow[ 127-PE_idx*8 : 120-PE_idx*8];
                    else
                        vData[PE_idx] = 'd0;
                end
                default : vData[PE_idx] = 'd0;
            endcase
        end
        
        // Stage 2 -> uvAccReg
        always @(posedge clk or negedge rst_n) begin : proc_uvAccReg
            if(~rst_n)
                uvAccReg[PE_idx] <= 'd0;
            else begin
                case (currentState)
                    S_cal_nt: begin
                        if (uReadFlagD1) //Delay 2 cycle
                            uvAccReg[PE_idx] <= accResult[PE_idx];
                    end
                endcase
            end
        end
        
        assign accResult[PE_idx] = pe1PipeReg[PE_idx] + pe1Acc[PE_idx];
        // pe1Acc -> CAl_NT
        always @(posedge clk or negedge rst_n) begin : proc_pe1Acc
            if(~rst_n)
                pe1Acc[PE_idx] <= 'd0;
            else begin
                case (currentState)
                    S_cal_nt: begin
                        if (~vReadFlagD1) //delay 2 cycle
                            pe1Acc[PE_idx] <= 'd0;
                        else
                            pe1Acc[PE_idx] <= accResult[PE_idx];
                    end
                    default : pe1Acc[PE_idx] <= 'd0;
                endcase    
            end
        end
    end
endgenerate
RA1SH3 calMatrix(.A(calAddr), .D(calTemp), .CLK(clk), .CEN(1'b0), .WEN(calWrite), .OEN(1'b0), .Q(readTemp));
// calTemp
always @(*) begin : proc_calTemp
    case (currentState)
        S_cal_nt: begin
            if (~uReadFlagD1/* && ~accComplete*/)
                calTemp = uvAccReg[countAcc[3:0]];
            else
                calTemp = 'd0;
        end
        default : calTemp = 'd0;
    endcase
end
// calWrite
always @(*) begin : proc_calWrite
    case (currentState)
        S_cal_nt: begin
            calWrite = uReadFlagD1 || accComplete;
        end
        default : calWrite = 1'b1;
    endcase    
end
// calAddr
//assign uRowM = uRow - 'd1;
always @(*) begin : proc_calAddr
    if (accComplete)
        calAddr = {countAccRow[3:0], countAcc[3:0]};
    else
        calAddr = {countAcc[3:0], countAccRow[3:0]};
end

// Stage 2
assign uvPtSum1[0] = pe1PipeReg[0] + pe1PipeReg[1];
assign uvPtSum1[1] = pe1PipeReg[2] + pe1PipeReg[3];
assign uvPtSum1[2] = pe1PipeReg[4] + pe1PipeReg[5];
assign uvPtSum1[3] = pe1PipeReg[6] + pe1PipeReg[7];
assign uvPtSum1[4] = pe1PipeReg[8] + pe1PipeReg[9];
assign uvPtSum1[5] = pe1PipeReg[10] + pe1PipeReg[11];
assign uvPtSum1[6] = pe1PipeReg[12] + pe1PipeReg[13];
assign uvPtSum1[7] = pe1PipeReg[14] + pe1PipeReg[15];

assign uvPtSum2[0] = uvPtSum1[0] + uvPtSum1[1];
assign uvPtSum2[1] = uvPtSum1[2] + uvPtSum1[3];
assign uvPtSum2[2] = uvPtSum1[4] + uvPtSum1[5];
assign uvPtSum2[3] = uvPtSum1[6] + uvPtSum1[7];

assign uvPtSum3[0] = uvPtSum2[0] + uvPtSum2[1];
assign uvPtSum3[1] = uvPtSum2[2] + uvPtSum2[3];

assign uvDP = uvPtSum3[0] + uvPtSum3[1];

// uvReg
always @(posedge clk or negedge rst_n) begin : proc_uvReg
    if(~rst_n)
        uvReg <= 'd0;
    else begin
        case (currentState)
            S_cal_t: uvReg <= uvDP;
            default : uvReg <= 'd0;
        endcase    
    end
end
/*
generate
    genvar uv_idx;
    for (uv_idx=0; uv_idx<16; uv_idx=uv_idx+1) begin
        always @(posedge clk or negedge rst_n) begin : proc_uvReg
            if(~rst_n)
                uvReg[uv_idx] <= 'd0;
            else begin
                case (currentState)
                    S_cal_t: begin
                        if (count == uv_idx)    
                            uvReg[uv_idx] <= uvDP;
                    end

                    default : uvReg[uv_idx] <= 'd0;
                endcase                  
            end
        end
    end
endgenerate
*/
// PE2
// Stage 3
// vRowDelay, vReadFlagDelay
always @(posedge clk or negedge rst_n) begin : proc_vD
    if(~rst_n) begin
        vRowD1 <= 'd0;
        vRowD2 <= 'd0;
        vRowD3 <= 'd0;
        uReadFlagD1 <= 'd0;
        vReadFlagD1 <= 'd0;
        vReadFlagD2 <= 'd0;
        vReadFlagD3 <= 'd0;
        accCompleteD1 <= 'd0;
        accCompleteD2 <= 'd0;
        countCalRowD1 <= 'd0;
    end 
    else begin
        vRowD1 <= vRow;
        vRowD2 <= vRowD1;
        vRowD3 <= vRowD2;
        uReadFlagD1 <= uReadFlag;
        vReadFlagD1 <= vReadFlag;
        vReadFlagD2 <= vReadFlagD1;
        vReadFlagD3 <= vReadFlagD2;
        accCompleteD1 <= accComplete;
        accCompleteD2 <= accCompleteD1;
        countCalRowD1 <= countCalRow;
    end
end
// wCal
always @(*) begin : proc_wCal
    case (currentState)
        S_cal_t: begin
            if (vReadFlagD3)
                wCal = wReg[vRowD3];
            else
                wCal = 'd0;
        end

        S_cal_nt: begin
            if (countAcc != 'd0 && accCompleteD2)
                wCal = wReg[countAccD1[3:0]];
            else
                wCal = 'd0;
        end

        default : wCal = 'd0;
    endcase
        
end
//pe2PipeReg
always @(posedge clk or negedge rst_n) begin : proc_pe2PipeReg
    if(~rst_n)
        pe2PipeReg <= 'd0;
    else begin
        case (currentState)
            S_cal_t: begin
                pe2PipeReg <= uvReg * wCal;
            end

            S_cal_nt: begin
                pe2PipeReg <= uvCal * wCal;
            end
            default : pe2PipeReg <= 'd0;
        endcase
    end
end
// uvCal
always @(*) begin : proc_uvCal
    case (currentState)
        S_cal_nt: begin
            if (countAcc != 'd0)
                uvCal = readTemp;
            else
                uvCal = 'd0;
        end
        default : uvCal = 'd0;
    endcase
end


// Stage 4
// pe2Acc
always @(posedge clk or negedge rst_n) begin : proc_pe2Acc
    if(~rst_n)
        pe2Acc <= 'd0;
    else begin
        case (currentState)
            S_cal_t: pe2Acc <= pe2Acc + pe2PipeReg;
            S_cal_nt: pe2Acc <= pe2Acc + pe2PipeReg;
            default : pe2Acc <= 'd0;
        endcase    
    end
end
// completeFlagDelay
always @(posedge clk or negedge rst_n) begin : proc_completeFlagD
    if(~rst_n) begin
        completeFlagD1 <= 1'b0;
        completeFlagD2 <= 1'b0;
        completeFlagD3 <= 1'b0;
    end 
    else begin
        completeFlagD1 <= completeFlag;
        completeFlagD2 <= completeFlagD1;
        completeFlagD3 <= completeFlagD2;
    end
end

//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
// Out Valid
always @(posedge clk or negedge rst_n) begin : proc_out_valid
    if(~rst_n)
        out_valid <= 1'b0;
    else begin
        case (currentState)
            S_cal_t: out_valid <= completeFlagD3;
            S_cal_nt: out_valid <= completeFlagD1;
        endcase
            //out_valid <= completeFlagD3;
    end
end
// Out
always @(*) begin : proc_out_value
    if(~out_valid)
        out_value <= 'd0;
    else begin
        out_value <= pe2Acc;
    end
end

endmodule

//---------------------------------------------------------------------
//   SUB MODULE
//---------------------------------------------------------------------
