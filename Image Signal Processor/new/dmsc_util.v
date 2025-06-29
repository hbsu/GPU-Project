`timescale 1ns / 1ps

// This module generates (x, y) coordinates for each incoming pixel. It is essential
// in image processing pipelines such as demosaicing, where spatial awareness is
// required to determine pixel type (R/G/B) and to correctly access neighboring pixels.
// It increments x with each pixel, and wraps to the next row by incrementing y when x reaches max.
module xy_counter #(
    parameter X_WIDTH = 12,
    parameter Y_WIDTH = 12,
    parameter X_MAX   = 4095,
    parameter Y_MAX   = 4095
)(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    output reg  [X_WIDTH-1:0] x,
    output reg  [Y_WIDTH-1:0] y
);
    always @(posedge clk) begin
        if (rst) begin
            x <= 0;
            y <= 0;
        end else if (enable) begin
            if (x == X_MAX) begin
                x <= 0;
                if (y == Y_MAX)
                    y <= 0;
                else
                    y <= y + 1;
            end else begin
                x <= x + 1;
            end
        end
    end
endmodule


//Essential to tell if its an R, G, or B
module pixel_type_decoder(
    input  wire x_lsb, // x[0]
    input  wire y_lsb, // y[0]
    output reg  [1:0] pixel_type // 00 = R, 01 = G, 10 = B
);
    always @(*) begin
        case ({y_lsb, x_lsb})
            2'b00: pixel_type = 2'b00; // R
            2'b01: pixel_type = 2'b01; // G
            2'b10: pixel_type = 2'b01; // G
            2'b11: pixel_type = 2'b10; // B
        endcase
    end
endmodule

// This shift register stores the three most recent pixels in a scanline. It is a key
// part of the line buffering system needed to build 3x3 spatial windows for
// neighborhood-based image operations like interpolation or edge detection.
module horizontal_shift_reg #(parameter DATA_WIDTH = 72)(
    input  wire clk,
    input  wire rst,
    input  wire enable,
    input  wire [DATA_WIDTH-1:0] in,
    output wire [DATA_WIDTH-1:0] w0, // newest
    output wire [DATA_WIDTH-1:0] w1,
    output wire [DATA_WIDTH-1:0] w2  // oldest
);
    reg [DATA_WIDTH-1:0] stage0, stage1, stage2;

    always @(posedge clk) begin
        if (rst) begin
            stage0 <= 0;
            stage1 <= 0;
            stage2 <= 0;
        end else if (enable) begin
            stage2 <= stage1;
            stage1 <= stage0;
            stage0 <= in;
        end
    end

    assign w0 = stage0;
    assign w1 = stage1;
    assign w2 = stage2;
endmodule


// This module aggregates outputs from three horizontal shift registers, representing
// three image rows, into a 3x3 pixel window. This window is necessary for spatial
// interpolation operations, like edge detection or bilinear filtering, which need
// simultaneous access to a neighborhood of pixels.
module window_builder #(parameter DATA_WIDTH = 72)(
    input  wire [DATA_WIDTH-1:0] r0_0, r0_1, r0_2,
    input  wire [DATA_WIDTH-1:0] r1_0, r1_1, r1_2,
    input  wire [DATA_WIDTH-1:0] r2_0, r2_1, r2_2,
    output wire [9*DATA_WIDTH-1:0] window_out
);
    assign window_out = {r0_0, r0_1, r0_2,
                         r1_0, r1_1, r1_2,
                         r2_0, r2_1, r2_2};
endmodule


// This module decomposes the 3x3 window created by `window_builder` into its 9
// constituent pixels. The pixels are ordered to allow easy access to the center pixel
// and its eight immediate neighbors, simplifying logic for convolution, interpolation,
// or other local operations.
module pixel_extractor #(parameter DATA_WIDTH = 72)(
    input  wire [9*DATA_WIDTH-1:0] window,
    output wire [DATA_WIDTH-1:0] center,
    output wire [DATA_WIDTH-1:0] n0, n1, n2, n3, n4, n5, n6, n7 // surrounding pixels
);
    assign {n0, n1, n2,
            n3, center, n4,
            n5, n6, n7} = window;
endmodule


// Computes a simple, rounded average between two pixel values. This is commonly used
// in demosaicing when interpolating missing color components by averaging nearby pixels.
module bilinear_interp #(parameter WIDTH = 12)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] result
);
    assign result = (a + b + 1'b1) >> 1; // rounding average
endmodule


// Estimates the green channel at a red or blue pixel by first averaging top/bottom and
// left/right neighbors, then taking the average of those two results. This emulates the
// central tendency of the green channel, which is sampled more frequently in Bayer filters.
module green_interp #(parameter WIDTH = 12)(
    input  wire [WIDTH-1:0] top,
    input  wire [WIDTH-1:0] bottom,
    input  wire [WIDTH-1:0] left,
    input  wire [WIDTH-1:0] right,
    output wire [WIDTH-1:0] result
);
    wire [WIDTH-1:0] vert_avg, horiz_avg;
    bilinear_interp #(WIDTH) v_avg (.a(top),    .b(bottom), .result(vert_avg));
    bilinear_interp #(WIDTH) h_avg (.a(left),   .b(right),  .result(horiz_avg));
    bilinear_interp #(WIDTH) g_avg (.a(vert_avg), .b(horiz_avg), .result(result));
endmodule


// Applies a Sobel kernel to a 3x3 neighborhood to compute an approximation of edge
// strength. It returns the squared gradient magnitude, avoiding a square root for
// efficiency. Used in edge-aware interpolation and adaptive demosaicing.
module sobel_edge_detector #(parameter WIDTH = 12)(
    input  wire [WIDTH-1:0] tl, t, tr,
    input  wire [WIDTH-1:0] ml,       mr,
    input  wire [WIDTH-1:0] bl, b, br,
    output wire [WIDTH+1:0] gradient
);
    wire signed [WIDTH+1:0] gx, gy;
    assign gx = (tr + (mr << 1) + br) - (tl + (ml << 1) + bl);
    assign gy = (bl + (b << 1) + br) - (tl + (t << 1) + tr);
    assign gradient = gx*gx + gy*gy; // approximate magnitude squared
endmodule


// Performs weighted interpolation between two candidate values based on their
// associated edge gradients. Helps reduce artifacts along edges by favoring the
// interpolation direction with less intensity variation.
module edge_aware_blender #(parameter WIDTH = 12)(
    input  wire [WIDTH-1:0] interp1,
    input  wire [WIDTH-1:0] interp2,
    input  wire [WIDTH+1:0] grad1,
    input  wire [WIDTH+1:0] grad2,
    output wire [WIDTH-1:0] result
);
    wire [WIDTH+2:0] weight1 = grad2;
    wire [WIDTH+2:0] weight2 = grad1;
    wire [WIDTH+3:0] numerator = weight1 * interp1 + weight2 * interp2;
    wire [WIDTH+2:0] denominator = weight1 + weight2 + 1;
    assign result = numerator / denominator;
endmodule
