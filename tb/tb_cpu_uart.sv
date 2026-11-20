`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_cpu_uart
// Description: The CPU transmits one byte (ASCII 'A') by storing to address 254.
//              The testbench decodes the serial line bit by bit. Loads its own
//              program, so it does not depend on what is in instruction_memory.sv.
//////////////////////////////////////////////////////////////////////////////////

module tb_cpu_uart;

    localparam int CLKS_PER_BIT = 1085;
    localparam int BIT_TIME_NS  = CLKS_PER_BIT * 8;   // 8 ns clock period

    logic clk = 0;
    logic reset;
    logic cpu_enable;
    logic uart_rx_in;

    logic [15:0] pc_out;
    logic [15:0] instruction_out;
    logic        halted;
    logic [3:0]  gpio_led;
    logic        uart_tx_out;
    logic        uart_busy;

    logic [7:0] expected_byte = 8'h41;

    // 125 MHz system clock
    always #4 clk = ~clk;

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

    task automatic load_program;
        for (int i = 0; i < 256; i++)
            dut.imem_inst.memory[i] = 16'h0000;

        dut.imem_inst.memory[0] = 16'h5241;  // LDI R1, 65   ('A')
        dut.imem_inst.memory[1] = 16'h72FE;  // ST  R1, [254] (start UART transmit)
        dut.imem_inst.memory[2] = 16'hF000;  // HALT
    endtask

    initial begin
        reset      = 1;
        cpu_enable = 1;
        uart_rx_in = 1;

        // Wait until the ROM's own initial block has finished, then overwrite it
        #1;
        load_program();

        repeat (3) @(negedge clk);
        reset = 0;

        // Wait for the UART start bit
        @(negedge uart_tx_out);

        if (uart_busy !== 1'b1)
            $fatal(1, "FAIL: UART not busy");

        // Sample in the middle of the start bit
        #(BIT_TIME_NS / 2);

        if (uart_tx_out !== 1'b0)
            $fatal(1, "FAIL: start bit incorrect");

        // Eight data bits, LSB first
        for (int i = 0; i < 8; i++) begin
            #BIT_TIME_NS;

            if (uart_tx_out !== expected_byte[i])
                $fatal(1, "FAIL: UART bit %0d incorrect", i);
        end

        // Stop bit
        #BIT_TIME_NS;

        if (uart_tx_out !== 1'b1)
            $fatal(1, "FAIL: stop bit incorrect");

        // Wait for the transmitter to finish
        wait (uart_busy === 1'b0);

        if (halted !== 1'b1)
            $fatal(1, "FAIL: CPU did not halt");

        if (dut.rf_inst.registers[1] !== 16'd65)
            $fatal(1, "FAIL: R1 incorrect");

        $display("---------------------------");
        $display("CPU UART TEST PASSED");
        $display("Transmitted ASCII A (0x41)");
        $display("---------------------------");
        $finish;
    end

    initial begin
        #150_000;
        $fatal(1, "FAIL: simulation timeout");
    end

endmodule