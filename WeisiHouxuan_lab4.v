// Template for Northwestern - CompEng 361 - Lab4 -- Version 1.1
// Groupname: weisihouxuan
// NetIDs: hgg8403, loe3291

// Some useful defines...please add your own
`define WORD_WIDTH 32
`define NUM_REGS 32

`define OPCODE_LUI        7'b0110111
`define OPCODE_AUIPC      7'b0010111
`define OPCODE_JAL        7'b1101111
`define OPCODE_JALR       7'b1100111
`define OPCODE_IMM        7'b0010011
`define OPCODE_COMPUTE    7'b0110011
`define OPCODE_BRANCH     7'b1100011
`define OPCODE_LOAD       7'b0000011
`define OPCODE_STORE      7'b0100011 

`define FUNC_ADD      3'b000
`define FUNC_SLL      3'b001
`define FUNC_SLT      3'b010
`define FUNC_SLTU     3'b011
`define FUNC_XOR      3'b100
`define FUNC_SRL      3'b101
`define FUNC_OR       3'b110
`define FUNC_AND      3'b111
`define FUNC_B       3'b000
`define FUNC_H       3'b001
`define FUNC_W       3'b010
`define FUNC_BU     3'b100
`define FUNC_HU     3'b101


`define AUX_FUNC_ADD  7'b0000000
`define AUX_FUNC_SUB  7'b0100000
`define AUX_FUNC_MUL_DIV  7'b0000001

`define SIZE_BYTE  2'b00
`define SIZE_HWORD 2'b01
`define SIZE_WORD  2'b10


