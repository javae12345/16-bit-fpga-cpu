`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 05:38:02 PM
// Design Name: 
// Module Name: tb_uart_tx
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module tb_uart_tx;

    localparam int CLK_FREQ = 1_000_000;
    localparam int BAUD_RATE = 100_000;
    localparam int CLKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam int BIT_TIME_NS = 10_000;

    logic clk = 0;
    logic reset;
    logic start;
    logic [7:0] data_in;
    logic tx;
    logic busy;

    // 1 MHz test clock
    always #500 clk = ~clk;

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .data_in(data_in),
        .tx(tx),
        .busy(busy)
    );

    initial begin
        reset = 1;
        start = 0;
        data_in = 0;

        repeat (3) @(negedge clk);
        reset = 0;

        // Send ASCII 'A' = 0x41
        @(negedge clk);
        data_in = 8'h41;
        start = 1;

        @(negedge clk);
        start = 0;

        if (busy !== 1'b1)
            $fatal(1, "FAIL: UART not busy");

        // Sample halfway through start bit
        #(BIT_TIME_NS / 2);

        if (tx !== 1'b0)
            $fatal(1, "FAIL: Incorrect start bit");

        // Sample each data bit in its center
        for (int i = 0; i < 8; i++) begin
            #BIT_TIME_NS;

            if (tx !== data_in[i])
                $fatal(1,
                    "FAIL: Data bit %0d incorrect", i);
        end

        // Sample stop bit
        #BIT_TIME_NS;

        if (tx !== 1'b1)
            $fatal(1, "FAIL: Incorrect stop bit");

        // Wait until transmitter returns to idle
        #BIT_TIME_NS;

        if (busy !== 1'b0)
            $fatal(1, "FAIL: UART still busy");

        if (tx !== 1'b1)
            $fatal(1, "FAIL: TX not idle");

        $display("UART TX TEST PASSED");
        $finish;
    end

    initial begin
        #200_000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule

