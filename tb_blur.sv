`timescale 1ns/1ps

module tb_blur;

reg clk;
reg reset;
reg pixel_valid;
reg [7:0] pixel_in;
wire pixel_out_valid;
wire [7:0] pixel_out;

integer infile;
integer outfile;
integer status;
reg [31:0] temp;

// Instantiate DUT
blur_top DUT (
    .clk(clk),
    .reset(reset),
    .pixel_valid(pixel_valid),
    .pixel_in(pixel_in),
    .pixel_out_valid(pixel_out_valid),
    .pixel_out(pixel_out)
);

// Clock
initial clk = 0;
always #5 clk = ~clk;

// Capture outputs
always @(posedge clk) begin
    if (pixel_out_valid) begin
        $fwrite(outfile, "%d\n", pixel_out);
    end
end

// Stimulus
initial begin
    infile  = $fopen("input_pixels.txt", "r");
    outfile = $fopen("output_pixels.txt", "w");

    if (infile == 0) begin
        $display("ERROR: could not open input_pixels.txt");
        $finish;
    end

    //allow + make sure one pixel per cycle (timing analysis)
    reset = 1;
    pixel_valid = 0;
    pixel_in = 0;
    repeat (5) @(posedge clk);
    reset = 0;

    // Feed pixels
    pixel_valid = 1;
    while (pixel_valid) begin
        status = $fscanf(infile, "%d\n", temp);
        //1 if it read one integer, 0 if format mismatch, -1 if eof 
        if (status != 1)
            break;
        pixel_in = temp[7:0];
        @(posedge clk);
    end
   
    pixel_valid = 0;
    pixel_in = 0;

    repeat (4000) @(posedge clk);

    $fclose(infile);
    $fclose(outfile);
    $stop; //instead of $finish since I don't want modelsim to close every time 
end

endmodule