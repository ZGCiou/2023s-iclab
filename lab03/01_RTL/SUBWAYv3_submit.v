module SUBWAY(
    //Input Port
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    //Output Port
    out_valid,
    out
);


input clk, rst_n;
input in_valid;
input [1:0] init;
input [1:0] in0, in1, in2, in3; 
output reg       out_valid;
output reg [1:0] out;


//==============================================//
//       parameter & integer declaration        //
//==============================================//
//parameter s_idle = 2'd0;
parameter s_input = 1'b0; //2'd1;
//parameter s_cal = 2'd2;
parameter s_output = 1'b1; //2'd3;

//==============================================//
//           reg & wire declaration             //
//==============================================//
// FSM
reg  [1:0] current_state, next_state;
reg  [5:0] count;
// Input
reg  [1:0] in [0:3]; //Bundle in0~in3
// Calculate data
reg  [1:0] map_block [0:3][0:3];
reg  [3:0] start_position_4b;//, target_position;
reg  [3:0] target_position_4b;
wire       is_train_block/*block_style*/, block_end;
wire [3:0] init_decode, possible_target, keep;
wire [3:0] l1, l2, l3, r1, r2, r3;
reg  [2:0] step_type;
reg  [1:0] step1, step2, step3, step4;
wire [3:0] data_step2, data_step4;
//reg  [3:0] data_step4;
reg  [1:0] move_history [0:62];

//==============================================//
//                  design                      //
//==============================================//
//------------------------------//
// FSM
//------------------------------// 
// current state
always @(posedge clk or negedge rst_n) begin : proc_current_state
    if(~rst_n)
        current_state <= s_input;
    else
        current_state <= next_state;
end
// next state
always @(*) begin : proc_next_state
    case (current_state)
        s_input: begin
            if (count == 63)
                next_state = s_output;
            else
                next_state = s_input;
        end

        s_output:begin
            if (count == 62)
                next_state = s_input;
            else
                next_state = s_output;
        end

        default : next_state = current_state;
    endcase
end
// count
always @(posedge clk or negedge rst_n) begin : proc_count
    if(~rst_n)
        count <= 0;
    else begin
        case (current_state)
            s_input: begin
                if (count == 63)
                    count <= 6'd0;
                else if (in_valid)
                    count <= count + 1;
            end

            s_output: begin
                if (count == 62)
                    count <= 6'd0;
                else
                    count <= count + 1;
            end
        endcase
    end
end


//------------------------------//
// INPUT
//------------------------------//
// Map (4*4 block)
// Shift Register

always @* begin //v2: use in_valid to avoid input x
    if (in_valid) begin
        in[0] = in0;
        in[1] = in1;
        in[2] = in2;
        in[3] = in3;
    end
    else begin
        in[0] = 2'b0;
        in[1] = 2'b0;
        in[2] = 2'b0;
        in[3] = 2'b0;
    end
end

/*
assign in[0] = in0;
assign in[1] = in1;
assign in[2] = in2;
assign in[3] = in3;
*/
/*
generate
    genvar rowidx_map;
    for (rowidx_map=0; rowidx_map<4; rowidx_map=rowidx_map+1) begin : map_block_row
        always @(posedge clk) begin
            case (current_state)
                s_input: begin
                    if (in_valid) begin
                        map_block[rowidx_map][3] <= in[rowidx_map];
                        map_block[rowidx_map][2] <= map_block[rowidx_map][3];
                        map_block[rowidx_map][1] <= map_block[rowidx_map][2];
                        map_block[rowidx_map][0] <= map_block[rowidx_map][1];
                    end
                    else begin
                        map_block[rowidx_map][3] <= 2'd0;
                        map_block[rowidx_map][2] <= 2'd0;
                        map_block[rowidx_map][1] <= 2'd0;
                        map_block[rowidx_map][0] <= 2'd0;
                    end
                end
            endcase
        end
    end
endgenerate
*/
generate
    genvar rowidx_map;
    for (rowidx_map=0; rowidx_map<4; rowidx_map=rowidx_map+1) begin : map_block_row
        always @(posedge clk) begin //v3: remove unnecessary control
            map_block[rowidx_map][3] <= in[rowidx_map];
            map_block[rowidx_map][2] <= map_block[rowidx_map][3];
            map_block[rowidx_map][1] <= map_block[rowidx_map][2];
            map_block[rowidx_map][0] <= map_block[rowidx_map][1];
        end
    end
