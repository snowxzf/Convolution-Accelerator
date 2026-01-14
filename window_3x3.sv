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

logic [1:0]counter; //keep track of amount of times it was shifted 

always_ff @(posedge clk) begin 
    if (reset) begin 
        w00 <= 0; w01 <= 0; w02 <= 0;
        w10 <= 0; w11 <= 0; w12 <= 0;
        w20 <= 0; w21 <= 0; w22 <= 0;
        //reset window reset 
        window_valid <= 0; 
        counter <= 0;
    end 
    
    else if (new_row) begin
        counter <= 0;
        window_valid <= 0; //invalidate until theres 2 new columns
        //but don't reset data since then prev 2 columns are 0
    end 

    else if (pixel_valid) begin 
        //shift left
        w00 <= w01; 
        w10 <= w11; 
        w20 <= w21; 
        w01 <= w02; 
        w11 <= w12;
        w21 <= w22;

        //insert new rightmost column 
        w02 <= row_m2_pixel;
        w12 <= row_m1_pixel;
        w22 <= pixel_in; 
        //recieving the most bottom-right corner pixel

        //increment counter if less than 2 
        if (counter < 2) begin
            counter <= counter + 1;
        end 

    end
    //check if two columns have been shifted (no -> 0)
    //wants window to be valid for all cycles after 2 columns (sliding window)
    //done immediately (used >= 1 since it only updates after full clock, so its still old value of counter)
    //only valid when a new pixel is entering AND counter >= 1 meaning its a new, complete window 
    window_valid <= (pixel_valid && counter >= 1);
end 


endmodule 