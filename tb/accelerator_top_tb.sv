module accelerator_top_tb;
    parameter ROWS = 4;
    parameter COLS = 4;
    parameter DATA_WIDTH = 8;
    parameter OUT_WIDTH = 32;


    logic clk = 0;
    logic rst;
    logic start;
    logic done;
    logic wclk = 0;
    logic [DATA_WIDTH-1:0] wdata;
    logic write_en;
    logic full;
    localparam DEPTH = 8;

    accelerator_top #(
        .ROWS(ROWS),
        .COLS(COLS),
        .DATA_WIDTH(DATA_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .DEPTH(DEPTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .wclk(wclk),
        .wdata(wdata),
        .write_en(write_en),
        .full(full),
        .start(start),
        .done(done)
    );


    always #15 clk = ~clk; //read clk
    always #5 wclk = ~wclk;

    initial begin
        //used to read raw text files directly into the internal BRAM arrays
        $readmemh("C:/Users/ayann/Documents/int8-neural-accelerator-fpga/docs/weights.mem", uut.weight_bram.memory);
        //$readmemh("C:/Users/ayann/Documents/int8-neural-accelerator-fpga/docs/vector.mem",  uut.vec_bram.memory);
        //vec will be read in from fifo
    end 

    // write vector bytes into FIFO from wclk domain
    task write_fifo(input logic [DATA_WIDTH-1:0] data);
        @(posedge wclk);
        while (full) @(posedge wclk);
        wdata = data;
        write_en = 1;
        @(posedge wclk);
        write_en = 0;
    endtask


    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, accelerator_top_tb);

        //reset to clear
        rst = 1;
        start = 0;
        write_en = 0;
        wdata = '0;
        repeat(2) @(posedge clk);
        rst = 0;
        @(posedge clk);

        //
        write_fifo(127);
        write_fifo(1);
        write_fifo(68);
        write_fifo(-21);  //will wrap correctly as 8-bit signed



        // trigger accelerator
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for Hardware Execution Complete
        wait(done == 1);
        repeat(8) @(posedge clk);

        //Dynamic Verification Loop (.memory)
        /*
        $display("RESULTS!!!!");
        for (int r = 0; r < ROWS; r++) begin
            $display("result[%0d] = %0d (Expected: %0d)", 
                     r, 
                     $signed(uut.out_bram.memory[r]), 
                     (r < COLS) ? (r + 1) : 0);  //if statement
        end
        */

        $display("RESULTS!!!!");
        $display("result[0] = %0d (unused row, expected 0)", $signed(uut.out_bram.memory[0]));
        $display("result[1] = %0d (unused row, expected 0)", $signed(uut.out_bram.memory[1]));
        $display("result[2] = %0d (Expected: 2145); MNIST digit-2 classifier output", $signed(uut.out_bram.memory[2]));
        $display("result[3] = %0d (unused row, expected 0)", $signed(uut.out_bram.memory[3]));

        $stop;
    end
    
    initial begin
        $timeformat(-9, 0, " ns", 10);
        //monitor when data leaves the BRAMs and goes into registers
        $monitor("@ %t | Row: %0d Col: %0d | VecData: %0d MatData: %0d | Result: %0d WE: %0b", 
                $time, uut.row_addr, uut.col_addr, $signed(uut.vec_data), $signed(uut.mat_data), $signed(uut.result_data), uut.write_en_out);
    end

    always @(posedge clk) begin
        if (uut.vec_wen)
            $display("[VEC LOAD] t=%0t addr=%0d data=%0d", 
                    $time, uut.vec_waddr, $signed(uut.vec_wdata));
    end
    
    always @(posedge wclk) begin
        if (write_en && !full)
            $display("[FIFO WRITE] t=%0t wdata=%0d", $time, $signed(wdata));
    end

endmodule