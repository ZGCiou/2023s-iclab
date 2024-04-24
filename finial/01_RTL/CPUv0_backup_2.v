//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//  2023 ICLAB Spring Course
//  Final Project   : Customized ISA Processor 
//  Author          : Zheng-Gang Ciou (nycu311511022.ee11@nycu.edu.tw)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//  File Name       : CPU.v
//  Module Name     : CPU
//  Release version : V1.0 (Release Date: 2023-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//++++++++++++++ Include DesignWare++++++++++++++++++
//synopsys translate_off
`include "/RAID2/cad/synopsys/synthesis/2022.03/dw/sim_ver/DW02_mult_2_stage.v"
`include "/RAID2/cad/synopsys/synthesis/2022.03/dw/sim_ver/DW_mult_pipe.v"
//synopsys translate_on
//+++++++++++++++++++++++++++++++++++++++++++++++++++
module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;


//###########################################
//
// Wrtie down your design below
//
//###########################################

//=====================================================================
//   REG AND WIRE DECLARATION
//=====================================================================
//=============== FSM ===============


//=========== Data Path =============
//--------------- IF ---------------
// Program Counter
reg [10:0] pc;
wire [10:0] pc_plus1;
wire [31:0] instr_addr;

// Instruction Memory
wire stall_imem;
wire [15:0] data_imem;

//--------------- ID ---------------
// Instruction
wire [15:0] instr;
wire [2:0] opcode;
wire [3:0] rs, rt, rd;
wire func;
wire signed [4:0] imm;
wire [12:0] jaddress;

// Register File
wire rf_reg_write;
wire [3:0] read_reg1, read_reg2, write_reg;
reg signed [15:0] read_data1, read_data2, write_data;

// Control Unit
wire jump, branch; // ID
wire alu_src, reg_dst, add, mul, slt; // EXE
wire mem_write, mem_read; // MEM
wire mem_to_reg, reg_write; // WB

// Hazard Detection Unit
wire pc_write, IF_ID_write, hazard;

// Branch, Jump
reg [15:0] branch_check_data1, branch_check_data2;
wire equal, IF_flash;
wire [1:0] pc_src;
wire [10:0] pc_branch, pc_jump;

//--------------- EX ---------------
reg signed [15:0] alu_in1, alu_in2, ID_EX_rd2_fw;
reg [3:0] reg_wb;

// Add
wire signed [15:0] add_out;

// Mul
wire signed [31:0] mul_out;

// Forwarding Unit
wire [1:0] branch_fwd1, branch_fwd2;
wire [1:0] alu_fwd1, alu_fwd2;
wire mem_fwd;

//--------------- MEM ---------------
// Data Memory
wire stall_dmem;
wire [15:0] data_dmem, mem_write_data_fw;

//========== Pipeline Register ==========
//--------------- IF/ID ---------------
// Flag
reg IF_ID_Reg_pipe_filled;
// Data
reg [10:0] IF_ID_Reg_pc_plus1;
reg [15:0] IF_ID_Reg_dmem_data;
//--------------- ID/EX ---------------
// Flag
reg ID_EX_Reg_pipe_filled;
// Control
reg ID_EX_Reg_alusrc, ID_EX_Reg_reg_dst, ID_EX_Reg_add, ID_EX_Reg_mul, ID_EX_Reg_slt; // EX ctrl
reg ID_EX_Reg_mem_write, ID_EX_Reg_mem_read; // MEM ctrl
reg ID_EX_Reg_mem_to_reg, ID_EX_Reg_reg_write; // WB ctrl
// Data
reg signed [15:0] ID_EX_Reg_rd1, ID_EX_Reg_rd2;
reg [12:0] ID_EX_Reg_instr_tail;
wire [3:0] ID_EX_rs, ID_EX_rt, ID_EX_rd;
wire signed [4:0] ID_EX_imm;
//--------------- EX_MUL ---------------
// Flag
reg EX_MUL_Reg_pipe_filled;
// Control
reg EX_MUL_Reg_mem_to_reg, EX_MUL_Reg_reg_write; // WB ctrl
// Data
reg [3:0] EX_MUL_Reg_reg_wb;
//--------------- EX/MEM ---------------
// Flag
reg EX_MEM_Reg_pipe_filled;
// Control
reg EX_MEM_Reg_mem_write, EX_MEM_Reg_mem_read; // MEM ctrl
reg EX_MEM_Reg_mem_to_reg, EX_MEM_Reg_reg_write; // WB ctrl
// Data
reg signed [15:0] EX_MEM_Reg_exe_result, EX_MEM_mem_write_data;
reg [3:0] EX_MEM_Reg_reg_wb, EX_MEM_Reg_rt;
//--------------- MEM/WB ---------------
// Flag
reg MEM_WB_Reg_pipe_filled;
// Control
reg MEM_WB_Reg_mem_to_reg, MEM_WB_Reg_reg_write; // WB ctrl
// Data
reg [15:0] MEM_WB_Reg_dmem_data;
reg signed [15:0] MEM_WB_Reg_exe_result;
reg [3:0] MEM_WB_Reg_reg_wb;

//========== Output ==========
wire stall;

//=====================================================================
//   PARAMETER AND INTEGER
//=====================================================================
//--------------------------- Parameter -------------------------------


//--------------------------- integer ---------------------------------


//=====================================================================
//   FSM
//=====================================================================



//=====================================================================
//   DATA PATH & CONTROL
//=====================================================================
//================== Stage 1: Instruction Fetch =======================
//------------------------ Program Counter ----------------------------
always @(posedge clk or negedge rst_n) begin : proc_pc
  if(~rst_n)
    pc <= 'd0;
  else if (~stall && pc_write) begin
    casez (pc_src)
      2'b1?: pc <= pc_jump;
      2'b?1: pc <= pc_branch;
      default : pc <= pc_plus1;
    endcase
  end
end
assign pc_plus1 = pc + 1;
assign instr_addr = {20'h00001, pc, 1'b0};

