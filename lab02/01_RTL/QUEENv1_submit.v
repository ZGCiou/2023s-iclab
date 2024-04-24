module QUEEN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    col,
    row,

    in_valid_num,
    in_num,

    out_valid,
    out,

    );

input               clk, rst_n, in_valid,in_valid_num;
input       [3:0]   col,row;
input       [2:0]   in_num;

output reg          out_valid;
output reg  [3:0]   out;

//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter s_idle = 3'd0;
parameter s_input = 3'd1;
parameter s_cal = 3'd2;
parameter s_back = 3'd3;
parameter s_output = 3'd4;

parameter no_position = 4'b1111;
integer i;
//==============================================//
//                 reg declaration              //
//==============================================//
reg [2:0] in_num_r, in_count; //store in_num
reg board[0:11][0:11]; //12*12 matrix, 1->queen 0->null
wire [11:0] atk_check[0:11]; //each column position state: 0->yes, 1->no
wire [11:0] board_col[0:11], board_row[0:11];
reg [11:0] back_map[0:11];

reg  [2:0] current_state, next_state;
reg  [3:0] count;
wire [3:0] current_col, current_row;
reg  [3:0] history_col[0:10], history_row[0:10];
wire [11:0] col_is_put, row_is_put;
wire [11:0] col_not_put, row_not_put, row_not_atk;
reg  [11:0] row_is_atk;
wire [11:0] col_all_atk;
wire complete, back;
wire [1:0] sel_mode;

wire [3:0] queen[0:11]; //the queen's Y position each column
wire [3:0] put_num;

//reg [3:0] in_queen[0:1]; //in_queen[0]= X position, in_queen[1]= Y position

//==============================================//
//            FSM State Declaration             //
//==============================================//
//current_state
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) 
        current_state <= s_idle;
    else 
        current_state <= next_state;
end

