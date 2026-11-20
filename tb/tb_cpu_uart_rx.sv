`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_cpu_uart_rx
// Description: A byte arrives while the CPU is paused. The FIFO must hold it.
//              The CPU is then enabled, reads the status word (address 253) and
//              the data (address 252), and writes the data to the LEDs.
//              Loads its own program, so it does not depend on what is in
//              instruction_memory.sv.
//////////////////////////////////////////////////////////////////////////////////

module tb_cpu_uart_rx;

    localparam int BIT_TIME_NS = 8680;   // 1085 clocks of 8 ns

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

        dut.imem_inst.memory[0] = 16'h62FD;  // LD R1, [253]  RX status
        dut.imem_inst.memory[1] = 16'h64FC;  // LD R2, [252]  RX data (pops the FIFO)
        dut.imem_inst.memory[2] = 16'h74FF;  // ST R2, [255]  LEDs
        dut.imem_inst.memory[3] = 16'hF000;  // HALT
    endtask

    // Simulate the computer transmitting one byte
    task automatic send_byte(input logic [7:0] value);
        @(negedge clk);

        // Start bit
        uart_rx_in = 1'b0;
        #BIT_TIME_NS;

        // Data bits, LSB first
        for (int i = 0; i < 8; i++) begin
            uart_rx_in = value[i];
            #BIT_TIME_NS;
        end

        // Stop bit
        uart_rx_in = 1'b1;
        #BIT_TIME_NS;

        // Additional idle time
        #BIT_TIME_NS;
    endtask

    initial begin
        reset      = 1'b1;
        cpu_enable = 1'b0;
        uart_rx_in = 1'b1;

        // Wait until the ROM's own initial block has finished, then overwrite it
        #1;
        load_program();

        repeat (4) @(negedge clk);
        reset = 1'b0;

        // The computer sends ASCII 'A' while the CPU is paused
        send_byte(8'h41);

        // The FIFO must have kept the byte
        if (dut.rx_ready !== 1'b1)
            $fatal(1, "FAIL: RX ready not set");

        if (dut.rx_count !== 4'd1)
            $fatal(1, "FAIL: RX count should be 1");

        if (dut.rx_data !== 8'h41)
            $fatal(1, "FAIL: RX data incorrect");

        if (dut.rx_overrun !== 1'b0)
            $fatal(1, "FAIL: unexpected overrun");

        $display("UART byte received and stored");

        // Let the CPU run
        @(negedge clk);
        cpu_enable = 1'b1;

        wait (halted === 1'b1);
        #1;

        // Status word = {10'b0, rx_count, rx_overrun, rx_ready}
        // With one byte queued: count = 1 -> bits [5:2] = 0001, ready -> bit 0
        // = 0b000101 = 0x0005
        if (dut.rf_inst.registers[1] !== 16'h0005)
            $fatal(1, "FAIL: UART status incorrect (got %h)",
                   dut.rf_inst.registers[1]);

        // R2 received ASCII 'A'
        if (dut.rf_inst.registers[2] !== 16'h0041)
            $fatal(1, "FAIL: UART data not loaded");

        // Reading address 252 must have removed the byte
        if (dut.rx_ready !== 1'b0 || dut.rx_count !== 4'd0)
            $fatal(1, "FAIL: byte not removed from the FIFO");

        // Low four bits of 0x41 = 0001
        if (gpio_led !== 4'b0001)
            $fatal(1, "FAIL: GPIO incorrect");

        if (pc_out !== 16'd3)
            $fatal(1, "FAIL: PC incorrect");

        $display("----------------------------");
        $display("CPU UART RX TEST PASSED");
        $display("----------------------------");
        $finish;
    end

    initial begin
        #200_000;
        $fatal(1, "FAIL: simulation timeout");
    end

endmodule