//---------------------- Instruction Memory ---------------------------
MEMORY_R #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) I_MEM (
  .clk          (clk),
  .rst_n        (rst_n),
  .address      (pc),
  .mem_read     (1'b1),
  .mem_read_data(data_imem),
  .stall        (stall_imem),
  //=========== AXI4 ===========
  //--- Read Address Channel ---
  .arid         (arid_m_inf[DRAM_NUMBER * ID_WIDTH-1:ID_WIDTH]),
  .araddr       (araddr_m_inf[DRAM_NUMBER * ADDR_WIDTH-1:ADDR_WIDTH]),
  .arlen        (arlen_m_inf[DRAM_NUMBER * 7 -1:7]),
  .arsize       (arsize_m_inf[DRAM_NUMBER * 3 -1:3]),
  .arburst      (arburst_m_inf[DRAM_NUMBER * 2 -1:2]),
  .arvalid      (arvalid_m_inf[DRAM_NUMBER-1:1]),
  .arready      (arready_m_inf[DRAM_NUMBER-1:1]),
  //--- Read Data Channel ------
  .rid          (rid_m_inf[DRAM_NUMBER * ID_WIDTH-1:ID_WIDTH]),
  .rdata        (rdata_m_inf[DRAM_NUMBER * DATA_WIDTH-1:DATA_WIDTH]),
  .rresp        (rresp_m_inf[DRAM_NUMBER * 2 -1:2]),
  .rlast        (rlast_m_inf[DRAM_NUMBER-1:1]),
  .rvalid       (rvalid_m_inf[DRAM_NUMBER-1:1]),
  .rready       (rready_m_inf[DRAM_NUMBER-1:1])
  //============================
);

//-------------------- Pipeline Register IF/ID ------------------------
always @(posedge clk or negedge rst_n) begin : proc_IF_ID_Reg
  if(~rst_n) begin
    IF_ID_Reg_pipe_filled <= 1'b0;
    IF_ID_Reg_pc_plus1 <= 'd0;
    IF_ID_Reg_dmem_data <= 'd0;
  end 
  else if (~stall && IF_ID_write) begin
    if (IF_flash) begin
      IF_ID_Reg_pipe_filled <= 1'b0;
      IF_ID_Reg_pc_plus1 <= 'd0;
      IF_ID_Reg_dmem_data <= 'd0;
    end
    else begin
      IF_ID_Reg_pipe_filled <= 1'b1;
      IF_ID_Reg_pc_plus1 <= pc_plus1;
      IF_ID_Reg_dmem_data <= data_imem;
    end
  end
end

//============== Stage 2: Instruction Decode / Read Register ==========
//------------------------ Instruction --------------------------------
assign instr = IF_ID_Reg_dmem_data;
assign opcode = instr[15:13];
assign rs = instr[12:9];
assign rt = instr[8:5];
assign rd = instr[4:1];
assign func = instr[0];
assign jaddress = instr[12:0];
assign imm = instr[4:0];
//------------------------ Register File ------------------------------
assign read_reg1 = rs;
assign read_reg2 = rt;

// Read port1
always @(*) begin : proc_read_data1
  case (read_reg1)
    'd0: read_data1 = core_r0;
    'd1: read_data1 = core_r1;
    'd2: read_data1 = core_r2;
    'd3: read_data1 = core_r3;
    'd4: read_data1 = core_r4;
    'd5: read_data1 = core_r5;
    'd6: read_data1 = core_r6;
    'd7: read_data1 = core_r7;
    'd8: read_data1 = core_r8;
    'd9: read_data1 = core_r9;
    'd10: read_data1 = core_r10;
    'd11: read_data1 = core_r11;
    'd12: read_data1 = core_r12;
    'd13: read_data1 = core_r13;
    'd14: read_data1 = core_r14;
    default : read_data1 = core_r15; //'d15
  endcase
end
//Read port2
always @(*) begin : proc_read_data2
  case (read_reg2)
    'd0: read_data2 = core_r0;
    'd1: read_data2 = core_r1;
    'd2: read_data2 = core_r2;
    'd3: read_data2 = core_r3;
    'd4: read_data2 = core_r4;
    'd5: read_data2 = core_r5;
    'd6: read_data2 = core_r6;
    'd7: read_data2 = core_r7;
    'd8: read_data2 = core_r8;
    'd9: read_data2 = core_r9;
    'd10: read_data2 = core_r10;
    'd11: read_data2 = core_r11;
    'd12: read_data2 = core_r12;
    'd13: read_data2 = core_r13;
    'd14: read_data2 = core_r14;
    default : read_data2 = core_r15; //'d15
  endcase
end
// Write
always @(negedge clk or negedge rst_n) begin : proc_core_reg
  if(~rst_n) begin
    core_r0 <= 16'b0;
    core_r1 <= 16'b0;
    core_r2 <= 16'b0;
    core_r3 <= 16'b0;
    core_r4 <= 16'b0;
    core_r5 <= 16'b0;
    core_r6 <= 16'b0;
    core_r7 <= 16'b0;
    core_r8 <= 16'b0;
    core_r9 <= 16'b0;
    core_r10 <= 16'b0;
    core_r11 <= 16'b0;
    core_r12 <= 16'b0;
    core_r13 <= 16'b0;
    core_r14 <= 16'b0;
    core_r15 <= 16'b0;
  end 
  else /*if (~stall)*/ begin
    if (rf_reg_write) begin
      case (write_reg)
        'd0: core_r0 <= write_data;
        'd1: core_r1 <= write_data;
        'd2: core_r2 <= write_data;
        'd3: core_r3 <= write_data;
        'd4: core_r4 <= write_data;
        'd5: core_r5 <= write_data;
        'd6: core_r6 <= write_data;
        'd7: core_r7 <= write_data;
        'd8: core_r8 <= write_data;
        'd9: core_r9 <= write_data;
        'd10: core_r10 <= write_data;
        'd11: core_r11 <= write_data;
        'd12: core_r12 <= write_data;
        'd13: core_r13 <= write_data;
        'd14: core_r14 <= write_data;
        'd15: core_r15 <= write_data;
      endcase
    end
  end
end

// Branch, Jump
always @(*) begin
  case (branch_fwd1)
    'd1: branch_check_data1 = EX_MEM_Reg_exe_result;
    'd2: branch_check_data1 = write_data;
    default : branch_check_data1 = read_data1;
  endcase
end
always @(*) begin
  case (branch_fwd2)
    'd1: branch_check_data2 = EX_MEM_Reg_exe_result;
    'd2: branch_check_data2 = write_data;
    default : branch_check_data2 = read_data2;
  endcase
end

assign equal = (branch_check_data1==branch_check_data2) ? 1'b1 : 1'b0;
assign pc_src[0] = branch && equal;
assign pc_src[1] = jump;
assign pc_branch = IF_ID_Reg_pc_plus1 + $signed(imm);
assign pc_jump = jaddress[11:1];
assign IF_flash = |pc_src;

