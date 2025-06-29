`timescale 1ns / 1ps

module lut_rom #(
    parameter OUT_WIDTH = 12
)(
    input wire clk,
    input wire rst,
    input wire [7:0] addr,                // 8-bit address (index)
    output reg [OUT_WIDTH-1:0] lut_out    // 12-bit output value
);

    // ROM storage for 256 entries, each OUT_WIDTH bits
    reg [OUT_WIDTH-1:0] rom [0:255];
    integer i;


    // Optional: preload with test values (editable for custom curves)
    initial begin
        for (i = 0; i < 256; i = i + 1)
            rom[i] = i * 16; // simple linear test pattern (0, 16, 32, ..., 4095)
    end

    always @(posedge clk) begin
        if (rst)
            lut_out <= 0;
        else
            lut_out <= rom[addr]; // read from ROM
    end

endmodule

`timescale 1ns / 1ps
`define INSERT 1'b1
`define REMOVE 1'b0

// GAMMA Stage 0: Unpack RGB + AUX, truncate RGB to 8 bits for LUT indexing
module gamma_c_0 #(parameter DATA_WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [6*DATA_WIDTH-1:0] data_in, // 72-bit input: 3x12b RGB + 3x12b AUX
    output reg [3*8-1:0] rgb8_out,         // Truncated 8-bit RGB (for LUT indexing)
    output reg [3*DATA_WIDTH-1:0] aux_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            rgb8_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    rgb8_out <= {data_in[6*DATA_WIDTH-5:6*DATA_WIDTH-12], data_in[5*DATA_WIDTH-5:5*DATA_WIDTH-12], data_in[4*DATA_WIDTH-5:4*DATA_WIDTH-12]};
                    aux_out <= data_in[3*DATA_WIDTH-1:0];
                    i_i_ready <= 0;
                    i_r_ready <= 1;
                end
                `REMOVE: begin
                    i_i_ready <= 1;
                    i_r_ready <= 0;
                end
            endcase
        end
    end
endmodule

// GAMMA Stage 1: Use 3x LUT lookup modules to map 8-bit RGB -> gamma-corrected 12-bit
module gamma_c_1 #(parameter LUT_DEPTH = 256, parameter OUT_WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*8-1:0] rgb8_in,
    input wire [3*OUT_WIDTH-1:0] aux_in,
    output reg [3*OUT_WIDTH-1:0] gamma_out,
    output reg [3*OUT_WIDTH-1:0] aux_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [OUT_WIDTH-1:0] gamma_r, gamma_g, gamma_b;
    lut_rom #(OUT_WIDTH) lut_r (.clk(clock) ,.rst(reset), .addr(rgb8_in[23:16]), .lut_out(gamma_r));
    lut_rom #(OUT_WIDTH) lut_g (.clk(clock) ,.rst(reset), .addr(rgb8_in[15:8]),  .lut_out(gamma_g));
    lut_rom #(OUT_WIDTH) lut_b (.clk(clock) ,.rst(reset), .addr(rgb8_in[7:0]),   .lut_out(gamma_b));

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            gamma_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    gamma_out <= {gamma_r, gamma_g, gamma_b};
                    aux_out <= aux_in;
                    i_i_ready <= 0;
                    i_r_ready <= 1;
                end
                `REMOVE: begin
                    i_i_ready <= 1;
                    i_r_ready <= 0;
                end
            endcase
        end
    end
endmodule

// GAMMA Stage 2: Pack gamma-corrected RGB with AUX into final 72-bit word
module gamma_c_2 #(parameter WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*WIDTH-1:0] gamma_rgb_in,
    input wire [3*WIDTH-1:0] aux_in,
    output reg [6*WIDTH-1:0] data_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            data_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    data_out <= {gamma_rgb_in, aux_in};
                    i_i_ready <= 0;
                    i_r_ready <= 1;
                end
                `REMOVE: begin
                    i_i_ready <= 1;
                    i_r_ready <= 0;
                end
            endcase
        end
    end
endmodule
