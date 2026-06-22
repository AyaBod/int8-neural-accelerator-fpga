module fsm_tb;
    parameter ROWS = 4;
    parameter COLS = 4;
    
    logic clk = 0;
    logic rst;
    logic start;
    logic write_en;
    logic vec_ren;
    logic mat_ren;
    logic valid_out;
    logic done;

    logic [$clog2(COLS)-1:0] col_addr;
    logic [$clog2(ROWS)-1:0] row_addr;

    fsm #(
        .ROWS(ROWS),
        .COLS(COLS)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        //.write_en(write_en),
        .vec_ren(vec_ren),
        .mat_ren(mat_ren),
        .col_addr(col_addr),
        .row_addr(row_addr),
        .valid_out(valid_out),
        .done(done)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin //use always for clock generators and logging prints
        $display("t=%0t | FSM: write_en=%b vec_ren=%b mat_ren=%b valid=%b done=%b | row=%0d col=%0d", 
                 $time, write_en, vec_ren, mat_ren, valid_out, done, row_addr, col_addr);
    end

    // Put this directly in your testbench module, outside of any procedural blocks
    valid_fsm_state: assert property (
        @(posedge clk) disable iff (rst)
        (uut.state inside {uut.IDLE, uut.PRELOAD, uut.LOAD, uut.COMPUTE, uut.STORE, uut.DONE})
    ) else $error("FSM entered illegal state: %0d", uut.state);

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, fsm_tb);

        //clear signals
        rst = 1'b1;
        start = 1'b0;
        repeat(2) @(posedge clk);

        rst = 1'b0;
        @(posedge clk);

        //trigger one pass
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait(done == 1'b1);
        @(posedge clk);

        $display("FSM reached DONE state");
        $finish;
    end

endmodule