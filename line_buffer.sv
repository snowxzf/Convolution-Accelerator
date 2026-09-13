// remembers the last two rows (y-1, y-2)
// outputs the pixel at the current column for those rows

module line_buffer (
    input  logic        clk,
    input  logic        reset,
    input  logic        pixel_valid,
    input  logic [7:0]  pixel_in,
    input  logic [6:0]  col,

    output logic [7:0]  row_m1_pixel, // row y-1
    output logic [7:0]  row_m2_pixel  // row y-2
);

    // two physical line buffers
    logic [7:0] rowA [0:127];
    logic [7:0] rowB [0:127];

    // which row is currently being written (row y)
    logic row_sel; 
    // row_sel = 0 → write rowA, read rowB as y-1
    // row_sel = 1 → write rowB, read rowA as y-1

    integer i;

    // combinational read of the two history rows at the current column, so the
    // outputs line up with the (un-delayed) current pixel_in in the window.
    // read-before-write is preserved because the array write below only takes
    // effect on the next clock edge.
    always_comb begin
        if (row_sel == 1'b0) begin
            row_m1_pixel = rowA[col]; // y-1
            row_m2_pixel = rowB[col]; // y-2
        end
        else begin
            row_m1_pixel = rowB[col];
            row_m2_pixel = rowA[col];
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            row_sel <= 1'b0;

            for (i = 0; i < 128; i++) begin
                rowA[i] <= 8'd0;
                rowB[i] <= 8'd0;
            end
        end
        else if (pixel_valid) begin
            // write current row (read-before-write vs the combinational read above)
            if (row_sel == 1'b0)
                rowA[col] <= pixel_in;
            else
                rowB[col] <= pixel_in;

            // end of row → swap roles
            if (col == 7'd127) begin
                row_sel <= ~row_sel;
            end
        end
    end

endmodule
