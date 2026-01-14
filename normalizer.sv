//division/scaling
//divide sum by 9, clamp to 8 bits 

//shrink output from convolution into 8 bits 

module normalizer (
    input  logic        clk,
    input  logic        valid_in,
    input  logic [14:0] sum_out,
    output logic        valid_out,
    output logic [7:0]  pixel_out
);

always_ff @(posedge clk) begin
    valid_out <= valid_in;
    pixel_out <= sum_out / 9;
end

endmodule
