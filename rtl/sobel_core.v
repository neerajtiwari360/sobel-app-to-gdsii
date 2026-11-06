`timescale 1ns/1ps
module sobel_core (
    input  wire [71:0] window,
    output wire [7:0]  edge_out
);

    wire [7:0] p00 = window[71:64];
    wire [7:0] p01 = window[63:56];
    wire [7:0] p02 = window[55:48];
    wire [7:0] p10 = window[47:40];
    wire [7:0] p11 = window[39:32];
    wire [7:0] p12 = window[31:24];
    wire [7:0] p20 = window[23:16];
    wire [7:0] p21 = window[15:8];
    wire [7:0] p22 = window[7:0];

    wire signed [12:0] gx =
          $signed({1'b0,p02})
        + ($signed({1'b0,p12}) <<< 1)
        + $signed({1'b0,p22})
        - $signed({1'b0,p00})
        - ($signed({1'b0,p10}) <<< 1)
        - $signed({1'b0,p20});

    wire signed [12:0] gy =
          $signed({1'b0,p20})
        + ($signed({1'b0,p21}) <<< 1)
        + $signed({1'b0,p22})
        - $signed({1'b0,p00})
        - ($signed({1'b0,p01}) <<< 1)
        - $signed({1'b0,p02});

    wire [12:0] abs_gx = gx < 0 ? -gx : gx;
    wire [12:0] abs_gy = gy < 0 ? -gy : gy;

    wire [13:0] magnitude = abs_gx + abs_gy;

    assign edge_out = magnitude > 255 ? 8'hFF
                                  : magnitude[7:0];

endmodule

