`timescale 1ns/1ps

// Testbench for the single-MAC (resource-shared) blur.
// Because blur_top needs ~11 cycles to process each window, this testbench
// feeds one pixel at a time and waits for that pixel's blurred output before
// presenting the next one (a simple ready/valid style handshake).

module tb_blur;

reg clk;
reg reset;
reg pixel_valid;
reg [7:0] pixel_in;
wire pixel_out_valid;
wire [7:0] pixel_out;
wire ready;

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
    .pixel_out(pixel_out),
    .ready(ready)
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

// Present exactly one pixel, then wait for its blurred result.
task feed(input [7:0] v);
begin
    @(posedge clk);
    pixel_in    = v;
    pixel_valid = 1;
    @(posedge clk);          // pixel sampled here: window shifts once
    pixel_valid = 0;
    @(posedge pixel_out_valid); // one output per input pixel
end
endtask

// Stimulus
initial begin
    infile  = $fopen("input_pixels.txt", "r");
    outfile = $fopen("output_pixels.txt", "w");

    if (infile == 0) begin
        $display("ERROR: could not open input_pixels.txt");
        $finish;
    end

    reset = 1;
    pixel_valid = 0;
    pixel_in = 0;
    repeat (5) @(posedge clk);
    reset = 0;
    @(posedge clk);

    // Feed pixels one at a time
    while (1) begin
        status = $fscanf(infile, "%d\n", temp);
        //1 if it read one integer, 0 if format mismatch, -1 if eof
        if (status != 1)
            break;
        feed(temp[7:0]);
    end

    repeat (50) @(posedge clk);

    $fclose(infile);
    $fclose(outfile);
    $stop; //instead of $finish since I don't want modelsim to close every time
end

endmodule
