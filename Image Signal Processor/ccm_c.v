`timescale 1ns / 1ps
`define INSERT 1'b1
`define REMOVE 1'b0

// CCM Stage 0: Unpack 72-bit input into RGB and AUX
module ccm_c_0 #(parameter DATA_WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [6*DATA_WIDTH-1:0] data_in, // 3x12 RGB + 3x12 AUX
    output reg [3*DATA_WIDTH-1:0] rgb_out,
    output reg [3*DATA_WIDTH-1:0] aux_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            rgb_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    rgb_out <= data_in[6*DATA_WIDTH-1:3*DATA_WIDTH];
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

// CCM Stage 1: Multiply R, G, B by CCM matrix rows
module ccm_c_1 #(parameter DATA_WIDTH = 12, parameter MATRIX_WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*DATA_WIDTH-1:0] rgb_in,
    input wire [3*DATA_WIDTH-1:0] aux_in,
    input wire [MATRIX_WIDTH-1:0] a11, a12, a13, a21, a22, a23, a31, a32, a33,
    output reg [3*2*DATA_WIDTH-1:0] partial_products_out, // 3 channels x 3 products
    output reg [3*DATA_WIDTH-1:0] aux_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [DATA_WIDTH-1:0] r = rgb_in[3*DATA_WIDTH-1:2*DATA_WIDTH];
    wire [DATA_WIDTH-1:0] g = rgb_in[2*DATA_WIDTH-1:DATA_WIDTH];
    wire [DATA_WIDTH-1:0] b = rgb_in[DATA_WIDTH-1:0];

    wire [2*DATA_WIDTH-1:0] p11, p12, p13, p21, p22, p23, p31, p32, p33;

    multiplier #(DATA_WIDTH) m11 (.a(r), .b(a11), .product(p11));
    multiplier #(DATA_WIDTH) m12 (.a(g), .b(a12), .product(p12));
    multiplier #(DATA_WIDTH) m13 (.a(b), .b(a13), .product(p13));

    multiplier #(DATA_WIDTH) m21 (.a(r), .b(a21), .product(p21));
    multiplier #(DATA_WIDTH) m22 (.a(g), .b(a22), .product(p22));
    multiplier #(DATA_WIDTH) m23 (.a(b), .b(a23), .product(p23));

    multiplier #(DATA_WIDTH) m31 (.a(r), .b(a31), .product(p31));
    multiplier #(DATA_WIDTH) m32 (.a(g), .b(a32), .product(p32));
    multiplier #(DATA_WIDTH) m33 (.a(b), .b(a33), .product(p33));

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            partial_products_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    partial_products_out <= {p11, p12, p13, p21, p22, p23, p31, p32, p33};
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

// CCM Stage 2: Sum partial products for each color channel
module ccm_c_2 #(parameter WIDTH = 24)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [9*WIDTH-1:0] partials_in, // 9 partials: 3 per output channel
    input wire [3*WIDTH/2-1:0] aux_in,
    output reg [3*WIDTH-1:0] result_out,
    output reg [3*WIDTH/2-1:0] aux_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [WIDTH-1:0] r_acc, g_acc, b_acc;

    wire [WIDTH-1:0] r1 = partials_in[9*WIDTH-1:8*WIDTH];
    wire [WIDTH-1:0] r2 = partials_in[8*WIDTH-1:7*WIDTH];
    wire [WIDTH-1:0] r3 = partials_in[7*WIDTH-1:6*WIDTH];
    wire [WIDTH-1:0] g1 = partials_in[6*WIDTH-1:5*WIDTH];
    wire [WIDTH-1:0] g2 = partials_in[5*WIDTH-1:4*WIDTH];
    wire [WIDTH-1:0] g3 = partials_in[4*WIDTH-1:3*WIDTH];
    wire [WIDTH-1:0] b1 = partials_in[3*WIDTH-1:2*WIDTH];
    wire [WIDTH-1:0] b2 = partials_in[2*WIDTH-1:WIDTH];
    wire [WIDTH-1:0] b3 = partials_in[WIDTH-1:0];

    wire [WIDTH-1:0] r_temp, g_temp, b_temp;
    wire dummy1, dummy2, dummy3, dummy4, dummy5, dummy6;

    rca #(WIDTH) add_r1 (.a(r1), .b(r2), .cin(1'b0), .sum(r_temp), .cout(dummy1));
    rca #(WIDTH) add_r2 (.a(r_temp), .b(r3), .cin(1'b0), .sum(r_acc), .cout(dummy2));

    rca #(WIDTH) add_g1 (.a(g1), .b(g2), .cin(1'b0), .sum(g_temp), .cout(dummy3));
    rca #(WIDTH) add_g2 (.a(g_temp), .b(g3), .cin(1'b0), .sum(g_acc), .cout(dummy4));

    rca #(WIDTH) add_b1 (.a(b1), .b(b2), .cin(1'b0), .sum(b_temp), .cout(dummy5));
    rca #(WIDTH) add_b2 (.a(b_temp), .b(b3), .cin(1'b0), .sum(b_acc), .cout(dummy6));

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            result_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    result_out <= {r_acc, g_acc, b_acc};
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

// CCM Stage 3: Right shift RGB to scale fixed-point results
module ccm_c_3 #(parameter WIDTH = 24, parameter SHIFT = 8)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*WIDTH-1:0] result_in,
    input wire [3*WIDTH/2-1:0] aux_in,
    output reg [3*(WIDTH-SHIFT)-1:0] scaled_out,
    output reg [3*WIDTH/2-1:0] aux_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [WIDTH-SHIFT-1:0] out_r, out_g, out_b;
    right_shifter #(WIDTH, SHIFT) s_r (.in(result_in[3*WIDTH-1:2*WIDTH]), .out(out_r));
    right_shifter #(WIDTH, SHIFT) s_g (.in(result_in[2*WIDTH-1:WIDTH]),   .out(out_g));
    right_shifter #(WIDTH, SHIFT) s_b (.in(result_in[WIDTH-1:0]),         .out(out_b));

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            scaled_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    scaled_out <= {out_r, out_g, out_b};
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

// CCM Stage 4: Clamp scaled RGB to 12-bit range
module ccm_c_4 #(parameter WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*WIDTH-1:0] scaled_in,
    input wire [3*WIDTH-1:0] aux_in,
    output reg [3*WIDTH-1:0] clamped_out,
    output reg [3*WIDTH-1:0] aux_out,
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
            clamped_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    clamped_out <= {cl_r, cl_g, cl_b};
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

// CCM Stage 5: Repack clamped RGB and AUX into 72-bit output
module ccm_c_5 #(parameter WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*WIDTH-1:0] clamped_in,
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
                    data_out <= {clamped_in, aux_in};
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

