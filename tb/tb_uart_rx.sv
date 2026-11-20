`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 06:42:23 PM
// Design Name: 
// Module Name: tb_uart_rx
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


module tb_uart_rx;

    localparam int CLK_FREQ = 1_000_000;
    localparam int BAUD_RATE = 100_000;
    localparam int BIT_TIME_NS = 10_000;

    logic clk = 0;
    logic reset;
    logic rx;

    logic [7:0] data_out;
    logic data_valid;

    // 1 MHz test clock
    always #500 clk = ~clk;

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(data_out),
        .data_valid(data_valid)
    );

    // Simulate a UART transmitter
    task automatic send_byte(input logic [7:0] value);
        @(negedge clk);

        // Start bit
        rx = 1'b0;
        #BIT_TIME_NS;

        // Eight data bits, LSB first
        for (int i = 0; i < 8; i++) begin
            rx = value[i];
            #BIT_TIME_NS;
        end

        // Stop bit
        rx = 1'b1;
        #BIT_TIME_NS;

        // Inter-frame idle time
        #BIT_TIME_NS;
    endtask

    // Send a byte and verify the received result
    task automatic check_byte(input logic [7:0] expected);
        fork
            begin
                send_byte(expected);
            end

            begin
                @(posedge data_valid);
                #1;

                if (data_out !== expected)
                    $fatal(1,
                        "FAIL: Expected %h, got %h",
                        expected, data_out);

                $display("Received byte: 0x%h", data_out);
            end
        join
    endtask

    initial begin
        reset = 1'b1;
        rx = 1'b1;

        repeat (3) @(negedge clk);
        reset = 1'b0;

        // Test ASCII 'A'
        check_byte(8'h41);

        // Test alternating bits
        check_byte(8'hA5);

        // Test all bits set
        check_byte(8'hFF);

        $display("---------------------------");
        $display("UART RX TEST PASSED");
        $display("---------------------------");

        $finish;
    end

    initial begin
        #500_000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule
