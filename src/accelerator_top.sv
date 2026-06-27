module accelerator_top #(
    parameter ROWS = 4,
    parameter COLS = 4,
    parameter DATA_WIDTH = 8, //int8 input width
    parameter OUT_WIDTH = 32,  //int32 accumulation width
    parameter DEPTH = 8
)(
    input logic clk,
    input logic rst,
    input logic wclk, //new
    input  logic [DATA_WIDTH-1:0] wdata,
    input logic write_en,
    output logic full,

    input logic start,
    output logic done

);

    //internal control signals from fsm
    logic write_en_out;
    logic vec_ren;
    logic mat_ren;
    logic valid_compute;
    logic fsm_done;
    logic [$clog2(COLS)-1:0] col_addr;
    logic [$clog2(ROWS)-1:0] row_addr;

    //internal signals for fifo and fsm
    logic empty;
    logic [DATA_WIDTH-1:0] rdata;
    logic read_en;
    logic vec_wen;
    logic [$clog2(COLS)-1:0] vec_waddr;
    logic [DATA_WIDTH-1:0] vec_wdata;


    //bram data signals
    logic signed [DATA_WIDTH-1:0] vec_data; // one element of input vector
    logic signed [DATA_WIDTH-1:0] mat_data; //one elemenet of weight matrix
    logic signed [OUT_WIDTH-1:0] result_data; //one output result / dot product

    //weight matrix bram that stores int8 weights
    //addresses by {row, col} flattened to single address
    logic [$clog2(ROWS*COLS)-1:0] mat_addr;
    assign mat_addr = {row_addr, col_addr};

    bram #(.WIDTH(DATA_WIDTH), .DEPTH(ROWS*COLS)) weight_bram (
        .clk(clk),
        .write_en(1'b0), 
        .addr_w('0),
        .addr_r(mat_addr),
        .write_data('0),
        .read_data(mat_data)
    );

    //input vector bram
    bram #(.WIDTH(DATA_WIDTH), .DEPTH(COLS)) vec_bram (
        .clk(clk),
        .write_en(vec_wen), 
        .addr_w(vec_waddr),
        .addr_r(col_addr),
        .write_data(vec_wdata),
        .read_data(vec_data)
    );


    logic [$clog2(ROWS)-1:0] row_addr_pipe1;
    logic [$clog2(ROWS)-1:0] row_addr_pipe2;

    // pipeplines the row address by 2 cycles to match the mvm
    always_ff @(posedge clk) begin
        if (rst) begin
            row_addr_pipe1 <= 0;
            row_addr_pipe2 <= 0;
        end else begin
            row_addr_pipe1 <= row_addr; //1 cycle after valid compute
            row_addr_pipe2 <= row_addr_pipe1; //2 cycles after vlaid compute
        end
    end


    //output bram
    bram #(.WIDTH(OUT_WIDTH), .DEPTH(ROWS)) out_bram (
        .clk(clk),
        .write_en(write_en_out),
        .addr_w(row_addr_pipe2),
        .addr_r(row_addr),
        .write_data(result_data),
        .read_data() 
    );

    logic preload_en;
    fsm #(.ROWS(ROWS), .COLS(COLS), .DATA_WIDTH(DATA_WIDTH)) fsm_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        //.write_en(write_en),
        .empty(empty),
        .rdata(rdata),
        .vec_ren(vec_ren),
        .mat_ren(mat_ren),
        .col_addr(col_addr),
        .row_addr(row_addr),
        .valid_out(valid_compute),
        .done(fsm_done),
        .preload_en(preload_en),
        .read_en(read_en),
        .vec_wen(vec_wen),
        .vec_waddr(vec_waddr),
        .vec_wdata(vec_wdata)
    );


    async_fifo #(.DEPTH(DEPTH), .DATA_WIDTH(DATA_WIDTH)) fifo_inst (
        .wclk(wclk),
        .rclk(clk),
        .rst(rst),
        .wdata(wdata),
        .write_en(write_en),
        .read_en(read_en),
        .full(full),
        .rdata(rdata),
        .empty(empty)
    );

    //temp registers 
    logic signed [DATA_WIDTH-1:0] vec_reg [0:COLS-1];
    logic signed [DATA_WIDTH-1:0] mat_reg [0:ROWS-1][0:COLS-1];
    logic valid_in_reg;

    //latch bram outputs into arrays
    logic preload_en_d1;
    logic [$clog2(COLS)-1:0] col_addr_d1;
    logic [$clog2(ROWS)-1:0] row_addr_d1_latch;
    logic vec_ren_d1;

    always_ff @(posedge clk) begin
        preload_en_d1     <= preload_en;
        col_addr_d1       <= col_addr;
        row_addr_d1_latch <= row_addr;
        vec_ren_d1        <= vec_ren;
    end

    //latch full matrix during preload phase
    always_ff @(posedge clk) begin
        if (preload_en_d1)
            mat_reg[row_addr_d1_latch][col_addr_d1] <= mat_data;
    end

    //latch vector during compute phase
    always_ff @(posedge clk) begin
        if (vec_ren_d1)
            vec_reg[col_addr_d1] <= vec_data;
    end

    logic valid_in_d1, valid_in_d2;
    always_ff @(posedge clk) begin
        valid_in_d1 <= valid_compute;
        valid_in_d2 <= valid_in_d1;
    end




    ////testing cycles///

    always_ff @(posedge clk) begin
        if (valid_in_reg) begin
            $display("valid_in fired | mat_reg[0]=%0d %0d %0d %0d | vec_reg=%0d %0d %0d %0d",
                mat_reg[0][0], mat_reg[0][1], mat_reg[0][2], mat_reg[0][3],
                vec_reg[0], vec_reg[1], vec_reg[2], vec_reg[3]);
        end
    end

    always_ff @(posedge clk) begin
        if (preload_en_d1)
            $display("preload write: mat_reg[%0d][%0d] = %0d", 
                    row_addr_d1_latch, col_addr_d1, mat_data);
    end

    /////////////////////

    // matrix vector multiplication results
    logic signed [OUT_WIDTH-1:0] mul_result [0:ROWS-1];
    logic mul_valid_out;

    mat_vec_mul #(
        .ROWS(ROWS), 
        .COLS(COLS)
    ) mul_inst (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in_d2),
        .vec(vec_reg),
        .mat(mat_reg),
        .result(mul_result),
        .valid_out(mul_valid_out)
    );

    assign write_en_out = mul_valid_out; //wait for valid out to tell us math is done
    assign result_data = mul_result[row_addr_pipe2];
    logic done_pipe1;
    logic done_pipe2;
    always_ff @(posedge clk) begin
        done_pipe1 <= fsm_done; //since the done singal fires too early this adds a small delay
        done_pipe2 <= done_pipe1; 
    end
    assign done = done_pipe2;

endmodule