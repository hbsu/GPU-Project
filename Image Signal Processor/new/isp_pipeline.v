// top_isp_pipeline.v

`timescale 1ns / 1ps
`define INSERT 1'b1
`define REMOVE 1'b0

module top_isp_pipeline(
    input wire clock,
    input wire reset,
    input wire u_i_ready,
    input wire u_r_ready,
    input wire [71:0] input_pixel,
    input wire [35:0] offset_in,
    input wire [35:0] gain_in,
    output wire [71:0] final_output,
    output wire i_i_ready,
    output wire i_r_ready
);

    // Internal wires for BLC
    wire [35:0] blc_offset_mid, blc_data_mid, blc_aux_mid;
    wire [35:0] blc_data_out, blc_aux_out;

    // Internal wires for LSC
    wire [71:0] lsc_product_mid;
    wire [71:0] lsc_rounded_mid;
    wire [35:0] lsc_scaled_out;

    // Internal wires for DMSC
    wire [71:0] dmsc_0_out, dmsc_1_out, dmsc_11_out;
    wire [11:0] dmsc_x, dmsc_y;
    wire [1:0] dmsc_pix_type;
    wire [647:0] dmsc_line_buf_out;
    wire [647:0] dmsc_window_out;
    wire [71:0] dmsc_center, dmsc_n0, dmsc_n1, dmsc_n2, dmsc_n3, dmsc_n4, dmsc_n5, dmsc_n6, dmsc_n7;
    wire [71:0] dmsc_interp_g, dmsc_interp_rgb, dmsc_blended_rgb, dmsc_final_rgb, dmsc_denoised_rgb, dmsc_corrected_rgb;

    // Internal wires for CCM
    wire [35:0] ccm_rgb, ccm_aux_0, ccm_aux_1, ccm_aux_2, ccm_aux_3, ccm_aux_4, ccm_aux_5;
    wire [107:0] ccm_products;
    wire [35:0] ccm_partial_out_2, ccm_scaled_out_3, ccm_clamped_4;

    // Internal wires for GAMMA
    wire [71:0] gamma_stage0_out;
    wire [23:0] gamma_rgb8;
    wire [35:0] gamma_aux_0, gamma_aux_1, gamma_corrected;

    // Instantiate BLC Pipeline
    blc_c_0 blc0(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .offset_in(offset_in), .data_in(input_pixel[71:36]), .aux_in(input_pixel[35:0]), .offset_out(blc_offset_mid), .data_out(blc_data_mid), .aux_out(blc_aux_mid), .i_i_ready(), .i_r_ready());
    blc_c_1 blc1(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .offset_in(blc_offset_mid), .data_in(blc_data_mid), .aux_in(blc_aux_mid), .offset_out(), .data_out(blc_data_out), .aux_out(blc_aux_out), .i_i_ready(), .i_r_ready());
    blc_c_2 blc2(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .offset_in(blc_offset_mid), .data_in(blc_data_out), .aux_in(blc_aux_out), .data_out(lsc_scaled_out), .aux_out(), .i_i_ready(), .i_r_ready());

    // Instantiate LSC Pipeline
    lsc_c_0 lsc0(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .data_in(lsc_scaled_out), .gain_in(gain_in), .product_out(lsc_product_mid), .i_i_ready(), .i_r_ready());
    lsc_c_1 lsc1(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .product_in(lsc_product_mid), .rounded_out(lsc_rounded_mid), .i_i_ready(), .i_r_ready());
    lsc_c_2 lsc2(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .rounded_in(lsc_rounded_mid), .scaled_out(lsc_scaled_out), .i_i_ready(), .i_r_ready());
    lsc_c_3 lsc3(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .scaled_in(lsc_scaled_out), .data_out(dmsc_0_out), .i_i_ready(), .i_r_ready());

    // Instantiate DMSC Pipeline
    dmsc_c_0 dmsc0(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .data_in(dmsc_0_out), .data_out(dmsc_1_out), .x_out(dmsc_x), .y_out(dmsc_y), .i_i_ready(), .i_r_ready());
    dmsc_c_1 dmsc1(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .data_in(dmsc_1_out), .x_in(dmsc_x), .y_in(dmsc_y), .data_out(dmsc_1_out), .pixel_type_out(dmsc_pix_type), .i_i_ready(), .i_r_ready());
    dmsc_c_2 dmsc2(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .data_in(dmsc_1_out), .line_buffer_out(dmsc_line_buf_out), .i_i_ready(), .i_r_ready());
    dmsc_c_3 dmsc3(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .r0(dmsc_line_buf_out[647:432]), .r1(dmsc_line_buf_out[431:216]), .r2(dmsc_line_buf_out[215:0]), .window_out(dmsc_window_out), .i_i_ready(), .i_r_ready());
    dmsc_c_4 dmsc4(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .window_in(dmsc_window_out), .center(dmsc_center), .n0(dmsc_n0), .n1(dmsc_n1), .n2(dmsc_n2), .n3(dmsc_n3), .n4(dmsc_n4), .n5(dmsc_n5), .n6(dmsc_n6), .n7(dmsc_n7), .i_i_ready(), .i_r_ready());
    dmsc_c_5 dmsc5(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .center(dmsc_center), .n0(dmsc_n0), .n1(dmsc_n1), .n2(dmsc_n2), .n3(dmsc_n3), .n4(dmsc_n4), .n5(dmsc_n5), .n6(dmsc_n6), .n7(dmsc_n7), .interpolated_g(dmsc_interp_g), .i_i_ready(), .i_r_ready());
    dmsc_c_6 dmsc6(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .interpolated_g(dmsc_interp_g), .interpolated_rgb(dmsc_interp_rgb), .i_i_ready(), .i_r_ready());
    dmsc_c_7 dmsc7(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .interpolated_rgb(dmsc_interp_rgb), .blended_rgb(dmsc_blended_rgb), .i_i_ready(), .i_r_ready());
    dmsc_c_8 dmsc8(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .blended_rgb(dmsc_blended_rgb), .final_rgb(dmsc_final_rgb), .i_i_ready(), .i_r_ready());
    dmsc_c_9 dmsc9(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .final_rgb(dmsc_final_rgb), .denoised_rgb(dmsc_denoised_rgb), .i_i_ready(), .i_r_ready());
    dmsc_c_10 dmsc10(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .denoised_rgb(dmsc_denoised_rgb), .corrected_rgb(dmsc_corrected_rgb), .i_i_ready(), .i_r_ready());

    // CCM + GAMMA
    ccm_c_0 ccm0(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .data_in(dmsc_corrected_rgb), .rgb_out(ccm_rgb), .aux_out(ccm_aux_0), .i_i_ready(), .i_r_ready());
    ccm_c_1 ccm1(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .rgb_in(ccm_rgb), .aux_in(ccm_aux_0), .a11(12'd256), .a12(12'd0), .a13(12'd0), .a21(12'd0), .a22(12'd256), .a23(12'd0), .a31(12'd0), .a32(12'd0), .a33(12'd256), .partial_products_out(ccm_products), .aux_out(ccm_aux_1), .i_i_ready(), .i_r_ready());
    ccm_c_2 ccm2(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .partials_in(ccm_products), .aux_in(ccm_aux_1), .result_out(ccm_partial_out_2), .aux_out(ccm_aux_2), .i_i_ready(), .i_r_ready());
    ccm_c_3 ccm3(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .result_in(ccm_partial_out_2), .aux_in(ccm_aux_2), .scaled_out(ccm_scaled_out_3), .aux_out(ccm_aux_3), .i_i_ready(), .i_r_ready());
    ccm_c_4 ccm4(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .scaled_in(ccm_scaled_out_3), .aux_in(ccm_aux_3), .clamped_out(ccm_clamped_4), .aux_out(ccm_aux_4), .i_i_ready(), .i_r_ready());
    ccm_c_5 ccm5(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .clamped_in(ccm_clamped_4), .aux_in(ccm_aux_4), .data_out(gamma_stage0_out), .i_i_ready(), .i_r_ready());

    gamma_c_0 gamma0(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .data_in(gamma_stage0_out), .rgb8_out(gamma_rgb8), .aux_out(gamma_aux_0), .i_i_ready(), .i_r_ready());
    gamma_c_1 gamma1(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .rgb8_in(gamma_rgb8), .aux_in(gamma_aux_0), .gamma_out(gamma_corrected), .aux_out(gamma_aux_1), .i_i_ready(), .i_r_ready());
    gamma_c_2 gamma2(.clock(clock), .reset(reset), .u_i_ready(u_i_ready), .u_r_ready(u_r_ready), .gamma_rgb_in(gamma_corrected), .aux_in(gamma_aux_1), .data_out(final_output), .i_i_ready(i_i_ready), .i_r_ready(i_r_ready));

endmodule
