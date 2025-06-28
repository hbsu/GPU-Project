`timescale 1ns / 1ps
`define INSERT 1'b1
`define REMOVE 1'b0

// DMSC Stage 0: Tag pixel with (x, y) coordinates
module dmsc_c_0 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [11:0] x_out,
    output reg [11:0] y_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    reg [11:0] x, y;
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            x <= 0;
            y <= 0;
            x_out <= 0;
            y_out <= 0;
            data_out <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    data_out <= data_in;
                    x_out <= x;
                    y_out <= y;
                    i_i_ready <= 0;
                    i_r_ready <= 1;
                    if (x == 12'd4095) begin
                        x <= 0;
                        y <= y + 1;
                    end else begin
                        x <= x + 1;
                    end
                end
                `REMOVE: begin
                    i_i_ready <= 1;
                    i_r_ready <= 0;
                end
            endcase
        end
    end
endmodule


// DMSC Stage 1: Determine pixel type (00 = R, 01 = G, 10 = B) based on Bayer pattern
module dmsc_c_1(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [71:0] data_in,
    input wire [11:0] x_in,
    input wire [11:0] y_in,
    output reg [71:0] data_out,
    output reg [1:0] pixel_type_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;
    reg [1:0] pixel_type;

    always @(*) begin
        case ({y_in[0], x_in[0]})
            2'b00: pixel_type = 2'b00; // R
            2'b01: pixel_type = 2'b01; // G
            2'b10: pixel_type = 2'b01; // G
            2'b11: pixel_type = 2'b10; // B
        endcase
    end

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            data_out <= 0;
            pixel_type_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    data_out <= data_in;
                    pixel_type_out <= pixel_type;
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


// DMSC Stage 2: Horizontal line buffer
module dmsc_c_2 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH*3-1:0] line_buffer_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;
    reg [DATA_WIDTH-1:0] buf0, buf1;

    always @(posedge clock) begin
        if (reset) begin
            buf0 <= 0;
            buf1 <= 0;
            line_buffer_out <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    line_buffer_out <= {buf1, buf0, data_in};
                    buf1 <= buf0;
                    buf0 <= data_in;
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


// DMSC Stage 3: Form 3x3 window from line buffers
module dmsc_c_3 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*DATA_WIDTH-1:0] r0,
    input wire [3*DATA_WIDTH-1:0] r1,
    input wire [3*DATA_WIDTH-1:0] r2,
    output reg [9*DATA_WIDTH-1:0] window_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            window_out <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    window_out <= {r0, r1, r2};
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


// DMSC Stage 4: Extract pixel and 8 neighbors
module dmsc_c_4 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [9*DATA_WIDTH-1:0] window_in,
    output reg [DATA_WIDTH-1:0] center,
    output reg [DATA_WIDTH-1:0] n0, n1, n2, n3, n4, n5, n6, n7,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            center <= 0; n0 <= 0; n1 <= 0; n2 <= 0;
            n3 <= 0; n4 <= 0; n5 <= 0; n6 <= 0; n7 <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    n0 <= window_in[9*DATA_WIDTH-1:8*DATA_WIDTH];
                    n1 <= window_in[8*DATA_WIDTH-1:7*DATA_WIDTH];
                    n2 <= window_in[7*DATA_WIDTH-1:6*DATA_WIDTH];
                    n3 <= window_in[6*DATA_WIDTH-1:5*DATA_WIDTH];
                    center <= window_in[5*DATA_WIDTH-1:4*DATA_WIDTH];
                    n4 <= window_in[4*DATA_WIDTH-1:3*DATA_WIDTH];
                    n5 <= window_in[3*DATA_WIDTH-1:2*DATA_WIDTH];
                    n6 <= window_in[2*DATA_WIDTH-1:1*DATA_WIDTH];
                    n7 <= window_in[1*DATA_WIDTH-1:0];
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


// DMSC Stage 5: Basic green channel interpolation placeholder
module dmsc_c_5 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [DATA_WIDTH-1:0] center,
    input wire [DATA_WIDTH-1:0] n0, n1, n2, n3, n4, n5, n6, n7,
    output reg [DATA_WIDTH-1:0] interpolated_g,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            interpolated_g <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    interpolated_g <= center; // Replace with real logic
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


// DMSC Stage 6: Placeholder for red/blue interpolation
module dmsc_c_6 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [DATA_WIDTH-1:0] interpolated_g,
    output reg [DATA_WIDTH-1:0] interpolated_rgb,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            interpolated_rgb <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    interpolated_rgb <= interpolated_g; // Replace with real logic
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

// DMSC Stage 7: Edge-aware blending placeholder
module dmsc_c_7 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [DATA_WIDTH-1:0] interpolated_rgb,
    output reg [DATA_WIDTH-1:0] blended_rgb,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            blended_rgb <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    blended_rgb <= interpolated_rgb; // Replace with actual edge-aware logic
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


// DMSC Stage 8: Assemble final RGB pixel (placeholder)
module dmsc_c_8 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [DATA_WIDTH-1:0] blended_rgb,
    output reg [DATA_WIDTH-1:0] final_rgb,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            final_rgb <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    final_rgb <= blended_rgb; // Replace with actual packing logic if needed
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


// DMSC Stage 9: Denoising placeholder
module dmsc_c_9 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [DATA_WIDTH-1:0] final_rgb,
    output reg [DATA_WIDTH-1:0] denoised_rgb,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            denoised_rgb <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    denoised_rgb <= final_rgb; // Replace with actual denoising logic
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


// DMSC Stage 10: Color correction placeholder
module dmsc_c_10 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [DATA_WIDTH-1:0] denoised_rgb,
    output reg [DATA_WIDTH-1:0] corrected_rgb,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            corrected_rgb <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    corrected_rgb <= denoised_rgb; // Replace with actual color correction logic
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


// DMSC Stage 11: Output stage placeholder
module dmsc_c_11 #(parameter DATA_WIDTH = 72)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [DATA_WIDTH-1:0] corrected_rgb,
    output reg [DATA_WIDTH-1:0] output_rgb,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    always @(posedge clock) begin
        if (reset) begin
            output_rgb <= 0;
            i_i_ready <= 1;
            i_r_ready <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    output_rgb <= corrected_rgb; // Final output handoff
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