endgenerate


//------------------------------//
// CALCULATE
//------------------------------//
// Start position (input init at first cycle)
decoder_2to4 INIT(.in(init), .out(init_decode));
always @(posedge clk) begin : proc_start_position //v3: remove rst_n
    case (current_state) //remove current_state -> area increase??
        s_input: begin
            if (count == 6'd0 && in_valid == 1'b1)
                start_position_4b <= init_decode;
            else 
                start_position_4b <= (block_end) ? target_position_4b : start_position_4b;
        end
    endcase
end
/*
always @(posedge clk or negedge rst_n) begin : proc_start_position
    if(~rst_n)
        start_position <= 2'b0;
    else begin
        case (current_state)
            s_input: begin
                if (count == 6'd0 && in_valid == 1'b1)
                    start_position <= init;
                else
                    start_position <= start_position;
            end
        endcase
    end
end

// Start position encode
decoder_2to4 START_POS(.in(start_position), .out(start_position_decode));
*/
// Possible target
assign possible_target = ~{in[3][0], in[2][0], in[1][0], in[0][0]}; //v2: fix input x

// Target position, Step type //v3: use reduction or |
assign keep = |(possible_target & start_position_4b);
assign l1 = |(possible_target & (start_position_4b << 1));
assign r1 = |(possible_target & (start_position_4b >> 1));
assign l2 = |(possible_target & (start_position_4b << 2));
assign r2 = |(possible_target & (start_position_4b >> 2));
assign l3 = |(possible_target & (start_position_4b << 3));
assign r3 = |(possible_target & (start_position_4b >> 3));
always @* begin
    if (is_train_block) begin
        target_position_4b = start_position_4b;
        step_type = 3'd0;
    end
    else begin
        if (keep) begin
            target_position_4b = start_position_4b;
            step_type = 3'd0;
        end
        else begin
            if (l1) begin
                target_position_4b = start_position_4b << 1;
                step_type = 3'd1;
            end
            else if (r1) begin
                target_position_4b = start_position_4b >> 1;
                step_type = 3'd2;
            end
            else if (l2) begin
                target_position_4b = start_position_4b << 2;
                step_type = 3'd3;
            end
            else if (r2) begin
                target_position_4b = start_position_4b >> 2;
                step_type = 3'd4;
            end
            else if (l3) begin
                target_position_4b = start_position_4b << 3;
                step_type = 3'd5;
            end
            else if (r3) begin
                target_position_4b = start_position_4b >> 3;
                step_type = 3'd6;
            end
            else begin
                target_position_4b = start_position_4b; //last block
                step_type = 3'd0;
            end
        end
    end
end
// Block style (train or obstcale)
assign is_train_block = count[2]; // 1->train block, 0->obstacle block
assign block_end = ~|count[1:0];

