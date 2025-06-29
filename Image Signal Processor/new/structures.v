module multiplier #(parameter WIDTH = 12)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    output wire [2*WIDTH-1:0] product
);
    assign product = a * b;
endmodule

module right_shifter #(parameter IN_WIDTH = 24, parameter SHIFT = 8)(
    input  wire [IN_WIDTH-1:0] in,
    output wire [IN_WIDTH-SHIFT-1:0] out
);
    assign out = in >> SHIFT;
endmodule



module inverter #(parameter BITWIDTH = 8)(
    input  wire [BITWIDTH-1:0] in,
    output wire [BITWIDTH-1:0] out
);

    genvar i;
    generate
        for (i = 0; i < BITWIDTH; i = i + 1) begin : invert_bits
            not u_not(out[i], in[i]);
        end
    endgenerate

endmodule

module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);
    wire w1, w2, w3;

    xor x1(w1, a, b);
    xor x2(sum, w1, cin);

    and a1(w2, a, b);
    and a2(w3, w1, cin);
    or  o1(cout, w2, w3);
endmodule

module rca #(parameter BITWIDTH = 8)(
    input  wire [BITWIDTH-1:0] a,
    input  wire [BITWIDTH-1:0] b,
    input  wire                cin,
    output wire [BITWIDTH-1:0] sum,
    output wire                cout
);

    wire [BITWIDTH:0] carry;
    assign carry[0] = cin;

    genvar i;
    generate
        for (i = 0; i < BITWIDTH; i = i + 1) begin : adder_stage
            full_adder fa (
                .a    (a[i]),
                .b    (b[i]),
                .cin  (carry[i]),
                .sum  (sum[i]),
                .cout (carry[i+1])
            );
        end
    endgenerate

    assign cout = carry[BITWIDTH];
endmodule

module comparator (
    input  wire a,
    input  wire b,
    output wire eq
);
    wire w1;

    xor x1(w1, a, b);
    not n1(eq, w1);
endmodule


module clamp #(
    parameter WIDTH = 12,
    parameter MIN   = 0,
    parameter MAX   = 4095
)(
    input  wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);

    assign out = (in < MIN) ? MIN :
                 (in > MAX) ? MAX :
                 in;

endmodule

