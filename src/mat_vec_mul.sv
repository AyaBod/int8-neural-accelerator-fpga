module mat_vec_mul #(  //matrix vector multiply
    parameter ROWS = 4,
    parameter COLS = 4 //sqaure
) (
    input logic clk,
    input logic rst,
    input logic valid_in, //data going in status
    input logic signed [7:0] vec [0:COLS-1], //input vector
    input logic signed [7:0] mat [0:ROWS-1][0:COLS-1], //input matrix
    output logic signed [31:0] result [0:ROWS-1], //output vector
    output logic valid_out

);

//general flow
//comb = actual math of multipling and adding tg
// ff = steps of math
//each row of matrix gets its own dot product unit
logic signed [16:0] products [0:ROWS-1][0:COLS-1];

always_comb begin
    for (int r = 0; r < ROWS; r++) begin ///for each row
        for (int c = 0; c < COLS; c++) begin //for each element in row
            products[r][c] = 16'($signed(mat[r][c]) * $signed(vec[c]));
        end
    end
end

always_ff @(posedge clk) begin
    if (rst) begin
        for (int r = 0; r < ROWS; r++) begin
            result[r] <= 0;
        end
    end else if (valid_in) begin
        logic signed [31:0] sum;
        for (int r = 0; r < ROWS; r++) begin
            sum = 0;
            for (int c = 0; c < COLS; c++) begin
                sum = sum + (products[r][c]);
            end
            result[r] <= sum;
        end
        valid_out <= 1; // sending out data
    end else begin
        valid_out <=0; //everything only lasts for one clock cycle
    end
end

///failed everything btw....
    
endmodule