//------------------------ Control Unit ------------------------------
CONTROL CTRL_UNIT (
  .Opcode  (opcode),
  .Func    (func),
  .Jump    (jump),
  .ALUSrc  (alu_src),
  .Branch  (branch),
  .RegDst  (reg_dst),
  .MemRead (mem_read),
  .MemWrite(mem_write),
  .MemtoReg(mem_to_reg),
  .RegWrite(reg_write),
  .Add     (add),
  .Mul     (mul),
  .Slt     (slt)
);

//--------------------- Hazard Detection Unit -------------------------
HAZARD_CTRL HAZARD_DET_UNIT (
  // 1: Load, Mul
  .FirstInstr_MemRead (EX_MEM_Reg_mem_read), // EX_MEM
  .FirstInstr_Mul     (EX_MUL_Reg_pipe_filled), // EX_MUL
  .FirstInstr_Rt      (EX_MEM_Reg_reg_wb), // EX_MEM
  .FirstInstr_Rd      (EX_MUL_Reg_reg_wb), // EX_MUL
  // 2: Load, Mul
  .FrontInstr_MemRead (ID_EX_Reg_mem_read),
  .FrontInstr_Mul     (ID_EX_Reg_mul),
  .FrontInstr_RegWrite(ID_EX_Reg_reg_write),
  .FrontInstr_Rd      (reg_wb),
  // 3
  .BackInstr_Mul      (mul),
  .BackInstr_Branch   (branch),
  .BackInstr_Opcode   (opcode),
  .BackInstr_Rs       (rs),
  .BackInstr_Rt       (rt),
  // Control Signal
  .PC_Write           (pc_write),
  .IF_ID_Write        (IF_ID_write),
  .Stall              (hazard)
);

//-------------------- Pipeline Register ID/EX ------------------------
always @(posedge clk or negedge rst_n) begin : proc_ID_EX_Reg
  if(~rst_n) begin
    // Flag
    ID_EX_Reg_pipe_filled <= 1'b0;
    // Control
    // EX: 5
    ID_EX_Reg_alusrc <= 'd0;
    ID_EX_Reg_reg_dst <= 'd0;
    ID_EX_Reg_add <= 'd0;
    ID_EX_Reg_mul <= 'd0;
    ID_EX_Reg_slt <= 'd0;
    // MEM: 2
    ID_EX_Reg_mem_write <= 'd0;
    ID_EX_Reg_mem_read <= 'd0;
    // WB: 2
    ID_EX_Reg_mem_to_reg <= 'd0;
    ID_EX_Reg_reg_write <= 'd0;

    // Data
    ID_EX_Reg_rd1 <= 'd0;
    ID_EX_Reg_rd2 <= 'd0;
    ID_EX_Reg_instr_tail <= 'd0;
  end 
  else if (~stall) begin
    // Flag
    ID_EX_Reg_pipe_filled <= hazard ? 1'b0 : IF_ID_Reg_pipe_filled;
    // Control
    // EX: 5
    ID_EX_Reg_alusrc <= (hazard || ~IF_ID_Reg_pipe_filled) ? 1'b0 : alu_src;
    ID_EX_Reg_reg_dst <= (hazard || ~IF_ID_Reg_pipe_filled) ? 1'b0 : reg_dst;
    ID_EX_Reg_add <= (hazard || ~IF_ID_Reg_pipe_filled) ? 1'b0 : add;
    ID_EX_Reg_mul <= (hazard || ~IF_ID_Reg_pipe_filled) ? 1'b0 : mul;
    ID_EX_Reg_slt <= (hazard || ~IF_ID_Reg_pipe_filled) ? 1'b0 : slt;
    // MEM: 2
    ID_EX_Reg_mem_write <= (hazard || ~IF_ID_Reg_pipe_filled) ? 1'b0 : mem_write;
    ID_EX_Reg_mem_read <= (hazard || ~IF_ID_Reg_pipe_filled) ? 1'b0 : mem_read;
    // WB: 2
    ID_EX_Reg_mem_to_reg <= (hazard || ~IF_ID_Reg_pipe_filled) ? 1'b0 : mem_to_reg;
    ID_EX_Reg_reg_write <= (hazard || ~IF_ID_Reg_pipe_filled) ? 1'b0 : reg_write;
    
    // Data
    ID_EX_Reg_rd1 <= read_data1;
    ID_EX_Reg_rd2 <= read_data2;
    ID_EX_Reg_instr_tail <= instr[12:0];
  end
end

assign ID_EX_rs = ID_EX_Reg_instr_tail[12:9];
assign ID_EX_rt = ID_EX_Reg_instr_tail[8:5];
assign ID_EX_rd = ID_EX_Reg_instr_tail[4:1];
assign ID_EX_imm = ID_EX_Reg_instr_tail[4:0];

//======================== Stage 3: Execute ===========================
// ALU input
always @(*) begin
  case (alu_fwd1)
    'd1: alu_in1 = EX_MEM_Reg_exe_result;
    'd2: alu_in1 = write_data;
    default : alu_in1 = ID_EX_Reg_rd1;
  endcase
end

always @(*) begin
  case (alu_fwd2)
      'd1: ID_EX_rd2_fw = EX_MEM_Reg_exe_result;
      'd2: ID_EX_rd2_fw = write_data;
      default : ID_EX_rd2_fw = ID_EX_Reg_rd2;
    endcase
end
always @(*) begin
  if (ID_EX_Reg_alusrc)
    alu_in2 = {{11{ID_EX_imm[4]}}, ID_EX_imm};
  else
    alu_in2 = ID_EX_rd2_fw;
end


// Write Back Target
always @(*) begin
  if (ID_EX_Reg_reg_dst) //R type: Write rd
    reg_wb = ID_EX_rd;
  else
    reg_wb = ID_EX_rt; // Write rt
end

//-------------------- Functional Unit: Add ---------------------------
ALU INT_ADD (
  .Add(ID_EX_Reg_add),
  .Slt(ID_EX_Reg_slt),
  .In1(alu_in1),
  .In2(alu_in2),
  .Out(add_out)
);

//-------------------- Functional Unit: Mul ---------------------------
DW_mult_pipe #(.a_width(16), .b_width(16), .num_stages(2), .stall_mode(1), .rst_mode(1)) INT_MUL (
  .clk    (clk),
  .rst_n  (rst_n),
  .en     (~stall),
  .tc     (1'b1),
  .a      (alu_in1),
  .b      (alu_in2),
  .product(mul_out)
);

