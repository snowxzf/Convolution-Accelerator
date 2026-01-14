//connects all modules together
//tracks row and column
//decides when ouput is valid 

module blur_top(
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
logic [6:0] WIDTH;
assign WIDTH = 128; 

always_ff @(posedge clk) begin
    if (reset) begin
        col <= 0;
        new_row <= 0;
    end 

    else if (pixel_valid) begin 
        if (col == WIDTH-1) begin 
            col <= 0; 
            new_row <= 1;
        end else begin 
            col <= col + 1;
            new_row <= 0; 
        end 
    end else begin 
        new_row <= 0; 
    end
end

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
    .new_row(new_row),   // ← ADD THIS
    .row_m1_pixel(row_m1_pixel),
    .row_m2_pixel(row_m2_pixel),
    .pixel_in(pixel_in),
    .window_valid(window_valid),
    .w00(w00), .w01(w01), .w02(w02),
    .w10(w10), .w11(w11), .w12(w12),
    .w20(w20), .w21(w21), .w22(w22)
);

convolution_onemac CONV (
    .clk(clk),
    .reset(reset),
    .window_valid(window_valid),
    .w00(w00), .w01(w01), .w02(w02),
    .w10(w10), .w11(w11), .w12(w12),
    .w20(w20), .w21(w21), .w22(w22),
    .sum_valid(sum_valid),
    .sum_out(sum_out)
);

normalizer NORM (
    .clk(clk),
    .valid_in(sum_valid),
    .sum_out(sum),
    .valid_out(pixel_out_valid),
    .pixel_out(pixel_out)
);

endmodule
