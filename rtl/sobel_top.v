`timescale 1ns/1ps

module sobel_top (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,

    input  wire [7:0] pixel_in,
    input  wire       in_valid,
    output wire       in_ready,

    output reg  [7:0] edge_out,
    output reg        out_valid,
    output reg        done
);

    reg active;
    reg [5:0] x;
    reg [5:0] y;

    wire real_pixel =
        (x >= 1 && x <= 30 &&
         y >= 1 && y <= 30);

    assign in_ready = active && real_pixel;

    wire advance =
        active && (!real_pixel || in_valid);

    wire [7:0] padded_pixel =
        real_pixel ? pixel_in : 8'd0;

    wire [71:0] window_data;
    wire [7:0] sobel_result;

    line_buffer buffer_inst (
        .clk(clk),
        .rst(rst),
        .step(advance),
        .col(x),
        .pixel_in(padded_pixel),
        .window_out(window_data)
    );

    sobel_core core_inst (
        .window(window_data),
        .edge_out(sobel_result)
    );

    wire output_position =
        (x >= 2 && y >= 2);

    wire output_border =
        (x == 2 || x == 31 ||
         y == 2 || y == 31);

    always @(posedge clk) begin

        if (rst) begin
            active    <= 0;
            x         <= 0;
            y         <= 0;
            edge_out  <= 0;
            out_valid <= 0;
            done      <= 0;

        end else begin

            out_valid <= 0;
            done      <= 0;

            if (start && !active) begin
                active <= 1;
                x <= 0;
                y <= 0;

            end else if (advance) begin

                if (output_position) begin
                    edge_out <= output_border
                              ? 8'd0
                              : sobel_result;
                    out_valid <= 1;
                end

                if (x == 31) begin
                    x <= 0;

                    if (y == 31) begin
                        y <= 0;
                        active <= 0;
                        done <= 1;
                    end else begin
                        y <= y + 1'b1;
                    end

                end else begin
                    x <= x + 1'b1;
                end
            end
        end
    end

endmodule
