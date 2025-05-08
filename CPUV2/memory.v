// 256 x 16-bit RAM for data memory
module data_ram (
    input wire clk,
    input wire we,
    input wire re,
    input wire [7:0] addr,
    input wire [15:0] din,
    output reg [15:0] dout
);

    reg [15:0] mem [0:255];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;
        if (re)
            dout <= mem[addr];
        else
            dout <= 16'hZZZZ;
    end

endmodule

module instruction_rom (
    input wire clk,
    input wire we,                // Write enable (for preload)
    input wire re,                // Read enable (during execution)
    input wire [7:0] addr,
    input wire [15:0] din,        // Data input for preload
    output reg [15:0] dout
);

    reg [15:0] mem [0:255];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;
        if (re)
            dout <= mem[addr];
        else
            dout <= 16'hZZZZ;
    end

endmodule
