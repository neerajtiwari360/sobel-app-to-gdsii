`timescale 1ns/1ps

module tb_sobel;

    reg [7:0] image_mem [0:899];
    reg [7:0] expected_mem [0:899];

    reg  [71:0] window;
    wire [7:0] edge_out;

    integer x, y, idx;
    integer mismatches;

    sobel_core dut (
        .window(window),
        .edge_out(edge_out)
    );

    initial begin
        $readmemh("tb/vectors/input.hex", image_mem);
        $readmemh("tb/vectors/expected.hex", expected_mem);

        mismatches = 0;

        for (y = 0; y < 30; y = y + 1) begin
            for (x = 0; x < 30; x = x + 1) begin

                idx = y * 30 + x;

                if (x == 0 || x == 29 ||
                    y == 0 || y == 29) begin

                    window = 72'd0;

                end else begin

                    window = {
                        image_mem[(y-1)*30 + (x-1)],
                        image_mem[(y-1)*30 + x],
                        image_mem[(y-1)*30 + (x+1)],

                        image_mem[y*30 + (x-1)],
                        image_mem[y*30 + x],
                        image_mem[y*30 + (x+1)],

                        image_mem[(y+1)*30 + (x-1)],
                        image_mem[(y+1)*30 + x],
                        image_mem[(y+1)*30 + (x+1)]
                    };

                end

                #10;

                if (edge_out !== expected_mem[idx]) begin
                    $display(
                        "FAIL pixel=%0d x=%0d y=%0d RTL=%0d expected=%0d",
                        idx, x, y, edge_out, expected_mem[idx]
                    );
                    mismatches = mismatches + 1;
                end
            end
        end

        if (mismatches == 0) begin
            $display("PASS: All 900 Sobel pixels match Python");
        end else begin
            $display("FAIL: %0d mismatches", mismatches);
            $fatal(1, "Sobel verification failed");
        end

        $finish;
    end

endmodule
