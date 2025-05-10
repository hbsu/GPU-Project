`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/09/2025 05:16:05 PM
// Design Name: 
// Module Name: cpuTB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module cpuTB(
	
    );
	
	
	wire ramWE, ramRE, pcramWE;
	wire[7:0] ramAddress;
	wire[15:0] ramDataIn, ramDataRead, pcRAMin;
	wire[7:0] pcRAMaddress;
	assign ramAddress = bootloadStatus ? bootloadAddress : pcRAMaddress;
	assign ramDataIn = bootloadStatus ? bootloadIn : pcRAMin;
	assign ramWE = bootloadStatus | pcramWE;
	
	reg clock, reset;
	wire romWE, romRE, pcromWE;
	wire[15:0] romDataRead, romDataIn;
	wire[7:0] romAddress; //either input from bootloader or pc
	reg bootloadStatus = 0; //if bootloader high, use bootload stuff
	reg[7:0] bootloadAddress; //rom address from bootloader
	wire[7:0] pcROMaddress; //rom address from pc
	reg[15:0] bootloadIn; //bootload instructions in
	wire[15:0] pcROMin; //pc wants to write instructions back into rom?
	assign romAddress = bootloadStatus ? bootloadAddress : pcROMaddress;
	assign romDataIn = bootloadStatus ? bootloadIn : pcROMin; 
	assign romWE = bootloadStatus | pcromWE;
	
	initial clock = 0;
	always #5 clock = ~clock; //100 mhz clock
	
	//instantiate cpu
	cpuStructSim core1(
		.clock(clock),
		.reset(reset),
		
		.instrData_in(romDataRead), //input[15:0]
		.instrReadM(romRE), //output read enable into rom
		.instrWriteM(pcromWE), //output write enable into rom
		.instrAddress(pcROMaddress),// instruction address to fetch from
		.instrData_out(pcROMin), //[15:0] output data for instruction file
		
		.ramData_in(ramDataRead), //input[15:0]
		.ramReadM(ramRE), //read local memory
		.ramWriteM(pcramWE), //write to local memory
		.ramAddress(pcRAMaddress), //address in ram/local memory
		.ramData_out(pcRAMin) //data to output to local memory
	);
	
	instruction_rom irom( //memory of instructions
			.clk(clock),
			.we(romWE), //input write enable
			.re(romRE), //input read enable
			.addr(romAddress), //input [7:0] address
			.din(romDataIn), //input data [15:0] for prelaoding
			.dout(romDataRead) //output data[15:0] read 
	);
	
	data_ram 		L1(
			.clk(clock),
			.we(ramWE), //input write enable
			.re(ramRE), //input read enable
			.addr(ramAddress), //input [7:0] address
			.din(ramDataIn), //input data [15:0] for inputting
			.dout(ramDataRead) //output data[15:0] read 
	);
	
	initial begin
	
	//use testbench
	
	//bootload
	//*****DO NOT REMOVE BELOW THIS LINE
        reset = 1; //Puts CPU in reset
        //BOOTLOADER
        bootloadStatus = 1; //STORE TESTBENCH BELOW THIS LINE
		//*****DO NOT REMOVE ABOVE THIS LINE
		
		//PUT TESTBENCH STARTING THIS LINE:

//ADD R1, R1, #1
 bootloadAddress = 8'h00;
bootloadIn = 16'b0001000100100001; // ADD R1, R1, #1
#10;

//ADD R1, R1, #1
 bootloadAddress = 8'h01;
bootloadIn = 16'b0001000100100001; // ADD R1, R1, #1
#10;

//ADD R1, R1, #1
 bootloadAddress = 8'h02;
bootloadIn = 16'b0001000100100001; // ADD R1, R1, #1
#10;

//ADD R1, R1, #1
 bootloadAddress = 8'h03;
bootloadIn = 16'b0001000100100001; // ADD R1, R1, #1
#10;

//ADD R1, R1, #1
 bootloadAddress = 8'h04;
bootloadIn = 16'b0001000100100001; // ADD R1, R1, #1
#10;

        
		//*****DO NOT REMOVE BELOW THIS LINE
		bootloadStatus = 0;
		#30;
        reset = 0;
		//*****DO NOT REMOVE ABOVE THIS LINE

        
        #100; //Allow time for commmands to pass. 
            //Each instruction takes at most 7 clock cycles,
            //so Run the testbench for #(70 * instruction count)      
	
		$finish;
	
	end
	
	
endmodule
