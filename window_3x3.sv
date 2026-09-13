//keeps shift registers, shifts pixels left each cycle
//insert newest column pixel on right
//forms a full 3x3 window

//line buffer only gives 1 column
//window is used to keep last 3 columns + output 9 pixels 

module window (
    input logic clk, 
    input logic reset, 
    input logic pixel_valid, 
    input logic new_row,

    input logic [7:0] row_m1_pixel, 
    input logic [7:0] row_m2_pixel, 
    input logic [7:0] pixel_in, 

    output logic window_valid, //only high after at least 2 rows exist, 2 columns have been shifted in 
    output logic [7:0] w00, w01, w02,
    output logic [7:0] w10, w11, w12,
    output logic [7:0] w20, w21, w22
); 

// The window slides one column per accepted pixel. At the start of a new row
// the two left-hand columns are off-image, so they must be forced to 0 (a
// zero-padded left border) instead of keeping the previous row's rightmost
// pixels. Emitting window_valid for every pixel gives exactly one output per
// input pixel, i.e. a full 128x128 output frame.

always_ff @(posedge clk) begin
    if (reset) begin
        w00 <= 0; w01 <= 0; w02 <= 0;
        w10 <= 0; w11 <= 0; w12 <= 0;
        w20 <= 0; w21 <= 0; w22 <= 0;
        window_valid <= 0;
    end
    else if (pixel_valid) begin
        if (new_row) begin
            // first pixel of a new row: left two columns are off-image -> 0,
            // only the new rightmost column carries real data
            w00 <= 0;            w01 <= 0;            w02 <= row_m2_pixel;
            w10 <= 0;            w11 <= 0;            w12 <= row_m1_pixel;
            w20 <= 0;            w21 <= 0;            w22 <= pixel_in;
        end
        else begin
            // shift left, insert new rightmost column
            w00 <= w01; w01 <= w02; w02 <= row_m2_pixel;
            w10 <= w11; w11 <= w12; w12 <= row_m1_pixel;
            w20 <= w21; w21 <= w22; w22 <= pixel_in;
        end
        // bottom-right-anchored window: every pixel produces one output,
        // with zero padding along the top and left image edges
        window_valid <= 1;
    end
    else begin
        window_valid <= 0;
    end
end


endmodule 