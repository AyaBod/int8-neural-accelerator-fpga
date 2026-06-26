module async_fifo_tb;
    parameter DEPTH = 8;
    parameter DATA_WIDTH = 8;

    localparam num_tests = 100;

    logic wclk = 0;
    logic rclk = 0;
    logic rst;
    logic [DATA_WIDTH-1:0] wdata;
    logic write_en;
    logic read_en;
    logic full;
    logic [DATA_WIDTH-1:0] rdata;
    logic empty;

    // scoreboard
    logic [DATA_WIDTH-1:0] scoreboard[$];
    logic [DATA_WIDTH-1:0] expected;

    async_fifo #(
        .DEPTH(DEPTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .wclk(wclk),
        .rclk(rclk),
        .rst(rst),
        .wdata(wdata),
        .write_en(write_en),
        .read_en(read_en),
        .full(full),
        .rdata(rdata),
        .empty(empty)
    );

    always #5 wclk = ~wclk;  // 100MHz
    always #15 rclk = ~rclk;  // 33MHz


    task write_byte(input logic [DATA_WIDTH-1:0] data);
        // wait until not full
        @(posedge wclk);
        while (full) begin
            $display("[WRITE] t=%0t waiting, full=1 data=%0d", $time, data);
            @(posedge wclk);
        end
        wdata = data;
        write_en = 1;
        scoreboard.push_back(data);
        $display("[WRITE] t=%0t wrote=%0d scoreboard_size=%0d", 
                $time, data, scoreboard.size());
        @(posedge wclk);
        write_en = 0;
    endtask

     int num_reads_completed; //int = 32 bits

    task read_and_check();
        if (!empty) begin
            read_en = 1;
            @(posedge rclk);
            read_en  = 0;
            expected = scoreboard.pop_front();
            $display("[READ]  t=%0t rdata=%0d expected=%0d match=%0b", 
                      $time, rdata, expected, (rdata == expected));
            assert(rdata == expected)
                else $error("MISMATCH: got %0d expected %0d", rdata, expected);
            num_reads_completed++;
        end else begin
            $display("[READ]  t=%0t SKIPPED empty=1", $time);
        end
    endtask


    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, async_fifo_tb);

        
        rst = 1;
        write_en = 0;
        read_en = 0;
        wdata = 0;
        @(posedge wclk);
        @(posedge rclk);
        rst = 0;

        num_reads_completed = 0;
        repeat(5) @(posedge wclk); // let clocks settle before fork

        fork
            // write thread
            begin
                repeat(num_tests) begin
                    write_byte($urandom_range(0, 255));
                    repeat($urandom_range(0, 4)) @(posedge wclk);
                end
                $display("[WRITE] t=%0t all %0d writes done", $time, num_tests);
            end

            // read thread — runs until all reads confirmed
            begin
                while (num_reads_completed < num_tests) begin
                    @(posedge rclk);
                    read_and_check();
                    repeat($urandom_range(1, 6)) @(posedge rclk);
                end
                $display("[READ]  t=%0t all %0d reads done", $time, num_tests);
            end

            // timeout
            begin
                #1000000;
                $display("[TIMEOUT] scoreboard_size=%0d reads_done=%0d", 
                          scoreboard.size(), num_reads_completed);
                $error("TIMEOUT: simulation hung");
                $finish;
            end
        join_any


        //if we get here either both threads finished or timeout fired
        //timeout calls $finish itself, so reaching here means success
        disable fork;

        //get rid of whats remaining in queue
        while (num_reads_completed < num_tests) begin
            @(posedge rclk);
            read_and_check();
        end

        if (num_reads_completed == num_tests)
            $display("PASSED: %0d transactions verified", num_tests);
        else
            $error("FAILED: only %0d/%0d reads completed", num_reads_completed, num_tests);
        $finish;
    end

endmodule