`timescale 1ns / 1ps

`define WORD_SIZE 16 //data and address word size

//Combinational instructions
//ADD 0001_I_REG_REG_REG_XX
//	//if I is high, do reg + reg, if I is low, treat last 5 bits as immediate
//SUB 0010_I_REG_REG_REG_XX
//MUL 0011_I_REG_REG_REG_XX
//AND 0100_I_REG_REG_REG_XX
//NOT 0101_X_REG_REG //First reg is result reg, second reg is input reg

//Load Store type instructiosn
//ST  0110_REG_imm9 //store from reg into memory address
//LD  0111_REG_imm9 //load into reg from memory address
//STR 1000_REG_REG_irrelevant //stores from reg to memory address in reg
//LDR 1001_REG_REG_irrelevant //load into reg from memory address in reg
//STI 1010_REG_imm9 //Store from register into PC + imm9 **UNIMPLEMENTED
//LDI 1011_REG_imm9 //Load into register from PC + imm9 **UNIMPLEMENTED

//Control Instructions
//JMP 1100_REG_000000000 //Jump to address in register
//RET 1101 //Jump to address in R7 (return register)
//BRZ 1110_REG_imm9 //Jump to address at imm9 if REG is zero. 
//BRN 1111_REG_imm9 //Jump to address at imm9 if REG is nonzero.
//NOP 0000


//////////////////////////////////////////////////////////////////////////////////
`define ADD     4'b0001
`define SUB     4'b0010
`define MUL     4'b0011
`define AND     4'b0100
//operations
`define NOT     4'b0101
`define ST      4'b0110
`define LD      4'b0111
`define STR     4'b1000
`define LDR     4'b1001
`define STI     4'b1010 //Unimplemented
`define LDI     4'b1011 //Unimplemented
`define JMP     4'b1100
`define RET     4'b1101
`define BRZ     4'b1110
`define BRN     4'b1111
`define NOP     4'b0000

