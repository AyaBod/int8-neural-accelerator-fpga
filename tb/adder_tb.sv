module adder_tb();
    // Testbench signals
    reg [7:0] a;
    reg [7:0] b;
    wire [8:0] sum;
    
    // Instantiate the adder module
    // Unit Under Test (UUT)
    adder uut (
        .a(a),
        .b(b),
        .sum(sum)
    );
    
    //resuseable testing task
    //method
    task check_adder(input [7:0] t_a, input [7:0] t_b, input [8:0] expected);
        begin
            a = t_a;
            b = t_b;
            #10; // wait for combinational settling i.e wait 10 units
            if (sum == expected)
                $display ("PASSED: %0d + %0d = %0d", t_a, t_b, sum);
            else
                $display ("FAILED: %0d + %0d | expected %0d, got %0d", t_a, t_b, expected, sum);
        end
     endtask
    
    // Test cases
    initial begin
        
        $dumpfile("dump.vcd");
        $dumpvars(0, adder_tb);

        //run tests
        check_adder(8'd10, 8'd20, 9'd30);
        check_adder(8'd255, 8'd1, 9'd256);
        check_adder(8'd0, 8'd0, 9'd0);

        $display("All tests done.");
        $finish;

    end
endmodule