// Step
assign data_step2 = {map_block[3][2][0], map_block[2][2][0], map_block[1][2][0], map_block[0][2][0]};
assign data_step4 = {in[3][0], in[2][0], in[1][0], in[0][0]}; //v3: use continuios assign (remove condictiion statement "current_state")
/*
always @(*) begin
    case (current_state)
        s_input: data_step4 = {in[3][0], in[2][0], in[1][0], in[0][0]};
        default : data_step4 = 4'b0;
    endcase
end
*/
always @(*) begin : proc_step
    case (step_type)
        3'd0: begin //forward
            step1 = 2'd0;
            step2 = (|(data_step2 & start_position_4b)) ? 2'd3 : 2'd0;
            step3 = 2'd0;
            step4 = (|(data_step4 & start_position_4b)) ? 2'd3 : 2'd0;
        end
        3'd1: begin //<<1 -> right 1
            step1 = 2'd1;
            step2 = (|(data_step2 & (start_position_4b<<1))) ? 2'd3 : 2'd0;
            step3 = 2'd0;
            step4 = 2'd0;//(|(data_step4 & (start_position_4b<<1))) ? 2'd3 : 2'd0;
        end
        3'd2: begin //>>1 -> left 1
            step1 = 2'd2;
            step2 = (|(data_step2 & (start_position_4b>>1))) ? 2'd3 : 2'd0;
            step3 = 2'd0;
            step4 = 2'd0;//(|(data_step4 & (start_position_4b>>1))) ? 2'd3 : 2'd0;
        end
        3'd3: begin //<<2 -> right 2
            step1 = 2'd1;
            step2 = (|(data_step2 & (start_position_4b<<1))) ? 2'd3 : 2'd0;
            step3 = 2'd1;
            step4 = 2'd0;//(|(data_step4 & (start_position_4b<<2))) ? 2'd3 : 2'd0;
        end
        3'd4: begin //>>2 -> left 2
            step1 = 2'd2;
            step2 = (|(data_step2 & (start_position_4b>>1))) ? 2'd3 : 2'd0;
            step3 = 2'd2;
            step4 = 2'd0;//(|(data_step4 & (start_position_4b>>2))) ? 2'd3 : 2'd0;
        end
        3'd5: begin //<<3 -> right 3
            step1 = 2'd1;
            step2 = (|(data_step2 & (start_position_4b<<1))) ? 2'd3 : 2'd0;
            step3 = 2'd1;
            step4 = 2'd1;//(|(data_step4 & (start_position_4b<<3))) ? 2'd3 : 2'd0;
        end
        //3'd6: 
        default : begin //>>3 -> left 3
            step1 = 2'd2;
            step2 = (|(data_step2 & (start_position_4b>>1))) ? 2'd3 : 2'd0;
            step3 = 2'd2;
            step4 = 2'd2;//(|(data_step4 & (start_position_4b>>3))) ? 2'd3 : 2'd0;
        end
        /* //v3: change case 6 to default (case step_style=3'd7 can't happen)
        default : begin //not expection
            step1 = 2'd0;
            step2 = 2'd0;
            step3 = 2'd0;
            step4 = 2'd0;
        end
        */
    endcase
end

// Move history
always @(posedge clk) begin : proc_move_history
    if (block_end) begin
        move_history [0] <= step4;
        move_history [1] <= step3;
        move_history [2] <= step2;
        move_history [3] <= step1;
    end
    else begin
        move_history [0] <= 2'd0;
        move_history [1] <= move_history [0];
        move_history [2] <= move_history [1];
        move_history [3] <= move_history [2];
    end
end
generate
    genvar mvReg_idx;
    for (mvReg_idx=4; mvReg_idx<63; mvReg_idx=mvReg_idx+1) begin : mvReg
        always @(posedge clk) begin
            move_history[mvReg_idx] <= move_history[mvReg_idx-1];
        end
    end
endgenerate

//------------------------------//
// OUTPUT
//------------------------------//
// Out Valid
always @(posedge clk or negedge rst_n) begin : proc_out_valid
    if(~rst_n)
        out_valid <= 1'b0;
    else begin
        case (current_state)
            s_input: out_valid <= 1'b0;
            s_output: out_valid <= 1'b1;
        endcase
    end
end
// Out
always @(posedge clk or negedge rst_n) begin : proc_out
    if(~rst_n)
        out <= 2'd0;
    else begin
        case (current_state)
            s_input: begin
                out <= 2'd0;
            end

            s_output: begin
                out <= move_history[62];
            end
        endcase
    end
end


endmodule

//==============================================//
//                Sub Module                    //
//==============================================//
module decoder_2to4(
    input [1:0] in,
    output reg [3:0] out
);

    always @(*) begin
        case (in)
            2'd0: out = 4'b0001;
            2'd1: out = 4'b0010;
            2'd2: out = 4'b0100;
            default : out = 4'b1000;
        endcase
    end

endmodule