//------------------------ Forwarding Unit -----------------------------
FORWARD_CTRL FWD_UNIT (
  // Branch
  .Branch_Rs   (rs),
  .Branch_Rt   (rt),
  // ALU
  .ALU_Rs      (ID_EX_rs),
  .ALU_Rt      (ID_EX_rt),
  // MEM
  .MEM_RegWrite(EX_MEM_Reg_reg_write),
  .MEM_Rt      (EX_MEM_Reg_rt),
  .MEM_Rd      (EX_MEM_Reg_reg_wb),
  // WB
  .WB_RegWrite (MEM_WB_Reg_reg_write),
  .WB_Rd       (MEM_WB_Reg_reg_wb),
  // Control Signal
  .BranchFwd_Rs(branch_fwd1),
  .BranchFwd_Rt(branch_fwd2),
  .ALUFwd_Rs   (alu_fwd1),
  .ALUFwd_Rt   (alu_fwd2),
  .MemFwd      (mem_fwd)
);

// Pipeline Register EX_MUL
always @(posedge clk or negedge rst_n) begin : proc_EX_MUL_Reg
  if(~rst_n) begin
    // Flag
    EX_MUL_Reg_pipe_filled <= 1'b0;
    // WB
    EX_MUL_Reg_mem_to_reg <= 'd0;
    EX_MUL_Reg_reg_write <= 'd0;
    // Data
    EX_MUL_Reg_reg_wb <= 'd0;
  end 
  else if (~stall) begin
    if (ID_EX_Reg_mul) begin
      // Flag
      EX_MUL_Reg_pipe_filled <= ID_EX_Reg_pipe_filled;
      // WB
      EX_MUL_Reg_mem_to_reg <= ID_EX_Reg_mem_to_reg;
      EX_MUL_Reg_reg_write <= ID_EX_Reg_reg_write;
      // Data
      EX_MUL_Reg_reg_wb <= reg_wb;
    end
    else begin // Gen Bubble in MUL stage 1
      // Flag
      EX_MUL_Reg_pipe_filled <= 1'b0;
      // WB
      EX_MUL_Reg_mem_to_reg <= 'd0;
      EX_MUL_Reg_reg_write <= 'd0;
      // Data
      EX_MUL_Reg_reg_wb <= 'd0;
    end
  end
end

//-------------------- Pipeline Register EX/MEM -----------------------
always @(posedge clk or negedge rst_n) begin : proc_EX_MEM_Reg
  if(~rst_n) begin
    // Flag
    EX_MEM_Reg_pipe_filled <= 1'b0;
    // MEM
    EX_MEM_Reg_mem_read <= 'd0;
    EX_MEM_Reg_mem_write <= 'd0;
    EX_MEM_Reg_rt <= 'd0;
    // WB
    EX_MEM_Reg_mem_to_reg <= 'd0;
    EX_MEM_Reg_reg_write <= 'd0;
    // Data
    EX_MEM_Reg_exe_result <= 'd0;
    EX_MEM_Reg_reg_wb <= 'd0;
    EX_MEM_mem_write_data <= 'd0;
  end 
  else if (~stall) begin
    if (EX_MUL_Reg_pipe_filled || ID_EX_Reg_mul) begin // MUL in EX or Gen Bubble
      // Flag
      EX_MEM_Reg_pipe_filled <= EX_MUL_Reg_pipe_filled;
      // MEM
      EX_MEM_Reg_mem_read <= 'd0;
      EX_MEM_Reg_mem_write <= 'd0;
      EX_MEM_Reg_rt <= 'd0;
      // WB
      EX_MEM_Reg_mem_to_reg <= EX_MUL_Reg_mem_to_reg;
      EX_MEM_Reg_reg_write <= EX_MUL_Reg_reg_write;
      // Data
      EX_MEM_Reg_exe_result <= mul_out[15:0];
      EX_MEM_Reg_reg_wb <= EX_MUL_Reg_reg_wb;
      EX_MEM_mem_write_data <= 'd0;
    end
    else begin // not MUL in EX
      // Flag
      EX_MEM_Reg_pipe_filled <= ID_EX_Reg_pipe_filled;
      // MEM
      EX_MEM_Reg_mem_read <= ID_EX_Reg_mem_read;
      EX_MEM_Reg_mem_write <= ID_EX_Reg_mem_write;
      EX_MEM_Reg_rt <= ID_EX_rt;
      // WB
      EX_MEM_Reg_mem_to_reg <= ID_EX_Reg_mem_to_reg;
      EX_MEM_Reg_reg_write <= ID_EX_Reg_reg_write;
      // Data
      EX_MEM_Reg_exe_result <= add_out;
      EX_MEM_Reg_reg_wb <= reg_wb;
      EX_MEM_mem_write_data <= ID_EX_rd2_fw;
    end
  end
end

//======================== Stage 4: Memory ============================
assign mem_write_data_fw = mem_fwd ? write_data : EX_MEM_mem_write_data;

//-------------------------- Data Memory ------------------------------
MEMORY_RW #(.ID_WIDTH(ID_WIDTH), .ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) D_MEM (
  .clk           (clk),
  .rst_n         (rst_n),
  .address       (EX_MEM_Reg_exe_result[10:0]),
  .mem_read      (EX_MEM_Reg_mem_read),
  .mem_read_data (data_dmem),
  .mem_write     (EX_MEM_Reg_mem_write),
  .mem_write_data(mem_write_data_fw),
  .stall         (stall_dmem),
  //=========== AXI4 ===========
  //--- Read Address Channel ---
  .arid          (arid_m_inf[ID_WIDTH-1:0]),
  .araddr        (araddr_m_inf[ADDR_WIDTH-1:0]),
  .arlen         (arlen_m_inf[6:0]),
  .arsize        (arsize_m_inf[2:0]),
  .arburst       (arburst_m_inf[1:0]),
  .arvalid       (arvalid_m_inf[0]),
  .arready       (arready_m_inf[0]),
  //--- Read Data Channel ------
  .rid           (rid_m_inf[ID_WIDTH-1:0]),
  .rdata         (rdata_m_inf[DATA_WIDTH-1:0]),
  .rresp         (rresp_m_inf[1:0]),
  .rlast         (rlast_m_inf[0]),
  .rvalid        (rvalid_m_inf[0]),
  .rready        (rready_m_inf[0]),
  //--- Write Address Channel ----------
  .awid          (awid_m_inf),
  .awaddr        (awaddr_m_inf),
  .awsize        (awsize_m_inf),
  .awburst       (awburst_m_inf),
  .awlen         (awlen_m_inf),
  .awvalid       (awvalid_m_inf),
  .awready       (awready_m_inf),
  //--- Write Data Channel -------------
  .wdata         (wdata_m_inf),
  .wlast         (wlast_m_inf),
  .wvalid        (wvalid_m_inf),
  .wready        (wready_m_inf),
  //--- Write Response Channel ---------
  .bid           (bid_m_inf),
  .bresp         (bresp_m_inf),
  .bvalid        (bvalid_m_inf),
  .bready        (bready_m_inf)
  //============================
);

