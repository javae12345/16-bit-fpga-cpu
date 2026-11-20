`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_cpu_branch
// Description: BEQ taken, BEQ not taken and JMP. Loads its own program, so it
//              does not depend on what is in instruction_memory.sv. Checks the
//              exact sequence of PC values, the registers and the final PC.
//////////////////////////////////////////////////////////////////////////////////

module tb_cpu_branch;

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

    logic [15:0] expected_pc [0:6];
    logic [15:0] last_pc;
    int          pc_index;

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

        dut.imem_inst.memory[0] = 16'h520A;  // LDI R1, 10
        dut.imem_inst.memory[1] = 16'h540A;  // LDI R2, 10
        dut.imem_inst.memory[2] = 16'h8285;  // BEQ R1, R2, 5   (taken)
        dut.imem_inst.memory[3] = 16'h5663;  // LDI R3, 99      (skipped)
        dut.imem_inst.memory[4] = 16'hF000;  // HALT            (skipped)
        dut.imem_inst.memory[5] = 16'h5601;  // LDI R3, 1
        dut.imem_inst.memory[6] = 16'h82C8;  // BEQ R1, R3, 8   (not taken: 10 != 1)
        dut.imem_inst.memory[7] = 16'h9009;  // JMP 9
        dut.imem_inst.memory[8] = 16'h564D;  // LDI R3, 77      (skipped)
        dut.imem_inst.memory[9] = 16'hF000;  // HALT
    endtask

    initial begin
        // Expected program counter sequence
        expected_pc[0] = 16'd0;
        expected_pc[1] = 16'd1;
        expected_pc[2] = 16'd2;
        expected_pc[3] = 16'd5;   // BEQ taken
        expected_pc[4] = 16'd6;
        expected_pc[5] = 16'd7;   // BEQ not taken
        expected_pc[6] = 16'd9;   // JMP

        reset      = 1;
        cpu_enable = 1;
        uart_rx_in = 1;

        // Wait until the ROM's own initial block has finished, then overwrite it
        #1;
        load_program();

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        if (pc_out !== expected_pc[0])
            $fatal(1, "FAIL: initial PC incorrect");

        pc_index = 0;
        last_pc  = pc_out;

        // Follow every change of the PC until the CPU halts
        while (halted !== 1'b1) begin
            @(posedge clk);
            #1;

            if (pc_out !== last_pc) begin
                pc_index++;

                if (pc_index > 6)
                    $fatal(1, "FAIL: too many PC changes (PC=%0d)", pc_out);

                if (pc_out !== expected_pc[pc_index])
                    $fatal(1, "FAIL: PC=%0d, expected %0d",
                           pc_out, expected_pc[pc_index]);

                $display("PC advanced to %0d", pc_out);
                last_pc = pc_out;
            end
        end

        if (pc_index !== 6)
            $fatal(1, "FAIL: only %0d PC changes seen, expected 6", pc_index);

        if (dut.rf_inst.registers[1] !== 16'd10)
            $fatal(1, "FAIL: R1 incorrect");

        if (dut.rf_inst.registers[2] !== 16'd10)
            $fatal(1, "FAIL: R2 incorrect");

        // R3 must be 1: the LDI of 99 and the LDI of 77 are both skipped
        if (dut.rf_inst.registers[3] !== 16'd1)
            $fatal(1, "FAIL: R3 incorrect");

        if (pc_out !== 16'd9)
            $fatal(1, "FAIL: final PC incorrect");

        $display("--------------------------");
        $display("BRANCH AND JUMP TEST PASSED");
        $display("--------------------------");
        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "FAIL: simulation timeout");
    end

endmodule