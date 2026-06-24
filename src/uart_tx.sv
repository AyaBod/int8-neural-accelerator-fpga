module uart_tx #(
    parameter baud_rate = 9600,
    parameter clk_freq = 50000000
    //clks_per_bit = clk_freq / baud_rate = 50,000,000 / 9600 ≈ 5208
)(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [7:0] data_byte,
    output logic tx_line,
    output logic done

);

    //state encoding
    typedef enum logic [1:0] {
        IDLE = 2'd0,
        START = 2'd1,
        DATA = 2'd2,
        STOP = 2'd3
    } state_type;

    state_type state;
    state_type next_state;

    //counters to track clks and bits
    localparam int clks_per_bit = clk_freq / baud_rate;
    logic [2:0] bit_index; // bc theres 8 bits so 1000
    logic [$clog2(clks_per_bit)-1:0] ticks;

    always_ff @ (posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    //next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = START;
            START: if (ticks == clks_per_bit - 1) next_state = DATA; //one cycle here is clks_per_bit
            DATA: begin
                if (ticks == clks_per_bit - 1 && bit_index == 7) next_state = STOP;
                else next_state = DATA; // bit_index can only reset if ticks = clk_per_bit
            end
            STOP: if (ticks == clks_per_bit - 1) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    //counter logic
    always_ff @ (posedge clk) begin
        if (rst) begin
            ticks <= 0;
            bit_index <= 0;
        end else begin
            case (state)
                START: begin
                    if (ticks < clks_per_bit - 1) ticks <= ticks +1;
                    else ticks <= 0;
                end
                DATA: begin
                    if (ticks < clks_per_bit - 1) ticks <= ticks + 1;
                    else begin
                        ticks <= 0;
                        if (bit_index < 7) bit_index <= bit_index + 1;
                        else bit_index <= 0;
                    end
                end
                STOP: begin
                    if (ticks < clks_per_bit - 1) ticks <= ticks +1;
                    else ticks <= 0;
                end
                default: ticks <=0;
            endcase
        end
    end

    always_comb begin
        tx_line = 1'b1; //idle high
        done = 1'b0;
        case (state)
            IDLE: tx_line = 1'b1;
            START: tx_line = 1'b0;
            DATA: tx_line= data_byte[bit_index];
            STOP: begin
                tx_line = 1'b1;
                if (ticks == clks_per_bit - 1) done = 1'b1;
            end
        endcase
    end

endmodule;