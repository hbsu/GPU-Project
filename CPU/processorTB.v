`timescale 1ns / 1ps

//Testbench for processor commands
//Example run will be shown. 
module processorTB(
    );
    
    reg clock, reset, writeEnable;
    reg[7:0] testAddress;
    reg[15:0] dataIn;
    wire[15:0] dataOut;
    reg[7:0] programCounter;
    reg[15:0] whatInstruction;
    wire[15:0] memDataIn; //input data from memory
    wire[15:0] resultData;
    wire[7:0] tempAddress;
    wire readFlag, writeFlag;
    wire[7:0] nextProgramCounter; //next program counter

    
    initial clock = 0;
    always #5 clock = ~clock; // 100 MHz clock
    
    test_memory L1( //Main memory rn
        .clk(clock), //Clock cycle
        .we(mem_we), //write enable
        .re(readFlag), //read enable
        .addr(memory_address), //Specify where in memory you want to write/read
        .din(testData), //Data to be put into memory, will only update if write enable is high
        .dout(memDataIn) //Read data value at specified memory location
    );
    
    processor cpu1(
    .clock(clock), //Clock
    .reset(reset), //Reset
    .currPc(nextProgramCounter), //NOT NECESSARY PORT
    .memDataIn(memDataIn), //input data, 16 bits, could be instruction or memory contents
    .dataOut(resultData), //output data, used for ST/STR
    .memAddr(tempAddress), //output address to be used in read or write or computation
    .readMem(readFlag), //output for read flag, turns on or off read enable
    .writeMem(writeFlag), //output for write flag, turns on or off write enable
    .nextPc(nextProgramCounter) //NOT A NECESSARY PORT
    );
    
    wire[7:0] memory_address; //8 bit memory address
    wire mem_we; //write enable
    wire[15:0] testData; //test data
	
	
	
	//The 3 nets below are for loading memory with data such as instructions.
	//when preload_we is high, assume CPU is in boot up. 
    reg preload_we = 0; //preload write enable, allows you to load data into memory
    reg[7:0] preload_addr = 0; //Preload address for where to assign a specific line
    reg[15:0] preload_data = 0; //Used to assign data in memory
    
    assign mem_we = preload_we | writeFlag; //control statement
	//If preload_we is high, use the preload instructions, otherwise use the outputs of the CPU
    assign memory_address  = preload_we ? preload_addr : tempAddress; 
    assign testData = preload_we ? preload_data : resultData; 
    
    initial begin 
    //TO USE THE TESTBENCH
        
        //*****DO NOT REMOVE BELOW THIS LINE
        reset = 1; //Puts CPU in reset
        #20;
        reset = 0;
        //BOOTLOADER
        preload_we = 1; //STORE TESTBENCH BELOW THIS LINE
		//*****DO NOT REMOVE ABOVE THIS LINE
		
		//PUT TESTBENCH STARTING THIS LINE:

        
		//*****DO NOT REMOVE BELOW THIS LINE
        preload_we = 0; //STORE TESTBENCH ABOVE THIS LINIE
        #10;
        reset = 1; //Puts CPU back in reset
        #70;
        reset = 0;
		//*****DO NOT REMOVE ABOVE THIS LINE

        
        #100; //Allow time for commmands to pass. 
            //Each instruction takes at most 7 clock cycles,
            //so Run the testbench for #(70 * instruction count)        
        
               
        $finish;
    
    end

    
endmodule


