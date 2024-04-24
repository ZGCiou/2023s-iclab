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
parameter S_input = 'd1;
parameter S_cal = 'd2;
parameter S_output = 'd3;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
// FSM
reg  [1:0] currentState, nextState;
reg  [1:0] count;
// SRAM
reg        write[0:255];
reg  [4:0] addr;
wire [7:0] readMatrix[0:255];
reg  [7:0] countElement;
reg  [3:0] countRow, countCol;
reg  [4:0] countMatrix;
// INDATA
reg  [1:0] sizeReg, modeReg;
reg  [4:0] idxReg[0:2];
// CALCULATE
reg  [7:0] aReg[0:255], bReg[0:255];

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
                nextState = S_input;
            else if (in_valid2)
                nextState = S_cal;
            else
                nextState = S_idle;
        end

        S_input: begin
            if (~in_valid)
                nextState = S_idle;
            else
                nextState = S_input;
        end
        /*
        S_cal: begin

        end

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
                if (in_valid2)
                    count <= count + 'd1;
            end

            S_cal: begin
                if (count < 'd3)
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

// dataMatrix, write
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
// countCol
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

            S_input: begin
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
// countRow
always @(posedge clk or negedge rst_n) begin : proc_countRow
    if(~rst_n)
        countRow <= 'd0;
    else begin
        case (currentState)
            S_input: begin
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

            S_input: begin
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
// countMatrix
always @(posedge clk or negedge rst_n) begin : proc_countMatrix
    if(~rst_n)
        countMatrix <= 'd0;
    else begin
        case (currentState)
            S_input: begin
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
// addr
always @(*) begin : proc_addr
    if (in_valid)
        addr = countMatrix;
    else if (in_valid2)
        addr = matrix_idx;
    else if (currentState == S_cal) //use sram data replace reg C
        addr = idxReg[2]; //C
    else
        addr = 'd0;
end

// idxReg
always @(posedge clk) begin : proc_idxMatrix //idxA, idxB not use (v0)
    case (currentState)
        S_idle: begin
            if (in_valid2)
                idxReg[2] <= matrix_idx;
        end

        S_cal: begin
            if (count < 'd3) begin
                idxReg[2] <= matrix_idx;
                idxReg[1] <= idxReg[2];
                idxReg[0] <= idxReg[1];
            end
        end
    endcase
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

//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
// Out Valid
always @(posedge clk or negedge rst_n) begin : proc_out_valid
    if(~rst_n)
        out_valid <= 1'b0;
    else begin
        case (currentState)
            S_output: out_valid = 1'b1;
            default : out_valid = 1'b0;
        endcase
    end
end
// Out
always @(posedge clk or negedge rst_n) begin : proc_out_value
    if(~rst_n)
        out_value <= 'd0;
    else begin
        out_value <= 'd0;
    end
end

endmodule

//---------------------------------------------------------------------
//   SUB MODULE
//---------------------------------------------------------------------
