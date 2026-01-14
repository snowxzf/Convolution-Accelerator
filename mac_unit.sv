module mac_unit (
    input logic clk, reset, enable,
    input logic [7:0]a, b, 
    output logic [15:0] acc
    );

logic [15:0] product; 

assign product = a*b; 

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        acc <= 0;
    end 
    else if (enable) begin
       acc <= acc + product;
    end
end

endmodule 

