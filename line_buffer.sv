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

    always_ff @(posedge clk) begin
        if (reset) begin
            row_sel <= 1'b0;
            row_m1_pixel <= 8'd0;
            row_m2_pixel <= 8'd0;

            for (i = 0; i < 128; i++) begin
                rowA[i] <= 8'd0;
                rowB[i] <= 8'd0;
            end
        end
        else if (pixel_valid) begin
            // output previous rows FIRST (read-before-write)
            if (row_sel == 1'b0) begin
                row_m1_pixel <= rowA[col]; // y-1
                row_m2_pixel <= rowB[col]; // y-2
                rowA[col]    <= pixel_in;  // write current row
            end
            else begin
                row_m1_pixel <= rowB[col];
                row_m2_pixel <= rowA[col];
                rowB[col]    <= pixel_in;
            end

            // end of row → swap roles
            if (col == 7'd127) begin
                row_sel <= ~row_sel;
            end
        end
    end

endmodule
