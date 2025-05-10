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
//BRZ 1110_REG_imm9 //Jump to address at PC + imm9 if REG is zero. 
//BRN 1111_REG_imm9 //Jump to address at PC + imm9 if REG is nonzero.
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
	output wire instrReadM,
	output reg instrWriteM,
	output [7:0] instrAddress, //next instruction address to fetch from
	output wire[15:0] instrData_out,
	
	//Data Memory
	input wire[15:0] ramData_in,
	output ramReadM,
	output ramWriteM,
	output[7:0] ramAddress,
	output wire[15:0] ramData_out

    );
	//Program Counter Related
	reg[7:0] PC;
	wire[7:0] nextPC, branchTarget, jumpTarget, returnAddress, pcSrc;
	wire[1:0] pcSel;
	
	reg[15:0]      IF2_Inst; //Using because i have synchronous memory
	reg[7:0]       IF2_PC, IF2_nextPC;
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
	ID_EX_dataMemRead, ID_EX_dataMemWrite, ID_EX_regWrite, ID_EX_immType, 
	ID_EX_compOrLoad, ID_EX_regAddressing;
	//aluSrcB is ROI aluSrcA is LDorST, 1 for using regfile stuff, 0 for using other. 
	reg[3:0] 	ID_EX_aluOP;
	//EX/MEM pipeline Registers
	reg[15:0] 	EX_MEM_aluResult, EX_MEM_dataOut, EX_MEM_RFread2, EX_MEM_dataFromMem;
	reg[7:0] 	EX_MEM_PC, EX_MEM_nextPC;
	reg[2:0] 	EX_MEM_RFwriteAddress;
	reg 		EX_MEM_dataMemRead, EX_MEM_dataMemWrite, EX_MEM_regWrite; //keep some control signals from ID/EX stage
	reg 		EX_MEM_compOrLoad, EX_MEM_regAddressing; //control signal for if result is computational or a load, so use aluResult or datafromMem
	//ADD NEW PIPELINE REGISTER BETWEEN MEM AND WB
	reg[15:0] 	MEM2_WB_dataFromMem, MEM2_WB_aluResult;
	reg[2:0] 	MEM2_WB_RFwriteAddress;
	reg			MEM2_WB_regWrite, MEM2_WB_compOrLoad;
	
	//MEM/WB pipeline registers
	reg[15:0] 	MEM_WB_dataToWriteback, MEM_WB_aluResult, MEM_WB_dataFromMem;
	reg[2:0] 	MEM_WB_RFwriteAddress;
	reg 		MEM_WB_regWrite, MEM_WB_compOrLoad;
	//Now we need control signals for all the data.
	wire 		isBranch, isJump, aluSrcA, aluSrcB, dataMemRead, dataMemWrite, regWrite, compOrLoad, immType, regAddressing;
	wire 		IFIDwrite, IDEXwrite; 	//Control signals to say whether or not to start the next pipeline stage. 
										// This is because memory retrieve and register file access are 1 cycle long
	wire[3:0] 	aluOP;
	//regFile
	wire[15:0] 	RFdata1, RFdata2;
	wire[2:0] 	RFwriteAddress;
	wire[2:0] RFreadReg1, RFreadReg2;
	//ALU
	wire[15:0] 	aluIn2a, aluIn2b, aluIn1;
	wire[15:0] 	aluResult;
	//writeback stage:
	wire[15:0] 	RFinputData;
	wire [15:0] wb_mux_out;
	
	//wait for load delay
	wire loading_data, executeStall, branchTaken;
	reg stallInserted; //testbench only
	
	registerFile 	regFile(
							.writeReg(MEM_WB_RFwriteAddress), .readReg1(RFreadReg1), .readReg2(RFreadReg2),
							.writeData(wb_mux_out), .clock(clock), .regWriteEnable(MEM_WB_regWrite), .reset(reset), 
							.readData1(RFdata1), .readData2(RFdata2)
							);
							
	//PC adder below
	adder_8b	PCADDER(.in1(8'b01),  .in2(PC), .adderout(nextPC));
	adder_8b	BRANCHADDER(.in1(PC), 	.in2(ID_EX_sext9[7:0]), .adderout(branchTarget));
	//00 is sequential, 01 is branch, 10 is jump, 11 is return
	//it should go nextPC, branchTarget from ALU, 
	mux16b41 pcSelmux(.in1(nextPC), .in2(branchTarget), .in3(ID_EX_RFread1), .in4(ID_EX_RFread1), .control(pcSel), .out(pcSrc)); //MUX for selecting what to use as the PC source
	alu 		ALU(.in1(aluIn1), .in2(aluIn2b), .aluFunc(ID_EX_aluOP), .aluResult(aluResult));
	mux16b 		alusrcA(.in1({{8{ID_EX_PC[7]}}, ID_EX_PC}) , .in2(ID_EX_RFread1), .control(ID_EX_aluSrcA), .out(aluIn1));//sign extend PC
	//If aluSrcB is immediate, use the immediate. It should stay imm5 or RFread2 UNLESS aluSrcA (Ld or Store instruction) is low.
	mux16b		alusrcB1(.in1(aluIn2a), .in2(ID_EX_RFread2), .control(ID_EX_aluSrcB), .out(aluIn2b));
	mux16b		alusrcB2(.in1(ID_EX_sext9[15:0]), .in2(ID_EX_sext5[15:0]), .control(ID_EX_immType), .out(aluIn2a));
	//If compOrLoad is zero, use data from memory, otherwise use the alu result, MEM_WB_dataToWriteback is the data which will be written into the regFile
	mux16b 		wb_data_sel(.in1(MEM_WB_dataFromMem), .in2(MEM_WB_aluResult), .control(MEM_WB_compOrLoad), .out(wb_mux_out)); 
	//Need a mux that chooses what address to use for writing to/ from memory
	mux16b 		mem_addr(.in1(EX_MEM_aluResult), .in2(EX_MEM_RFread2), .control(EX_MEM_regAddressing), .out(ramAddress));
	branchController bc1(
		.aluOp(ID_EX_aluOP),		//
		.inputData(ID_EX_RFread1), 	//data from regFile
		.pcSel(pcSel),				//PC select bits
		.branchTaken(branchTaken)	//is branch taken?
	);
	controller 	c1(
		.IF_ID_Inst(IF_ID_Inst), .isBranch(isBranch), .isJump(isJump), 
		.aluSrcA(aluSrcA),.aluSrcB(aluSrcB), 
		.dataMemRead(dataMemRead), .dataMemWrite(dataMemWrite), 
		.regWrite(regWrite), 
		.compOrLoad(compOrLoad),.immType(immType), .regAddressing(regAddressing),
		.aluOP(aluOP),.RFwriteAddress(RFwriteAddress)
	);
	regReadDec rrd1(
	.IF_ID_Inst(IF_ID_Inst), .RFreadReg1(RFreadReg1), .RFreadReg2(RFreadReg2)
	);
	hazardDetector h1(
		.instruction(IF_ID_Inst), 
		.ID_EX_RFWriteAddress(ID_EX_RFwriteAddress),
		.EX_MEM_RFWriteAddress(EX_MEM_RFwriteAddress), 
		.MEM2_WB_RFWriteAddress(MEM2_WB_RFwriteAddress),
		.MEM_WB_RFWriteAddress(MEM_WB_RFwriteAddress),
		.ID_EX_regWrite(ID_EX_regWrite),
		.EX_MEM_regWrite(EX_MEM_regWrite), 
		.MEM2_WB_regWrite(MEM2_WB_regWrite),
		.MEM_WB_regWrite(MEM_WB_regWrite),
		.stall(executeStall)
	);
	//during execute stage, based on the instruction opcode, the output will be 
	//branchTaken and the corresponding pcSel.
	//Inputs will be: opcode, read from the reg.
	//if jump or ret, branchtaken = 1 and pcsel is the corresponding one.
	//if BReq or BRz, check the input data and choose if to do PC or branch, 
	//pcSel should be updated correspondingly
	//create Hazard Detection unit. 
	//Check if incoming Instruction has dependencies in the write-to register of any current instruction
	//Inputs should be IF_ID_Inst, 
	//ID_EX_RFWriteAddress, 
	//EX_MEM_RFWriteAddress,
	//MEM_WB_RFWriteAddress,
	//ID_EX_regWrite //High or low?
	//EX_MEM_regWrite //updating memory or nah
	//MEM_WB_regWrite //check memory or writeback
	//output Stall or nah
	
	
	//Hazard Detection
	//Any data read from readData1 should be directly wired as outgoingData, only will be written out there if WE is high
	
	assign instrReadM = 1'b1;
    assign instrAddress = PC;
	assign ramData_out = EX_MEM_dataOut;
	assign ramReadM = EX_MEM_dataMemRead;
	assign ramWriteM = EX_MEM_dataMemWrite;
	assign loading_data = ID_EX_dataMemRead; // if instruction is a load, add a 1 cycle penalty
	
	//Reset Protocol
	always @(posedge clock) begin
		if(reset) begin
			PC <= 0;

        // Flush IF/ID stage
			IF2_Inst <= 16'b0;
			IF2_PC <= 8'b0;
			IF2_nextPC <= 8'b0;
		
            IF_ID_Inst <= 16'b0;
            IF_ID_PC <= 8'b0;
            IF_ID_nextPC <= 8'b0;
    
            // Flush ID/EX stage
            ID_EX_RFread1 <= 16'b0;
            ID_EX_RFread2 <= 16'b0;
            ID_EX_sext5 <= 16'b0;
            ID_EX_sext9 <= 16'b0;
            ID_EX_PC <= 8'b0;
            ID_EX_nextPC <= 8'b0;
            ID_EX_RFwriteAddress <= 3'b0;
            ID_EX_isBranch <= 0;
            ID_EX_isJump <= 0;
            ID_EX_aluSrcA <= 0;
            ID_EX_aluSrcB <= 0;
            ID_EX_dataMemRead <= 0;
            ID_EX_dataMemWrite <= 0;
            ID_EX_regWrite <= 0;
            ID_EX_compOrLoad <= 0;
            ID_EX_aluOP <= 4'b0;
            ID_EX_immType <= 0;
			ID_EX_regAddressing <= 0;
    
            // Similarly clear EX/MEM and MEM/WB...
            // EX/MEM stage
            EX_MEM_aluResult <= 16'b0;
            EX_MEM_dataOut <= 16'b0;
            EX_MEM_PC <= 8'b0;
            EX_MEM_nextPC <= 8'b0;
            EX_MEM_RFwriteAddress <= 3'b0;
            EX_MEM_dataMemRead <= 0;
            EX_MEM_dataMemWrite <= 0;
            EX_MEM_regWrite <= 0;
            EX_MEM_compOrLoad <= 0;
			EX_MEM_regAddressing <= 0;
			EX_MEM_RFread2 <= 0;
			EX_MEM_dataFromMem <= 16'b0;
    
            // MEM/WB stage
            MEM_WB_aluResult <= 16'b0;
            MEM_WB_dataFromMem <= 16'b0;
            MEM_WB_RFwriteAddress <= 3'b0;
            MEM_WB_regWrite <= 0;
            MEM_WB_compOrLoad <= 0;
            MEM_WB_dataToWriteback <= 16'b0;
			
		end else if (branchTaken) begin
			//Flush
			//Insert NOP and FLUSH
			IF_ID_Inst <= `NOP;
			ID_EX_RFwriteAddress <= 3'b0;
			ID_EX_regWrite <= 1'b0;
			ID_EX_dataMemRead <= 1'b0;
			ID_EX_dataMemWrite <= 1'b0;
			ID_EX_aluOP <= `NOP;
			PC <= pcSrc; //New Mux
		
		
		
		end else if(!executeStall)begin
            PC <= pcSrc;
			IF2_PC <= PC;
			IF2_nextPC <= nextPC;
			IF2_Inst <= instrData_in;
			//if2 stage
			IF_ID_PC <= IF2_PC;
			IF_ID_nextPC <= IF2_nextPC;
			IF_ID_Inst <= IF2_Inst;
		
		end if (executeStall) begin
			PC <= PC; //hold pc, stall the fetch
			
			IF2_PC <= IF2_PC;
			IF2_nextPC <= IF2_nextPC;
			IF2_Inst <= IF2_Inst;
			
			IF_ID_PC 				<= IF_ID_PC;
			IF_ID_nextPC 			<= IF_ID_nextPC;
			IF_ID_Inst 				<= IF_ID_Inst; //Hold current instruction
			
			//Insert NOP into ID/EX to kill dependent instruction
			ID_EX_RFwriteAddress 	<= 3'b0;
			ID_EX_regWrite 			<= 1'b0;
			ID_EX_aluOP 			<= `NOP;
			ID_EX_dataMemRead 		<= 1'b0;
			ID_EX_dataMemWrite 		<= 1'b0;
			ID_EX_compOrLoad 		<= 1'b0;
			stallInserted           <= 1'b1;
			
			
		end else begin 
		
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
			ID_EX_regAddressing		<= regAddressing;
            stallInserted           <= 1'b0;

		end	
			//EX/Mem Stage EXECUTE STAGE
			EX_MEM_aluResult 		<= aluResult;
			EX_MEM_dataOut 			<= ID_EX_RFread1; //data from RF read port 1 is always the outgoing data
			EX_MEM_PC 				<= ID_EX_PC;
			EX_MEM_nextPC 			<= ID_EX_nextPC;
			EX_MEM_RFwriteAddress 	<= ID_EX_RFwriteAddress;
			EX_MEM_dataMemRead 		<= ID_EX_dataMemRead;
			EX_MEM_dataMemWrite 	<= ID_EX_dataMemWrite;
			EX_MEM_regWrite 		<= ID_EX_regWrite;
			EX_MEM_compOrLoad 		<= ID_EX_compOrLoad;
			EX_MEM_regAddressing	<= ID_EX_regAddressing;
			EX_MEM_RFread2 			<= ID_EX_RFread2;
//			EX_MEM_dataFromMem      <= ramData_in;

			//Mem2 to WB JUST FOR STORE
			MEM2_WB_dataFromMem 	<= ramData_in;
			MEM2_WB_aluResult 		<= EX_MEM_aluResult;
			MEM2_WB_RFwriteAddress 	<= EX_MEM_RFwriteAddress;
			MEM2_WB_regWrite 		<= EX_MEM_regWrite;
			MEM2_WB_compOrLoad 		<= EX_MEM_compOrLoad;
			
			//MEM WB
			MEM_WB_aluResult 		<= 	MEM2_WB_aluResult;
			MEM_WB_dataFromMem 		<= 	MEM2_WB_dataFromMem; //used to be EX_MEM_dataFromMem
			MEM_WB_RFwriteAddress 	<= 	MEM2_WB_RFwriteAddress;
			MEM_WB_regWrite 		<=	MEM2_WB_regWrite;
			MEM_WB_compOrLoad 		<= 	MEM2_WB_compOrLoad;
			MEM_WB_dataToWriteback    <= wb_mux_out;
	end
	
	
 
endmodule