//next_state
always @* begin
    case (current_state)
        s_idle: begin 
            if (in_valid) begin
                if (in_num == 3'd1) next_state = s_cal;
                else next_state = s_input;
            end
            else next_state = s_idle;
        end

        s_input:begin
            if (count == in_count) next_state = s_cal;
            else next_state = s_input;
        end

        s_cal: begin
            case (sel_mode) //{commplete,back}
                2'b01: next_state = s_back;
                2'b10: next_state = s_output;
                2'b11: next_state = s_back;
                default : next_state = s_cal;
            endcase
        end

        s_back: begin
            case (back)
                1'b0: next_state = s_cal;
                default : next_state = s_back;
            endcase
        end

        s_output: begin
            if (count == 4'd11) next_state = s_idle;
            else next_state = s_output;
        end

        default : next_state = current_state;
    endcase
end

//count
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        count <= 3'd0;
    else begin
        case (current_state)
            s_idle: count <= 4'd0;

            s_input: begin
                if (count == in_count)
                    count <= 4'd0;
                else
                    count <= count + 4'd1;
            end

            s_cal: count <= 4'd0;

            s_output: begin
                if (count == 4'd11)
                    count <= 4'd0;
                else
                    count <= count + 4'd1;
            end

            default : count <= count;
        endcase
    end
end
//==============================================//
//                  Input Block                 //
//==============================================//
//Store in_num
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)
        in_num_r <= 3'd0;
    else begin
        case (current_state)
            s_idle: if (in_valid_num) in_num_r <= in_num;
            default : in_num_r <= in_num_r;
        endcase
    end
end
always @(*) begin
    in_count = in_num_r - 3'd2;
end
/*
//Store col, row
always @(posedge clk or negedge rst_n) begin : proc_in_queen
    if(~rst_n) begin
        in_queen[0] <= 4'b0;
        in_queen[1] <= 4'b0;
    end else begin
        case (current_state)
            s_idle : begin
                if (in_valid) begin
                    in_queen[0] <= row;
                    in_queen[1] <= col;
                end
            end
            s_input : begin
                if (in_valid) begin
                    in_queen[0] <= row;
                    in_queen[1] <= col;
                end
            end
            default : begin
                in_queen[0] <= 4'b0;
                in_queen[1] <= 4'b0;
            end
        endcase
            
    end
end
*/
//==============================================//
//                Calculate Block               //
//==============================================//

//Board
generate
    genvar row_idx, col_idx;
    for (row_idx=0; row_idx<12; row_idx=row_idx+1) begin : Board_row
        for (col_idx=0; col_idx<12; col_idx=col_idx+1) begin : Board_col
            always @(posedge clk or negedge rst_n) begin : proc_board
                if(~rst_n) begin
                    board[row_idx][col_idx] <= 1'b0;
                end else begin
                    case (current_state)
                        s_idle: begin
                            if (in_valid)
                                if (row_idx == row && col_idx == col)
                                    board[row_idx][col_idx] <= 1'b1;
                        end
                        
                        s_input: begin
                            if (in_valid)
                                if (row_idx == row && col_idx == col)
                                    board[row_idx][col_idx] <= 1'b1;
                        end
                        
                        s_cal: begin
                            if (~back) begin
                                if (col_idx == current_col && row_idx == current_row) begin
                                    board[row_idx][col_idx] <= 1'b1;
                                end
                            end
                            else begin
                                if (col_idx == history_col[0] && row_idx == history_row[0]) begin
                                    board[row_idx][col_idx] <= 1'b0;
                                end
                            end
                        end

                        s_back: begin
                            if (~back) begin
                                if (col_idx == current_col && row_idx == current_row) begin
                                    board[row_idx][col_idx] <= 1'b1;
                                end
                            end
                            else begin
                                if (col_idx == history_col[0] && row_idx == history_row[0]) begin
                                    board[row_idx][col_idx] <= 1'b0;
                                end
                            end
                        end

                        s_output: begin
                            if (count == 4'd11)
                                board[row_idx][col_idx] <= 1'b0;
                        end
                        
                        default : board[row_idx][col_idx] <= board[row_idx][col_idx];
                    endcase
                end
            end
        end
    end
endgenerate

//board_col, board_row, col_is_put, row_is_put
assign board_col[0] = { board[11][0], board[10][0], board[9][0], board[8][0], board[7][0], board[6][0],board[5][0], board[4][0], board[3][0], board[2][0], board[1][0], board[0][0] };
assign board_col[1] = { board[11][1], board[10][1], board[9][1], board[8][1], board[7][1], board[6][1],board[5][1], board[4][1], board[3][1], board[2][1], board[1][1], board[0][1] };
assign board_col[2] = { board[11][2], board[10][2], board[9][2], board[8][2], board[7][2], board[6][2],board[5][2], board[4][2], board[3][2], board[2][2], board[1][2], board[0][2] };
assign board_col[3] = { board[11][3], board[10][3], board[9][3], board[8][3], board[7][3], board[6][3],board[5][3], board[4][3], board[3][3], board[2][3], board[1][3], board[0][3] };
assign board_col[4] = { board[11][4], board[10][4], board[9][4], board[8][4], board[7][4], board[6][4],board[5][4], board[4][4], board[3][4], board[2][4], board[1][4], board[0][4] };
assign board_col[5] = { board[11][5], board[10][5], board[9][5], board[8][5], board[7][5], board[6][5],board[5][5], board[4][5], board[3][5], board[2][5], board[1][5], board[0][5] };
assign board_col[6] = { board[11][6], board[10][6], board[9][6], board[8][6], board[7][6], board[6][6],board[5][6], board[4][6], board[3][6], board[2][6], board[1][6], board[0][6] };
assign board_col[7] = { board[11][7], board[10][7], board[9][7], board[8][7], board[7][7], board[6][7],board[5][7], board[4][7], board[3][7], board[2][7], board[1][7], board[0][7] };
assign board_col[8] = { board[11][8], board[10][8], board[9][8], board[8][8], board[7][8], board[6][8],board[5][8], board[4][8], board[3][8], board[2][8], board[1][8], board[0][8] };
assign board_col[9] = { board[11][9], board[10][9], board[9][9], board[8][9], board[7][9], board[6][9],board[5][9], board[4][9], board[3][9], board[2][9], board[1][9], board[0][9] };
assign board_col[10] = { board[11][10], board[10][10], board[9][10], board[8][10], board[7][10], board[6][10],board[5][10], board[4][10], board[3][10], board[2][10], board[1][10], board[0][10] };
assign board_col[11] = { board[11][11], board[10][11], board[9][11], board[8][11], board[7][11], board[6][11],board[5][11], board[4][11], board[3][11], board[2][11], board[1][11], board[0][11] };

assign board_row[0] = { board[0][11], board[0][10], board[0][9], board[0][8], board[0][7], board[0][6],board[0][5], board[0][4], board[0][3], board[0][2], board[0][1], board[0][0] };
assign board_row[1] = { board[1][11], board[1][10], board[1][9], board[1][8], board[1][7], board[1][6],board[1][5], board[1][4], board[1][3], board[1][2], board[1][1], board[1][0] };
assign board_row[2] = { board[2][11], board[2][10], board[2][9], board[2][8], board[2][7], board[2][6],board[2][5], board[2][4], board[2][3], board[2][2], board[2][1], board[2][0] };
assign board_row[3] = { board[3][11], board[3][10], board[3][9], board[3][8], board[3][7], board[3][6],board[3][5], board[3][4], board[3][3], board[3][2], board[3][1], board[3][0] };
assign board_row[4] = { board[4][11], board[4][10], board[4][9], board[4][8], board[4][7], board[4][6],board[4][5], board[4][4], board[4][3], board[4][2], board[4][1], board[4][0] };
assign board_row[5] = { board[5][11], board[5][10], board[5][9], board[5][8], board[5][7], board[5][6],board[5][5], board[5][4], board[5][3], board[5][2], board[5][1], board[5][0] };
assign board_row[6] = { board[6][11], board[6][10], board[6][9], board[6][8], board[6][7], board[6][6],board[6][5], board[6][4], board[6][3], board[6][2], board[6][1], board[6][0] };
assign board_row[7] = { board[7][11], board[7][10], board[7][9], board[7][8], board[7][7], board[7][6],board[7][5], board[7][4], board[7][3], board[7][2], board[7][1], board[7][0] };
assign board_row[8] = { board[8][11], board[8][10], board[8][9], board[8][8], board[8][7], board[8][6],board[8][5], board[8][4], board[8][3], board[8][2], board[8][1], board[8][0] };
assign board_row[9] = { board[9][11], board[9][10], board[9][9], board[9][8], board[9][7], board[9][6],board[9][5], board[9][4], board[9][3], board[9][2], board[9][1], board[9][0] };
assign board_row[10] = { board[10][11], board[10][10], board[10][9], board[10][8], board[10][7], board[10][6],board[10][5], board[10][4], board[10][3], board[10][2], board[10][1], board[10][0] };
assign board_row[11] = { board[11][11], board[11][10], board[11][9], board[11][8], board[11][7], board[11][6],board[11][5], board[11][4], board[11][3], board[11][2], board[11][1], board[11][0] };

assign col_is_put = { |board_col[11], |board_col[10], |board_col[9], |board_col[8], |board_col[7], |board_col[6], |board_col[5], |board_col[4], |board_col[3], |board_col[2], |board_col[1], |board_col[0] };
assign row_is_put = { |board_row[11], |board_row[10], |board_row[9], |board_row[8], |board_row[7], |board_row[6], |board_row[5], |board_row[4], |board_row[3], |board_row[2], |board_row[1], |board_row[0] };
assign col_not_put = ~col_is_put;
assign row_not_put = ~row_is_put;

//current_col
pirEncode_12to4 COL_SELECT(.in(col_not_put), .out(current_col));
//current_row
always @(*) begin 
    case (current_col)
        4'd0: row_is_atk = atk_check[0] | back_map[0];// | row_is_put;
        4'd1: row_is_atk = atk_check[1] | back_map[1];// | row_is_put;
        4'd2: row_is_atk = atk_check[2] | back_map[2];// | row_is_put;
        4'd3: row_is_atk = atk_check[3] | back_map[3];// | row_is_put;
        4'd4: row_is_atk = atk_check[4] | back_map[4];// | row_is_put;
        4'd5: row_is_atk = atk_check[5] | back_map[5];// | row_is_put;
        4'd6: row_is_atk = atk_check[6] | back_map[6];// | row_is_put;
        4'd7: row_is_atk = atk_check[7] | back_map[7];// | row_is_put;
        4'd8: row_is_atk = atk_check[8] | back_map[8];// | row_is_put;
        4'd9: row_is_atk = atk_check[9] | back_map[9];// | row_is_put;
        4'd10: row_is_atk = atk_check[10] | back_map[10];// | row_is_put;
        4'd11: row_is_atk = atk_check[11] | back_map[11];// | row_is_put;
        default : row_is_atk = 12'b111111111111;
    endcase
end
assign row_not_atk = ~row_is_atk;
pirEncode_12to4 ROW_SELECT(.in(row_not_atk), .out(current_row));

//atk_check
assign atk_check[0] = (board_col[1]<<1) | (board_col[1]>>1) | (board_col[2]<<2) | (board_col[2]>>2) | (board_col[3]<<3) | (board_col[3]>>3)
                     | (board_col[4]<<4) | (board_col[4]>>4) | (board_col[5]<<5) | (board_col[5]>>5) | (board_col[6]<<6) | (board_col[6]>>6)
                     | (board_col[7]<<7) | (board_col[7]>>7) | (board_col[8]<<8) | (board_col[8]>>8) | (board_col[9]<<9) | (board_col[9]>>9)
                     | (board_col[10]<<10) | (board_col[10]>>10) | (board_col[11]<<11) | (board_col[11]>>11) | row_is_put;

assign atk_check[1] = (board_col[0]<<1) | (board_col[0]>>1) | (board_col[2]<<1) | (board_col[2]>>1) | (board_col[3]<<2) | (board_col[3]>>2)
                     | (board_col[4]<<3) | (board_col[4]>>3) | (board_col[5]<<4) | (board_col[5]>>4) | (board_col[6]<<5) | (board_col[6]>>5)
                     | (board_col[7]<<6) | (board_col[7]>>6) | (board_col[8]<<7) | (board_col[8]>>7) | (board_col[9]<<8) | (board_col[9]>>8)
                     | (board_col[10]<<9) | (board_col[10]>>9) | (board_col[11]<<10) | (board_col[11]>>10) | row_is_put;

assign atk_check[2] = (board_col[0]<<2) | (board_col[0]>>2) | (board_col[1]<<1) | (board_col[1]>>1) | (board_col[3]<<1) | (board_col[3]>>1)
                     | (board_col[4]<<2) | (board_col[4]>>2) | (board_col[5]<<3) | (board_col[5]>>3) | (board_col[6]<<4) | (board_col[6]>>4)
                     | (board_col[7]<<5) | (board_col[7]>>5) | (board_col[8]<<6) | (board_col[8]>>6) | (board_col[9]<<7) | (board_col[9]>>7)
                     | (board_col[10]<<8) | (board_col[10]>>8) | (board_col[11]<<9) | (board_col[11]>>9) | row_is_put;

assign atk_check[3] = (board_col[0]<<3) | (board_col[0]>>3) | (board_col[1]<<2) | (board_col[1]>>2) | (board_col[2]<<1) | (board_col[2]>>1)
                     | (board_col[4]<<1) | (board_col[4]>>1) | (board_col[5]<<2) | (board_col[5]>>2) | (board_col[6]<<3) | (board_col[6]>>3)
                     | (board_col[7]<<4) | (board_col[7]>>4) | (board_col[8]<<5) | (board_col[8]>>5) | (board_col[9]<<6) | (board_col[9]>>6)
                     | (board_col[10]<<7) | (board_col[10]>>7) | (board_col[11]<<8) | (board_col[11]>>8) | row_is_put;

assign atk_check[4] = (board_col[0]<<4) | (board_col[0]>>4) | (board_col[1]<<3) | (board_col[1]>>3) | (board_col[2]<<2) | (board_col[2]>>2)
                     | (board_col[3]<<1) | (board_col[3]>>1) | (board_col[5]<<1) | (board_col[5]>>1) | (board_col[6]<<2) | (board_col[6]>>2)
                     | (board_col[7]<<3) | (board_col[7]>>3) | (board_col[8]<<4) | (board_col[8]>>4) | (board_col[9]<<5) | (board_col[9]>>5)
                     | (board_col[10]<<6) | (board_col[10]>>6) | (board_col[11]<<7) | (board_col[11]>>7) | row_is_put;

assign atk_check[5] = (board_col[0]<<5) | (board_col[0]>>5) | (board_col[1]<<4) | (board_col[1]>>4) | (board_col[2]<<3) | (board_col[2]>>3)
                     | (board_col[3]<<2) | (board_col[3]>>2) | (board_col[4]<<1) | (board_col[4]>>1) | (board_col[6]<<1) | (board_col[6]>>1)
                     | (board_col[7]<<2) | (board_col[7]>>2) | (board_col[8]<<3) | (board_col[8]>>3) | (board_col[9]<<4) | (board_col[9]>>4)
                     | (board_col[10]<<5) | (board_col[10]>>5) | (board_col[11]<<6) | (board_col[11]>>6) | row_is_put;

assign atk_check[6] = (board_col[0]<<6) | (board_col[0]>>6) | (board_col[1]<<5) | (board_col[1]>>5) | (board_col[2]<<4) | (board_col[2]>>4)
                     | (board_col[3]<<3) | (board_col[3]>>3) | (board_col[4]<<2) | (board_col[4]>>2) | (board_col[5]<<1) | (board_col[5]>>1)
                     | (board_col[7]<<1) | (board_col[7]>>1) | (board_col[8]<<2) | (board_col[8]>>2) | (board_col[9]<<3) | (board_col[9]>>3)
                     | (board_col[10]<<4) | (board_col[10]>>4) | (board_col[11]<<5) | (board_col[11]>>5) | row_is_put;

assign atk_check[7] = (board_col[0]<<7) | (board_col[0]>>7) | (board_col[1]<<6) | (board_col[1]>>6) | (board_col[2]<<5) | (board_col[2]>>5)
                     | (board_col[3]<<4) | (board_col[3]>>4) | (board_col[4]<<3) | (board_col[4]>>3) | (board_col[5]<<2) | (board_col[5]>>2)
                     | (board_col[6]<<1) | (board_col[6]>>1) | (board_col[8]<<1) | (board_col[8]>>1) | (board_col[9]<<2) | (board_col[9]>>2)
                     | (board_col[10]<<3) | (board_col[10]>>3) | (board_col[11]<<4) | (board_col[11]>>4) | row_is_put;

assign atk_check[8] = (board_col[0]<<8) | (board_col[0]>>8) | (board_col[1]<<7) | (board_col[1]>>7) | (board_col[2]<<6) | (board_col[2]>>6)
                     | (board_col[3]<<5) | (board_col[3]>>5) | (board_col[4]<<4) | (board_col[4]>>4) | (board_col[5]<<3) | (board_col[5]>>3)
                     | (board_col[6]<<2) | (board_col[6]>>2) | (board_col[7]<<1) | (board_col[7]>>1) | (board_col[9]<<1) | (board_col[9]>>1)
                     | (board_col[10]<<2) | (board_col[10]>>2) | (board_col[11]<<3) | (board_col[11]>>3) | row_is_put;

assign atk_check[9] = (board_col[0]<<9) | (board_col[0]>>9) | (board_col[1]<<8) | (board_col[1]>>8) | (board_col[2]<<7) | (board_col[2]>>7)
                     | (board_col[3]<<6) | (board_col[3]>>6) | (board_col[4]<<5) | (board_col[4]>>5) | (board_col[5]<<4) | (board_col[5]>>4)
                     | (board_col[6]<<3) | (board_col[6]>>3) | (board_col[7]<<2) | (board_col[7]>>2) | (board_col[8]<<1) | (board_col[8]>>1)
                     | (board_col[10]<<1) | (board_col[10]>>1) | (board_col[11]<<2) | (board_col[11]>>2) | row_is_put;

assign atk_check[10] = (board_col[0]<<10) | (board_col[0]>>10) | (board_col[1]<<9) | (board_col[1]>>9) | (board_col[2]<<8) | (board_col[2]>>8)
                      | (board_col[3]<<7) | (board_col[3]>>7) | (board_col[4]<<6) | (board_col[4]>>6) | (board_col[5]<<5) | (board_col[5]>>5)
                      | (board_col[6]<<4) | (board_col[6]>>4) | (board_col[7]<<3) | (board_col[7]>>3) | (board_col[8]<<2) | (board_col[8]>>2)
                      | (board_col[9]<<1) | (board_col[9]>>1) | (board_col[11]<<1) | (board_col[11]>>1) | row_is_put;

assign atk_check[11] = (board_col[0]<<11) | (board_col[0]>>11) | (board_col[1]<<10) | (board_col[1]>>10) | (board_col[2]<<9) | (board_col[2]>>9)
                      | (board_col[3]<<8) | (board_col[3]>>8) | (board_col[4]<<7) | (board_col[4]>>7) | (board_col[5]<<6) | (board_col[5]>>6)
                      | (board_col[6]<<5) | (board_col[6]>>5) | (board_col[7]<<4) | (board_col[7]>>4) | (board_col[8]<<3) | (board_col[8]>>3)
                      | (board_col[9]<<2) | (board_col[9]>>2) | (board_col[10]<<1) | (board_col[10]>>1) | row_is_put;

//Complete check
assign put_num = col_is_put[0] + col_is_put[1] + col_is_put[2] + col_is_put[3] + col_is_put[4] + col_is_put[5] + col_is_put[6] + col_is_put[7] + col_is_put[8] + col_is_put[9] + col_is_put[10] + col_is_put[11];
assign complete = (put_num == 4'd11) ? 1'b1 : 1'b0;

//Back check
assign col_all_atk = { &atk_check[11], &atk_check[10], &atk_check[9], &atk_check[8], &atk_check[7], &atk_check[6], &atk_check[5], &atk_check[4], &atk_check[3], &atk_check[2], &atk_check[1], &atk_check[0]} | col_is_put;
assign back = (| (col_is_put ^ col_all_atk)) | &current_row;

//Sel mode (cal or back or out)
assign sel_mode = { complete, back };

/*old code
//queen
generate
    genvar idx;
    for (iodx=0; idx<12; idx=idx+1) begin
        always @(posedge clk or negedge rst_n) begin : proc_queen
            if(~rst_n) begin
                queen[idx] <= 4'b1111; //1111 present haven't put the queen yet
            end else begin
                case (current_state)
                    s_input : begin
                        if (idx == in_queen[1]) 
                            queen[idx] <= in_queen[0];
                    end
                    s_cal : begin
                        ;
                    end
                    default : ;
                endcase
            end
        end
    end
endgenerate

//atk_map
generate
    genvar jdx, kdx;
    for (jdx=0; jdx<12; jdx=jdx+1) begin : atk_map_col
        for (kdx=0; kdx<12; kdx=kdx+1) begin : atk_map_row
            always @* begin
                for (i=0; i<12; i=i+1) begin
                    if (~&queen_row[i]) begin
                        if (queen_row[i] == jdx | queen_row[i]+i == jdx+kdx | $signed(queen_row[i])-i == kdx-jdx) begin
                            atk[jdx][kdx] = 1'b1;
                        end
                        else begin
                            atk[jdx][kdx] = 1'b0;
                        end
                    end
                    else begin
                        atk[jdx][kdx] = 1'b0;
                    end
                end
            end
        end
    end
endgenerate
*/

//GOOD LUCKY
//==============================================//
//                  Back Block                  //
//==============================================//
//History column
always @(posedge clk  or negedge rst_n) begin : proc_history_col
    if(~rst_n) begin
        history_col[0] <= no_position;
        history_col[1] <= no_position;
        history_col[2] <= no_position;
        history_col[3] <= no_position;
        history_col[4] <= no_position;
        history_col[5] <= no_position;
        history_col[6] <= no_position;
        history_col[7] <= no_position;
        history_col[8] <= no_position;
        history_col[9] <= no_position;
        history_col[10] <= no_position;
    end
    else begin
        case (current_state)
            s_cal: begin
                if (~back) begin
                    history_col[0] <= current_col;
                    history_col[1] <= history_col[0];
                    history_col[2] <= history_col[1];
                    history_col[3] <= history_col[2];
                    history_col[4] <= history_col[3];
                    history_col[5] <= history_col[4];
                    history_col[6] <= history_col[5];
                    history_col[7] <= history_col[6];
                    history_col[8] <= history_col[7];
                    history_col[9] <= history_col[8];
                    history_col[10] <= history_col[9];
                end
                else begin
                    history_col[0] <= history_col[1];
                    history_col[1] <= history_col[2];
                    history_col[2] <= history_col[3];
                    history_col[3] <= history_col[4];
                    history_col[4] <= history_col[5];
                    history_col[5] <= history_col[6];
                    history_col[6] <= history_col[7];
                    history_col[7] <= history_col[8];
                    history_col[8] <= history_col[9];
                    history_col[9] <= history_col[10];
                    history_col[10] <= no_position;
                end
            end

            s_back: begin
                if (~back) begin
                    history_col[0] <= current_col;
                    history_col[1] <= history_col[0];
                    history_col[2] <= history_col[1];
                    history_col[3] <= history_col[2];
                    history_col[4] <= history_col[3];
                    history_col[5] <= history_col[4];
                    history_col[6] <= history_col[5];
                    history_col[7] <= history_col[6];
                    history_col[8] <= history_col[7];
                    history_col[9] <= history_col[8];
                    history_col[10] <= history_col[9];
                end
                else begin
                    history_col[0] <= history_col[1];
                    history_col[1] <= history_col[2];
                    history_col[2] <= history_col[3];
                    history_col[3] <= history_col[4];
                    history_col[4] <= history_col[5];
                    history_col[5] <= history_col[6];
                    history_col[6] <= history_col[7];
                    history_col[7] <= history_col[8];
                    history_col[8] <= history_col[9];
                    history_col[9] <= history_col[10];
                    history_col[10] <= no_position;
                end
            end

            s_output: begin
                if (count == 4'd11) begin
                    history_col[0] <= no_position;
                    history_col[1] <= no_position;
                    history_col[2] <= no_position;
                    history_col[3] <= no_position;
                    history_col[4] <= no_position;
                    history_col[5] <= no_position;
                    history_col[6] <= no_position;
                    history_col[7] <= no_position;
                    history_col[8] <= no_position;
                    history_col[9] <= no_position;
                    history_col[10] <= no_position;
                end
            end
        endcase
    end
end
//History row
always @(posedge clk or negedge rst_n) begin : proc_history_row
    if(~rst_n) begin
        history_row[0] <= no_position;
        history_row[1] <= no_position;
        history_row[2] <= no_position;
        history_row[3] <= no_position;
        history_row[4] <= no_position;
        history_row[5] <= no_position;
        history_row[6] <= no_position;
        history_row[7] <= no_position;
        history_row[8] <= no_position;
        history_row[9] <= no_position;
        history_row[10] <= no_position;
    end
    else begin
        case (current_state)
            s_cal: begin
                if (~back) begin
                    history_row[0] <= current_row;
                    history_row[1] <= history_row[0];
                    history_row[2] <= history_row[1];
                    history_row[3] <= history_row[2];
                    history_row[4] <= history_row[3];
                    history_row[5] <= history_row[4];
                    history_row[6] <= history_row[5];
                    history_row[7] <= history_row[6];
                    history_row[8] <= history_row[7];
                    history_row[9] <= history_row[8];
                    history_row[10] <= history_row[9];
                end
                else begin
                    history_row[0] <= history_row[1];
                    history_row[1] <= history_row[2];
                    history_row[2] <= history_row[3];
                    history_row[3] <= history_row[4];
                    history_row[4] <= history_row[5];
                    history_row[5] <= history_row[6];
                    history_row[6] <= history_row[7];
                    history_row[7] <= history_row[8];
                    history_row[8] <= history_row[9];
                    history_row[9] <= history_row[10];
                    history_row[10] <= no_position;
                end
            end

            s_back: begin
                if (~back) begin
                    history_row[0] <= current_row;
                    history_row[1] <= history_row[0];
                    history_row[2] <= history_row[1];
                    history_row[3] <= history_row[2];
                    history_row[4] <= history_row[3];
                    history_row[5] <= history_row[4];
                    history_row[6] <= history_row[5];
                    history_row[7] <= history_row[6];
                    history_row[8] <= history_row[7];
                    history_row[9] <= history_row[8];
                    history_row[10] <= history_row[9];
                end
                else begin
                    history_row[0] <= history_row[1];
                    history_row[1] <= history_row[2];
                    history_row[2] <= history_row[3];
                    history_row[3] <= history_row[4];
                    history_row[4] <= history_row[5];
                    history_row[5] <= history_row[6];
                    history_row[6] <= history_row[7];
                    history_row[7] <= history_row[8];
                    history_row[8] <= history_row[9];
                    history_row[9] <= history_row[10];
                    history_row[10] <= no_position;
                end
            end

            s_output: begin
                if (count == 4'd11) begin
                    history_row[0] <= no_position;
                    history_row[1] <= no_position;
                    history_row[2] <= no_position;
                    history_row[3] <= no_position;
                    history_row[4] <= no_position;
                    history_row[5] <= no_position;
                    history_row[6] <= no_position;
                    history_row[7] <= no_position;
                    history_row[8] <= no_position;
                    history_row[9] <= no_position;
                    history_row[10] <= no_position;
                end
            end
        endcase
    end
end

//Back map
generate
    genvar back_idx;
    for (back_idx=0; back_idx<12; back_idx=back_idx+1) begin
         always @(posedge clk or negedge rst_n) begin : proc_back_map
            if(~rst_n) begin
                back_map[back_idx] <= 12'd0;
            end 
            else begin
                case (current_state)
                    s_cal: begin
                        if (back) begin
                            if (current_col == back_idx) begin
                                if (current_row == no_position)
                                    back_map[back_idx] <= 12'd0; 
                            end

                            if (history_col[0] == back_idx) begin
                                back_map[back_idx][0] <= (history_row[0] == 4'd0) ? 1'b1 : back_map[back_idx][0];
                                back_map[back_idx][1] <= (history_row[0] == 4'd1) ? 1'b1 : back_map[back_idx][1];
                                back_map[back_idx][2] <= (history_row[0] == 4'd2) ? 1'b1 : back_map[back_idx][2];
                                back_map[back_idx][3] <= (history_row[0] == 4'd3) ? 1'b1 : back_map[back_idx][3];
                                back_map[back_idx][4] <= (history_row[0] == 4'd4) ? 1'b1 : back_map[back_idx][4];
                                back_map[back_idx][5] <= (history_row[0] == 4'd5) ? 1'b1 : back_map[back_idx][5];
                                back_map[back_idx][6] <= (history_row[0] == 4'd6) ? 1'b1 : back_map[back_idx][6];
                                back_map[back_idx][7] <= (history_row[0] == 4'd7) ? 1'b1 : back_map[back_idx][7];
                                back_map[back_idx][8] <= (history_row[0] == 4'd8) ? 1'b1 : back_map[back_idx][8];
                                back_map[back_idx][9] <= (history_row[0] == 4'd9) ? 1'b1 : back_map[back_idx][9];
                                back_map[back_idx][10] <= (history_row[0] == 4'd10) ? 1'b1 : back_map[back_idx][10];
                                back_map[back_idx][11] <= (history_row[0] == 4'd11) ? 1'b1 : back_map[back_idx][11];
                            end
                        end
                    end

                    s_back: begin
                        if (back) begin
                            if (current_col == back_idx) begin
                                if (current_row == no_position)
                                    back_map[back_idx] <= 12'd0; 
                            end
                            
                            else if (history_col[0] == back_idx) begin
                                back_map[back_idx][0] <= (history_row[0] == 4'd0) ? 1'b1 : back_map[back_idx][0];
                                back_map[back_idx][1] <= (history_row[0] == 4'd1) ? 1'b1 : back_map[back_idx][1];
                                back_map[back_idx][2] <= (history_row[0] == 4'd2) ? 1'b1 : back_map[back_idx][2];
                                back_map[back_idx][3] <= (history_row[0] == 4'd3) ? 1'b1 : back_map[back_idx][3];
                                back_map[back_idx][4] <= (history_row[0] == 4'd4) ? 1'b1 : back_map[back_idx][4];
                                back_map[back_idx][5] <= (history_row[0] == 4'd5) ? 1'b1 : back_map[back_idx][5];
                                back_map[back_idx][6] <= (history_row[0] == 4'd6) ? 1'b1 : back_map[back_idx][6];
                                back_map[back_idx][7] <= (history_row[0] == 4'd7) ? 1'b1 : back_map[back_idx][7];
                                back_map[back_idx][8] <= (history_row[0] == 4'd8) ? 1'b1 : back_map[back_idx][8];
                                back_map[back_idx][9] <= (history_row[0] == 4'd9) ? 1'b1 : back_map[back_idx][9];
                                back_map[back_idx][10] <= (history_row[0] == 4'd10) ? 1'b1 : back_map[back_idx][10];
                                back_map[back_idx][11] <= (history_row[0] == 4'd11) ? 1'b1 : back_map[back_idx][11];
                                
                            end
                        end
                    end

                    s_output: begin
                        if (count == 4'd11) begin
                            back_map[back_idx] <= 12'd0;
                        end
                    end
                endcase
            end
        end          
    end
endgenerate


//==============================================//
//                  Output Block                //
//==============================================//
//out_vaild
always @(posedge clk or negedge rst_n) begin : proc_out_valid
    if(~rst_n)
        out_valid <= 0;
    else begin
        case (current_state)
            s_output: out_valid <= 1'b1;
            default : out_valid <= 1'b0;
        endcase
    end
end
//queen
pirEncode_12to4 QUEEN_OUT0(.in(board_col[0]), .out(queen[0]));
pirEncode_12to4 QUEEN_OUT1(.in(board_col[1]), .out(queen[1]));
pirEncode_12to4 QUEEN_OUT2(.in(board_col[2]), .out(queen[2]));
pirEncode_12to4 QUEEN_OUT3(.in(board_col[3]), .out(queen[3]));
pirEncode_12to4 QUEEN_OUT4(.in(board_col[4]), .out(queen[4]));
pirEncode_12to4 QUEEN_OUT5(.in(board_col[5]), .out(queen[5]));
pirEncode_12to4 QUEEN_OUT6(.in(board_col[6]), .out(queen[6]));
pirEncode_12to4 QUEEN_OUT7(.in(board_col[7]), .out(queen[7]));
pirEncode_12to4 QUEEN_OUT8(.in(board_col[8]), .out(queen[8]));
pirEncode_12to4 QUEEN_OUT9(.in(board_col[9]), .out(queen[9]));
pirEncode_12to4 QUEEN_OUT10(.in(board_col[10]), .out(queen[10]));
pirEncode_12to4 QUEEN_OUT11(.in(board_col[11]), .out(queen[11]));
//out
always @(posedge clk or negedge rst_n) begin : proc_out
    if(~rst_n) begin
        out <= 4'd0;
    end else begin
        case (current_state)
            s_output: begin
                case (count)
                    4'd0: out <= queen[0];
                    4'd1: out <= queen[1];
                    4'd2: out <= queen[2];
                    4'd3: out <= queen[3];
                    4'd4: out <= queen[4];
                    4'd5: out <= queen[5];
                    4'd6: out <= queen[6];
                    4'd7: out <= queen[7];
                    4'd8: out <= queen[8];
                    4'd9: out <= queen[9];
                    4'd10: out <= queen[10];
                    4'd11: out <= queen[11];
                    default : out <= 4'd0;
                endcase
            end
            default : out <= 4'd0;
        endcase
    end
end

endmodule 

//==============================================//
//                  Sub Module                  //
//==============================================//
module pirEncode_12to4 (
    input [11:0] in,
    output reg [3:0] out
);

    always @* begin
        casez (in)
            12'bzzzzzzzzzzz1: out = 4'd0;
            12'bzzzzzzzzzz10: out = 4'd1;
            12'bzzzzzzzzz100: out = 4'd2;
            12'bzzzzzzzz1000: out = 4'd3;
            12'bzzzzzzz10000: out = 4'd4;
            12'bzzzzzz100000: out = 4'd5;
            12'bzzzzz1000000: out = 4'd6;
            12'bzzzz10000000: out = 4'd7;
            12'bzzz100000000: out = 4'd8;
            12'bzz1000000000: out = 4'd9;
            12'bz10000000000: out = 4'd10;
            12'b100000000000: out = 4'd11;//1011
            default : out = 4'b1111;
        endcase    
    end

endmodule
