
`timescale 1ns / 1ps

module tb_cpu_uart_poll;

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

    task automatic send_byte(input logic [7:0] value);
        @(negedge clk);

        uart_rx_in = 1'b0; // Start bit
        #BIT_TIME_NS;

        for (int i = 0; i < 8; i++) begin
            uart_rx_in = value[i];
            #BIT_TIME_NS;
        end

        uart_rx_in = 1'b1; // Stop bit
        #BIT_TIME_NS;
    endtask

    initial begin
        reset = 1'b1;
        cpu_enable = 1'b1;
        uart_rx_in = 1'b1;

        repeat (4) @(negedge clk);
        reset = 1'b0;

        // Let the CPU enter the polling loop.
        repeat (40) @(negedge clk);

        if (gpio_led !== 4'b0000)
            $fatal(1, "FAIL: LEDs changed before receiving");

        // Send A = 0x41
        send_byte(8'h41);

        wait (gpio_led === 4'b0001);
        $display("A received: LEDs = %b", gpio_led);

        // Allow the CPU to consume the byte.
        repeat (30) @(negedge clk);

        if (dut.rx_ready !== 1'b0)
            $fatal(1, "FAIL: First byte not acknowledged");

        // Send B = 0x42
        send_byte(8'h42);

        wait (gpio_led === 4'b0010);
        $display("B received: LEDs = %b", gpio_led);

        repeat (30) @(negedge clk);

        if (dut.rx_ready !== 1'b0)
            $fatal(1, "FAIL: Second byte not acknowledged");

        if (halted !== 1'b0)
            $fatal(1, "FAIL: CPU halted unexpectedly");

        $display("----------------------------");
        $display("CPU UART POLLING TEST PASSED");
        $display("----------------------------");

        $finish;
    end

    initial begin
        #300_000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule
