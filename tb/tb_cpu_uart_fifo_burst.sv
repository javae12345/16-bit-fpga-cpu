`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 10:14:12 PM
// Design Name: 
// Module Name: tb_cpu_uart_fifo_burst
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



`timescale 1ns / 1ps

module tb_cpu_uart_fifo_burst;

    localparam int BIT_TIME_NS = 8680;

    logic clk = 0;
    logic reset;
    logic cpu_enable;
    logic uart_rx_in;

    logic [15:0] pc_out;
    logic [15:0] instruction_out;
    logic halted;
    logic [3:0] gpio_led;
    logic uart_tx_out;
    logic uart_busy;

    logic [7:0] expected [0:3];
    integer bytes_read = 0;

    always #4 clk = ~clk;  // 125 MHz

    cpu_top dut (
        .clk(clk),
        .reset(reset),
        .cpu_enable(cpu_enable),
        .uart_rx_in(uart_rx_in),
        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .halted(halted),
        .gpio_led(gpio_led),
        .uart_tx_out(uart_tx_out),
        .uart_busy(uart_busy)
    );

    // Simulate one UART frame arriving.
    task automatic send_byte(input logic [7:0] value);
        @(negedge clk);

        uart_rx_in = 1'b0;
        #BIT_TIME_NS;

        for (int i = 0; i < 8; i++) begin
            uart_rx_in = value[i];
            #BIT_TIME_NS;
        end

        uart_rx_in = 1'b1;
        #BIT_TIME_NS;
    endtask

    // Observe the actual FIFO-consuming CPU loads.
    // This checks the byte BEFORE the FIFO pointer advances.
    always @(posedge clk) begin
        if (!reset &&
            dut.rx_read_ack &&
            dut.rx_ready) begin

            if (bytes_read >= 4)
                $fatal(1, "FAIL: Unexpected extra read");

            if (dut.rx_data !== expected[bytes_read])
                $fatal(1,
                    "FAIL: Byte %0d expected %h, got %h",
                    bytes_read,
                    expected[bytes_read],
                    dut.rx_data
                );

            $display(
                "CPU read byte %0d: %c",
                bytes_read,
                dut.rx_data
            );

            bytes_read = bytes_read + 1;
        end
    end

    initial begin
        expected[0] = 8'h41; // A
        expected[1] = 8'h42; // B
        expected[2] = 8'h43; // C
        expected[3] = 8'h44; // D

        reset = 1'b1;
        cpu_enable = 1'b0;
        uart_rx_in = 1'b1;

        repeat (4) @(negedge clk);
        reset = 1'b0;

        // CPU stays paused while bytes arrive.
        send_byte(8'h41);
        send_byte(8'h42);
        send_byte(8'h43);
        send_byte(8'h44);

        // Give the receiver time to settle.
        repeat (10) @(negedge clk);

        if (dut.rx_count !== 4)
            $fatal(1,
                "FAIL: Expected count 4, got %0d",
                dut.rx_count
            );

        if (dut.rx_data !== 8'h41)
            $fatal(1, "FAIL: Oldest byte should be A");

        if (dut.rx_overrun !== 1'b0)
            $fatal(1, "FAIL: Unexpected FIFO overrun");

        $display("FIFO successfully stored ABCD");

        // Resume CPU execution.
        @(negedge clk);
        cpu_enable = 1'b1;

        // Wait until all four loads have occurred.
        wait (bytes_read == 4);

        // Allow final GPIO store to complete.
        repeat (20) @(negedge clk);

        if (dut.rx_count !== 0)
            $fatal(1, "FAIL: FIFO should be empty");

        if (gpio_led !== 4'b0100)
            $fatal(1,
                "FAIL: Expected LEDs 0100, got %b",
                gpio_led
            );

        if (halted !== 1'b0)
            $fatal(1, "FAIL: CPU halted unexpectedly");

        $display("-------------------------------");
        $display("CPU UART FIFO BURST TEST PASSED");
        $display("-------------------------------");

        $finish;
    end

    initial begin
        #600_000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule

