module uart_tx_tb;
    parameter baud_rate = 100;
    parameter clk_freq = 400;
    //clk_frq/baud_rate= 4 clks_per_bit; faster for simulation purposes instead of 52080

    logic clk = 0;
    logic rst;
    logic start;
    logic [7:0] data_byte;
    logic tx_line;
    logic done;

    uart_tx #(
        .baud_rate(baud_rate),
        .clk_freq(clk_freq)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_byte(data_byte),
        .tx_line(tx_line),
        .done(done)
    );

    always #5 clk = ~clk;

    //sampling tx line every clock edge
    always @(posedge clk) begin
        $display("t=%0t | state=%s tx_line=%b done=%b bit_index=%d", 
                  $time, uut.state.name(), tx_line, done, uut.bit_index);
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, uart_tx_tb);

        rst = 1;
        start = 0;
        data_byte = 8'b00000000;
        repeat(2) @(posedge clk);  //hold reset for 2 clock edges so it actually gets sampled
        rst = 0;
        @(posedge clk);

        data_byte = 8'b10110010;
        start = 1;
        @(posedge clk);
        start = 0;

        wait(done == 1);
        @(posedge clk);

        $display("tx finished sending 8'b10110010");
        $finish;

    end

endmodule
