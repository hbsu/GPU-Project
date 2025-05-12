
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


module controller(
	input wire[15:0] IF_ID_Inst,
	output reg isBranch, 
	isJump, aluSrcA, aluSrcB, dataMemRead, dataMemWrite, regWrite,
	compOrLoad, immType, regAddressing,
	output reg[3:0] aluOP,
	output reg[2:0] RFwriteAddress,
	output reg isLoad
);

always @(*) begin
	
	aluOP = 4'b0000;
	aluSrcA = 1'b1;
	aluSrcB = 1'b1;
	dataMemRead = 1'b0;
	dataMemWrite = 1'b0;
	regWrite = 1'b0;
	compOrLoad = 1'b0;
	isJump = 1'b0;
	isBranch = 1'b0;
	immType = 1'b0;
	regAddressing = 1'b0;
	RFwriteAddress = IF_ID_Inst[10:8];//default register-register computation
	isLoad = 1'b0;
	

	case(IF_ID_Inst[15:12])
		`ADD, `SUB, `MUL, `AND, `NOT:
			begin
			aluOP = IF_ID_Inst[15:12];
			aluSrcA = 1'b1; //use register value
			aluSrcB = IF_ID_Inst[11];
			regWrite = 1'b1; //write to register
			compOrLoad = 1'b1; //Use value from computation
			RFwriteAddress = IF_ID_Inst[10:8];
			immType = ~IF_ID_Inst[11];
			regAddressing = 1'b0;
			end
		`ST:
			begin
			aluOP = IF_ID_Inst[15:12];
			aluSrcA = 1'b0; //Use PC
			aluSrcB = 1'b0; //Use immediate
			dataMemRead = 1'b0;
			dataMemWrite = 1'b1;
			immType = 1'b0; //Use imm9
			regWrite = 1'b0;
			compOrLoad = 1'b0; //doesn't matter
			regAddressing = 1'b0;
			end
		`STR: 
			begin
			aluOP = IF_ID_Inst[15:12];
			aluSrcA = 1'b0;
			aluSrcB = 1'b1;
			dataMemRead = 1'b0;
			dataMemWrite = 1'b1;
			immType = 1'b0; //doesn't matter
			regWrite = 1'b0; //don't write
			compOrLoad = 1'b0; //doesn't matter
			regAddressing = 1'b1;
			end
		`LD:
			begin
			aluOP = IF_ID_Inst[15:12];
			aluSrcA = 1'b0; //needs to be PC
			aluSrcB = 1'b0; //use immediate
			dataMemRead = 1'b1;
			dataMemWrite = 1'b0;
			immType = 1'b0; //Use immediate 9
			regWrite = 1'b1;
			RFwriteAddress = IF_ID_Inst[11:9];
			compOrLoad = 1'b0; //Use value from memory
			regAddressing = 1'b0; //using pc offset
			isLoad = 1'b1;
			end
		`LDR:
			begin
			aluOP = IF_ID_Inst[15:12];
			aluSrcA = 1'b0;
			aluSrcB = 1'b0;
			immType = 1'b0;
			dataMemRead = 1'b1;
			dataMemWrite = 1'b0;
			regWrite = 1'b1; //write
			compOrLoad = 1'b0; //memory
			regAddressing = 1'b1; //Use reg
			RFwriteAddress = IF_ID_Inst[11:9];
			isLoad = 1'b1;
			end
		`JMP, `BRZ, `BRN, `RET:
			begin
			aluOP = IF_ID_Inst[15:12];
			end
		default: begin 
				///do nothing
			end

	endcase

    end 
endmodule

module branchController(
	input wire[3:0] aluOp,
	input wire[15:0] inputData,
	output reg[2:0] pcSel,
	output reg branchTaken
);
	always @(*) begin
		if(aluOp == `JMP) begin
			branchTaken = 1'b1; //Branch taken 
			pcSel = 2'b10;
		end else if(aluOp == `RET) begin
			branchTaken = 1'b1;
			pcSel = 2'b11; 
		end else if(aluOp == `BRZ) begin
			if(inputData == 0) begin
				branchTaken = 1'b1;
				pcSel = 2'b01;
			end else begin
				branchTaken = 1'b0;
				pcSel = 2'b00;
			end
		end else if(aluOp == `BRN) begin
			if(inputData < 0) begin
				branchTaken = 1'b1;
				pcSel = 2'b01;
			end else begin
				branchTaken = 1'b0;
				pcSel = 2'b00;
			end
		end else begin
			pcSel <= 2'b0;
			branchTaken = 1'b0;
		end
	
	end

endmodule;

module hazardDetector(
	input wire[15:0] instruction,
	input wire[2:0] ID_EX_RFWriteAddress,
	EX_MEM_RFWriteAddress, MEM2_WB_RFWriteAddress, MEM_WB_RFWriteAddress,
	input wire ID_EX_regWrite, EX_MEM_regWrite, MEM2_WB_regWrite, MEM_WB_regWrite,
	input wire ID_EX_isLoad,
	output reg stall, newWriteIncoming,
	output reg[1:0]forwardA, forwardB
);

	always @(*) begin
		newWriteIncoming =    (ID_EX_regWrite && (ID_EX_RFWriteAddress == MEM_WB_RFWriteAddress)) || 
		                      (EX_MEM_regWrite && (EX_MEM_RFWriteAddress == MEM_WB_RFWriteAddress)) ||
							  (MEM2_WB_regWrite && (MEM2_WB_RFWriteAddress == MEM_WB_RFWriteAddress));
	
		case(instruction[15:12])
			`ADD, `SUB, `AND, `MUL, `NOT: begin //addx_1_reg_reg_reg or addx_0_reg_reg_imm5
				//check if register 1 can be forwarded
				
				
				if((ID_EX_RFWriteAddress == instruction[7:5]) && ID_EX_regWrite) begin 
					if(ID_EX_isLoad) begin
						stall = 1'b1;
						forwardA = 2'b00;
					end else begin
						stall = 1'b0;
						forwardA = 2'b01;
					end
					end
				else if((EX_MEM_RFWriteAddress == instruction[7:5]) && EX_MEM_regWrite) begin 
					stall = 1'b0;
					forwardA = 2'b10;
					end
				else if((MEM2_WB_RFWriteAddress == instruction[7:5]) && MEM2_WB_regWrite) 
					begin
					stall = 1'b0;
					forwardA = 2'b11;
					end
				else begin 
					forwardA = 2'b00;
					stall = 1'b0;
				end
			
				case(instruction[11]) //check if it is register or immediate
					1'b1: begin //Check if register 2 can be forwarded
						if((ID_EX_RFWriteAddress == instruction[4:2]) && ID_EX_regWrite) 
						begin 
							if(ID_EX_isLoad) begin
						stall = 1'b1;
						forwardB = 2'b00;
					end else begin
						stall = 1'b0;
						forwardB = 2'b01;
					end
					end
						else if((EX_MEM_RFWriteAddress == instruction[4:2]) && EX_MEM_regWrite) 
						begin						
							stall = 1'b0;
							forwardB = 2'b10;
							end
						else if((MEM2_WB_RFWriteAddress == instruction[4:2]) && MEM2_WB_regWrite) 
						begin
							stall = 1'b0;
							forwardB = 2'b11;
							end
						else begin 
							stall = 1'b0;
							forwardB = 2'b00;
							end
					end
					default: forwardB = 2'b00;
				endcase
				end
			`ST: begin //stxx_reg_imm, also checks if register 1 can be forwarded
				if((ID_EX_RFWriteAddress == instruction[11:9]) && ID_EX_regWrite) begin 
					if(ID_EX_isLoad) begin
						stall = 1'b1;
						forwardA = 2'b00;
					end else begin
						stall = 1'b0;
						forwardA = 2'b01;
					end
					end
				else if((EX_MEM_RFWriteAddress == instruction[11:9]) && EX_MEM_regWrite) begin 
					stall = 1'b0;
					forwardA = 2'b10;
					end
				else if((MEM2_WB_RFWriteAddress == instruction[11:9]) && MEM2_WB_regWrite) 
					begin
					stall = 1'b0;
					forwardA = 2'b11;
					end
				else begin 
					forwardA = 2'b00;
					stall = 1'b0;
				end
				end
			`STR: begin //strx_reg_reg_xxxxxx, checks if both register 1 and 2 can be forwarded
				if((ID_EX_RFWriteAddress == instruction[11:9]) && ID_EX_regWrite) begin 
					if(ID_EX_isLoad) begin
						stall = 1'b1;
						forwardA = 2'b00;
					end else begin
						stall = 1'b0;
						forwardA = 2'b01;
					end
					end
				else if((EX_MEM_RFWriteAddress == instruction[11:9]) && EX_MEM_regWrite) begin 
					stall = 1'b0;
					forwardA = 2'b10;
					end
				else if((MEM2_WB_RFWriteAddress == instruction[11:9]) && MEM2_WB_regWrite) 
					begin
					stall = 1'b0;
					forwardA = 2'b11;
					end
				else begin 
					forwardA = 2'b00;
					stall = 1'b0;
				end
				if((ID_EX_RFWriteAddress == instruction[8:6]) && ID_EX_regWrite) begin 
					stall = 1'b0;
					forwardB = 2'b01;
					end
				else if((EX_MEM_RFWriteAddress == instruction[8:6]) && EX_MEM_regWrite) begin 
					stall = 1'b0;
					forwardB = 2'b10;
					end
				else if((MEM2_WB_RFWriteAddress == instruction[8:6]) && MEM2_WB_regWrite) 
					begin
					stall = 1'b0;
					forwardB = 2'b11;
					end
				else begin 
					forwardB = 2'b00;
					stall = 1'b0;
				end
				end
			`BRZ, `BRN: begin //BRZx_REG, BRNx_REG
				if((ID_EX_RFWriteAddress == instruction[11:9]) && ID_EX_regWrite) begin 
					if(ID_EX_isLoad) begin
						stall = 1'b1;
						forwardA <= 2'b00;
					end else begin
						stall = 1'b0;
						forwardA = 2'b01;
					end
					end
				else if((EX_MEM_RFWriteAddress == instruction[11:9]) && EX_MEM_regWrite) begin 
					stall = 1'b0;
					forwardA = 2'b10;
					end
				else if((MEM2_WB_RFWriteAddress == instruction[11:9]) && MEM2_WB_regWrite) 
					begin
					stall = 1'b0;
					forwardA = 2'b11;
					end
				else begin 
					forwardA = 2'b00;
					stall = 1'b0;
				end
			end
			default: begin
			 forwardA = 2'b00;
			 forwardB = 2'b00;
			 stall = 1'b0;
			end
		endcase
			
	end


endmodule
