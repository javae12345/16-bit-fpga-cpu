`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_cpu_gpio
// Description: ALU result written to the memory-mapped LEDs at address 255.
//              Loads its own program, so it does not depend on what is in
//              instruction_memory.sv.
//////////////////////////////////////////////////////////////////////////////////

module tb_cpu_gpio;

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

    // 100 MHz simulation clock
    always #5 clk = ~clk;

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

        dut.imem_inst.memory[0] = 16'h5205;  // LDI R1, 5
        dut.imem_inst.memory[1] = 16'h5407;  // LDI R2, 7
        dut.imem_inst.memory[2] = 16'h0650;  // ADD R3, R1, R2
        dut.imem_inst.memory[3] = 16'h76FF;  // ST  R3, [255]   (LEDs)
        dut.imem_inst.memory[4] = 16'hF000;  // HALT
    endtask

    initial begin
        reset      = 1;
        cpu_enable = 1;
        uart_rx_in = 1;

        // Wait until the ROM's own initial block has finished, then overwrite it
        #1;
        load_program();

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // LEDs must be off after reset
        if (gpio_led !== 4'b0000)
            $fatal(1, "FAIL: GPIO reset incorrect");

        wait (halted === 1'b1);
        #1;

        if (dut.rf_inst.registers[1] !== 16'd5)
            $fatal(1, "FAIL: R1 incorrect");

        if (dut.rf_inst.registers[2] !== 16'd7)
            $fatal(1, "FAIL: R2 incorrect");

        if (dut.rf_inst.registers[3] !== 16'd12)
            $fatal(1, "FAIL: ALU result incorrect");

        // 12 = 1100; only the low four bits reach the LEDs
        if (gpio_led !== 4'b1100)
            $fatal(1, "FAIL: GPIO should equal 1100");

        if (pc_out !== 16'd4)
            $fatal(1, "FAIL: final PC incorrect");

        $display("----------------------------");
        $display("CPU GPIO TEST PASSED");
        $display("----------------------------");
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "FAIL: simulation timeout");
    end

endmodule