//-------------------- Pipeline Register MEM/WB -----------------------
always @(posedge clk or negedge rst_n) begin : proc_MEM_WB_Reg
  if(~rst_n) begin
    // Flag
    MEM_WB_Reg_pipe_filled <= 1'b0;
    // Control
    MEM_WB_Reg_mem_to_reg <= 'd0;
    MEM_WB_Reg_reg_write <= 'd0;
    // Data
    MEM_WB_Reg_dmem_data <= 'd0;
    MEM_WB_Reg_exe_result <= 'd0;
    MEM_WB_Reg_reg_wb <= 'd0;
  end 
  else if (~stall) begin
    // Flag
    MEM_WB_Reg_pipe_filled <= EX_MEM_Reg_pipe_filled;
    // Control
    MEM_WB_Reg_mem_to_reg <= EX_MEM_Reg_mem_to_reg;
    MEM_WB_Reg_reg_write <= EX_MEM_Reg_reg_write;
    // Data
    MEM_WB_Reg_dmem_data <= data_dmem;
    MEM_WB_Reg_exe_result <= EX_MEM_Reg_exe_result;
    MEM_WB_Reg_reg_wb <= EX_MEM_Reg_reg_wb;
  end
  else begin
    // Flag
    MEM_WB_Reg_pipe_filled <= 1'b0;
    // Control
    MEM_WB_Reg_mem_to_reg <= MEM_WB_Reg_mem_to_reg;
    MEM_WB_Reg_reg_write <= MEM_WB_Reg_reg_write;
    // Data
    MEM_WB_Reg_dmem_data <= MEM_WB_Reg_dmem_data;
    MEM_WB_Reg_exe_result <= MEM_WB_Reg_exe_result;
    MEM_WB_Reg_reg_wb <= MEM_WB_Reg_reg_wb;
  end
end

//====================== Stage 4: Write Back ==========================
assign rf_reg_write = MEM_WB_Reg_reg_write;
assign write_reg = MEM_WB_Reg_reg_wb;

always @(*) begin
  if (MEM_WB_Reg_mem_to_reg)
    write_data = MEM_WB_Reg_dmem_data;
  else
    write_data = MEM_WB_Reg_exe_result;
end

//=====================================================================
//   OUTPUT
//=====================================================================
assign stall = stall_imem || stall_dmem;

always @(posedge clk or negedge rst_n) begin
  if (~rst_n)
    IO_stall <= 1'b1;/*
  else if (stall)
    IO_stall <= 1'b1;*/
  else
    IO_stall <= ~MEM_WB_Reg_pipe_filled;
end

endmodule

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   SUB MODULE
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//################################################# DATA MEMORY ##################################################
module MEMORY_RW #(
  parameter ID_WIDTH = 4,
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 16
) (
  clk,
  rst_n,
  address,
  mem_read,
  mem_read_data,
  mem_write,
  mem_write_data,
  stall,
  //=========== AXI4 ===========
  //--- Read Address Channel ---
  arid,
  araddr,
  arlen,
  arsize,
  arburst,
  arvalid,
  arready,
  //--- Read Data Channel ------
  rid,
  rdata,
  rresp,
  rlast,
  rvalid,
  rready,
  //--- Write Address Channel --
  awid,
  awaddr,
  awlen,
  awsize,
  awburst,
  awvalid,
  awready,
  //--- Write Data Channel -----
  wdata,
  wlast,
  wvalid,
  wready,
  //--- Write Response Channel -
  bid,
  bresp,
  bvalid,
  bready
  //============================
);
//=====================================================================
//   PORT DECLARATION
//=====================================================================
input wire clk, rst_n;
input wire [10:0] address;
input wire mem_read;
input wire mem_write;
input wire [15:0] mem_write_data;
output reg [15:0] mem_read_data;
output wire stall;

//============= AXI4 ================
//--- Read Address Channel ----------
output  wire [ID_WIDTH-1:0]   arid;
output  wire [ADDR_WIDTH-1:0] araddr;
output  wire [6:0]            arlen;
output  wire [2:0]            arsize;
output  wire [1:0]            arburst;
output  wire                  arvalid;
input   wire                  arready;
//--- Read Data Channel --------------
input   wire [ID_WIDTH-1:0]   rid;
input   wire [DATA_WIDTH-1:0] rdata;
input   wire [1:0]            rresp;
input   wire                  rlast;
input   wire                  rvalid;
output  wire                  rready;
//--- Write Address Channel ----------
output  wire [ID_WIDTH-1:0]   awid;
output  wire [ADDR_WIDTH-1:0] awaddr;
output  wire [2:0]            awsize;
output  wire [1:0]            awburst;
output  wire [6:0]            awlen;
output  wire                  awvalid;
input   wire                  awready;
//--- Write Data Channel -------------
output  wire [DATA_WIDTH-1:0] wdata;
output  wire                  wlast;
output  wire                  wvalid;
input   wire                  wready;
//--- Write Response Channel ---------
input   wire [ID_WIDTH-1:0]   bid;
input   wire [1:0]            bresp;
input   wire                  bvalid;
output  wire                  bready;
//====================================

//=====================================================================
//   REG AND WIRE DECLARATION
//=====================================================================
//-------- Address --------
wire in_block_addr;
wire [2:0] in_tag;

//-------- FSM ------------
reg [2:0] cur_state, next_state;

//-------- Cache ----------
reg [1:0] valid;
reg [2:0] tag [0:1];
reg hit;
wire cache_write_n;
wire [7:0] cache_addr;
wire [15:0] cache_write_data, cache_data;
reg [6:0] offset;

//-------- Output ----------
wire stall_write;

