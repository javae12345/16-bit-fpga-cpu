`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 10:11:29 PM
// Design Name: 
// Module Name: tb_uart_rx_fifo_bridge
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



module tb_uart_rx_fifo_bridge;

    logic clk = 0;
    logic reset;
    logic [7:0] rx_byte;
    logic data_valid;
    logic read_ack;

    logic [7:0] rx_data;
    logic rx_ready;
    logic rx_overrun;
    logic [3:0] rx_count;

    always #5 clk = ~clk;

    uart_rx_fifo_bridge dut (
        .clk(clk),
        .reset(reset),
        .rx_byte(rx_byte),
        .data_valid(data_valid),
        .read_ack(read_ack),
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .rx_overrun(rx_overrun),
        .rx_count(rx_count)
    );

    task automatic receive_byte(input logic [7:0] value);
        @(negedge clk);
        rx_byte = value;
        data_valid = 1'b1;

        @(negedge clk);
        data_valid = 1'b0;
    endtask

    task automatic consume_byte(input logic [7:0] expected);
        @(negedge clk);

        if (!rx_ready || rx_data !== expected)
            $fatal(1, "FAIL: Expected %h, got %h",
                   expected, rx_data);

        read_ack = 1'b1;

        @(negedge clk);
        read_ack = 1'b0;
    endtask

    initial begin
        reset = 1'b1;
        rx_byte = 8'h00;
        data_valid = 1'b0;
        read_ack = 1'b0;

        repeat (3) @(negedge clk);
        reset = 1'b0;

        // Receive A, B, C
        receive_byte(8'h41);
        receive_byte(8'h42);
        receive_byte(8'h43);

        if (rx_count !== 3 || !rx_ready)
            $fatal(1, "FAIL: FIFO should contain 3 bytes");

        // Merely inspecting data must not remove it.
        repeat (3) @(negedge clk);

        if (rx_data !== 8'h41 || rx_count !== 3)
            $fatal(1, "FAIL: Data changed without read_ack");

        // Consume in FIFO order
        consume_byte(8'h41);
        consume_byte(8'h42);
        consume_byte(8'h43);

        if (rx_ready || rx_count !== 0)
            $fatal(1, "FAIL: FIFO should be empty");

        // Fill all eight entries
        for (int i = 0; i < 8; i++)
            receive_byte(8'h50 + i);

        if (rx_count !== 8)
            $fatal(1, "FAIL: FIFO should be full");

        // Ninth byte must be dropped
        receive_byte(8'hFF);

        if (!rx_overrun || rx_count !== 8)
            $fatal(1, "FAIL: Overrun not detected");

        // First byte must still be present
        consume_byte(8'h50);

        if (rx_overrun)
            $fatal(1, "FAIL: Overrun did not clear");

        if (rx_count !== 7)
            $fatal(1, "FAIL: Incorrect count after read");

        $display("-------------------------------");
        $display("UART RX FIFO BRIDGE TEST PASSED");
        $display("-------------------------------");

        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule
