module uart_rx_tb;
    parameter baud_rate = 100;
    parameter clk_freq  = 6400;
    // clks_per_bit = 6400/100 = 64, clks_per_tick = 64/16 = 4

    logic clk = 0;
    logic rst;
    logic start;
    logic [7:0] tx_data_byte;
    logic tx_line;
    logic tx_done;

    logic [7:0] rx_data_byte;
    logic rx_done;

    //tx feeds into tx
    uart_tx #(
        .baud_rate(baud_rate),
        .clk_freq(clk_freq)
    ) tx_uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_byte(tx_data_byte),
        .tx_line(tx_line),
        .done(tx_done)
    );

    uart_rx #(
        .baud_rate(baud_rate),
        .clk_freq(clk_freq)
    ) rx_uut (
        .clk(clk),
        .rst(rst),
        .rx_line(tx_line),       //tx output wired to rx input
        .data_byte(rx_data_byte),
        .done(rx_done)
    );

    always #5 clk = ~clk;

    task send_and_check(input logic [7:0] byte_to_send);
        tx_data_byte = byte_to_send;
        start = 1;
        @(posedge clk);
        start = 0;

        wait(rx_done == 1);
        @(posedge clk);

        if (rx_data_byte == byte_to_send)
            $display("PASS: sent %b, received %b", byte_to_send, rx_data_byte);
        else
            $display("FAIL: sent %b, received %b", byte_to_send, rx_data_byte);

        //wait for both modules to settle back to idle before next test
        repeat(10) @(posedge clk);
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, uart_rx_tb);

        rst = 1; start = 0; tx_data_byte = 0;
        repeat(2) @(posedge clk);
        rst = 0;
        @(posedge clk);

        send_and_check(8'b10110010);
        send_and_check(8'b00000000);
        send_and_check(8'b11111111);
        send_and_check(8'b01010101);
        send_and_check(8'b10101010);

        $display("all uart tests done.");
        $finish;
    end

endmodule