//=====================================================================
//   PARAMETER AND INTEGER
//=====================================================================
//--------------- SPEC ---------------
// Cache Size: 256 * 16 bits
// Block Size: 128 * 16 bits
// Block Number: 2
// Mapping Rule: Direct Map
// Write Hit Rule: Write Through
// Write Miss Rule: Write No Allocate
//--------------- Address ------------
// address[6:0]: Block Offset
// address[7]: Block Address
// address[10:8]: Tag
//--------------- SRAM ---------------
// Cache Address: 8 bits, address[7:0]
// Cache Data; 16 bits
//------------------------------------

//---------- FSM ----------
localparam S_IDLE = 'd0;
localparam S_READ_WAIT_ADDR_READY = 'd1;
localparam S_READ = 'd2;
localparam S_WRITE_WAIT_ADDR_READY = 'd3;
localparam S_WRITE = 'd4;
localparam S_WRITE_WAIT_RESP = 'd5;

//=====================================================================
//   FSM
//=====================================================================
// Current State
always @(posedge clk or negedge rst_n) begin : proc_cur_state
  if(~rst_n)
    cur_state <= S_IDLE;
  else begin
    cur_state <= next_state;
  end
end

// Next State
always @(*) begin : proc_next_state
  case (cur_state)
    S_IDLE: begin
      if (~hit && mem_read)
        next_state = S_READ_WAIT_ADDR_READY;
      else if (mem_write)
        next_state = S_WRITE_WAIT_ADDR_READY;
      else
        next_state = S_IDLE;
    end

    S_READ_WAIT_ADDR_READY: begin
      if (arready)
        next_state = S_READ;
      else
        next_state = S_READ_WAIT_ADDR_READY;
    end

    S_READ: begin
      if (rlast) 
        next_state = S_IDLE;
      else
        next_state = S_READ;
    end

    S_WRITE_WAIT_ADDR_READY: begin
      if (awready)
        next_state = S_WRITE;
      else
        next_state = S_WRITE_WAIT_ADDR_READY;
    end

    S_WRITE: begin
      if (wlast && wready)
        next_state = S_IDLE;
      else
        next_state = S_WRITE;
    end

    S_WRITE_WAIT_RESP: begin
      if (bvalid)
        next_state = S_IDLE;
      else
        next_state = S_WRITE_WAIT_RESP;
    end

    default : next_state = cur_state;
  endcase
end

//=====================================================================
//   CACHE
//=====================================================================
// SRAM
RA1SH_256_16 DATA_CACHE(.A(cache_addr), .D(cache_write_data), .CLK(~clk), .CEN(1'b0), .WEN(cache_write_n), .OEN(1'b0), .Q(cache_data));

// Cache Address
assign cache_addr = (mem_read && ~hit) ? {in_block_addr, offset} : address[7:0];

// Cache Write
assign cache_write_n = ((mem_write && hit) || (mem_read && rvalid)) ? 1'b0 : 1'b1;

// Cache Write Data
assign cache_write_data = (mem_write) ? mem_write_data : rdata;

always @(posedge clk or negedge rst_n) begin : proc_offset
  if(~rst_n)
    offset <= 'd0;
  else begin
    if (next_state==S_IDLE)
      offset <= 'd0;
    else if (rvalid) begin
      offset <= offset + 'd1;
    end
  end
end

// Address
assign in_tag = address[10:8];
assign in_block_addr = address[7];

// Cache Hit
always @(*) begin : proc_hit
  if(in_block_addr) begin
    if (valid[1] && tag[1]==in_tag)
      hit = 1'b1;
    else
      hit = 1'b0;
  end
  else begin
    if (valid[0] && tag[0]==in_tag)
      hit = 1'b1;
    else
      hit = 1'b0;
  end
end

// Valid Bit
always @(posedge clk or negedge rst_n) begin : proc_valid
  if(~rst_n)
    valid <= 2'b0; 
  else begin
    if ((cur_state==S_READ) && rlast) begin
      case (in_block_addr)
        'd0: valid[0] <= 1'b1;
        'd1: valid[1] <= 1'b1;
      endcase
    end
  end
end

// Tag
always @(posedge clk or negedge rst_n) begin : proc_tag
  if(~rst_n) begin
    tag[0] <= 'd0;
    tag[1] <= 'd0;
  end
  else begin
    if ((cur_state==S_READ) && rlast) begin
      case (in_block_addr)
        'd0: tag[0] <= in_tag;
        'd1: tag[1] <= in_tag;
      endcase
    end
  end
end

//=====================================================================
//   DRAM
//=====================================================================
//--------------- Read ----------------
// Read Address Channel
assign arid = 'd0;
assign araddr = (cur_state==S_READ_WAIT_ADDR_READY) ? {20'h00001, address[10:7], 8'b0} : 'd0;
assign arlen = (cur_state==S_READ_WAIT_ADDR_READY) ? 7'b1111111 : 'd0;
assign arsize = 3'b001;
assign arburst = 2'b01;
assign arvalid = (cur_state==S_READ_WAIT_ADDR_READY);

// Read Data Channel
assign rready = (cur_state==S_READ);

//--------------- Write ---------------
// Write Address Channel
assign awid = 'd0;
assign awaddr = (cur_state==S_WRITE_WAIT_ADDR_READY) ? {20'h00001, address, 1'b0} : 'd0;
assign awlen = 'd0;
assign awsize = 3'b001;
assign awburst = 2'b01;
assign awvalid = (cur_state==S_WRITE_WAIT_ADDR_READY);

// Write Data Channel
assign wdata = (cur_state==S_WRITE) ? mem_write_data : 'd0;
assign wlast = (cur_state==S_WRITE);
assign wvalid = (cur_state==S_WRITE);

// Write Response Channel
assign bready = rst_n;//(cur_state==S_WRITE);

//=====================================================================
//   OUTPUT
//=====================================================================
assign stall_write = (next_state==S_WRITE_WAIT_ADDR_READY) || (next_state==S_WRITE);// || (mem_write&&(cur_state==S_IDLE));
assign stall = stall_write || (mem_read && ~hit);//(~hit || bvalid) && (mem_read || mem_write);
always @(*) begin : proc_mem_read_data
  if (hit && mem_read)
    mem_read_data = cache_data;
  else
    mem_read_data = 'd0;
end

endmodule

