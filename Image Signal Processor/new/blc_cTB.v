`timescale 1ns / 1ps

module blc_pipeline_tb;

    parameter DATA_WIDTH = 8;
    reg clock, reset;

    reg u_i_ready_0, u_r_ready_0;
    reg [DATA_WIDTH-1:0] data_in, offset_in;

    wire [DATA_WIDTH-1:0] offset_0_out, offset_1_out, data_2_out, data_3_out;
    wire [DATA_WIDTH-1:0] data_0_out, data_1_out;
    wire i_i_ready_0, i_r_ready_0, i_i_ready_1, i_r_ready_1;
    wire i_i_ready_2, i_r_ready_2, i_i_ready_3, i_r_ready_3;

    // Clock generation
    initial clock = 0;
    always #5 clock = ~clock;

    // DUT: Chain the modules
    blc_c_0 #(.DATA_WIDTH(DATA_WIDTH)) stage0 (
        .clock(clock),
        .reset(reset),
        .u_i_ready(u_i_ready_0),
        .u_r_ready(i_i_ready_1),
        .offset_in(offset_in),
        .data_in(data_in),
        .offset_out(offset_0_out),
        .data_out(data_0_out),
        .i_i_ready(i_i_ready_0),
        .i_r_ready(i_r_ready_0)
    );

    blc_c_1 #(.DATA_WIDTH(DATA_WIDTH)) stage1 (
        .clock(clock),
        .reset(reset),
        .u_i_ready(i_r_ready_0),
        .u_r_ready(i_i_ready_2),
        .offset_in(offset_0_out),
        .data_in(data_0_out),
        .offset_out(offset_1_out),
        .data_out(data_1_out),
        .i_i_ready(i_i_ready_1),
        .i_r_ready(i_r_ready_1)
    );

    blc_c_2 #(.DATA_WIDTH(DATA_WIDTH)) stage2 (
        .clock(clock),
        .reset(reset),
        .u_i_ready(i_r_ready_1),
        .u_r_ready(i_i_ready_3),
        .offset_in(offset_1_out),
        .data_in(data_1_out),
        .data_out(data_2_out),
        .i_i_ready(i_i_ready_2),
        .i_r_ready(i_r_ready_2)
    );

    blc_c_3 #(.DATA_WIDTH(DATA_WIDTH)) stage3 (
        .clock(clock),
        .reset(reset),
        .u_i_ready(i_r_ready_2),
        .u_r_ready(1'b1), // Sink is always ready
        .data_in(data_2_out),
        .data_out(data_3_out),
        .i_i_ready(i_i_ready_3),
        .i_r_ready(i_r_ready_3)
    );

    // Stimulus
    initial begin
        $display("Starting BLC Pipeline Testbench...");
        reset = 1;
        u_i_ready_0 = 0;
        data_in = 8'h00;
        offset_in = 8'h00;

        #20;
        reset = 0;

        // Set input
        @(posedge clock);
        data_in = 8'h09;       // Example pixel data
        offset_in = 8'h0A;     // Offset to subtract
        
        #5;
        u_i_ready_0 = 1;

        @(posedge clock);
        u_i_ready_0 = 0;       // Remove input after a cycle

        // Wait for pipeline to propagate
        repeat (20) @(posedge clock);

        $display("Final Output: %h", data_3_out);
        $finish;
    end

endmodule
