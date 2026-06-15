module bram #(
    parameter DEPTH = 16, //number of entries
    parameter WIDTH = 8 //data width but as bits
) (
    input logic clk,
    input logic write_en, //write enable
    input logic [$clog2(DEPTH)-1:0] addr_w, //write address [$clog2(DEPTH)-1:0] number of bits for 16 enties 0-15 requires 4 bits so log base 2 16
    input logic [$clog2(DEPTH)-1:0] addr_r, //read address    addr = address register
    input logic [WIDTH-1:0] write_data,
    output logic [WIDTH-1:0] read_data
);

    logic [WIDTH-1:0] memory [0:DEPTH-1]; // columns ( 8 bits) rows (16 entries)

    //write
    always_ff @ (posedge clk) begin
        if (write_en) begin
            memory[addr_w] <= write_data;
        end
    end
    //read
    always_ff @ (posedge clk) begin
        read_data <= memory[addr_r];
    end

    
    
endmodule