//ADD 0001_I_REG_REG_REG_XX
//	//if I is high, do reg + reg, if I is low, treat last 5 bits as immediate
//SUB 0010_I_REG_REG_REG_XX
//MUL 0011_I_REG_REG_REG_XX
//AND 0100_I_REG_REG_REG_XX
//NOT 0101_X_REG_REG //First reg is result reg, second reg is input reg
//ST  0110_REG_imm9 //store from reg into memory address
//LD  0111_REG_imm9 //load into reg from memory address
//STR 1000_REG_REG_irrelevant //stores from reg to memory address in reg
//LDR 1001_REG_REG_irrelevant //load into reg from memory address in reg
//STI 1010_REG_imm9 //Store from register into PC + imm9
//LDI 1011_REG_imm9 //Load into register from PC + imm9
//JMP 1100_REG_000000000 //Jump to address in register
//RET 1101 //Jump to address in R7 (return register)
//BRZ 1110_REG_imm9 //Jump to address at imm9 if REG is zero. 
//BRN 1111_REG_imm9 //Jump to address at imm9 if REG is nonzero.
//NOP 0000


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
`define STI     4'b1010
`define LDI     4'b1011
`define JMP     4'b1100
`define RET     4'b1101
`define BRZ     4'b1110
`define BRN     4'b1111
`define NOP     4'b0000


module processor(
    input wire clock, //clock signal
    input wire reset, //reset pin, mainly for testing
    input wire[7:0] currPc, //current program counter, not used
    input wire[15:0] memDataIn, //memDataIn is used to read whatever is in an LD or LDR
    //memDataIn and currInstruction may be combined into one
    output reg[15:0] dataOut, //instruction at program counter, used to write from ST or STR
    output reg[7:0] memAddr, //address for memory operations, used to find PC from the outside
    output reg readMem, //flag for whether to read memory
    output reg writeMem, //flag for whether to write memory
    output reg[7:0] nextPc //program counter. currently unused
    
    );
    reg  [15:0] regfile [7:0]; //8 registers of 16 length 
    wire branch; //branch flag
    wire branch_target; //branch target, may be implemented with pipelining
    reg[15:0] instruction; //currently executing instruction
    reg[7:0] pc; //program counter
    reg [3:0] opcode; //instruction opcode (AND, ADD, LD) for ex
    reg [2:0] destReg; //destination register for compute , used in ALU ops
    reg [2:0] regA; //input register for compute
    reg [2:0] regB; //input register for compute
    reg [4:0] imm5; //used for ALU opps with an immediate
    reg [15:0] signed_imm5; //sign extension
    reg [8:0] imm9; //used for non ALU ops
    reg [15:0] signed_imm9; //sign extension
    reg ROI; //is it register or immediate
    reg [2:0] resReg; //destination register for non compute/ non ALU commands
    reg [2:0] inReg; //registers for STR and LDR
    reg [15:0] aluResult; //result of ALU for temporary storage
    
    reg [2:0] state;
    localparam  FETCH = 3'b0000, //Fetch state, get the program counter at the correct memory address
                WAIT_FOR_ISA = 3'b001, //one clock cycle delay for reads (FETCH needs a read)
                DECODE = 3'b010, //assign parts of the current instruction with a task, only needs current instruction
                EXECUTE = 3'b011, //execute the commands and store result in ALUresult to be assigned later. branch commands go straight to writeback
                MEM = 3'b100, //Memory stage for commands that need memory access (LD/ST)
                MEMDELAY = 3'b101, //one cycle delay for memory commmands
                WB = 3'b110; //write back into memory/local memory
    
    always@(posedge clock)
        if(reset) begin
            pc <= 0;
            state <= FETCH;
            readMem <= 0;
            writeMem <= 0;              
        end else begin
    
    
        case (state)
            FETCH: begin
                memAddr <= pc;
                readMem <= 1;
                writeMem <= 0;
                state <= WAIT_FOR_ISA;
            
            end
            
            WAIT_FOR_ISA: begin
                state <= DECODE; 
            end
            
            DECODE: begin
                instruction = memDataIn;    
                opcode = instruction[15:12];
                destReg = instruction[10:8]; //destination register for compute 
                regA = instruction[7:5]; //input register for compute
                regB = instruction[4:2]; //input register for compute
                imm5 = instruction[4:0];
                signed_imm5 = {{11{imm5[4]}},imm5};
                imm9 = instruction[8:0];
                signed_imm9 = {{7{imm9[8]}}, imm9};
                ROI = instruction[11]; //is it register or immediate
                resReg = instruction[11:9]; //destination register for non compute commands
                inReg = instruction[8:6]; //registers for STR and LDR
                readMem <= 0;
                state <= EXECUTE;
            end
                
            EXECUTE: 
                begin //beginning of case statement
                    case (opcode)
                        `ADD: 
                            begin
                            if(ROI == 1)aluResult <= regfile[regA] + regfile[regB];
                            else aluResult <= regfile[regA] + signed_imm5;
                            
                            end
                        `SUB: 
                            begin
                            if(ROI == 1)aluResult <= regfile[regA] - regfile[regB];
                            else aluResult <= regfile[regA] - signed_imm5;
                            
                            end
                        `MUL: begin
                            if(ROI == 1)aluResult <= regfile[regA] * regfile[regB];
                            else aluResult <= regfile[regA] * signed_imm5;
                           
                            end
                        `AND: begin
                            if(ROI == 1)aluResult <= regfile[regA] & regfile[regB];
                            else aluResult <= regfile[regA] & signed_imm5;
                            
                            end
                        `NOT: aluResult <= ~regfile[regA];
                        `ST: begin
                            aluResult <= pc + signed_imm9;
                            dataOut <= regfile[resReg];
                            end
                        `LD: begin
                            aluResult <= pc + signed_imm9;
            
                            end
                        `STR: begin
                            aluResult <= pc + inReg;
                            dataOut <= regfile[resReg];
            
                            end
                        `LDR: begin
                            aluResult <= pc + inReg;
            
                            end
                        `JMP: begin
                            aluResult <= regfile[resReg]; //next PC candidate
                            end
                            `RET: begin
                                aluResult <= regfile[7]; //r7 is return address
                            end
                            
                            `BRZ: begin
                                if(regfile[resReg] == 0)
                                    aluResult <= pc + signed_imm9; //jmp to next
                                else 
                                    aluResult <= pc + 1; //go through
                           end
                           `BRN: begin
                                if(regfile[resReg] != 0)
                                    aluResult <= pc + signed_imm9;
                                else 
                                    aluResult <= pc + 1;
                           end
                           `NOP: begin
                                aluResult <= pc + 1;
                           end
                        default: aluResult <= 0;//do nothing   
                        endcase   
                        if(opcode == `JMP || opcode == `RET ||
                        opcode == `BRZ || opcode == `BRN ||
                        opcode == `NOP) state <= WB;
                        else 
                            state <= MEM;
                    end //end of case
            MEM: begin
                case(opcode)
                    `LD, `LDR: begin
                        memAddr <= aluResult[7:0];
                        readMem <= 1;
                    end
                    `ST, `STR: begin
                        memAddr <= aluResult[7:0];
                    end
                    default: ;
                    endcase
                state <= MEMDELAY;
            end
            MEMDELAY: begin
                case(opcode)
                    `LD, `LDR: begin
                        readMem <= 1;
                    end
                    `ST, `STR: begin
                        writeMem <= 1;
                    end
                    default: ;
                    endcase
                    state <= WB;
            end
            WB: begin
                readMem <= 0;
                writeMem <= 0;
                case(opcode) 
                    `ADD, `SUB, `MUL, `AND, `NOT: begin
                        regfile[destReg] <= aluResult;
                        pc <= pc + 1;
                        nextPc <= pc + 1;
                        end
                    `LD, `LDR: begin    
                        regfile[resReg] <= memDataIn; //from the load
                        pc <= pc + 1;
                        nextPc <= pc + 1;
                        end
                    `JMP, `RET, `BRZ, `BRN: pc <= aluResult; //switch address
                    default: begin 
                                pc <= pc + 1; //all others just move to next instruction
                             nextPc <= pc + 1;
                             end
                endcase
                state <= FETCH;
            end 
            
            default: state <= FETCH;
        
        endcase
    end
        
endmodule


//Test memory module. 256 lines of memory with 16 bit line length. WE allows a write, RE allows a read. Outputs undefined if neither is specified. 
module test_memory (
    input wire clk,
    input wire we,                 // Write enable
    input wire re,                  // read enable
    input wire [7:0] addr,         // 8-bit address
    input wire [15:0] din,         // Data input
    output reg [15:0] dout         // Data output
);

    reg [15:0] mem [0:255];        // Memory array: 256 rows, 16 bits wide

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;      // Write to memory
        if (re)
            dout <= mem[addr];         // Read from memory
            else 
            dout <= 16'hZZZZ;  ///undefined
    end

endmodule 
