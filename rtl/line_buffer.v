`timescale 1ns/1ps

module line_buffer (
    input  wire        clk,
    input  wire        rst,
    input  wire        step,
    input  wire [5:0]  col,
    input  wire [7:0]  pixel_in,
    output wire [71:0] window_out
);

    reg [7:0] row1 [0:31];
    reg [7:0] row2 [0:31];

    reg [7:0] top0, top1;
    reg [7:0] mid0, mid1;
    reg [7:0] bot0, bot1;

    wire [7:0] top_new = row2[col];
    wire [7:0] mid_new = row1[col];

    assign window_out = {
        top0, top1, top_new,
        mid0, mid1, mid_new,
        bot0, bot1, pixel_in
    };

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            top0 <= 0;
            top1 <= 0;
            mid0 <= 0;
            mid1 <= 0;
            bot0 <= 0;
            bot1 <= 0;
        end else if (step) begin

            // Preserve previous two image rows.
            row2[col] <= row1[col];
            row1[col] <= pixel_in;

            // Update horizontal sliding window.
            top0 <= top1;
            top1 <= top_new;

            mid0 <= mid1;
            mid1 <= mid_new;

            bot0 <= bot1;
            bot1 <= pixel_in;
        end
    end

endmodule
