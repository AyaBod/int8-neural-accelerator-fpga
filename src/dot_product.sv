module dot_product #(
    parameter N = 4 //number of elements whos products being added
) (
    input logic clk,
    input logic rst,
    input logic valid_in, //sending data to input verb
    input logic signed [7:0] a [0:N-1], //input vector
    input logic signed [7:0] b [0:N-1], //weight vector
    output logic signed [31:0] result,
    output logic valid_out //sending data to output  verb
);

    //first stage : multiply
    logic signed [15:0] products [0:N-1]; // array of each element multiplied (16 bits)
    
    always_comb begin
        for (int i = 0; i < N; i++) begin
            products[i] = a[i] * b[i];
        end
    end

    //second stage : add it all up
    always_ff @(posedge clk) begin
        if (rst) begin 
            result <= 0;
            valid_out <= 0; //nothing to show bc zeroed out
        end else if (valid_in) begin
            logic signed [31:0] sum;
            sum = 0;
            for (int i = 0; i < N; i++) begin
                sum = sum + products[i];
            end
            result <= sum;
            valid_out <= 1;
        end else begin
            valid_out <= 0; //if no valid input then no valid output
        end
    end

endmodule
//a dot b = (a1xb1) + (a2xb2) + (a3xb3)
