module mat_vec_mul_tb;
    parameter ROWS = 4;
    parameter COLS = 4;

    logic clk = 0;
    logic rst;
    logic valid_in;
    logic signed [7:0] vec [0:COLS-1];
    logic signed [7:0] mat [0:ROWS-1][0:COLS-1];
    logic signed [31:0] result [0:ROWS-1];
    logic valid_out;
    
    mat_vec_mul #(.ROWS(ROWS), .COLS(COLS)) uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .vec(vec),
        .mat(mat),
        .result(result),
        .valid_out(valid_out)
    );

    always #5 clk = ~clk;

    task check_mul(
        input logic signed [7:0] t_mat [0:ROWS-1][0:COLS-1],
        input logic signed [7:0] t_vec [0:COLS-1],
        input logic signed [31:0] expected [0:ROWS-1]
    );
    mat = t_mat;
    vec = t_vec;
    valid_in = 1;
    @(posedge clk); //wait one clock cycle 
    valid_in = 0;
    repeat(2) @(posedge clk);
    //clk 1 = stage 1 to stage 2
    //clk 2 = stage 2 to output
        for (int r = 0; r < ROWS; r++) begin
            if (result[r] == expected[r])
                $display("PASSED row %0d: result = %0d", r, result[r]);
            else
                $display("FAILED row %0d: expected %0d, got %0d", r, expected[r], result[r]);
        end

    endtask
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, mat_vec_mul_tb);

        rst = 1; 
        valid_in = 0;
        repeat(2) @(posedge clk);
        rst = 0;
        @(posedge clk);
        #1;



        //test 1
        check_mul(
            '{'{-94,-50,-107,-52}, '{13,-67,21,-99}, '{31,-96,-3,-111}, '{82,-114,-67,124}},
            '{-114,108,43,6},
            '{32'd403, -32'd8409, -32'd14697, -32'd23797}
        );

        #1;
        //all-ones matrix * [1,1,1,1] = [4,4,4,4]
        check_mul(
            '{'{96,45,119,41}, '{66,43,-56,-64}, '{34,-40,-28,82}, '{-4,46,80,-72}},
            '{91,-51,105,108},
            '{32'd23364, -32'd8979, 32'd11050, -32'd2086}
        );


        #1;
        //negative weights * positive input
        check_mul(
            '{'{-100,105,99,75}, '{43,48,101,-78}, '{34,-96,11,-101}, '{-2,103,-38,-72}},
            '{-119,3,90,46},
            '{32'sd24575, 32'sd529, -32'sd7990, -32'sd6185}
        );

        #1;
        //all max positive values
        check_mul(
            '{'{127,127,127,127}, '{127,127,127,127}, '{127,127,127,127}, '{127,127,127,127}},
            '{127,127,127,127},
            '{32'sd64516, 32'sd64516, 32'sd64516, 32'sd64516}
        );

        #1;
        //all max negative values
        check_mul(
            '{'{-128,-128,-128,-128}, '{-128,-128,-128,-128}, '{-128,-128,-128,-128}, '{-128,-128,-128,-128}},
            '{-128,-128,-128,-128},
            '{32'sd65536, 32'sd65536, 32'sd65536, 32'sd65536}
        );

        #1;
        //zero matrix, nonzero vector
        check_mul(
            '{'{0,0,0,0}, '{0,0,0,0}, '{0,0,0,0}, '{0,0,0,0}},
            '{50,-30,20,-10},
            '{32'sd0, 32'sd0, 32'sd0, 32'sd0}
        );
        



        /*
        //identity matrix * [1,2,3,4] = [1,2,3,4]
        check_mul(
            '{'{1,0,0,0}, '{0,1,0,0}, '{0,0,1,0}, '{0,0,0,1}},
            '{1,2,3,4},
            '{32'd1, 32'd2, 32'd3, 32'd4}
        );

        #1;
        //all-ones matrix * [1,1,1,1] = [4,4,4,4]
        check_mul(
            '{'{1,1,1,1}, '{1,1,1,1}, '{1,1,1,1}, '{1,1,1,1}},
            '{1,1,1,1},
            '{32'd4, 32'd4, 32'd4, 32'd4}
        );

        #1;
        //negative weights * positive input
        check_mul(
            '{'{-1,-1,-1,-1}, '{-1,-1,-1,-1}, '{-1,-1,-1,-1}, '{-1,-1,-1,-1}},
            '{1,1,1,1},
            '{-32'sd4, -32'sd4, -32'sd4, -32'sd4}
        );
        */



        repeat(2) @(posedge clk);
        $display("All tests done.");
        $finish;
    end


endmodule