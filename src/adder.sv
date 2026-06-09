module adder (
    //logic is synonomous to reg and wire
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [8:0] sum
);
    assign sum = a + b; //continuously sum
    
endmodule