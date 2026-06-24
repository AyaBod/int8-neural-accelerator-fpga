module uart_rx #(
    parameter int baud_rate = 9600,
    parameter int clk_freq  = 50000000
)(
    input  logic clk,
    input  logic rst,
    input  logic rx_line,
    output logic [7:0] data_byte,
    output logic done
);

    localparam int clks_per_bit = clk_freq / baud_rate;
    localparam int ticks_per_bit = 16;
    localparam int clks_per_tick = clks_per_bit / ticks_per_bit;

    typedef enum logic [1:0] {
        IDLE  = 2'd0,
        START = 2'd1,
        DATA  = 2'd2,
        STOP  = 2'd3
    } state_type;

    state_type state, next_state;

    logic [$clog2(clks_per_tick)-1:0] clk_count;  //counts clk cycles within one tick
    logic [3:0] tick_count; //counts ticks 0-15 within one bit
    logic [2:0] bit_index;
    logic [7:0] rx_shift_reg; //holds bits as they're received

    //ticks once every clks_per_tick clock cycles
    logic tick;
    always_ff @(posedge clk) begin
        if (rst || state == IDLE) begin
            clk_count <= 0;
            tick      <= 0;
        end else if (clk_count == clks_per_tick - 1) begin
            clk_count <= 0; //reset it
            tick      <= 1;
        end else begin
            clk_count <= clk_count + 1;
            tick      <= 0;
        end
    end


    always_ff @(posedge clk) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    //next state logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE:  if (rx_line == 1'b0) next_state = START;
            START: if (tick && tick_count == ticks_per_bit - 1) next_state = DATA; //personal cycle
            DATA: begin
                if (tick && tick_count == ticks_per_bit - 1 && bit_index == 7)
                    next_state = STOP;
                else
                    next_state = DATA;
            end
            STOP: if (tick && tick_count == ticks_per_bit - 1) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    //tick_count and bit_index counter logic
    always_ff @(posedge clk) begin
        if (rst) begin
            tick_count <= 0;
            bit_index  <= 0;
        end else begin
            case (state)
                START: begin
                    if (tick) begin
                        if (tick_count < ticks_per_bit - 1) tick_count <= tick_count + 1;
                        else tick_count <= 0;
                    end
                end
                DATA: begin
                    if (tick) begin
                        if (tick_count < ticks_per_bit - 1) begin
                            tick_count <= tick_count + 1;
                        end else begin
                            tick_count <= 0;
                            if (bit_index < 7) bit_index <= bit_index + 1;
                            else bit_index <= 0;
                        end
                    end
                end
                STOP: begin
                    if (tick) begin
                        if (tick_count < ticks_per_bit - 1) tick_count <= tick_count + 1;
                        else tick_count <= 0;
                    end
                end
                default: tick_count <= 0;
            endcase
        end
    end

    //sample rx_line at tick 8 (midpoint) and store into shift register
    always_ff @(posedge clk) begin
        if (rst) begin
            rx_shift_reg <= 0;
        end else if (state == DATA && tick && tick_count == 7) begin
            rx_shift_reg[bit_index] <= rx_line;
        end
    end

    // output logic
    always_comb begin
        done = 1'b0;
        if (state == STOP && tick && tick_count == ticks_per_bit - 1)
            done = 1'b1;
    end

    assign data_byte = rx_shift_reg;

endmodule