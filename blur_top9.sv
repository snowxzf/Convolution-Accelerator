//connects all modules together
//tracks row and column
//decides when ouput is valid 

module blur_top9(
    input  logic clk, reset,
    input  logic pixel_valid,
    input  logic [7:0] pixel_in,

    output logic pixel_out_valid,
    output logic [7:0] pixel_out
);

logic [6:0] col;
logic [7:0] row_m1_pixel, row_m2_pixel;

logic window_valid;
logic [7:0] w00, w01, w02,
            w10, w11, w12,
            w20, w21, w22;

logic sum_valid;
logic [14:0] sum;

// column counter
logic new_row;
logic wrapped;                // held-high marker that the column counter just wrapped
localparam int WIDTH = 128;   // must be wide enough to hold 128 (a 7-bit reg truncates it to 0)

always_ff @(posedge clk) begin
    if (reset) begin
        col     <= 0;
        wrapped <= 0;
    end
    else if (pixel_valid) begin
        if (col == WIDTH-1) begin
            col     <= 0;
            wrapped <= 1;
        end else begin
            col     <= col + 1;
            wrapped <= 0;
        end
    end
    // wrapped is deliberately NOT cleared while pixel_valid is low (kept for
    // parity with the single-MAC top; harmless for the streaming 9-MAC case)
end

// the first pixel of a new row is the one fed right after a column wrap
assign new_row = pixel_valid && wrapped;

line_buffer LB (
    .clk(clk),
    .reset(reset),
    .pixel_valid(pixel_valid),
    .pixel_in(pixel_in),
    .col(col),
    .row_m1_pixel(row_m1_pixel),
    .row_m2_pixel(row_m2_pixel)
);

window WINDOW (
    .clk(clk),
    .reset(reset),
    .pixel_valid(pixel_valid),
    .new_row(new_row),  
    .row_m1_pixel(row_m1_pixel),
    .row_m2_pixel(row_m2_pixel),
    .pixel_in(pixel_in),
    .window_valid(window_valid),
    .w00(w00), .w01(w01), .w02(w02),
    .w10(w10), .w11(w11), .w12(w12),
    .w20(w20), .w21(w21), .w22(w22)
);

convolution_9mac CONV (
    .clk(clk),
    .reset(reset),
    .window_valid(window_valid),

    .w00(w00), .w01(w01), .w02(w02),
    .w10(w10), .w11(w11), .w12(w12),
    .w20(w20), .w21(w21), .w22(w22),

    .sum_valid(sum_valid),
    .sum_out(sum)
);

normalizer NORM (
    .clk(clk),
    .valid_in(sum_valid),
    .sum_out(sum),
    .valid_out(pixel_out_valid),
    .pixel_out(pixel_out)
);

endmodule