//############################################### INSTRUCTION MEMORY ###############################################
module MEMORY_R #(
  parameter ID_WIDTH = 4,
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 16
) (
  clk,
  rst_n,
  address,
  mem_read,
  mem_read_data,
  stall,
  //=========== AXI4 ===========
  //--- Read Address Channel ---
  arid,
  araddr,
  arlen,
  arsize,
  arburst,
  arvalid,
  arready,
  //--- Read Data Channel ------
  rid,
  rdata,
  rresp,
  rlast,
  rvalid,
  rready
  //============================
);
//=====================================================================
//   PORT DECLARATION
//=====================================================================
input wire clk, rst_n;
input wire [10:0] address;
input wire mem_read;
output reg [15:0] mem_read_data;
output wire stall;

//============= AXI4 ================
//--- Read Address Channel ----------
output  wire [ID_WIDTH-1:0]   arid;
output  wire [ADDR_WIDTH-1:0] araddr;
output  wire [6:0]            arlen;
output  wire [2:0]            arsize;
output  wire [1:0]            arburst;
output  wire                  arvalid;
input   wire                  arready;
//--- Read Data Channel --------------
input   wire [ID_WIDTH-1:0]   rid;
input   wire [DATA_WIDTH-1:0] rdata;
input   wire [1:0]            rresp;
input   wire                  rlast;
input   wire                  rvalid;
output  wire                  rready;
//====================================

//=====================================================================
//   REG AND WIRE DECLARATION
//=====================================================================
//-------- Address --------
wire in_block_addr;
wire [2:0] in_tag;

//-------- FSM ------------
reg [1:0] cur_state, next_state;

//-------- Cache ----------
reg [1:0] valid;
reg [2:0] tag [0:1];
reg hit;
wire [7:0] cache_addr, cache_addr_r, cache_addr_w;
wire [15:0] cache_data;
reg [6:0] offset;

//=====================================================================
//   PARAMETER AND INTEGER
//=====================================================================
//--------------- SPEC ---------------
// Cache Size: 256 * 16 bits
// Block Size: 128 * 16 bits
// Block Number: 2
// Mapping Rule: Direct Map
//--------------- Address ------------
// address[6:0]: Block Offset
// address[7]: Block Address
// address[10:8]: Tag
//--------------- SRAM ---------------
// Cache Address: 8 bits, address[7:0]
// Cache Data; 16 bits
//------------------------------------

//---------- FSM ----------
localparam S_IDLE = 'd0;
localparam S_READ_WAIT_ADDR_READY = 'd1;
localparam S_READ = 'd2;

//=====================================================================
//   FSM
//=====================================================================
// Current State
always @(posedge clk or negedge rst_n) begin : proc_cur_state
  if(~rst_n)
    cur_state <= S_IDLE;
  else begin
    cur_state <= next_state;
  end
end

// Next State
always @(*) begin : proc_next_state
  case (cur_state)
    S_IDLE: begin
      if (~hit)
        next_state = S_READ_WAIT_ADDR_READY;
      else
        next_state = S_IDLE;
    end

    S_READ_WAIT_ADDR_READY: begin
      if (arready)
        next_state = S_READ;
      else
        next_state = S_READ_WAIT_ADDR_READY;
    end

    S_READ: begin
      if (rlast)
        next_state = S_IDLE;
      else
        next_state = S_READ;
    end

    default : next_state = cur_state;
  endcase
end

//=====================================================================
//   CACHE
//=====================================================================
// SRAM
RA1SH_256_16 INSTR_CACHE(.A(cache_addr), .D(rdata), .CLK(~clk), .CEN(1'b0), .WEN(~rvalid), .OEN(1'b0), .Q(cache_data));

assign cache_addr = (hit) ? cache_addr_r : cache_addr_w;
assign cache_addr_r = address[7:0];
assign cache_addr_w = {in_block_addr, offset};

always @(posedge clk or negedge rst_n) begin : proc_offset
  if(~rst_n)
    offset <= 'd0;
  else begin
    if (next_state==S_IDLE)
      offset <= 'd0;
    else if (rvalid) begin
      offset <= offset + 'd1;
    end
  end
end

// Address
assign in_tag = address[10:8];
assign in_block_addr = address[7];

// Cache Hit
always @(*) begin : proc_hit
  if(in_block_addr) begin
    if (valid[1] && tag[1]==in_tag)
      hit = 1'b1;
    else
      hit = 1'b0;
  end
  else begin
    if (valid[0] && tag[0]==in_tag)
      hit = 1'b1;
    else
      hit = 1'b0;
  end
end

// Valid Bit
always @(posedge clk or negedge rst_n) begin : proc_valid
  if(~rst_n)
    valid <= 2'b0; 
  else begin
    if ((cur_state==S_READ) && rlast) begin
      case (in_block_addr)
        'd0: valid[0] <= 1'b1;
        'd1: valid[1] <= 1'b1;
      endcase
    end
  end
end

// Tag
always @(posedge clk or negedge rst_n) begin : proc_tag
  if(~rst_n) begin
    tag[0] <= 'd0;
    tag[1] <= 'd0;
  end
  else begin
    if ((cur_state==S_READ) && rlast) begin
      case (in_block_addr)
        'd0: tag[0] <= in_tag;
        'd1: tag[1] <= in_tag;
      endcase
    end
  end
end

//=====================================================================
//   DRAM
//=====================================================================
//--------------- Read ----------------
// Read Address Channel
assign arid = 'd0;
assign araddr = (cur_state==S_READ_WAIT_ADDR_READY) ? {20'h00001, address[10:7], 8'b0} : 'd0;
assign arlen = (cur_state==S_READ_WAIT_ADDR_READY) ? 7'b1111111 : 'd0;
assign arsize = 3'b001;
assign arburst = 2'b01;
assign arvalid = (cur_state==S_READ_WAIT_ADDR_READY);

// Read Data Channel
assign rready = (cur_state==S_READ);


//=====================================================================
//   OUTPUT
//=====================================================================
assign stall = ~hit;
always @(*) begin : proc_mem_read_data
  if (hit && mem_read)
    mem_read_data = cache_data;
  else
    mem_read_data = 'd0;
end

endmodule

//############################################### MAIN CONTROL ####################################################
module CONTROL (
  input wire [2:0] Opcode,
  input Func,
  output RegDst,
  output Jump,
  output Branch,
  output MemRead,
  output MemtoReg,
  output MemWrite,
  output ALUSrc,
  output RegWrite,
  output Add,
  output Mul,
  output Slt
);

