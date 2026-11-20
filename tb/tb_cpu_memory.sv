`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_cpu_memory
// Description: Store then load through data RAM. Loads its own program, so it
//              does not depend on what is in instruction_memory.sv.
//////////////////////////////////////////////////////////////////////////////////

module tb_cpu_memory;

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
        for (int i = 0; i < 256; i++) begin
            dut.imem_inst.memory[i] = 16'h0000;
            dut.dmem_inst.memory[i] = 16'h0000;
        end

        dut.imem_inst.memory[0] = 16'h5232;  // LDI R1, 50
        dut.imem_inst.memory[1] = 16'h7214;  // ST  R1, [20]
        dut.imem_inst.memory[2] = 16'h6414;  // LD  R2, [20]
        dut.imem_inst.memory[3] = 16'hF000;  // HALT
    endtask

    initial begin
        reset      = 1;
        cpu_enable = 1;
        uart_rx_in = 1;

        // Wait until the memories' own initial blocks have finished
        #1;
        load_program();

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        wait (halted === 1'b1);
        #1;

        if (dut.rf_inst.registers[1] !== 16'd50)
            $fatal(1, "FAIL: R1 should contain 50");

        if (dut.dmem_inst.memory[20] !== 16'd50)
            $fatal(1, "FAIL: Memory[20] should contain 50");

        if (dut.rf_inst.registers[2] !== 16'd50)
            $fatal(1, "FAIL: R2 should contain 50");

        if (pc_out !== 16'd3)
            $fatal(1, "FAIL: PC should be 3");

        $display("-----------------------------");
        $display("CPU MEMORY TEST PASSED");
        $display("-----------------------------");
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "FAIL: simulation timeout");
    end

endmodule