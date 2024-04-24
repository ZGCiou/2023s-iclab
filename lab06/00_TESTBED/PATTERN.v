//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : PATTERN.v
//   	Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL_TOP
    `define CYCLE_TIME 60.0
`endif

`ifdef GATE_TOP
    `define CYCLE_TIME 60.0
`endif

module PATTERN (
    // Output signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Input signals
    out_valid, out_Rx, out_Ry
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
output reg clk, rst_n, in_valid;
output reg [5:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
input out_valid;
input [5:0] out_Rx, out_Ry;

// ================================================================
//  Parameters & Integer
// ================================================================
integer PAT_NUM;
real CYCLE = `CYCLE_TIME;
integer SEED = 123;
integer pat_count;
integer fileIN, fileOUT;
integer wait_val_time;
integer golden_Rx, golden_Ry, golden_s;
integer total_latency;

// ================================================================
//  Wire & Registers 
// ================================================================


// ================================================================
//  Clock
// ================================================================
initial begin
    clk = 0;
end
always #(CYCLE/2.0) clk = ~clk;

// ================================================================
// Initial
// ================================================================

initial begin
    fileIN = $fopen("../00_TESTBED/InData.txt","r");
    fileOUT = $fopen("../00_TESTBED/GoldOut.txt","r");
    $fscanf(fileIN, "PAT_NUM=%d\n", PAT_NUM);

    total_latency = 0;
    reset_task;

    for (pat_count=1; pat_count<=PAT_NUM; pat_count=pat_count+1) begin
        input_task;
        wait_out_valid_task;
        check_ans_task;
        $display("Pass Pattern No.%3d, latency %3d ns",pat_count, wait_val_time*CYCLE);
    end
    $fclose(fileIN);
    $fclose(fileOUT);
    YOU_PASS_TASK;
end

// ================================================================
// Task
// ================================================================
// Reset task
task reset_task; //SPEC_6, SPEC_7
begin
    //$display("Start reset_task");
    rst_n = 1'b1;
    in_valid = 1'b0;
    in_prime = 'bx;
    in_Px = 'bx;
    in_Py = 'bx;
    in_Qx = 'bx;
    in_Qy = 'bx;
    in_a = 'bx;
    force clk = 0;
    #10; rst_n = 0;
    #CYCLE; rst_n = 1;
    if (out_valid !== 1'b0 || out_Rx !== 'd0 || out_Ry !== 'd0) begin
        $display("********************************************************************************");
        $display("* !!!All output signals should be reset after the reset signal is asserted.!!! *");
        $display("********************************************************************************");
        repeat(5) @(negedge clk);
        $finish;
    end
    #CYCLE; release clk;
end
endtask

// Input task
task  input_task();
integer i;
integer wait_nr_time;
begin
    if (pat_count == 'd1)
       repeat(2) @(negedge clk);
    else begin
        wait_nr_time =  $urandom_range(2, 4);
        for (i=0; i<wait_nr_time; i=i+1) begin
            // out_valid is low -> wait for next round
            // **SPEC 4**
            // The out should be reset when your out_valid is low.
            if (out_Rx !== 'd0 || out_Ry !== 'd0) begin
                $display("*************************************************************");
                $display("* !!!The out should be reset when your out_valid is low.!!! *");
                $display("*************************************************************");
                repeat(5) @(negedge clk);
                $finish;
            end
            @(negedge clk);
        end
    end

    in_valid = 1'b1;
    $fscanf(fileIN, "%d %d %d %d %d %d\n", in_prime, in_Px, in_Py, in_Qx, in_Qy, in_a);
    if (out_valid === 1'b1) begin
        $display("*****************************************************************");
        $display("* !!!The out_valid should not be high when in_valid is high.!!! *");
        $display("*****************************************************************");
        repeat(5) @(negedge clk);
        $finish;
    end
    @(negedge clk);

    if (out_valid === 1'b1) begin
        $display("*****************************************************************");
        $display("* !!!The out_valid should not be high when in_valid is high.!!! *");
        $display("*****************************************************************");
        repeat(5) @(negedge clk);
        $finish;
    end

    in_valid = 0;
    in_prime = 'bx;
    in_Px = 'bx;
    in_Py = 'bx;
    in_Qx = 'bx;
    in_Qy = 'bx;
    in_a = 'bx;
end
endtask

//Wait out valid
task wait_out_valid_task; //SPEC_6
begin
    //$display("Start wait_out_valid_task");
    wait_val_time = 0;
    while (out_valid !== 1'b1) begin
        wait_val_time = wait_val_time + 1;
        if (wait_val_time ==1000) begin
            $display("**********************************************************");
            $display("* !!!The execution latency is limited in 1000 cycles.!!! *");
            $display("**********************************************************");
            repeat(5) @(negedge clk);
            $finish;
        end
        @(negedge clk);
    end
    total_latency = total_latency + wait_val_time;
end
endtask

//Check answer
task check_ans_task();
begin
    $fscanf(fileOUT, "%d %d s = %d", golden_Rx, golden_Ry, golden_s);
    if (out_Rx !== golden_Rx || out_Ry !== golden_Ry) begin
        $display("****************************************************************");
        $display("*                             FAIL!                            *");
        $display("*                                                              *");
        $display("*                         Pattern NO.%4d                      *", pat_count);
        $display("*                                                              *");
        $display("*                 Your out_Rx = %3d, out_Ry = %3d              *", out_Rx, out_Ry);
        $display("*               Answer out_Rx = %3d, out_Ry = %3d              *", golden_Rx, golden_Ry);
        $display("****************************************************************");
        repeat(5) @(negedge clk);
        $finish;
    end
    @(negedge clk);
end
endtask

task YOU_PASS_TASK;
begin
    $display("--------------------------------------------------------------------");
    $display("             ~(￣▽￣)~(＿△＿)~(￣▽￣)~(＿△＿)~(￣▽￣)~                 ");
    $display("                                                                    ");
    $display("                         Congratulations!                           ");
    $display("                  You have passed all patterns!                     ");
    $display("                                                                    ");
    $display("                  Total Latency = %d ns                         ", total_latency*CYCLE);
    $display("--------------------------------------------------------------------");

  repeat(2) @(negedge clk);
  $finish;
end
endtask

endmodule