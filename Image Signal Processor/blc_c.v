`timescale 1ns / 1ps
`define INSERT 1'b1
`define REMOVE 1'b0

module blc_c_0 #(parameter DATA_WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*DATA_WIDTH-1:0] offset_in,
    input wire [3*DATA_WIDTH-1:0] data_in,
    input wire [3*DATA_WIDTH-1:0] aux_in,
    output reg [3*DATA_WIDTH-1:0] offset_out,
    output reg [3*DATA_WIDTH-1:0] data_out,
    output reg [3*DATA_WIDTH-1:0] aux_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [DATA_WIDTH-1:0] inv_r, inv_g, inv_b;
    inverter #(DATA_WIDTH) invR (.in(offset_in[3*DATA_WIDTH-1:2*DATA_WIDTH]), .out(inv_r));
    inverter #(DATA_WIDTH) invG (.in(offset_in[2*DATA_WIDTH-1:DATA_WIDTH]), .out(inv_g));
    inverter #(DATA_WIDTH) invB (.in(offset_in[DATA_WIDTH-1:0]), .out(inv_b));

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            data_out <= 0;
            offset_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    data_out <= data_in;
                    offset_out <= {inv_r, inv_g, inv_b};
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


module blc_c_1 #(parameter DATA_WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*DATA_WIDTH-1:0] offset_in,
    input wire [3*DATA_WIDTH-1:0] data_in,
    input wire [3*DATA_WIDTH-1:0] aux_in,
    output reg [3*DATA_WIDTH-1:0] offset_out,
    output reg [3*DATA_WIDTH-1:0] data_out,
    output reg [3*DATA_WIDTH-1:0] aux_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [DATA_WIDTH-1:0] inc_r, inc_g, inc_b;
    rca #(DATA_WIDTH) rcR (.a(offset_in[3*DATA_WIDTH-1:2*DATA_WIDTH]), .b({{(DATA_WIDTH-1){1'b0}}, 1'b1}), .cin(1'b0), .sum(inc_r), .cout());
    rca #(DATA_WIDTH) rcG (.a(offset_in[2*DATA_WIDTH-1:DATA_WIDTH]),   .b({{(DATA_WIDTH-1){1'b0}}, 1'b1}), .cin(1'b0), .sum(inc_g), .cout());
    rca #(DATA_WIDTH) rcB (.a(offset_in[DATA_WIDTH-1:0]),             .b({{(DATA_WIDTH-1){1'b0}}, 1'b1}), .cin(1'b0), .sum(inc_b), .cout());

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            data_out <= 0;
            offset_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    data_out <= data_in;
                    offset_out <= {inc_r, inc_g, inc_b};
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


module blc_c_2 #(parameter DATA_WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*DATA_WIDTH-1:0] offset_in,
    input wire [3*DATA_WIDTH-1:0] data_in,
    input wire [3*DATA_WIDTH-1:0] aux_in,
    output reg [3*DATA_WIDTH-1:0] data_out,
    output reg [3*DATA_WIDTH-1:0] aux_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire [DATA_WIDTH-1:0] sum_r, sum_g, sum_b;
    rca #(DATA_WIDTH) rcR (.a(offset_in[3*DATA_WIDTH-1:2*DATA_WIDTH]), .b(data_in[3*DATA_WIDTH-1:2*DATA_WIDTH]), .cin(1'b0), .sum(sum_r), .cout());
    rca #(DATA_WIDTH) rcG (.a(offset_in[2*DATA_WIDTH-1:DATA_WIDTH]),   .b(data_in[2*DATA_WIDTH-1:DATA_WIDTH]),   .cin(1'b0), .sum(sum_g), .cout());
    rca #(DATA_WIDTH) rcB (.a(offset_in[DATA_WIDTH-1:0]),              .b(data_in[DATA_WIDTH-1:0]),              .cin(1'b0), .sum(sum_b), .cout());

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            data_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    data_out <= {sum_r, sum_g, sum_b};
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


module blc_c_3 #(parameter DATA_WIDTH = 12)(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [3*DATA_WIDTH-1:0] data_in,
    input wire [3*DATA_WIDTH-1:0] aux_in,
    output reg [3*DATA_WIDTH-1:0] data_out,
    output reg [3*DATA_WIDTH-1:0] aux_out,
    output reg i_i_ready,
    output reg i_r_ready
);
    wire insert = u_i_ready && i_i_ready;

    wire eq_r, eq_g, eq_b;
    comparator cmpR (.a(data_in[3*DATA_WIDTH-1]), .b(1'b0), .eq(eq_r));
    comparator cmpG (.a(data_in[2*DATA_WIDTH-1]), .b(1'b0), .eq(eq_g));
    comparator cmpB (.a(data_in[DATA_WIDTH-1]),   .b(1'b0), .eq(eq_b));

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1;
            i_r_ready <= 0;
            data_out <= 0;
            aux_out <= 0;
        end else begin
            case (insert)
                `INSERT: begin
                    data_out <= {eq_r ? data_in[3*DATA_WIDTH-1:2*DATA_WIDTH] : 0,
                                 eq_g ? data_in[2*DATA_WIDTH-1:DATA_WIDTH]   : 0,
                                 eq_b ? data_in[DATA_WIDTH-1:0]              : 0};
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