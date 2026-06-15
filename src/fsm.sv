module fsm #(
    parameter ROWS = 4,
    parameter COLS = 4
)(
    input logic clk,
    input logic rst,
    input logic start, //goes high to start load
    output logic write_en, //write enable for output in BRAM
    output logic vec_ren, //read enable for vector in BRAM
    output logic mat_ren, //read enable for matrix in BRAM
    output logic [$clog2(COLS)-1:0] col_addr, //current column index
    output logic [$clog2(ROWS)-1:0] row_addr,  // current row index
    output logic valid_out,     // result is valid
    output logic done           // full pass done 

);

    //state encoding
    typedef enum logic [2:0] { 
        IDLE = 3'd0, //3 bits required for 5 in binary
        LOAD = 3'd1,
        COMPUTE = 3'd2,
        STORE = 3'd3, 
        DONE = 3'd4
    } state_type; 

    state_type state;
    state_type next_state;

    //counters to track where we are in matrix
    logic [$clog2(ROWS)-1:0] row_cnt;
    logic [$clog2(COLS)-1:0] col_cnt;

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
            IDLE: if (start) next_state = LOAD;
            LOAD: next_state = COMPUTE;
            COMPUTE: next_state = STORE;
            STORE: if (row_cnt == ROWS-1) next_state = DONE;
                   else next_state = LOAD;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    //counter logic
    always_ff @ (posedge clk) begin
        if (rst) begin
            row_cnt <= 0;
            col_cnt <= 0;
        end else begin //only need begin and end if item has 2+ actions
            case (state)  
                LOAD: col_cnt <= 0; // reset col count to 0 for new row
                COMPUTE: if (col_cnt < COLS-1) col_cnt <= col_cnt + 1;
                STORE: if (row_cnt < ROWS-1) row_cnt <= row_cnt + 1;
                DONE: begin
                    row_cnt <= 0;
                    col_cnt <= 0;
                end
                default: begin //if none of the states match, just hold current value
                    row_cnt <= row_cnt;
                    col_cnt <= col_cnt;
                end
            endcase
        end
    end

    //output logic
    always_comb begin
        write_en = 0;
        vec_ren = 0;
        mat_ren = 0;
        valid_out = 0;
        done = 0;
        col_addr = col_cnt;
        row_addr = row_cnt;

        case (state)
            IDLE:; //all outputs already 0 
            LOAD: begin
                vec_ren = 1;
                mat_ren = 1;
            end
            COMPUTE: begin
                vec_ren = 1; //while computing prev cycle, let load take in new cycle data
                mat_ren = 1;
            end
            STORE: begin
                write_en = 1;
                valid_out = 1;
            end
            DONE: begin
                done = 1;
            end
            default:;
        endcase
    end

endmodule