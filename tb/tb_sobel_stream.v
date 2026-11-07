`timescale 1ns/1ps

module tb_sobel_stream;

    reg clk = 0;
    always #5 clk = ~clk;

    reg rst = 1;
    reg start = 0;

    reg [7:0] image_mem [0:899];
    reg [7:0] expected_mem [0:899];

    wire [7:0] pixel_in;
    wire in_valid;
    wire in_ready;

    wire [7:0] edge_out;
    wire out_valid;
    wire done;

    integer sent_count = 0;
    integer recv_count = 0;
    integer mismatches = 0;
    integer cycles = 0;
    integer accepted;

    assign in_valid = (sent_count < 900);

    assign pixel_in = (sent_count < 900)
                    ? image_mem[sent_count]
                    : 8'd0;

    sobel_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .pixel_in(pixel_in),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .edge_out(edge_out),
        .out_valid(out_valid),
        .done(done)
    );

    initial begin
        $readmemh("tb/vectors/input.hex", image_mem);
        $readmemh("tb/vectors/expected.hex", expected_mem);

        $dumpfile("simulation/waveforms/sobel_stream.vcd");
        $dumpvars(0, tb_sobel_stream);

        repeat (4) @(negedge clk);

        rst = 0;
        start = 1;

        @(negedge clk);
        start = 0;
    end

    always @(posedge clk) begin
        if (!rst) begin

            // Capture input handshake before registers update.
            accepted = in_valid && in_ready;
            cycles = cycles + 1;

            // Observe registered outputs after the clock edge.
            #1;

            if (accepted)
                sent_count = sent_count + 1;

            if (out_valid) begin

                if (recv_count >= 900) begin
                    $fatal(1, "Too many output pixels");
                end

                if (edge_out !== expected_mem[recv_count]) begin
                    $display(
                        "MISMATCH pixel=%0d RTL=%0d expected=%0d",
                        recv_count,
                        edge_out,
                        expected_mem[recv_count]
                    );

                    mismatches = mismatches + 1;
                end

                recv_count = recv_count + 1;
            end

            if (done) begin

                $display("");
                $display("==== STREAMING SOBEL TEST ====");
                $display("Input pixels  : %0d", sent_count);
                $display("Output pixels : %0d", recv_count);
                $display("Clock cycles  : %0d", cycles);
                $display("Mismatches    : %0d", mismatches);

                if (sent_count == 900 &&
                    recv_count == 900 &&
                    mismatches == 0) begin

                    $display("PASS: 900/900 pixels match Python");

                end else begin
                    $fatal(1, "Streaming verification FAILED");
                end

                $finish;
            end
        end
    end

    initial begin
        #20000;
        $fatal(1, "Simulation timeout");
    end

endmodule
