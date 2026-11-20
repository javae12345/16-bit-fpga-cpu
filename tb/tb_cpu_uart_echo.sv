`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 09:20:52 PM
// Design Name: 
// Module Name: tb_cpu_uart_echo
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

module tb_cpu_uart_echo;

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

    // Simulate computer transmitting a byte
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

    // Decode the byte transmitted by our CPU
    task automatic check_transmitted_byte(
        input logic [7:0] expected
    );
        logic [7:0] received;

        // Detect falling edge of TX start bit
        @(negedge uart_tx_out);

        #(BIT_TIME_NS / 2);

        if (uart_tx_out !== 1'b0)
            $fatal(1, "FAIL: Invalid TX start bit");

        for (int i = 0; i < 8; i++) begin
            #BIT_TIME_NS;
            received[i] = uart_tx_out;
        end

        #BIT_TIME_NS;

        if (uart_tx_out !== 1'b1)
            $fatal(1, "FAIL: Invalid TX stop bit");

        if (received !== expected)
            $fatal(1,
                "FAIL: Expected %h, received %h",
                expected, received);

        $display("Echo received: 0x%h", received);
    endtask

    task automatic test_echo(
        input logic [7:0] character
    );
        fork
            send_byte(character);
            check_transmitted_byte(character);
        join

        // Check the LED result
        if (gpio_led !== character[3:0])
            $fatal(1, "FAIL: Incorrect LED output");
    endtask

    initial begin
        reset = 1'b1;
        cpu_enable = 1'b1;
        uart_rx_in = 1'b1;

        repeat (4) @(negedge clk);
        reset = 1'b0;

        // Give CPU time to enter polling loop
        repeat (40) @(negedge clk);

        test_echo(8'h41);  // A

        repeat (40) @(negedge clk);

        test_echo(8'h42);  // B

        if (halted !== 1'b0)
            $fatal(1, "FAIL: CPU unexpectedly halted");

        $display("-------------------------");
        $display("CPU UART ECHO TEST PASSED");
        $display("-------------------------");

        $finish;
    end

    initial begin
        #1_000_000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule
