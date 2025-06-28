`define INSERT 1'b1
`define REMOVE 1'b0

module fifo_shell #(
    parameter DATA_WIDTH = 1,
    parameter FIFO_DEPTH = 1
)(
    input wire clock,
    input wire reset,
    input wire u_i_ready, // is top module ready to give info
    input wire u_r_ready, // is bottom module ready to receive info
    input wire [DATA_WIDTH - 1 : 0] data_in,
    output reg [DATA_WIDTH - 1 : 0] data_out,
    output reg i_i_ready, // I am ready to receive info
    output reg i_r_ready  // I am ready to give info
);

    reg [DATA_WIDTH - 1 : 0] payload_data_process;
    reg full, empty; // flags for full or empty
    wire insert;

    assign insert = u_i_ready && i_i_ready;

    // Adder instance
    wire [DATA_WIDTH - 1 : 0] adder_out;
    adder #(.WIDTH(DATA_WIDTH)) a1 (
        .a(data_in),
        .b({{(DATA_WIDTH-1){1'b0}}, 1'b1}), // adding 1
        .c(adder_out)
    );

    always @(posedge clock) begin
        if (reset) begin
            i_i_ready <= 1'b1;
            i_r_ready <= 1'b0;
            data_out <= {DATA_WIDTH{1'b0}};
            payload_data_process <= {DATA_WIDTH{1'b0}};
        end else begin
            case (insert)
                `INSERT: begin
                    payload_data_process <= adder_out;
                    data_out <= adder_out;
                    i_i_ready <= 1'b0;
                    i_r_ready <= 1'b1;
                end
                `REMOVE: begin
                    i_i_ready <= 1'b1;
                    i_r_ready <= 1'b0;
                end
            endcase
        end
    end

endmodule

module adder #(
    parameter WIDTH = 1
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [WIDTH-1:0] c
);
    assign c = a + b;
endmodule

