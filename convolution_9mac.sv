module convolution_9mac (
    input logic clk, reset,
    input logic window_valid, 
    input logic [7:0] w00, w01, w02,
    input logic [7:0] w10, w11, w12,
    input logic [7:0] w20, w21, w22, 

    output logic sum_valid, 
    output logic [14:0] sum_out
); 

logic [7:0] k = 1; //can change to other varying values k00, k01, etc. later 
logic [15:0] p00, p01, p02;
logic [15:0] p10, p11, p12;
logic [15:0] p20, p21, p22;

logic [16:0] s0, s1, s2;
logic [18:0] s3;

always_comb begin 
    p00 = w00 * k; 
    p01 = w01 * k; 
    p02 = w02 * k; 
    p10 = w10 * k; 
    p11 = w11 * k; 
    p12 = w12 * k; 
    p20 = w20 * k; 
    p21 = w21 * k; 
    p22 = w22 * k; 
end 

always_comb begin 
    s0 = p00 + p01 + p02;
    s1 = p10 + p11 + p12;
    s2 = p20 + p21 + p22;
    s3 = s0 + s1 + s2;
end 

always_ff @(posedge clk) begin 
    if (reset) begin 
        sum_out <= 0; 
        sum_valid <=0; 
    end else begin 
        sum_valid <= window_valid;
        if (window_valid) begin 
            sum_out <= s3; 
        end
    end
end 

endmodule