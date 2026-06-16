module accelerator_top_tb;
    parameter ROWS = 4;
    parameter COLS = 4;
    parameter DATA_WIDTH = 8;
    parameter OUT_WIDTH = 32;


    logic clk = 0;
    logic rst;
    logic start;
    logic done;

    accelerator_top #(
        .ROWS(ROWS),
        .COLS(COLS),
        .DATA_WIDTH(DATA_WIDTH),
        .OUT_WIDTH(OUT_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        // Reads raw text files directly into the internal BRAM arrays
        $readmemh("C:/Users/ayann/Documents/int8-neural-accelerator-fpga/docs/weights.txt", uut.weight_bram.memory);
        $readmemh("C:/Users/ayann/Documents/int8-neural-accelerator-fpga/docs/vector.txt",  uut.vec_bram.memory);
    end 

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, accelerator_top_tb);

        //reset to clear
        rst = 1;
        start = 0;
        repeat(2) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // trigger accelerator
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for Hardware Execution Complete
        wait(done == 1);
        repeat(8) @(posedge clk);

        // Dynamic Verification Loop (.memory)
        $display("RESULTS!!!!");
        for (int r = 0; r < ROWS; r++) begin
            $display("result[%0d] = %0d (Expected: %0d)", 
                     r, 
                     $signed(uut.out_bram.memory[r]), 
                     (r < COLS) ? (r + 1) : 0);  //if statement
        end

        $stop;
    end
    
    initial begin
        $timeformat(-9, 0, " ns", 10);
        // Monitor when data leaves the BRAMs and goes into registers
        $monitor("@ %t | Row: %0d Col: %0d | VecData: %0d MatData: %0d | Result: %0d WE: %0b", 
                $time, uut.row_addr, uut.col_addr, $signed(uut.vec_data), $signed(uut.mat_data), $signed(uut.result_data), uut.write_en_out);
    end

endmodule