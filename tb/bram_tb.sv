module bram_tb; 
    parameter WIDTH = 8;
    parameter DEPTH = 16;

    logic clk = 0;
    logic write_en;
    logic [$clog2(DEPTH)-1:0] addr_w; // $clog2(DEPTH) = address width
    logic [$clog2(DEPTH)-1:0] addr_r;
    logic [WIDTH-1:0] write_data;
    logic [WIDTH-1:0] read_data;

    bram #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) uut (
        .clk(clk),
        .write_en(write_en),
        .addr_w(addr_w),
        .addr_r(addr_r),
        .write_data(write_data),
        .read_data(read_data)
    );

    always #5 clk = ~clk; //clock

    //writing test
    task write_mem(
        input logic [$clog2(DEPTH)-1:0] addr,
        input logic [WIDTH-1:0] data
    );
        write_en = 1'b1; //high
        addr_w = addr;
        write_data = data;
        @(posedge clk); //wait one cycle
        write_en = 1'b0;
    endtask

    //reading test
    task read_mem(
        input logic [$clog2(DEPTH)-1:0] addr,
        input logic [WIDTH-1:0] expected
    );

        addr_r = addr;
        repeat(2) @(posedge clk); //1 cycle internal bram latency
        if (read_data == expected)
            $display("PASSED: read address [%0d]: got %0d", addr, read_data);
        else 
            $display("FAILED: read address [%0d]: expected %0d, got %0d", addr, expected, read_data);

    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, bram_tb);

        //clear everything
        write_en = 1'b0;
        addr_w = '0;
        addr_r  = '0;
        write_data = '0;
        repeat(2) @(posedge clk);

        //write test
        write_mem($clog2(DEPTH)'(0), WIDTH'(42)); //$clog2(DEPTH)'(0) casts 0 to the bit size of $clog2(DEPTH)
        write_mem($clog2(DEPTH)'(1), WIDTH'(127));
        write_mem($clog2(DEPTH)'(2), WIDTH'(255));
        write_mem($clog2(DEPTH)'(3), WIDTH'(7));


        //read what we just wrote
        read_mem($clog2(DEPTH)'(0), WIDTH'(42));
        read_mem($clog2(DEPTH)'(1), WIDTH'(127));
        read_mem($clog2(DEPTH)'(2), WIDTH'(255));
        read_mem($clog2(DEPTH)'(3), WIDTH'(7));

        //overwrite test
        write_mem($clog2(DEPTH)'(0), WIDTH'(99));
        read_mem($clog2(DEPTH)'(0), WIDTH'(99));

        $display("all BRAM tests done");
        $finish;
    end


endmodule