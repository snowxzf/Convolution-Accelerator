// Resource-shared convolution: ONE multiply-accumulate unit reused 9 times.
//
// A single MAC can do one multiply-add per clock, but a 3x3 convolution needs
// nine, so this block cannot accept a new pixel every cycle the way the 9-MAC
// version can. Instead it exposes a `ready` handshake: it latches the 3x3
// window when it starts, spends 9 cycles accumulating w00..w22 (weight = 1 for
// a box blur), emits the sum, and only then raises `ready` again. The top level
// feeds the next pixel when `ready` is high, so the window is stable throughout.

module convolution_onemac (
    input  logic        clk, reset,
    input  logic        window_valid,
    input  logic [7:0]  w00, w01, w02,
    input  logic [7:0]  w10, w11, w12,
    input  logic [7:0]  w20, w21, w22,

    output logic        sum_valid,
    output logic [14:0] sum_out,
    output logic        ready       // high when a new window can be accepted
);

    typedef enum logic [1:0] {IDLE, ACC, DONE} state_t;
    state_t state;

    logic [3:0] cnt;          // which of the 9 taps we are on (0..8)
    logic [7:0] win [0:8];    // latched copy of the window

    // one shared MAC (b = 1 -> pure accumulate for a box blur)
    logic        mac_en, mac_rst;
    logic [7:0]  mac_a;
    logic [15:0] mac_acc;

    mac_unit mac_1 (
        .clk    (clk),
        .reset  (mac_rst),
        .enable (mac_en),
        .a      (mac_a),
        .b      (8'd1),
        .acc    (mac_acc)
    );

    // drive the MAC controls combinationally so there is no 1-cycle skew
    assign mac_a   = win[cnt];
    assign mac_en  = (state == ACC);
    assign mac_rst = (state == IDLE);   // keep the accumulator cleared while idle
    assign ready   = (state == IDLE);

    always_ff @(posedge clk) begin
        if (reset) begin
            state     <= IDLE;
            cnt       <= 0;
            sum_out   <= 0;
            sum_valid <= 0;
        end
        else begin
            sum_valid <= 0;                 // default: pulse for one cycle only

            case (state)
                IDLE: begin
                    cnt <= 0;
                    if (window_valid) begin // latch the window and start
                        win[0] <= w00; win[1] <= w01; win[2] <= w02;
                        win[3] <= w10; win[4] <= w11; win[5] <= w12;
                        win[6] <= w20; win[7] <= w21; win[8] <= w22;
                        state  <= ACC;
                    end
                end

                ACC: begin                  // mac_en is high here; acc += win[cnt]
                    if (cnt == 8) state <= DONE;
                    cnt <= cnt + 1;
                end

                DONE: begin                 // acc now holds all 9 taps
                    sum_out   <= mac_acc[14:0];
                    sum_valid <= 1;
                    state     <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