module cpuStructSim(
	input wire clock, //clock signal
    input wire reset, //reset pin, mainly for testing
	
	//Instruction Memory
    input wire[15:0] instrData_in, //memDataIn is used to read whatever is in an LD or LDR
	output instrReadM,
	output reg instrWriteM,
	output [7:0] instrAddress,
	output wire[15:0] instrData_out,
	
	//Data Memory
	input wire[15:0] ramData_in,
	output ramReadM,
	output ramWriteM,
	output[7:0] ramAddress,
	output wire[15:0] ramData_out

    );
	//Program Counter Related
	reg[7:0] PC, nextPC;
	// IF/ID pipeline Registers, no control signals atm
	reg[15:0]	IF_ID_Inst;
	reg[7:0]	IF_ID_PC, IF_ID_nextPC;
	//ID/EX pipeline registers
	//Non control signals
	reg[15:0] 	ID_EX_RFread1, ID_EX_RFread2, ID_EX_sext5, ID_EX_sext9; 
	reg[7:0] 	ID_EX_PC, ID_EX_nextPC;
	reg[2:0] 	ID_EX_RFwriteAddress;
	//control signals
	reg 		ID_EX_isBranch, ID_EX_isJump, ID_EX_aluSrcA, ID_EX_aluSrcB, 
	ID_EX_dataMemRead, ID_EX_dataMemWrite, ID_EX_regWrite, ID_EX_immType 
	ID_EX_compOrLoad;
	//aluSrcB is ROI aluSrcA is LDorST, 1 for using regfile stuff, 0 for using other. 
	reg[3:0] 	ID_EX_aluOP;
	//EX/MEM pipeline Registers
	reg[15:0] 	EX_MEM_aluResult, EX_MEM_dataOut;
	reg[7:0] 	EX_MEM_PC, EX_MEM_nextPC;
	reg[2:0] 	EX_MEM_RFwriteAddress;
	reg 		EX_MEM_dataMemRead, EX_MEM_dataMemWrite, EX_MEM_regWrite; //keep some control signals from ID/EX stage
	reg 		EX_MEM_compOrLoad; //control signal for if result is computational or a load, so use aluResult or datafromMem
	//MEM/WB pipeline registers
	reg[15:0] 	MEM_WB_dataToWriteback, MEM_WB_aluResult, MEM_WB_dataFromMem;
	reg[2:0] 	MEM_WB_RFwriteAddress;
	reg 		MEM_WB_regWrite, MEM_WB_compOrLoad;
	//Now we need control signals for all the data.
	wire 		isBranch, isJump, aluSrcA, aluSrcB, dataMemRead, dataMemWrite, regWrite, compOrLoad, immType;
	wire 		IFIDwrite, IDEXwrite; 	//Control signals to say whether or not to start the next pipeline stage. 
										// This is because memory retrieve and register file access are 1 cycle long
	wire[3:0] 	aluOP;
	//regFile
	wire[15:0] 	RFdata1, RFdata2;
	wire[2:0] 	RFwriteAddress, RFreadReg1, RFreadReg2;
	//ALU
	reg[15:0] 	aluIn2a, aluIn2b, aluIn1;
	wire[15:0] 	aluResult;
	//writeback stage:
	wire[15:0] 	RFinputData;
	
	registerFile 	regFile(
							.writeReg(MEM_WB_RFwriteAddress), .readReg1(RFreadReg1), .readReg2(RFreadReg2),
							.writeData(MEM_WB_dataToWriteback), .clock(clock), .regWriteEnable(MEM_WB_regWrite), .reset(reset), 
							.readData1(RFdata1), .readData2(RFdata2)
							);
							
	//PC adder below
	adder_8b	PCADDER(.in1(8'b01),  .in2(PC), .adderout(nextPC));
	adder_8b	BRANCHADDER(.in1(PC), 	.in2(instrData_in[7:0]), .adderout(/*implement later*/));
	alu 		ALU(.in1(aluIn1), .in2(aluIn2b), .aluFunc(ID_EX_aluOP), .aluResult(aluResult));
	//Need Muxes for lots of stuff, right now MUXES for combinational logic.
	// mux3b 		resReg(IF_ID_INST[11:9], IF_ID_INST[10:8], ID_EX_aluSrcA, ID_EX_RFwriteAddress);
	// mux3b		regA(IF_ID_INST[11:9], IF_ID_INST[10:8], ID_EX_aluSrcA, ID_EX_RFreadReg1);
	// mux3b		regB();
	mux16b 		alusrcA(.in1({{8{ID_EX_PC[7]}}, ID_EX_PC}) , .in2(ID_EX_RFread1), .control(ID_EX_aluSrcA), .out(aluIn1));//sign extend PC
	//If aluSrcB is immediate, use the immediate. It should stay imm5 or RFread2 UNLESS aluSrcA (Ld or Store instruction) is low.
	mux16b		alusrcB1(.in1(aluIn2a), .in2(ID_EX_RFread2), .control(ID_EX_aluSrcB), .out(aluIn2b));
	mux16b		alusrcB2(.in1(ID_EX_Sext9), .in2(ID_EX_Sext5), .control(ID_EX_immType), .out(aluIn2a));
	//If compOrLoad is zero, use data from memory, otherwise use the alu result, MEM_WB_dataToWriteback is the data which will be written into the regFile
	mux16b 		wb_data_sel(.in1(MEM_WB_dataFromMem), .in2(MEM_WB_aluResult), .control(MEM_WB_compOrLoad), .out(MEM_WB_dataToWriteback)); 
	
	controller 	c1(
		.IF_ID_Inst(IF_ID_Inst), .isBranch(isBranch), .isJump(isJump), 
		.aluSrcA(aluSrcA),.aluSrcB(aluSrcB), 
		.dataMemRead(dataMemRead), .dataMemWrite(dataMemWrite), 
		.regWrite(regWrite), 
		.compOrLoad(compOrLoad),.immType(immType),
		.aluOP(aluOP),.RFwriteAddress(RFwriteAddress)
	);
	
	
	//Reset Protocol
	always @(posedge clock) begin
		if(!reset) begin
			PC <= 0;
		end
		else begin
			PC <= nextPC;
		end
	end
	
	//right now just do arithmatic stuff
	always @(*) begin
		if(IF_ID_Inst[15:12] == `ADD || IF_ID_Inst[15:12] == `SUB || IF_ID_Inst[15:12] == `MUL || 
		IF_ID_Inst[15:12] == `AND || IF_ID_Inst[15:12] == `NOT) begin
			RFreadReg1 = IF_ID_Inst[7:5];
			RFreadReg2 = IF_ID_Inst[4:2];
		end else begin
			RFreadReg1 = IF_ID_Inst[11:9]; //TEMPORARY
			RFreadReg2 = IF_ID_Inst[11:9];//TEMPORARY
		end
		
		
	end
	
	always @(posedge clock) begin
		//IF/ID registers FETCH STAGE
		IF_ID_PC <= PC;
		IF_ID_nextPC <= nextPC;
		IF_ID_Inst <= instrData_in;
	
		//ID/EX stage DECODE STAGE
		ID_EX_sext5 			<= {{11{IF_ID_Inst[4]}}, IF_ID_Inst[4:0]};
		ID_EX_sext9 			<= {{7{IF_ID_Inst[8]}}, IF_ID_Inst[8:0]};
		ID_EX_RFread1 			<= RFdata1;
		ID_EX_RFread2 			<= RFdata2;
		ID_EX_PC 				<= IF_ID_PC;
		ID_EX_nextPC 			<= IF_ID_nextPC;
		ID_EX_RFwriteAddress 	<= RFwriteAddress; //determined in control unit
		ID_EX_isBranch 			<= isBranch;
		ID_EX_isJump 			<= isJump;
		ID_EX_aluSrcA 			<= aluSrcA;
		ID_EX_aluSrcB 			<= aluSrcB;
		ID_EX_dataMemRead 		<= dataMemRead;
		ID_EX_dataMemWrite 		<= dataMemWrite;
		ID_EX_regWrite 			<= regWrite;
		ID_EX_compOrLoad		<= compOrLoad;
		ID_EX_aluOP 			<= aluOP;
		ID_EX_immType 			<= immType;
		
		
		//EX/Mem Stage EXECUTE STAGE
		EX_MEM_aluResult 		<= aluResult;
		EX_MEM_dataOut 			<= aluIn1;
		EX_MEM_PC 				<= ID_EX_PC;
		EX_MEM_nextPC 			<= ID_EX_nextPC;
		EX_MEM_RFwriteAddress 	<= ID_EX_RFwriteAddress;
		EX_MEM_dataMemRead 		<= ID_EX_dataMemRead;
		EX_MEM_dataMemWrite 	<= ID_EX_dataMemWrite;
		EX_MEM_regWrite 		<= ID_EX_regWrite;
		EX_MEM_compOrLoad 		<= ID_EX_compOrLoad;
		
		//MEM WB
		MEM_WB_aluResult 		<= 	EX_MEM_aluResult;
		MEM_WB_dataFromMem 		<= 	ramData_in;
		MEM_WB_RFwriteAddress 	<= 	EX_MEM_RFwriteAddress;
		MEM_WB_regWrite 		<=	EX_MEM_regWrite;
		MEM_WB_compOrLoad 		<= 	EX_MEM_compOrLoad;

	
	end
endmodule