//----- R type -----
// RedDst 0: write rt, 1: write rd
assign RegDst = (Opcode[2:1] == 2'b00);
assign RegWrite = (Opcode[1:0] == 2'b11 || Opcode[2:1] == 2'b00);
assign Mul = ({Opcode, Func} == 4'b0010);
assign Slt = ({Opcode, Func} == 4'b0011);

//----- I type -----
assign ALUSrc = (Opcode[2:1] == 2'b01);
assign Add = (Opcode[2:1] == 2'b01 || {Opcode, Func} == 4'b0001); //load, store, add
// load
assign MemRead = (Opcode[1:0] == 2'b11);
assign MemtoReg = (Opcode[1:0] == 2'b11);
// store
assign MemWrite = (Opcode[1:0] == 2'b10);
// branch
assign Branch = ({Opcode[2], Opcode[0]} == 2'b11);

//----- J type -----
assign Jump = ({Opcode[2], Opcode[0]} == 2'b10);

endmodule

//###################################################### ALU ######################################################
module ALU (
  input wire Add,
  input wire Slt,
  input wire signed [15:0] In1,
  input wire signed [15:0] In2,
  output wire signed [15:0] Out
);

wire signed [15:0] In2_N, Add_in1, Add_in2, Sum;

assign In2_N = ~In2 + 1'b1;
assign Add_in1 = In1;
assign Add_in2 = (Add) ? In2 : In2_N;
assign Sum = (Add_in1 + Add_in2);
assign Out = Slt ? {15'b0, Sum[15]} : Sum;

endmodule

//################################################################################################################
module HAZARD_CTRL (
  // 1: Load, Mul
  input wire FirstInstr_MemRead, // EX_MEM
  input wire FirstInstr_Mul, // EX_MUL
  input wire [3:0] FirstInstr_Rt, // EX_MEM
  input wire [3:0] FirstInstr_Rd, // EX_MUL
  // 2: Load, Mul
  input wire FrontInstr_MemRead,
  input wire FrontInstr_Mul,
  input wire FrontInstr_RegWrite,
  input wire [3:0] FrontInstr_Rd,
  // 3
  input wire BackInstr_Mul,
  input wire BackInstr_Branch,
  input wire [2:0] BackInstr_Opcode,
  input wire [3:0] BackInstr_Rs,
  input wire [3:0] BackInstr_Rt,
  // Control Signal
  output PC_Write,
  output IF_ID_Write,
  output Stall
);

reg mul_hazrad, load_hazard, branch_hazard;
wire hazard;

// Mul
always @(*) begin
  if (FrontInstr_Mul) begin
    if (BackInstr_Mul)
      mul_hazrad = ((FrontInstr_Rd==BackInstr_Rs) || (FrontInstr_Rd==BackInstr_Rt));
    else
      mul_hazrad = 1'b1;
  end
  else
    mul_hazrad = 1'b0;
end
// Load
always @(*) begin
  if (FrontInstr_MemRead) begin // Load
    if (BackInstr_Opcode[2:1]==2'b00) // R type
      load_hazard = ((FrontInstr_Rd==BackInstr_Rs) || (FrontInstr_Rd==BackInstr_Rt));
    else if (BackInstr_Opcode[2:1]==2'b01) // Load, Store
      load_hazard = (FrontInstr_Rd==BackInstr_Rs);
    else
      load_hazard = 1'b0;
  end
  else
    load_hazard = 1'b0;
end
// Branch
always @(*) begin
  if (BackInstr_Branch) begin
    if (FrontInstr_RegWrite)
      branch_hazard = ((FrontInstr_Rd==BackInstr_Rs) || (FrontInstr_Rd==BackInstr_Rt));
    else if (FirstInstr_Mul)
      branch_hazard = ((FirstInstr_Rd==BackInstr_Rs) || (FirstInstr_Rd==BackInstr_Rt));
    else if (FirstInstr_MemRead)
      branch_hazard = ((FirstInstr_Rt==BackInstr_Rs) || (FirstInstr_Rt==BackInstr_Rt));
    else
      branch_hazard = 1'b0;
  end
  else
    branch_hazard = 1'b0;
end

assign hazard = mul_hazrad || load_hazard || branch_hazard;
assign PC_Write = ~hazard;
assign IF_ID_Write = ~hazard;
assign Stall = hazard;

endmodule

//################################################################################################################
module FORWARD_CTRL (
  input [3:0] Branch_Rs,
  input [3:0] Branch_Rt,
  input [3:0] ALU_Rs,
  input [3:0] ALU_Rt,
  input MEM_RegWrite,
  input [3:0] MEM_Rt,
  input [3:0] MEM_Rd,
  input WB_RegWrite,
  input [3:0] WB_Rd,
  output reg [1:0] ALUFwd_Rs,
  output reg [1:0] ALUFwd_Rt,
  output reg [1:0] BranchFwd_Rs,
  output reg [1:0] BranchFwd_Rt,
  output reg MemFwd
);

// ALU
always @(*) begin
  if (MEM_RegWrite && (ALU_Rs==MEM_Rd))
    ALUFwd_Rs = 'd1;
  else if (WB_RegWrite && (ALU_Rs==WB_Rd))
    ALUFwd_Rs = 'd2;
  else
    ALUFwd_Rs = 'd0;
end
always @(*) begin
  if (MEM_RegWrite && (ALU_Rt==MEM_Rd))
    ALUFwd_Rt = 'd1;
  else if (WB_RegWrite && (ALU_Rt==WB_Rd))
    ALUFwd_Rt = 'd2;
  else
    ALUFwd_Rt = 'd0;
end

// MEM
always @(*) begin
  if (WB_RegWrite)
    MemFwd = (MEM_Rt==WB_Rd);
  else
    MemFwd = 'd0;
end

// Branch
always @(*) begin
  if (MEM_RegWrite && (Branch_Rs==MEM_Rd))
    BranchFwd_Rs = 'd1;
  else if (WB_RegWrite && (Branch_Rs==WB_Rd))
    BranchFwd_Rs = 'd2;
  else
    BranchFwd_Rs = 'd0;
end
always @(*) begin
  if (MEM_RegWrite && (Branch_Rt==MEM_Rd))
    BranchFwd_Rt = 'd1;
  else if (WB_RegWrite && (Branch_Rt==WB_Rd))
    BranchFwd_Rt = 'd2;
  else
    BranchFwd_Rt = 'd0;
end

endmodule

//################################################################################################################
