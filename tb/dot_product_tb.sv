module dot_product_tb;
    parameter N = 4; //already defaulted but keep for changes
    
    // Signals
    logic clk = 0;
    logic rst;
    logic valid_in;
    logic signed [7:0]  a [0:N-1];
    logic signed [7:0]  b [0:N-1];
    logic signed [31:0] result;
    logic valid_out;

    //unit under test
    dot_product #(.N(N)) uut (
        .clk(clk), 
        .rst(rst),
        .valid_in(valid_in),
        .a(a),
        .b(b),
        .result(result),
        .valid_out(valid_out)
    );

    always #5 clk = ~clk; //10 ns clock generator

    task check_dot(
        input logic signed [7:0] ta [0:N-1],
        input logic signed [7:0] tb [0:N-1],
        input logic signed [31:0] expected
    );
        a = tb;
        b = tb;
        valid_in = 1;
        @(posedge clk);
        valid_in = 0;
        @(posedge clk); //1 clock cycle latency

        if (result == expected)
            $display("PASSED: result = %0d", result);
        else 
            $display("FAIL: expected %0d, got %0d", expected, result);
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, dot_product_tb);

        //restting sequence
        rst = 1;
        valid_in = 0;
        repeat(2) @(posedge clk);
        rst = 0;

        //if didnt have this input data arrives same time rst=0
        @(posedge clk); 

        //run test cases
        //[1,2,3,4] dot [1,2,3,4] = 1+4+9+16 = 30
        check_dot('{1,2,3,4}, '{1,2,3,4}, 32'd30);

        //[1,0,0,0] · [5,5,5,5] = 5
        check_dot('{1,0,0,0}, '{5,5,5,5}, 32'd5);
        
        //all zeros = 0
        check_dot('{0,0,0,0}, '{0,0,0,0}, 32'd0);
        
        //[-1,-1,-1,-1] dot [1,1,1,1] = -4
        check_dot('{1,1,1,1}, '{-1,-1,-1,-1}, -32'sd4); 

        //no wait cycle waveform would end exactly when last tes output comes in
        repeat(2) @(posedge clk);
        $display("all tests done");
        $finish;        
    end
endmodule