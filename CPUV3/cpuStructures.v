module adder_8b(
    input wire[7:0] in1, in2,
    output wire[7:0] adderout
    );
		wire [6:0] carry;

		full_adder fa0 (.a(in1[0]), .b(in2[0]), .cin(1'b0),        .sum(adderout[0]), .cout(carry[0]));
		full_adder fa1 (.a(in1[1]), .b(in2[1]), .cin(carry[0]),    .sum(adderout[1]), .cout(carry[1]));
		full_adder fa2 (.a(in1[2]), .b(in2[2]), .cin(carry[1]),    .sum(adderout[2]), .cout(carry[2]));
		full_adder fa3 (.a(in1[3]), .b(in2[3]), .cin(carry[2]),    .sum(adderout[3]), .cout(carry[3]));
		full_adder fa4 (.a(in1[4]), .b(in2[4]), .cin(carry[3]),    .sum(adderout[4]), .cout(carry[4]));
		full_adder fa5 (.a(in1[5]), .b(in2[5]), .cin(carry[4]),    .sum(adderout[5]), .cout(carry[5]));
		full_adder fa6 (.a(in1[6]), .b(in2[6]), .cin(carry[5]),    .sum(adderout[6]), .cout(carry[6]));
		full_adder fa7 (.a(in1[7]), .b(in2[7]), .cin(carry[6]),    .sum(adderout[7]), .cout(/* optional: final carry-out */));

					
			
endmodule

    
module full_adder (
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule

module sext5( input wire[4:0] in5, output wire[15:0] out16);
    assign out16 = {{11{in5[4]}}, in5};
endmodule
    
module sext9 (input wire[8:0] in9, output wire[15:0] out16);
    assign out16 = {{8{in9[8]}}, in9};
endmodule

//module mux3b (
//    input wire [2:0] in1,
//    input wire [2:0] in2,
//    input wire control,
//    output wire [2:0] out
//);

//    mux1b m0 (.a(in1[0]), .b(in2[0]), .sel(control), .y(out[0]));
//    mux1b m1 (.a(in1[1]), .b(in2[1]), .sel(control), .y(out[1]));
//    mux1b m2 (.a(in1[2]), .b(in2[2]), .sel(control), .y(out[2]));

//endmodule
module mux16b41(
	input wire[15:0] in1, in2, in3 ,in4,
	input wire[1:0] control, 
	output wire[15:0] out
);
	wire[15:0] mux_out1, mux_out2;
	mux16b out1(.in1(in1), .in2(in2), .control(control[0]), .out(mux_out1)); 
	mux16b out2(.in1(in3), .in2(in4), .control(control[0]), .out(mux_out2));
	mux16b out3(.in1(mux_out1), .in2(mux_out2), .control(control[1]), .out(out));



endmodule

module mux1b (
    input wire a,
    input wire b,
    input wire sel,
    output wire y
);
    wire not_sel;
    wire a_and, b_and;

    not (not_sel, sel);
    and (a_and, a, not_sel);
    and (b_and, b, sel);
    or  (y, a_and, b_and);
endmodule



module mux16b (
    input wire [15:0] in1,
    input wire [15:0] in2,
    input wire control,
    output wire [15:0] out
);

    mux1b m0  (.a(in1[0]),  .b(in2[0]),  .sel(control), .y(out[0]));
    mux1b m1  (.a(in1[1]),  .b(in2[1]),  .sel(control), .y(out[1]));
    mux1b m2  (.a(in1[2]),  .b(in2[2]),  .sel(control), .y(out[2]));
    mux1b m3  (.a(in1[3]),  .b(in2[3]),  .sel(control), .y(out[3]));
    mux1b m4  (.a(in1[4]),  .b(in2[4]),  .sel(control), .y(out[4]));
    mux1b m5  (.a(in1[5]),  .b(in2[5]),  .sel(control), .y(out[5]));
    mux1b m6  (.a(in1[6]),  .b(in2[6]),  .sel(control), .y(out[6]));
    mux1b m7  (.a(in1[7]),  .b(in2[7]),  .sel(control), .y(out[7]));
    mux1b m8  (.a(in1[8]),  .b(in2[8]),  .sel(control), .y(out[8]));
    mux1b m9  (.a(in1[9]),  .b(in2[9]),  .sel(control), .y(out[9]));
    mux1b m10 (.a(in1[10]), .b(in2[10]), .sel(control), .y(out[10]));
    mux1b m11 (.a(in1[11]), .b(in2[11]), .sel(control), .y(out[11]));
    mux1b m12 (.a(in1[12]), .b(in2[12]), .sel(control), .y(out[12]));
    mux1b m13 (.a(in1[13]), .b(in2[13]), .sel(control), .y(out[13]));
    mux1b m14 (.a(in1[14]), .b(in2[14]), .sel(control), .y(out[14]));
    mux1b m15 (.a(in1[15]), .b(in2[15]), .sel(control), .y(out[15]));

endmodule

module dff(
    input clock,
    input enable,
    input D,
    input reset,
    output reg Q
);
    always @(posedge clock)
        Q <= ((enable & D) | (~enable & Q)) & reset;

endmodule

module register(
	input wire [15:0] in,
	input wire clock, enable, reset,
	output reg [15:0] out
);
	dff dfr0  (clock, enable, in[0],  reset, out[0]);
	dff dfr1  (clock, enable, in[1],  reset, out[1]);
	dff dfr2  (clock, enable, in[2],  reset, out[2]);
	dff dfr3  (clock, enable, in[3],  reset, out[3]);
	dff dfr4  (clock, enable, in[4],  reset, out[4]);
	dff dfr5  (clock, enable, in[5],  reset, out[5]);
	dff dfr6  (clock, enable, in[6],  reset, out[6]);
	dff dfr7  (clock, enable, in[7],  reset, out[7]);
	dff dfr8  (clock, enable, in[8],  reset, out[8]);
	dff dfr9  (clock, enable, in[9],  reset, out[9]);
	dff dfr10 (clock, enable, in[10], reset, out[10]);
	dff dfr11 (clock, enable, in[11], reset, out[11]);
	dff dfr12 (clock, enable, in[12], reset, out[12]);
	dff dfr13 (clock, enable, in[13], reset, out[13]);
	dff dfr14 (clock, enable, in[14], reset, out[14]);
	dff dfr15 (clock, enable, in[15], reset, out[15]);

endmodule


//module registerFile( //one clock cycle delay
//	input [2:0] writeReg,
//	input wire [2:0] readReg1,
//	input wire [2:0] readReg2,
//	input wire [15:0] writeData,
//	input wire clock, regWriteEnable, reset,
//	output wire[15:0] readData1, readData2
//);
//	//8 general purpose 16-bit registers
//	reg[15:0] registers[7:0];
//	register regA (registers[readReg1], clock, 1'b1, reset, readData1); //output readData1
//	register regB (registers[readReg2], clock, 1'b1, reset, readData2); //output readData2
//	//Next line will only occur if writeEnable is high. 
//	register inReg(writeData, clock, regWriteEnable, reset, registers[writeReg]); //write into associated register
	
//endmodule

module registerFile (
    input wire [2:0] writeReg,
    input wire [2:0] readReg1,
    input wire [2:0] readReg2,
    input wire [15:0] writeData,
    input wire clock, regWriteEnable, reset,
    output wire [15:0] readData1, readData2
);
    // Declare individual registers using your `register` module
    wire [15:0] reg_out [7:0];

    // 8 general purpose 16-bit registers
    reg [15:0] registers [7:0];

    // Asynchronous Read (Combinational)
    assign readData1 = registers[readReg1];
    assign readData2 = registers[readReg2];

    // Synchronous Write
    always @(posedge clock or posedge reset) begin
  
        if(reset) begin
            registers[0] <= 16'b0;
            registers[1] <= 16'b0;
            registers[2] <= 16'b0;
            registers[3] <= 16'b0;
            registers[4] <= 16'b0;
            registers[5] <= 16'b0;
            registers[6] <= 16'b0;
            registers[7] <= 16'b0;
        end
        else if (regWriteEnable) begin
            registers[writeReg] <= writeData;
        end
    end
endmodule

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


module alu(
	input wire [15:0] in1, //either R1 or PC
	input wire [15:0] in2, //either R2 or imm
	input wire [3:0] aluFunc,
	output reg [15:0] aluResult
); 

	always @(*)begin 
		case(aluFunc)
			`ADD: 	 aluResult = in1 + in2;
			`SUB: 	 aluResult = in1 - in2;
			`MUL: 	 aluResult = in1 * in2;
			`AND: 	 aluResult = in1 & in2;
			`NOT: 	 aluResult = ~in1;
			`ST: 	 aluResult = in1 + in2; //pc + offset
			`LD: 	 aluResult = in1 + in2; 
			`STR: 	 aluResult = in1 + in2; //pc + incomming Register Data
			`LDR: 	 aluResult = in1 + in2;
			default:  aluResult = 16'bZ;
        endcase 
	end
endmodule

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

//register read decoder
module regReadDec(
	input wire [15:0] IF_ID_Inst,
	output reg[2:0] RFreadReg1, RFreadReg2
);
	always @(*) begin
		if(IF_ID_Inst[15:12] == `ADD || IF_ID_Inst[15:12] == `SUB || IF_ID_Inst[15:12] == `MUL || 
		IF_ID_Inst[15:12] == `AND || IF_ID_Inst[15:12] == `NOT) begin
			RFreadReg1 <= IF_ID_Inst[7:5];
			RFreadReg2 <= IF_ID_Inst[4:2];
		end else if(IF_ID_Inst[15:12] == `ST)begin
			RFreadReg1 <= IF_ID_Inst[11:9]; //where to pull value
		end else if(IF_ID_Inst[15:12] == `STR) begin
			RFreadReg1 <= IF_ID_Inst[11:9]; //where to pull value
			RFreadReg2 <= IF_ID_Inst[8:6]; //Where to read following address
		end else if(IF_ID_Inst[15:12] == `LDR) begin
			RFreadReg2 <= IF_ID_Inst[8:6]; //Where to read following address
		end else if(IF_ID_Inst[15:12] == `JMP 
					|| IF_ID_Inst[15:12] == `BRZ 
					|| IF_ID_Inst[15:12] == `BRN) begin
			RFreadReg1 <= IF_ID_Inst[11:9]; //where to read the register from
		end else if(IF_ID_Inst[15:12] == `RET) begin 
			RFreadReg1 <= 3'b0111; //read from r7
		end else begin
			RFreadReg1 <= IF_ID_Inst[11:9]; 	//TEMPORARY DEFAULT
			RFreadReg2 <= IF_ID_Inst[11:9];		//TEMPORARY DEFAULT
		end
	
	end



endmodule