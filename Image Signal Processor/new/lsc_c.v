`timescale 1ns / 1ps
`define INSERT 1'b1
`define REMOVE 1'b0

// LSC Stage 0: 12b x 12b multipliers for R, G, B (output 24b each)
module lsc_c_0 #(parameter DATA_WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*DATA_WIDTH-1:0] data_in,
    input wire [3*DATA_WIDTH-1:0] gain_in,
    output reg [3*2*DATA_WIDTH-1:0] product_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [2*DATA_WIDTH-1:0] prod_r, prod_g, prod_b;
    multiplier #(DATA_WIDTH) mul_r (.a(data_in[3*DATA_WIDTH-1:2*DATA_WIDTH]), .b(gain_in[3*DATA_WIDTH-1:2*DATA_WIDTH]), .product(prod_r));
    multiplier #(DATA_WIDTH) mul_g (.a(data_in[2*DATA_WIDTH-1:DATA_WIDTH]),   .b(gain_in[2*DATA_WIDTH-1:DATA_WIDTH]),   .product(prod_g));
    multiplier #(DATA_WIDTH) mul_b (.a(data_in[DATA_WIDTH-1:0]),              .b(gain_in[DATA_WIDTH-1:0]),              .product(prod_b));

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            product_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    product_out <= {prod_r, prod_g, prod_b};
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


// LSC Stage 1: Add 128 to each 24-bit product (rounding pre-shift)
module lsc_c_1 #(parameter IN_WIDTH = 24)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*IN_WIDTH-1:0] product_in,
    output reg [3*IN_WIDTH-1:0] rounded_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [IN_WIDTH-1:0] sum_r, sum_g, sum_b;
    rca #(IN_WIDTH) add_r (.a(product_in[3*IN_WIDTH-1:2*IN_WIDTH]), .b(24'd128), .c(1'b0), .sum(sum_r), .cout());
    rca #(IN_WIDTH) add_g (.a(product_in[2*IN_WIDTH-1:IN_WIDTH]),   .b(24'd128), .c(1'b0), .sum(sum_g), .cout());
    rca #(IN_WIDTH) add_b (.a(product_in[IN_WIDTH-1:0]),            .b(24'd128), .c(1'b0), .sum(sum_b), .cout());

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            rounded_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    rounded_out <= {sum_r, sum_g, sum_b};
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


// LSC Stage 2: Right shift to scale Q4.8 to  int
module lsc_c_2 #(parameter IN_WIDTH = 24, parameter SHIFT = 8)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*IN_WIDTH-1:0] rounded_in,
    output reg [3*(IN_WIDTH-SHIFT)-1:0] scaled_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [IN_WIDTH-SHIFT-1:0] out_r, out_g, out_b;
    right_shifter #(IN_WIDTH, SHIFT) s_r (.in(rounded_in[3*IN_WIDTH-1:2*IN_WIDTH]), .out(out_r));
    right_shifter #(IN_WIDTH, SHIFT) s_g (.in(rounded_in[2*IN_WIDTH-1:IN_WIDTH]),   .out(out_g));
    right_shifter #(IN_WIDTH, SHIFT) s_b (.in(rounded_in[IN_WIDTH-1:0]),            .out(out_b));

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            scaled_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    scaled_out <= {out_r, out_g, out_b};
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


// LSC Stage 3: Clamp to 12-bit max
module lsc_c_3 #(parameter WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*WIDTH-1:0] scaled_in,
    output reg [3*WIDTH-1:0] data_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [WIDTH-1:0] cl_r, cl_g, cl_b;
    clamp #(WIDTH, 0, 4095) clR (.in(scaled_in[3*WIDTH-1:2*WIDTH]), .out(cl_r));
    clamp #(WIDTH, 0, 4095) clG (.in(scaled_in[2*WIDTH-1:WIDTH]),   .out(cl_g));
    clamp #(WIDTH, 0, 4095) clB (.in(scaled_in[WIDTH-1:0]),         .out(cl_b));

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            data_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    data_out <= {cl_r, cl_g, cl_b};
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
