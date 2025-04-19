`timescale 1ns / 1ps


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
        .clk(clock),
        .we(mem_we),
        .re(readFlag),
        .addr(memory_address),
        .din(testData),
        .dout(memDataIn)
    );
    
    processor cpu1(
    .clock(clock), 
    .reset(reset), 
    .currPc(nextProgramCounter), //
    .memDataIn(memDataIn), //input data
    .dataOut(resultData), //output
    .memAddr(tempAddress), //output address to be used in read or write or computation
    .readMem(readFlag), //output for read flag
    .writeMem(writeFlag), //output for write flag
    .nextPc(nextProgramCounter) //output for next program counter. Unused currently
    );
    
    wire[7:0] memory_address;
    wire mem_we;
    wire[15:0] testData;
    reg preload_we = 0;
    reg[7:0] preload_addr = 0;
    reg[15:0] preload_data = 0;
    
    assign mem_we = preload_we | writeFlag;
    assign memory_address  = preload_we ? preload_addr : tempAddress;
    assign testData = preload_we ? preload_data : resultData; 
    
    initial begin 
    
        
        
        reset = 1;
        #20;
        reset = 0;
        //BOOTLOADER
        preload_we = 1; //STORE TESTBENCH BELOW THIS LINE
       
// AND R0, R0, #0
preload_addr = 8'h00;
preload_data = 16'b0100000000000000; // AND R0, R0, #0
#10;

// AND R1, R1, #0
preload_addr = 8'h01;
preload_data = 16'b0100000100100000; // AND R1, R1, #0
#10;

// AND R2, R2, #0
preload_addr = 8'h02;
preload_data = 16'b0100001001000000; // AND R2, R2, #0
#10;

// AND R3, R3, #0
preload_addr = 8'h03;
preload_data = 16'b0100001101100000; // AND R3, R3, #0
#10;

// AND R4, R4, #0
preload_addr = 8'h04;
preload_data = 16'b0100010010000000; // AND R4, R4, #0
#10;

// AND R5, R5, #0
preload_addr = 8'h05;
preload_data = 16'b0100010110100000; // AND R5, R5, #0
#10;

// AAND R6, R6, #0
preload_addr = 8'h06;
preload_data = 16'b0100011011000000; // AND R6, R6, #0
#10;

// AND R7, R7, #0
preload_addr = 8'h07;
preload_data = 16'b0100011111100000; // AND R7, R7, #0
#10;

//ADD R1, R1, #3

preload_addr = 8'h08;
preload_data = 16'b0001000100100011; // ADD R1, R1, #3
#10;

//ADD R2, R2, #2

preload_addr = 8'h09;
preload_data = 16'b0001001001000010; // ADD R2, R2, #2
#10;

//ADD R3, R1, R2

preload_addr = 8'h0A;
preload_data = 16'b0001101100101000; // ADD R3, R1, R2
#10;

//ST R3, #10

preload_addr = 8'h0B;
preload_data = 16'b0110011000001010; // ST R3, #10
#10;

//LD R4, #10

preload_addr = 8'h0C;
preload_data = 16'b0111100000001010; // LD R4, #10
#10;

//SUB R5, R5, R3

preload_addr = 8'h0D;
preload_data = 16'b0010110101101100; // SUB R5, R3, R3
#10;

//BRZ R5, #2

preload_addr = 8'h0E;
preload_data = 16'b1110101000000010; // BRZ R5, #2
#10;

//ADD R4, R4, #99

preload_addr = 8'h0F;
preload_data = 16'b0001010010000011; // ADD R4, R4, #99
#10;

//ADD R6, R6, #1

preload_addr = 8'h10;
preload_data = 16'b0001011011000001; // ADD R6, R6, #1
#10;

        
        preload_we = 0; //STORE TESTBENCH ABOVE THIS LINIE
        
        #10;
        reset = 1;
        
        #70;
        reset = 0;
        
        #1750; //Multiply this by amount of commands
        
        
               
        $finish;
    
    end

    
endmodule


