`timescale 1ns / 1ps

module fifo_chain_3stage_tb;

    // Parameters
    parameter DATA_WIDTH = 2;

    // Clock and Reset
    reg clock = 0;
    reg reset;

    // Clock Generation
    always #5 clock = ~clock;

    // Stage 1: External input to FIFO1
    reg  [DATA_WIDTH-1:0] top_data_in;
    reg                   top_valid_in;
    wire                  top_ready_out;

    // FIFO1 <-> FIFO2
    wire [DATA_WIDTH-1:0] mid1_data;
    wire                  mid1_valid;
    wire                  mid1_ready;

    // FIFO2 <-> FIFO3
    wire [DATA_WIDTH-1:0] mid2_data;
    wire                  mid2_valid;
    wire                  mid2_ready;

    // FIFO3 -> Final output
    wire [DATA_WIDTH-1:0] final_data;
    wire                  final_valid;
    wire                  final_ready;

    assign final_ready = 1'b1;  // Sink always ready to consume

    // FIFO 1
    fifo_shell #(.DATA_WIDTH(DATA_WIDTH)) fifo1 (
        .clock(clock),
        .reset(reset),
        .u_i_ready(top_valid_in),
        .u_r_ready(mid1_ready),
        .data_in(top_data_in),
        .data_out(mid1_data),
        .i_i_ready(top_ready_out),
        .i_r_ready(mid1_valid)
    );

    // FIFO 2
    fifo_shell #(.DATA_WIDTH(DATA_WIDTH)) fifo2 (
        .clock(clock),
        .reset(reset),
        .u_i_ready(mid1_valid),
        .u_r_ready(mid2_ready),
        .data_in(mid1_data),
        .data_out(mid2_data),
        .i_i_ready(mid1_ready),
        .i_r_ready(mid2_valid)
    );

    // FIFO 3
    fifo_shell #(.DATA_WIDTH(DATA_WIDTH)) fifo3 (
        .clock(clock),
        .reset(reset),
        .u_i_ready(mid2_valid),
        .u_r_ready(final_ready),
        .data_in(mid2_data),
        .data_out(final_data),
        .i_i_ready(mid2_ready),
        .i_r_ready(final_valid)
    );

    initial begin
        // Initialize
        reset = 1;
        top_valid_in = 0;
        top_data_in = 1'b0;

        // Hold reset for a few cycles
        #12;
        reset = 0;

        // Insert one value into FIFO1
        #10;
                top_data_in = 1'b1;
#5;
        top_valid_in = 1;

        #10;
        top_valid_in = 0;

        // Wait and observe the pipeline
        #100;

        $display("Final Output Data: %b", final_data);
        $display("Final Valid: %b", final_valid);

        $finish;
    end

endmodule
