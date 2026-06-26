module async_fifo #(
    parameter DEPTH      = 8,
    parameter DATA_WIDTH = 8
) (
    input wclk,
    input rclk,
    input rst,
    input [DATA_WIDTH-1:0] wdata,
    input write_en,
    input read_en,
    output full,
    output [DATA_WIDTH-1:0] rdata,
    output empty
);

    localparam PTR_WIDTH = $clog2(DEPTH) + 1;

    logic [PTR_WIDTH-1:0] wptr;
    logic [PTR_WIDTH-1:0] rptr;
    logic [DATA_WIDTH-1:0] mem [DEPTH];

    //gray encoded pointers
    logic [PTR_WIDTH-1:0] wptr_gray;
    logic [PTR_WIDTH-1:0] rptr_gray;

    //2ff synchronizer stages write pointer into read domain
    logic [PTR_WIDTH-1:0] wptr_gray_s1;
    logic [PTR_WIDTH-1:0] wptr_gray_s2;

    //2ff synchronizer stages read pointer into write domain
    logic [PTR_WIDTH-1:0] rptr_gray_s1;
    logic [PTR_WIDTH-1:0] rptr_gray_s2;

    // reset synchronized into each domain
    logic rst_w_s1, rst_w_s2, rst_w;
    logic rst_r_s1, rst_r_s2, rst_r;

    //for resetting synchronizers rst into write domain
    always_ff @(posedge wclk or posedge rst) begin
        if (rst) {rst_w_s2, rst_w_s1} <= 2'b11;
        else     {rst_w_s2, rst_w_s1} <= {rst_w_s1, 1'b0};
    end
    assign rst_w = rst_w_s2;

    //for resetting synchronizers rst into read domain
    always_ff @(posedge rclk or posedge rst) begin
        if (rst) {rst_r_s2, rst_r_s1} <= 2'b11;
        else     {rst_r_s2, rst_r_s1} <= {rst_r_s1, 1'b0};
    end
    assign rst_r = rst_r_s2;

    //gray conversion
    assign wptr_gray = wptr ^ (wptr >> 1);
    assign rptr_gray = rptr ^ (rptr >> 1);

    //write logic
    always_ff @(posedge wclk or posedge rst_w) begin
        if (rst_w)
            wptr <= '0;
        else if (write_en && !full) begin
            mem[wptr[PTR_WIDTH-2:0]] <= wdata;
            wptr <= wptr + 1;
        end
    end

    //read logic
    assign rdata = mem[rptr[PTR_WIDTH-2:0]];
    always_ff @(posedge rclk or posedge rst_r) begin
        if (rst_r)
            rptr <= '0;
        else if (read_en && !empty)
            rptr <= rptr + 1;
    end

    //2ff synchronizers

    //write pointer into read domain
    always_ff @(posedge rclk or posedge rst_r) begin
        if (rst_r) {wptr_gray_s2, wptr_gray_s1} <= '0;
        else       {wptr_gray_s2, wptr_gray_s1} <= {wptr_gray_s1, wptr_gray};
    end

    //read pointer into write domain
    always_ff @(posedge wclk or posedge rst_w) begin
        if (rst_w) {rptr_gray_s2, rptr_gray_s1} <= '0;
        else       {rptr_gray_s2, rptr_gray_s1} <= {rptr_gray_s1, rptr_gray};
    end

    //full empty flags
    //empty; all bits match
    assign empty = (wptr_gray_s2 == rptr_gray);

    //full; only first and second msb differ rest match
    assign full = (wptr_gray[PTR_WIDTH-1]   != rptr_gray_s2[PTR_WIDTH-1])  &&
                  (wptr_gray[PTR_WIDTH-2]   != rptr_gray_s2[PTR_WIDTH-2])  &&
                  (wptr_gray[PTR_WIDTH-3:0] == rptr_gray_s2[PTR_WIDTH-3:0]);

endmodule