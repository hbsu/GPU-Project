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
	isJump, aluSrcA, aluSrcB, dataMemRead, dataMemWrite, regWrite, compOrLoad, immType
	output reg[3:0] aluOP,
	output reg[2:0] RFwriteAddress
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
	RFwriteAddress = IF_ID_INST[10:8];//default register-register computation
	

	case(IF_ID_INST[15:12])
		`ADD, `SUB, `MUL, `AND, `NOT:
			begin
			aluOP = IF_ID_INST[15:12];
			aluSrcA = 1'b1; //use register value
			aluSrcB = IF_ID_INST[11];
			regWrite = 1'b1; //write to register
			compOrLoad = 1'b1; //Use value from computation
			RFwriteAddress = IF_ID_INST[10:8];
			immType = ~IF_ID_INST[11];
			end
			
		default: begin 
				///do nothing
			end

	end	


endmodule