module PipelinedCPU(halt, clk, rst);
   output halt;
   input clk, rst;

   wire [`WORD_WIDTH-1:0] PC, PC_F, PC_D, PC_E, PC_M, PC_W;
   wire [`WORD_WIDTH-1:0] InstWord, InstWord_F, InstWord_D;
   wire [`WORD_WIDTH-1:0] StoreData_M, DataWord_M;
   wire [1:0]  MemSize;
   assign MemSize = `SIZE_WORD;
   wire        MemWrEn_D, MemWrEn_E, MemWrEn_M;
   
   wire [4:0]  Rsrc1_D, Rsrc1_E, Rsrc1_M, Rsrc1_W;
   wire [4:0]  Rsrc2_D, Rsrc2_E, Rsrc2_M, Rsrc2_W;
   wire [4:0]  Rdst_D, Rdst_E, Rdst_M, Rdst_W;
   wire [`WORD_WIDTH-1:0] Rdata1_D, Rdata1_E;
   wire [`WORD_WIDTH-1:0] Rdata1_read_D, Rdata2_read_D;
   wire [`WORD_WIDTH-1:0] Rdata2_D, Rdata2_E, Rdata2_M;
   wire [`WORD_WIDTH-1:0] SrcA_E, SrcB_E, WriteData_E;
   wire [`WORD_WIDTH-1:0] RWrdata_W;
   wire        RWrEn_D, RWrEn_E, RWrEn_M, RWrEn_W;

   wire [`WORD_WIDTH-1:0] NPC, PC_Plus_4_F, PC_Plus_4_W;
   wire [6:0]  opcode_D, opcode_E, opcode_M, opcode_W;

   wire [6:0]  funct7_D, funct7_E, funct7_M, funct7_W;
   wire [2:0]  funct3_D, funct3_E, funct3_M, funct3_W;
   wire [31:0] imm_D, imm_E, imm_M, imm_W;


   wire [2:0] imm_sel_D, Load_sel_D, Load_sel_E, Load_sel_M;
   wire EUSrc_D, EUSrc_E;
   wire [1:0] Store_sel_D, Store_sel_E, Store_sel_M, RWr_sel_D, RWr_sel_E, RWr_sel_M, RWr_sel_W, NPC_sel;
   wire MemtoReg_D, MemtoReg_E, MemtoReg_M, MemtoReg_W;
   

   wire [31:0] StoreData_B_M;
   wire [31:0] StoreData_H_M;
   wire [31:0] StoreData_W_M;

   wire [31:0] LoadData_B_M;
   wire [31:0] LoadData_H_M;
   wire [31:0] LoadData_W_M;
   wire [31:0] LoadData_BU_M;
   wire [31:0] LoadData_HU_M;
   wire [31:0] LoadData_M, LoadData_W;

   wire [31:0] Result_W;
   wire [31:0] ExecutionResult_E, ExecutionResult_M, ExecutionResult_W;

   wire [31:0] PC_AUIPC_W, PC_branch_E, PC_jal_E, PC_jalr_E;

   wire stall;
   wire is_long_latency_ex;
   assign stall = is_long_latency_ex;
   wire Flush;
   // assign stall=1'b0;

   wire [1:0] FowardA_E, FowardB_E;
   wire Foward_Rdata1_D, Foward_Rdata2_D;
   

   wire invalid_op;
   
   // Only support R-TYPE ADD and SUB
   assign halt = invalid_op;
   assign invalid_op = !(((opcode_D == `OPCODE_COMPUTE) || (opcode_D == `OPCODE_AUIPC)
             || (opcode_D == `OPCODE_BRANCH) || (opcode_D == `OPCODE_IMM) || (opcode_D == `OPCODE_JAL)
             || (opcode_D == `OPCODE_JALR) || (opcode_D == `OPCODE_LOAD) || (opcode_D == `OPCODE_LUI) 
             || (opcode_D == `OPCODE_STORE)) && ((funct3_D == `FUNC_ADD) 
             || (funct3_D == `FUNC_AND) || (funct3_D == `FUNC_B) || (funct3_D == `FUNC_BU)
             || (funct3_D == `FUNC_H) || (funct3_D == `FUNC_HU) || (funct3_D == `FUNC_OR)
             || (funct3_D == `FUNC_SLL) || (funct3_D == `FUNC_SLT) || (funct3_D == `FUNC_SLTU)
             || (funct3_D == `FUNC_SRL) || (funct3_D == `FUNC_W) || (funct3_D == `FUNC_XOR)) ||
		      ((funct7_D == `AUX_FUNC_ADD) || (funct7_D == `AUX_FUNC_SUB))|| (funct7_D == `AUX_FUNC_MUL_DIV)) || (InstWord_F == 32'h00000000);
     

   

   // IF
   // Instruction Fetch****************************************************
   
   // Program Counter
   Reg PC_REG(.Din(NPC), .Qout(PC_F), .WE(!stall), .CLK(clk), .RST(rst));

   // Fetch Address Datapath
   assign PC_Plus_4_F = PC_F + 4;
   assign PC_branch_E = PC_E + imm_E;
   assign PC_jal_E = PC_E + imm_E;
   assign PC_jalr_E = ExecutionResult_E;
   MUX32_4_1 MUX_NPC(.a(PC_Plus_4_F), .b(PC_branch_E), .c(PC_jal_E), .d(PC_jalr_E), .sel(NPC_sel), .o(NPC));

   Mem   MEM(.InstAddr(PC_F), .InstOut(InstWord_F), 
            .DataAddr(ExecutionResult_M), .DataSize(MemSize), .DataIn(StoreData_M), .DataOut(DataWord_M), .WE(MemWrEn_M), .CLK(clk));
   assign PC = PC_F;
   assign InstWord = InstWord_F;
      // IF_ID_REG
      // SINGALS NEED TO BE PASSED TO ID
      // PC, InstWord
   IF_ID_REG IF_ID(.PC(PC_F), .InstWord(InstWord_F),

   .o_PC(PC_D), .o_InstWord(InstWord_D),

   .clk(clk), .rst(rst), .WE(!stall), .Flush(Flush));

   

   // ID 
   // Instruction Decode****************************************************
   assign opcode_D = InstWord_D[6:0];   
   assign Rdst_D = InstWord_D[11:7]; 
   assign Rsrc1_D = InstWord_D[19:15];
   assign Rsrc2_D = InstWord_D[24:20];
   assign funct3_D = InstWord_D[14:12];  // R-Type, I-Type, S-Type
   assign funct7_D = InstWord_D[31:25];  // R-Type
   // Control Unit
   Control CU(.funct7(funct7_D), .funct3(funct3_D), .opcode(opcode_D),
   .MemWrEn(MemWrEn_D), .RWrEn(RWrEn_D), .imm_sel(imm_sel_D), .EUSrc(EUSrc_D), .Store_sel(Store_sel_D), .Load_sel(Load_sel_D), .MemtoReg(MemtoReg_D), .RWr_sel(RWr_sel_D), .rst(rst));
   // Immediate Generation
   ImmGen IMM(.Inst(InstWord_D), .imm_sel(imm_sel_D), .imm(imm_D));
   // Register File
   RegFile RF(.AddrA(Rsrc1_D), .DataOutA(Rdata1_read_D), 
	      .AddrB(Rsrc2_D), .DataOutB(Rdata2_read_D), 
	      .AddrW(Rdst_W), .DataInW(RWrdata_W), .WenW(RWrEn_W), .CLK(clk));

   MUX32_2_1 MUX_Rdata1_D(.a(Rdata1_read_D), .b(RWrdata_W), .sel(Foward_Rdata1_D), .o(Rdata1_D));
   MUX32_2_1 MUX_Rdata2_D(.a(Rdata2_read_D), .b(RWrdata_W), .sel(Foward_Rdata2_D), .o(Rdata2_D));
      // ID_EX_REG
      // SIGNALS NEED TO BE PASSED TO EX
      // Rdata1, Rdata2, imm
      // EUSrc, Store_sel, MemWrEn, Load_sel, MemtoReg, RWr_sel, RWrEn 
      // opcode, funct3, funct7, Rsrc1, Rsrc2, Rdst
      // PC
   ID_EX_REG ID_EX(
      .Rdata1(Rdata1_D), .Rdata2(Rdata2_D), .imm(imm_D), 
      .EUSrc(EUSrc_D), .Store_sel(Store_sel_D), .MemWrEn(MemWrEn_D), .Load_sel(Load_sel_D), .MemtoReg(MemtoReg_D), .RWr_sel(RWr_sel_D), .RWrEn(RWrEn_D), 
      .opcode(opcode_D), .funct3(funct3_D), .funct7(funct7_D), .Rsrc1(Rsrc1_D), .Rsrc2(Rsrc2_D), .Rdst(Rdst_D), 
      .PC(PC_D),
      
      .o_Rdata1(Rdata1_E), .o_Rdata2(Rdata2_E), .o_imm(imm_E),
      .o_EUSrc(EUSrc_E), .o_Store_sel(Store_sel_E), .o_MemWrEn(MemWrEn_E), .o_Load_sel(Load_sel_E), .o_MemtoReg(MemtoReg_E), .o_RWr_sel(RWr_sel_E), .o_RWrEn(RWrEn_E),
      .o_opcode(opcode_E), .o_funct3(funct3_E), .o_funct7(funct7_E), .o_Rsrc1(Rsrc1_E), .o_Rsrc2(Rsrc2_E), .o_Rdst(Rdst_E),
      .o_PC(PC_E),
      
      .clk(clk), .rst(rst), .WE(!stall), .Flush(Flush));
   

   // EX 
   // Execute****************************************************
   
   Hazard_Unit Hazard(
   .opcode_D(opcode_D), .funct3_D(funct3_D), .funct7_D(funct7_D),
   .opcode_E(opcode_E), .funct3_E(funct3_E), .funct7_E(funct7_E),
   .opcode_M(opcode_M), .funct3_M(funct3_M), .funct7_M(funct7_M),
   .Rsrc1_D(Rsrc1_D), .Rsrc2_D(Rsrc2_D),
   .Rsrc1_E(Rsrc1_E), .Rsrc2_E(Rsrc2_E), 
   .Rdst_M(Rdst_M), .Rdst_W(Rdst_W), .RWrEn_M(RWrEn_M), .RWrEn_W(RWrEn_W), 
   .branch_taken(ExecutionResult_E[0]),

   .Foward_Rdata1_D(Foward_Rdata1_D), .Foward_Rdata2_D(Foward_Rdata2_D),
   .FowardA_E(FowardA_E), .FowardB_E(FowardB_E),
   
   .Flush(Flush));

   MUX32_4_1 MUX_Rdata1_E(.a(Rdata1_E), .b(ExecutionResult_M), .c(RWrdata_W), .d(LoadData_M), .sel(FowardA_E), .o(SrcA_E));
   MUX32_4_1 MUX_Rdata2_E(.a(Rdata2_E), .b(ExecutionResult_M), .c(RWrdata_W), .d(LoadData_M), .sel(FowardB_E), .o(WriteData_E));
   MUX32_2_1 MUX_opB(.a(WriteData_E), .b(imm_E), .sel(EUSrc_E), .o(SrcB_E));
   ExecutionUnit EU(.out(ExecutionResult_E), .opA(SrcA_E), .opB(SrcB_E), .func(funct3_E), .auxFunc(funct7_E), .opcode(opcode_E));
   SIM_LONG_EX_UNIT sim_long_ex(.clk(clk), .rst(rst), .opcode(opcode_E), .func(funct3_E), .auxFunc(funct7_E), .is_long_latency_ex(is_long_latency_ex));

   NPC_Unit NPCU(.rst(rst), .opcode(opcode_E), .logic_result(ExecutionResult_E[0]), .NPC_sel(NPC_sel));

      // EX_MEM_REG
      // SIGNALS NEED TO BE PASSED TO MEM
      // imm, ExecutionResult, Rdata2
      // Store_sel, MemWrEn, Load_sel, MemtoReg, RWr_sel, RWrEn
      // opcode, funct3, funct7, Rsrc1, Rsrc2, Rdst
      // PC
   EX_MEM_REG EX_MEM(
      .imm(imm_E), .ExecutionResult(ExecutionResult_E), .Rdata2(WriteData_E),
      .Store_sel(Store_sel_E), .MemWrEn(MemWrEn_E), .Load_sel(Load_sel_E), .MemtoReg(MemtoReg_E), .RWr_sel(RWr_sel_E), .RWrEn(RWrEn_E),
      .opcode(opcode_E), .funct3(funct3_E), .funct7(funct7_E), .Rsrc1(Rsrc1_E), .Rsrc2(Rsrc2_E), .Rdst(Rdst_E),
      .PC(PC_E),
      
      .o_imm(imm_M), .o_ExecutionResult(ExecutionResult_M), .o_Rdata2(Rdata2_M),
      .o_Store_sel(Store_sel_M), .o_MemWrEn(MemWrEn_M), .o_Load_sel(Load_sel_M), .o_MemtoReg(MemtoReg_M), .o_RWr_sel(RWr_sel_M), .o_RWrEn(RWrEn_M),
      .o_opcode(opcode_M), .o_funct3(funct3_M), .o_funct7(funct7_M), .o_Rsrc1(Rsrc1_M), .o_Rsrc2(Rsrc2_M), .o_Rdst(Rdst_M),
      .o_PC(PC_M),
      
      .clk(clk), .rst(rst), .is_long_latency_ex(is_long_latency_ex));

   // MEM
   // Memory Access****************************************************

   // StoreData
   assign StoreData_B_M = { {24{Rdata2_M[7]}}, Rdata2_M[7:0]};
   assign StoreData_H_M = { {16{Rdata2_M[15]}}, Rdata2_M[15:0]};
   assign StoreData_W_M = Rdata2_M;
   MUX32_4_1 MUX_StoreData(.a(StoreData_B_M), .b(StoreData_H_M), .c(StoreData_W_M), .d(StoreData_W_M), .sel(Store_sel_M), .o(StoreData_M));

   // Mem is already implemented in the IF stage
   
   // LoadData
   assign LoadData_B_M = { {24{DataWord_M[7]}}, DataWord_M[7:0]};
   assign LoadData_H_M = { {16{DataWord_M[15]}}, DataWord_M[15:0]};
   assign LoadData_W_M = DataWord_M;
   assign LoadData_BU_M = {24'b0, DataWord_M[7:0]};
   assign LoadData_HU_M = {16'b0, DataWord_M[15:0]};
   MUX32_8_1 MUX_LoadData(.a(LoadData_B_M), .b(LoadData_H_M), .c(LoadData_W_M), .d(LoadData_BU_M), .e(LoadData_HU_M), .f(LoadData_W_M), .g(LoadData_W_M), .h(LoadData_W_M), .sel(Load_sel_M), .o(LoadData_M));

      // MEM_WB_REG
      // SIGNALS NEED TO BE PASSED TO WB
      // LoadData, ExecutionResult, imm
      // MemtoReg, RWr_sel, RWrEn
      // opcode, funct3, funct7, Rsrc1, Rsrc2, Rdst
      // PC
   MEM_WB_REG MEM_WB(
      .LoadData(LoadData_M), .ExecutionResult(ExecutionResult_M), .imm(imm_M),
      .MemtoReg(MemtoReg_M), .RWr_sel(RWr_sel_M), .RWrEn(RWrEn_M),
      .opcode(opcode_M), .funct3(funct3_M), .funct7(funct7_M), .Rsrc1(Rsrc1_M), .Rsrc2(Rsrc2_M), .Rdst(Rdst_M),
      .PC(PC_M),

      .o_LoadData(LoadData_W), .o_ExecutionResult(ExecutionResult_W), .o_imm(imm_W),
      .o_MemtoReg(MemtoReg_W), .o_RWr_sel(RWr_sel_W), .o_RWrEn(RWrEn_W),
      .o_opcode(opcode_W), .o_funct3(funct3_W), .o_funct7(funct7_W), .o_Rsrc1(Rsrc1_W), .o_Rsrc2(Rsrc2_W), .o_Rdst(Rdst_W),
      .o_PC(PC_W),

      .clk(clk), .rst(rst));



   // WB
   // Write Back****************************************************


   // Mem or Ex Result to write back
   MUX32_2_1 MUX_Result(.a(ExecutionResult_W), .b(LoadData_W), .sel(MemtoReg_W), .o(Result_W));

   // write to register file
   assign PC_AUIPC_W = PC_W + (imm_W<<12);
   assign PC_Plus_4_W = PC_W + 4;
   MUX32_4_1 MUX_RWrdata(.a(PC_Plus_4_W), .b(PC_AUIPC_W), .c(Result_W), .d(Result_W), .sel(RWr_sel_W), .o(RWrdata_W));


   
endmodule // PipelinedCPU


module ExecutionUnit(out, opA, opB, func, auxFunc, opcode);
   output [`WORD_WIDTH-1:0] out;
   input [`WORD_WIDTH-1:0] opA, opB;
   input [2:0] func;
   input [6:0] auxFunc, opcode;

   input rst;
   // reg is_long_latency_ex;
   output reg is_long_latency_ex;

   wire [`WORD_WIDTH-1:0] add, sub, slli, srli, srai,
                        logicAnd, logicOr, logicXor, slti, sltiu,
                        mul, mulh, mulhsu, mulhu, div, divu, rem, remu,
                        lui, jal, jalr, addi, xori, ori, andi,
                        slli_imm, srli_imm, srai_imm, load_store_addr, branch,
                        mul_result, mulh_result, mulhsu_result, mulhu_result, 
                        div_result, divu_result, rem_result, remu_result;
   wire [63:0] full_product, full_product_s, full_product_su;

   assign add = opA + opB;
   assign sub = opA - opB;
   assign slli = opA << opB[4:0];
   assign compLT = ($signed(opA) < $signed(opB)) ? 1 : 0;
   assign compLTU = (opA < opB) ? 1 : 0;
   assign logicXor = opA ^ opB;
   assign srli = opA >> opB[4:0];
   assign srai = $signed(opA) >>> opB[4:0];
   assign logicOr = opA | opB;
   assign logicAnd = opA & opB;

   assign addi = opA + opB;
   assign slti = ($signed(opA) < $signed(opB)) ? 1 : 0;
   assign sltiu = (opA < opB) ? 1 : 0;
   assign xori = opA ^ opB;
   assign ori = opA | opB;
   assign andi = opA & opB;
   assign slli_imm = opA << opB[4:0];
   assign srli_imm = opA >> opB[4:0];
   assign srai_imm = $signed(opA) >>> opB[4:0];

   assign lui = opB << 12;
   assign jal = opA + opB;
   assign jalr = (opA + opB) & ~1;

   assign branch = (func == 3'b000 && opA == opB) ? 1 :         // BEQ
                  (func == 3'b001 && opA != opB) ? 1 :         // BNE
                  (func == 3'b100 && $signed(opA) < $signed(opB)) ? 1 : // BLT
                  (func == 3'b101 && $signed(opA) >= $signed(opB)) ? 1 : // BGE
                  (func == 3'b110 && opA < opB) ? 1 :          // BLTU
                  (func == 3'b111 && opA >= opB) ? 1 : 0;      // BGEU
   assign load_store_addr = opA + opB;

   assign full_product = opA * opB;
   assign full_product_s = $signed(opA) * $signed(opB);
   assign full_product_su = $signed(opA) * opB;
   assign mul_result = full_product_s[31:0];
   assign mulh_result = full_product_s[63:32];
   assign mulhsu_result = full_product_su[63:32];
   assign mulhu_result = full_product[63:32];
   assign div_result = $signed(opA) / $signed(opB);
   assign divu_result = opA / opB;
   assign rem_result = $signed(opA) % $signed(opB);
   assign remu_result = opA % opB;

   assign out = ((opcode == `OPCODE_COMPUTE) && (auxFunc != `AUX_FUNC_MUL_DIV)) ? 
                     ((func == 3'b000) ? ((auxFunc == `AUX_FUNC_ADD) ? add : sub) :
                        (func == 3'b001) ? slli :
                        (func == 3'b010) ? compLT :
                        (func == 3'b011) ? compLTU :
                        (func == 3'b100) ? logicXor :
                        (func == 3'b101) ? ((auxFunc == `AUX_FUNC_SUB) ? srai : srli) :
                        (func == 3'b110) ? logicOr :
                        (func == 3'b111) ? logicAnd : 32'hXXXXXXXX) :
                  (opcode == `OPCODE_IMM) ? 
                     ((func == 3'b000) ? addi :
                        (func == 3'b010) ? slti :
                        (func == 3'b011) ? sltiu :
                        (func == 3'b100) ? xori :
                        (func == 3'b110) ? ori :
                        (func == 3'b111) ? andi :
                        (func == 3'b001) ? slli_imm :
                        (func == 3'b101) ? ((auxFunc == `AUX_FUNC_SUB) ? srai_imm : srli_imm) :
                        32'hXXXXXXXX) :
                  (opcode == `OPCODE_LUI) ? lui :
                  (opcode == `OPCODE_JAL) ? jal :
                  (opcode == `OPCODE_JALR) ? jalr :
                  (opcode == `OPCODE_BRANCH) ? branch :
                  (opcode == `OPCODE_LOAD || opcode == `OPCODE_STORE) ? load_store_addr :
                  (opcode == `OPCODE_COMPUTE && auxFunc == `AUX_FUNC_MUL_DIV) ?
                     ((func == 3'b000) ? mul_result :
                        (func == 3'b001) ? mulh_result :
                        (func == 3'b010) ? mulhsu_result :
                        (func == 3'b011) ? mulhu_result :
                        (func == 3'b100) ? div_result :
                        (func == 3'b101) ? divu_result :
                        (func == 3'b110) ? rem_result :
                        (func == 3'b111) ? remu_result :
                        32'hXXXXXXXX) :
                  32'hXXXXXXXX;
   

endmodule // ExecutionUnit

module NPC_Unit(rst, opcode, logic_result, NPC_sel);
   input rst;
   input [6:0] opcode;
   input logic_result;
   output [1:0] NPC_sel;
   assign NPC_sel = (!rst)? 2'b00:
                     (opcode == `OPCODE_BRANCH && logic_result) ? 2'b01 :
                         (opcode == `OPCODE_JAL) ? 2'b10 : 
                           (opcode == `OPCODE_JALR) ? 2'b11 : 
                           2'b00;
endmodule   

module Control(funct7, funct3, opcode, MemWrEn, RWrEn, imm_sel, EUSrc, Store_sel, Load_sel, MemtoReg, RWr_sel, rst);
      input [6:0] funct7;
      input [2:0] funct3;
      input [6:0] opcode;
      input rst;
      output [2:0] imm_sel, Load_sel;
      output EUSrc;
      output [1:0] Store_sel, RWr_sel;
      output MemtoReg;
      output MemWrEn, RWrEn;
   
      assign MemWrEn = (!rst)? 1'b0: (opcode == `OPCODE_STORE) ? 1'b1 : 1'b0;
      assign RWrEn = (!rst)? 1'b0: (opcode == `OPCODE_COMPUTE || opcode == `OPCODE_IMM || opcode == `OPCODE_LUI || opcode == `OPCODE_AUIPC || opcode == `OPCODE_LOAD || opcode == `OPCODE_JAL || opcode == `OPCODE_JALR) ? 1 : 0;
      assign imm_sel = (opcode == `OPCODE_IMM && funct3 == `FUNC_SLTU) ? 3'b100 : 
                       (opcode == `OPCODE_BRANCH) ? 3'b110 : 
                       (opcode == `OPCODE_LOAD || (opcode == `OPCODE_IMM && funct3 != `FUNC_SLTU) ) ? 3'b011 : 
                       (opcode == `OPCODE_STORE) ? 3'b101 : 
                       (opcode == `OPCODE_LUI || opcode == `OPCODE_AUIPC) ? 3'b000 :
                       (opcode == `OPCODE_JAL) ? 3'b001 : 
                       (opcode == `OPCODE_JALR) ? 3'b010 : 3'b000;
      assign EUSrc = (opcode == `OPCODE_IMM || opcode == `OPCODE_LUI || opcode == `OPCODE_AUIPC || opcode == `OPCODE_JAL || opcode == `OPCODE_JALR || opcode == `OPCODE_LOAD || opcode == `OPCODE_STORE ) ? 1'b1 : 1'b0;
      assign Store_sel = (opcode == `OPCODE_STORE) ? 
                           (funct3 == `FUNC_B) ? 2'b00 :
                           (funct3 == `FUNC_H) ? 2'b01 :
                           (funct3 == `FUNC_W) ? 2'b10 : 2'b00
                           : 2'b00;
      assign Load_sel = (opcode == `OPCODE_LOAD) ? 
                           (funct3 == `FUNC_B) ? 3'b000 : 
                           (funct3 == `FUNC_H) ? 3'b001 :
                           (funct3 == `FUNC_W) ? 3'b010 :
                           (funct3 == `FUNC_BU) ? 3'b011 :
                           (funct3 == `FUNC_HU) ? 3'b100 : 3'b000
                           : 3'b000;
      assign MemtoReg = (opcode == `OPCODE_LOAD) ? 1'b1 : 1'b0;
      assign RWr_sel = (opcode == `OPCODE_LUI || opcode == `OPCODE_LOAD || opcode == `OPCODE_IMM || opcode == `OPCODE_COMPUTE) ? 2'b10 :
                        (opcode == `OPCODE_AUIPC) ? 2'b01 :
                        (opcode == `OPCODE_JAL || opcode == `OPCODE_JALR) ? 2'b00 : 
                        2'b10;
      
endmodule


module ImmGen(Inst, imm_sel, imm);
    input [31:0] Inst;
    input [2:0] imm_sel;
    output [31:0] imm;
 
    wire [31:0] imm_U;
    wire [31:0] imm_JAL;
    wire [31:0] imm_JALR;
    wire [31:0] imm_I_s;
    wire [31:0] imm_I_u;
    wire [31:0] imm_S;
    wire [31:0] imm_B;

   assign imm_U = {12'b0, Inst[31:12]};
   assign imm_JAL = { {11{Inst[31]}}, Inst[31], Inst[19:12], Inst[20], Inst[30:21], 1'b0 };
   assign imm_JALR = {{20{Inst[31]}}, Inst[31:20]};
   assign imm_I_s = {{20{Inst[31]}}, Inst[31:20]};
   assign imm_I_u = { 20'b0, Inst[31:20] };
   assign imm_S = { {20{Inst[31]}}, Inst[31:25], Inst[11:7]};
   assign imm_B = { {20{Inst[31]}}, Inst[7], Inst[30:25], Inst[11:8], 1'b0};

   assign imm = (imm_sel == 3'b000) ? imm_U :
                (imm_sel == 3'b001) ? imm_JAL :
                (imm_sel == 3'b010) ? imm_JALR :
                (imm_sel == 3'b011) ? imm_I_s :
                (imm_sel == 3'b100) ? imm_I_u :
                (imm_sel == 3'b101) ? imm_S :
                (imm_sel == 3'b110) ? imm_B : 32'b0;
endmodule

module MUX32_8_1(a, b, c, d, e, f, g, h, sel, o);
    input [31:0] a, b, c, d, e, f, g, h;  
    input [2:0] sel;          
    output [31:0] o;          

   
    assign o = (sel == 3'b000) ? a :
               (sel == 3'b001) ? b :
               (sel == 3'b010) ? c :
               (sel == 3'b011) ? d :
               (sel == 3'b100) ? e :
               (sel == 3'b101) ? f :
               (sel == 3'b110) ? g :
               (sel == 3'b111) ? h : 32'b0;  // 0 BY DEFAULT
endmodule


module MUX32_4_1(a, b, c, d, sel, o);
    input [31:0] a, b, c, d;  
    input [1:0] sel;          
    output [31:0] o;          

   
    assign o = (sel == 2'b00) ? a :
               (sel == 2'b01) ? b :
               (sel == 2'b10) ? c :
               (sel == 2'b11) ? d : 32'b0;  // 0 BY DEFAULT
endmodule

module MUX32_2_1(a, b, sel, o);
    input [31:0] a, b;  
    input sel;          
    output [31:0] o;          

   
    assign o = (sel == 1'b0) ? a :
               (sel == 1'b1) ? b : 32'b0;  // 0 BY DEFAULT
endmodule


module IF_ID_REG(PC, InstWord, 

o_PC, o_InstWord, 

clk, rst, WE, Flush);
      input [`WORD_WIDTH-1:0] PC, InstWord;
      output [`WORD_WIDTH-1:0] o_PC, o_InstWord;
      input clk, rst, WE ,Flush;
      reg [`WORD_WIDTH-1:0] o_PC, o_InstWord;
      always @(negedge clk or negedge rst)
         if (!rst || Flush)
            begin
               o_PC <= 32'h00000000;
               o_InstWord <= 32'h00000013; //"NOP" instrution: addi x0, x0, 0
            end
         else
            begin
               if(WE)
                  begin
                     o_PC <= PC;
                     o_InstWord <= InstWord;
                  end
            end
      
endmodule

module ID_EX_REG(Rdata1, Rdata2, imm, 
EUSrc, Store_sel, MemWrEn, Load_sel, MemtoReg, RWr_sel, RWrEn, 
opcode, funct3, funct7, Rsrc1, Rsrc2, Rdst, 
PC,

o_Rdata1, o_Rdata2, o_imm,
o_EUSrc, o_Store_sel, o_MemWrEn, o_Load_sel, o_MemtoReg, o_RWr_sel, o_RWrEn,
o_opcode, o_funct3, o_funct7, o_Rsrc1, o_Rsrc2, o_Rdst,
o_PC,

clk, rst, WE, Flush);
      input [31:0] Rdata1, Rdata2, imm;
      input EUSrc, MemWrEn,  MemtoReg, RWrEn;
      input [1:0] RWr_sel;
      input [2:0] Load_sel;
      input [1:0] Store_sel;
      input [6:0] opcode, funct7;
      input [2:0] funct3;
      input [4:0] Rsrc1, Rsrc2, Rdst;
      input [31:0] PC;
      output [31:0] o_Rdata1, o_Rdata2, o_imm;
      output o_EUSrc;
      output [1:0] o_Store_sel, o_RWr_sel;
      output o_MemtoReg;
      output o_MemWrEn, o_RWrEn;
      output [2:0] o_Load_sel;
      output [6:0] o_opcode, o_funct7;
      output [2:0] o_funct3;
      output [4:0] o_Rsrc1, o_Rsrc2, o_Rdst;
      output [31:0] o_PC;
      input clk, rst, WE, Flush;
      reg [31:0] o_Rdata1, o_Rdata2, o_imm;
      reg o_EUSrc;
      reg [1:0] o_Store_sel, o_RWr_sel;
      reg o_MemtoReg;
      reg o_MemWrEn, o_RWrEn;
      reg [2:0] o_Load_sel;
      reg [6:0] o_opcode, o_funct7;
      reg [2:0] o_funct3;
      reg [4:0] o_Rsrc1, o_Rsrc2, o_Rdst;
      reg [31:0] o_PC;
      always @(negedge clk or negedge rst)
         if (!rst || Flush)
            begin
               o_Rdata1 <= 32'h00000000;
               o_Rdata2 <= 32'h00000000;
               o_imm <= 32'h00000000;
               o_EUSrc <= 1'b0;
               o_Store_sel <= 2'b00;
               o_MemWrEn <= 1'b0;
               o_Load_sel <= 3'b000;
               o_MemtoReg <= 1'b0;
               o_RWr_sel <= 2'b00;
               o_RWrEn <= 1'b0;
               o_opcode <= 7'b0000000;
               o_funct3 <= 3'b000;
               o_funct7 <= 7'b0000000;
               o_Rsrc1 <= 5'b00000;
               o_Rsrc2 <= 5'b00000;
               o_Rdst <= 5'b00000;
               o_PC <= 32'h00000000;
            end
         else
            begin
               if(WE)
               begin
                  o_Rdata1 <= Rdata1;
                  o_Rdata2 <= Rdata2;
                  o_imm <= imm;
                  o_EUSrc <= EUSrc;
                  o_Store_sel <= Store_sel;
                  o_MemWrEn <= MemWrEn;
                  o_Load_sel <= Load_sel;
                  o_MemtoReg <= MemtoReg;
                  o_RWr_sel <= RWr_sel;
                  o_RWrEn <= RWrEn;
                  o_opcode <= opcode;
                  o_funct3 <= funct3;
                  o_funct7 <= funct7;
                  o_Rsrc1 <= Rsrc1;
                  o_Rsrc2 <= Rsrc2;
                  o_Rdst <= Rdst;
                  o_PC <= PC;
               end
            end
endmodule

module EX_MEM_REG(imm, ExecutionResult, Rdata2,
Store_sel, MemWrEn, Load_sel, MemtoReg, RWr_sel, RWrEn,
opcode, funct3, funct7, Rsrc1, Rsrc2, Rdst,
PC,

o_imm, o_ExecutionResult, o_Rdata2,
o_Store_sel, o_MemWrEn, o_Load_sel, o_MemtoReg, o_RWr_sel, o_RWrEn,
o_opcode, o_funct3, o_funct7, o_Rsrc1, o_Rsrc2, o_Rdst,
o_PC,

clk, rst, is_long_latency_ex);
      input [31:0] imm, ExecutionResult, Rdata2;
      input  MemWrEn, MemtoReg, RWrEn;
      input [1:0] RWr_sel;
      input [2:0] Load_sel;
      input [1:0] Store_sel;
      input [6:0] opcode, funct7;
      input [2:0] funct3;
      input [4:0] Rsrc1, Rsrc2, Rdst;
      input [31:0] PC;
      output [31:0] o_imm, o_ExecutionResult, o_Rdata2;
      output o_MemWrEn, o_MemtoReg, o_RWrEn;
      output [1:0] o_RWr_sel;
      output [1:0] o_Store_sel;
      output [2:0] o_Load_sel;
      output [6:0] o_opcode, o_funct7;
      output [2:0] o_funct3;
      output [4:0] o_Rsrc1, o_Rsrc2, o_Rdst;
      output [31:0] o_PC;
      input clk, rst, is_long_latency_ex;
      reg [31:0] o_imm, o_ExecutionResult, o_Rdata2;
      reg o_MemWrEn, o_MemtoReg, o_RWrEn;
      reg [1:0] o_RWr_sel;
      reg [2:0] o_Load_sel;
      reg [1:0] o_Store_sel;
      reg [6:0] o_opcode, o_funct7;
      reg [2:0] o_funct3;
      reg [4:0] o_Rsrc1, o_Rsrc2, o_Rdst;
      reg [31:0] o_PC;
      always @(negedge clk or negedge rst)
         if (!rst || is_long_latency_ex)
            begin
               o_imm <= 32'h00000000;
               o_ExecutionResult <= 32'h00000000;
               o_Rdata2 <= 32'h00000000;
               o_Store_sel <= 1'b0;
               o_MemWrEn <= 1'b0;
               o_Load_sel <= 3'b000;
               o_MemtoReg <= 1'b0;
               o_RWr_sel <= 2'b00;
               o_RWrEn <= 1'b0;
               o_opcode <= 7'b0000000;
               o_funct3 <= 3'b000;
               o_funct7 <= 7'b0000000;
               o_Rsrc1 <= 5'b00000;
               o_Rsrc2 <= 5'b00000;
               o_Rdst <= 5'b00000;
               o_PC <= 32'h00000000;
            end
         else
            begin
               o_imm <= imm;
               o_ExecutionResult <= ExecutionResult;
               o_Rdata2 <= Rdata2;
               o_Store_sel <= Store_sel;
               o_MemWrEn <= MemWrEn;
               o_Load_sel <= Load_sel;
               o_MemtoReg <= MemtoReg;
               o_RWr_sel <= RWr_sel;
               o_RWrEn <= RWrEn;
               o_opcode <= opcode;
               o_funct3 <= funct3;
               o_funct7 <= funct7;
               o_Rsrc1 <= Rsrc1;
               o_Rsrc2 <= Rsrc2;
               o_Rdst <= Rdst;
               o_PC <= PC;
            end
endmodule

module MEM_WB_REG(LoadData, ExecutionResult, imm,
MemtoReg, RWr_sel, RWrEn,
opcode, funct3, funct7, Rsrc1, Rsrc2, Rdst,
PC,

o_LoadData, o_ExecutionResult, o_imm,
o_MemtoReg, o_RWr_sel, o_RWrEn,
o_opcode, o_funct3, o_funct7, o_Rsrc1, o_Rsrc2, o_Rdst,
o_PC,

clk, rst);
      input [31:0] LoadData, ExecutionResult, imm;
      input MemtoReg, RWrEn;
      input [1:0] RWr_sel;
      input [6:0] opcode, funct7;
      input [2:0] funct3;
      input [4:0] Rsrc1, Rsrc2, Rdst;
      input [31:0] PC;
      output [31:0] o_LoadData, o_ExecutionResult, o_imm;
      output o_MemtoReg, o_RWrEn;
      output [1:0] o_RWr_sel;
      output [6:0] o_opcode, o_funct7;
      output [2:0] o_funct3;
      output [4:0] o_Rsrc1, o_Rsrc2, o_Rdst;
      output [31:0] o_PC;
      input clk, rst;
      reg [31:0] o_LoadData, o_ExecutionResult, o_imm;
      reg o_MemtoReg, o_RWrEn;
      reg [1:0] o_RWr_sel;
      reg [6:0] o_opcode, o_funct7;
      reg [2:0] o_funct3;
      reg [4:0] o_Rsrc1, o_Rsrc2, o_Rdst;
      reg [31:0] o_PC;
      always @(negedge clk or negedge rst)
         if (!rst)
            begin
               o_LoadData <= 32'h00000000;
               o_ExecutionResult <= 32'h00000000;
               o_imm <= 32'h00000000;
               o_MemtoReg <= 1'b0;
               o_RWr_sel <= 2'b00;
               o_RWrEn <= 1'b0;
               o_opcode <= 7'b0000000;
               o_funct3 <= 3'b000;
               o_funct7 <= 7'b0000000;
               o_Rsrc1 <= 5'b00000;
               o_Rsrc2 <= 5'b00000;
               o_Rdst <= 5'b00000;
               o_PC <= 32'h00000000;
            end
         else
            begin
               o_LoadData <= LoadData;
               o_ExecutionResult <= ExecutionResult;
               o_imm <= imm;
               o_MemtoReg <= MemtoReg;
               o_RWr_sel <= RWr_sel;
               o_RWrEn <= RWrEn;
               o_opcode <= opcode;
               o_funct3 <= funct3;
               o_funct7 <= funct7;
               o_Rsrc1 <= Rsrc1;
               o_Rsrc2 <= Rsrc2;
               o_Rdst <= Rdst;
               o_PC <= PC;
            end
endmodule


module SIM_LONG_EX_UNIT(clk, rst, opcode, func ,auxFunc, is_long_latency_ex); 
   input [6:0] opcode;
   input [6:0] auxFunc;
   input [2:0] func;
   input clk, rst;
   output reg is_long_latency_ex;

   parameter ex_latency_mul = 3;
   parameter ex_latency_div = 19;

   wire is_mul;
   wire is_div;
   reg [5:0] count;

   assign is_mul = (opcode == `OPCODE_COMPUTE && auxFunc == `AUX_FUNC_MUL_DIV && func[2] == 1'b0) ? 1 : 0;
   assign is_div = (opcode == `OPCODE_COMPUTE && auxFunc == `AUX_FUNC_MUL_DIV && func[2] == 1'b1) ? 1 : 0;

   // latency
   always @ (posedge clk or negedge rst) begin
         if (!rst) begin
            is_long_latency_ex <= 0;
            count <= 0;
         end
         else if (is_div) begin
            if (count == ex_latency_div) begin
               is_long_latency_ex <= 0;
               count <= 0;
            end
            else begin
               is_long_latency_ex <= 1;
               count <= count + 1;
            end
         end
         else if (is_mul) begin
            if (count == ex_latency_mul) begin
               is_long_latency_ex <= 0;
               count <= 0;
            end
            else begin
               is_long_latency_ex <= 1;
               count <= count + 1;
            end
         end
         else begin
            is_long_latency_ex <= 0;
            count <= 0;
         end
      end
endmodule

module Hazard_Unit(
opcode_D, funct3_D, funct7_D,
opcode_E, funct3_E, funct7_E,
opcode_M, funct3_M, funct7_M,
Rsrc1_D, Rsrc2_D,
Rsrc1_E, Rsrc2_E, 
Rdst_M, Rdst_W, RWrEn_M, RWrEn_W,
branch_taken,

Foward_Rdata1_D, Foward_Rdata2_D,
FowardA_E, FowardB_E,

Flush);
   input [6:0] opcode_D;
   input [2:0] funct3_D;
   input [6:0] funct7_D;
   input [6:0] opcode_E;
   input [2:0] funct3_E;
   input [6:0] funct7_E;
   input [6:0] opcode_M;
   input [2:0] funct3_M;
   input [6:0] funct7_M;
   input [4:0] Rsrc1_D, Rsrc2_D;
   input [4:0] Rsrc1_E, Rsrc2_E, Rdst_M, Rdst_W;
   input RWrEn_M, RWrEn_W;
   input branch_taken;
   output Foward_Rdata1_D, Foward_Rdata2_D;
   output [1:0] FowardA_E, FowardB_E;
   output Flush;

   wire match_Rdata1_D_W, match_Rdata2_D_W;
   wire match_A_E_M, match_A_E_W, match_B_E_M, match_B_E_W;
   wire match_A_E_M_load, match_B_E_M_load;

   assign match_Rdata1_D_W = (RWrEn_W && Rdst_W == Rsrc1_D && Rdst_W != 5'b00000);
   assign match_Rdata2_D_W = (RWrEn_W && Rdst_W == Rsrc2_D && Rdst_W != 5'b00000);
   assign match_A_E_M_ex = (RWrEn_M && Rdst_M == Rsrc1_E && opcode_M != `OPCODE_LOAD && Rdst_M != 5'b00000);
   assign match_A_E_W = (RWrEn_W && Rdst_W == Rsrc1_E && Rdst_W != 5'b00000);
   assign match_B_E_M_ex = (RWrEn_M && Rdst_M == Rsrc2_E && opcode_M != `OPCODE_LOAD && Rdst_M != 5'b00000);
   assign match_B_E_W = (RWrEn_W && Rdst_W == Rsrc2_E && Rdst_W != 5'b00000);
   assign match_A_E_M_load = (RWrEn_M && Rdst_M == Rsrc1_E && opcode_M == `OPCODE_LOAD && Rdst_M != 5'b00000);
   assign match_B_E_M_load = (RWrEn_M && Rdst_M == Rsrc2_E && opcode_M == `OPCODE_LOAD && Rdst_M != 5'b00000);

   assign Foward_Rdata1_D = (match_Rdata1_D_W) ? 1'b1 : 1'b0;
   assign Foward_Rdata2_D = (match_Rdata2_D_W) ? 1'b1 : 1'b0;
   assign FowardA_E = (match_A_E_M_load) ? 2'b11 :
                     (match_A_E_W) ? 2'b10 :
                     (match_A_E_M_ex) ? 2'b01 : 2'b00;
   assign FowardB_E = (match_B_E_M_load) ? 2'b11 :
                     (match_B_E_W) ? 2'b10 :
                     (match_B_E_M_ex) ? 2'b01 : 2'b00;

   assign Flush = (opcode_E == `OPCODE_BRANCH && branch_taken) ? 1'b1 : 1'b0;

endmodule