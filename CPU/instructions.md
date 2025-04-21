Sample run:
AND R0, R0, #0; <br />
AND R1, R1, #0; <br />
AND R2, R2, #0; <br />
AND R3, R3, #0; <br />
AND R4, R4, #0; <br />
AND R5, R5, #0; <br />
AND R6, R6, #0; <br />
AND R7, R7, #0; //Initialize registers <br />
ADD R1, R1, #5; //put 5 into register 1 <br />
ADD R2, R2, #5; //put 5 into register 2 <br />
ADD R3, R1, R2; //Add 5 + 5 into R3 <br />
ST R4, #8; //Store the contents of 0x11 into register 4 <br />

You need processor.v and processorTB.v to run this.<br />
Copy and paste the below code into the preload section of the testbench.
Because it is 13 commands. The additional run time should be 13 * 70 = #910 <br />

To check the output, you can either view the memory or the register content of the processor.
To look at register content of the processor, go to scope, click on cpu1, and look in the objects tab and scroll to regfile
<br />

![registers](example1reg.png)


To look at memory, go to scope, click on L1, and look at the objects tab and open up mem.

![memory](example1MEM.png)

//regInit

// AND R0, R0, #0 <br />
preload_addr = 8'h00; <br />
preload_data = 16'b0100000000000000; // AND R0, R0, #0 <br />
#10; <br />
<br />
// AND R1, R1, #0 <br />
preload_addr = 8'h01; <br />
preload_data = 16'b0100000100100000; // AND R1, R1, #0 <br />
#10; <br />
<br />
// AND R2, R2, #0 <br />
preload_addr = 8'h02; <br />
preload_data = 16'b0100001001000000; // AND R2, R2, #0 <br />
#10; <br />
<br />
// AND R3, R3, #0<br />
preload_addr = 8'h03;<br />
preload_data = 16'b0100001101100000; // AND R3, R3, #0<br />
#10;<br />
<br />
// AND R4, R4, #0<br />
preload_addr = 8'h04;<br />
preload_data = 16'b0100010010000000; // AND R4, R4, #0<br />
#10;<br />
<br />
// AND R5, R5, #0<br />
preload_addr = 8'h05;<br />
preload_data = 16'b0100010110100000; // AND R5, R5, #0<br />
#10;<br />
<br />
// AND R6, R6, #0<br />
preload_addr = 8'h06;<br />
preload_data = 16'b0100011011000000; // AND R6, R6, #0<br />
#10;<br />
<br />
// AND R7, R7, #0<br />
preload_addr = 8'h07;<br />
preload_data = 16'b0100011111100000; // AND R7, R7, #0<br />
#10;<br />
<br />
//ADD R1, R1, #5<br />
<br />
preload_addr = 8'h08;<br />
preload_data = 16'b0001000100100101; // ADD R1, R1, #5<br />
#10;<br />
<br />
//ADD R2, R2, #5<br />
<br />
preload_addr = 8'h09;<br />
preload_data = 16'b0001001001000101; // ADD R2, R2, #5<br />
#10;<br />
<br />
//ADD R3, R1, R2<br />
<br />
preload_addr = 8'h0A;<br />
preload_data = 16'b0001101100101000; // ADD R3, R1, R2<br />
#10;<br />
<br />
//ST R3, #8<br />
<br />
preload_addr = 8'h0B;<br />
preload_data = 16'b0110100000000110; // ST R3, #8<br />
#10;<br />
<br />
preload_addr = 8'h11;<br />
preload_data = 16'b1011111011101111 //BEEF<br />
#10;<br />
