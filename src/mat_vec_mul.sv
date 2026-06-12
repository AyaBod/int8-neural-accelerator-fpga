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


/*
//general flow
//comb = actual math of multipling and adding tg
// ff = steps of math
//each row of matrix gets its own dot product unit
logic signed [16:0] products [0:ROWS-1][0:COLS-1];


(* use_dsp = "yes" *)
always_comb begin
    for (int r = 0; r < ROWS; r++) begin ///for each row
        for (int c = 0; c < COLS; c++) begin //for each element in row
            products[r][c] = 16'($signed(mat[r][c]) * $signed(vec[c]));
        end
    end
end
*/

//pipelining workflow
//stage 1
(* use_dsp = "yes" *)
logic signed [15:0] products_reg [0:ROWS-1][0:COLS-1]; //products register
logic valid_pipe;

always_ff @(posedge clk) begin
    if (rst) begin
        valid_pipe <= 1'b0;
        for (int r = 0; r < ROWS; r++) begin
            for (int c = 0; c < COLS; c++) begin
                products_reg[r][c] <= '0;
            end
        end
    end else begin
        valid_pipe <= valid_in; //valid 
        for (int r = 0; r < ROWS; r++) begin ///for each row
            for (int c = 0; c < COLS; c++) begin //for each element in row
                products_reg[r][c] <= 16'($signed(mat[r][c]) * $signed(vec[c]));
            end
    end
    end
end

//stage 2
always_ff @(posedge clk) begin
    if (rst) begin
        valid_out = 1'b0;
        for (int r = 0; r < ROWS; r++) begin
            result[r] <= '0;
        end
    end else if (valid_pipe) begin
        
        logic signed [31:0] sum;
        for (int r = 0; r < ROWS; r++) begin
            //use = for temp local variables to accumulate accross loops
            sum = 0; //need to create seperate variable to add cols so result doesnt get overwritten
            for (int c = 0; c < COLS; c++) begin
                sum = sum + (products_reg[r][c]);
            end
            result[r] <= sum; //then set result equal to seperate sum
        end
        valid_out <= valid_pipe; //pass valid condition so send out data
    end //if valid_in is 0 and rst is 0, the cycles  will hold the current state
end

    
endmodule