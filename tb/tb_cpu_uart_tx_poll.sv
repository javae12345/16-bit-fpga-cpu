
`timescale 1ns / 1ps

module tb_cpu_uart_tx_poll;

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

    integer received_count = 0;

    always #4 clk = ~clk; // 125 MHz

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

    // Computer sends one UART byte
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

    // Monitor every byte transmitted by the CPU
    initial begin : tx_monitor
        logic [7:0] decoded;

        expected[0] = 8'h41;
        expected[1] = 8'h42;
        expected[2] = 8'h43;
        expected[3] = 8'h44;

        wait (reset === 1'b0);

        for (int j = 0; j < 4; j++) begin

            // Wait for TX start bit
            @(negedge uart_tx_out);

            // Sample middle of start bit
            #(BIT_TIME_NS / 2);

            if (uart_tx_out !== 1'b0)
                $fatal(1, "FAIL: Invalid start bit");

            // Sample data bits
            for (int i = 0; i < 8; i++) begin
                #BIT_TIME_NS;
                decoded[i] = uart_tx_out;
            end

            // Sample stop bit
            #BIT_TIME_NS;

            if (uart_tx_out !== 1'b1)
                $fatal(1, "FAIL: Invalid stop bit");

            if (decoded !== expected[j])
                $fatal(1,
                    "FAIL: Byte %0d expected %h, got %h",
                    j, expected[j], decoded);

            $display("CPU transmitted: %c", decoded);
            received_count++;
        end
    end

    initial begin
        reset = 1'b1;
        cpu_enable = 1'b0;
        uart_rx_in = 1'b1;

        repeat (4) @(negedge clk);
        reset = 1'b0;

        // Fill FIFO while CPU is paused
        send_byte(8'h41);
        send_byte(8'h42);
        send_byte(8'h43);
        send_byte(8'h44);

        repeat (10) @(negedge clk);

        if (dut.rx_count !== 4)
            $fatal(1, "FAIL: FIFO count should be 4");

        if (dut.rx_overrun !== 1'b0)
            $fatal(1, "FAIL: Unexpected RX overrun");

        $display("RX FIFO contains ABCD");

        // Resume CPU at full speed
        @(negedge clk);
        cpu_enable = 1'b1;

        // Wait until all four characters have been echoed
        wait (received_count == 4);

        // Allow final instruction to finish
        repeat (30) @(negedge clk);

        if (dut.rx_count !== 0)
            $fatal(1, "FAIL: FIFO not empty");

        if (gpio_led !== 4'b0100)
            $fatal(1, "FAIL: Final LED output incorrect");

        if (halted !== 1'b0)
            $fatal(1, "FAIL: CPU halted unexpectedly");

        $display("--------------------------------");
        $display("CPU UART TX POLLING TEST PASSED");
        $display("--------------------------------");

        $finish;
    end

    // Timeout
    initial begin
        #1_500_000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule
