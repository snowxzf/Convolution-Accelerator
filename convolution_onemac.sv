//perform convolution 
//turn 3x3 window and turn onto output pixel 
//using one mac 

module convolution_onemac (
    input logic clk, reset,
    input logic window_valid, 
    input logic [7:0] w00, w01, w02,
    input logic [7:0] w10, w11, w12,
    input logic [7:0] w20, w21, w22, 

    output logic sum_valid, 
    output logic [14:0] sum_out
); 

//define states
//typedef enum [2:0] {IDLE, MAC, OUTPUT} statetype; 
typedef enum {IDLE=0, MAC=1, OUTPUT=2} statetype; //for modelsim running
statetype state; 

//counter for number of times mac was repeated 
logic [3:0] counter; 

//instantiate MAC 
logic mac_enable;
logic mac_reset;
logic signed [7:0] mac_a, mac_b;
logic signed [14:0] mac_acc;

mac_unit mac_1 (
    .clk    (clk),
    .reset  (mac_reset),
    .enable (mac_enable),
    .a      (mac_a),
    .b      (mac_b),
    .acc    (mac_acc)
);

//setting input values 
always_comb begin 
    case (counter) 
        0: mac_a = w00;
        1: mac_a = w01;
        2: mac_a = w02;
        3: mac_a = w10;
        4: mac_a = w11;
        5: mac_a = w12;
        6: mac_a = w20;
        7: mac_a = w21;
        8: mac_a = w22;
        default: mac_a = 0;
    endcase 
    mac_b = 1; //equal weight to blur 
end 

//fsm - single process fsm since its small 
//doesn't affect case since <= means it updates simultaneously at clk edge after block finishes 
//dones't affect current execution 

always_ff @(posedge clk) begin 
    if (reset) begin 
        state <= IDLE; 
        counter <= 0;
        sum_out <= 0; 
        sum_valid <= 0; 
    end 

    else begin
        mac_enable <= 0; //default, set to 1 when using mac
        mac_reset <= 0; 
        sum_valid <= 0; 

        case(state)
            IDLE: begin 
                mac_reset <= 1; 
                counter <= 0; 
                if (window_valid) state <= MAC; 
            end 

            MAC: begin 
                mac_enable <= 1; 
                if (counter <8) begin 
                    counter <= counter + 1; 
                    state <= MAC; //to be safe 
                end 
                else begin 
                    state <= OUTPUT;
                    counter <= 0; 
                end
            end 

            OUTPUT: begin 
                sum_out <= mac_acc[14:0];
                sum_valid <= 1; 
                if (window_valid) begin 
                    mac_reset <= 1; 
                    counter <= 0; 
                    state <= MAC; //start next convolution immediately so its every 10 instead of 11 cycles 
                end 
                else begin 
                    state <= IDLE;
                end
            end  
        endcase 
    end
end 

endmodule