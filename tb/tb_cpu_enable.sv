`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 12:49:15 AM
// Design Name: 
// Module Name: tb_cpu_enable
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




module tb_cpu_enable;

    logic clk;
    logic reset;
    logic cpu_enable;

    logic [15:0] pc_out;
    logic [15:0] instruction_out;
    logic halted;

    cpu_top dut (
        .clk(clk),
        .reset(reset),
        .cpu_enable(cpu_enable),
        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .halted(halted)
    );

    // 100 MHz simulation clock
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        cpu_enable = 0;

        // Load test program into instruction memory
        // Simulation-only initialization
        #1;
        dut.imem_inst.memory[0] = 16'h5232;
        dut.imem_inst.memory[1] = 16'h7214;
        dut.imem_inst.memory[2] = 16'h6414;
        dut.imem_inst.memory[3] = 16'hF000;

        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 0;
        cpu_enable = 1;

        // Wait for ST instruction's WRITEBACK state
        while (!(pc_out == 16'd1 &&
                 dut.control_inst.state == 2'b10))
            @(negedge clk);

        // Pause before the store is committed
        cpu_enable = 0;
        #1;

        if (dut.control_inst.mem_write !== 1'b0)
            $fatal(1, "FAIL: Memory write active while paused");

        // Wait for five system clock cycles
        repeat (5) begin
            @(posedge clk);
            #1;

            // Must stay in WRITEBACK
            if (dut.control_inst.state !== 2'b10)
                $fatal(1, "FAIL: FSM changed while paused");

            // PC must remain at address 1
            if (pc_out !== 16'd1)
                $fatal(1, "FAIL: PC changed while paused");

            if (dut.control_inst.mem_write !== 1'b0)
                $fatal(1, "FAIL: Memory write while paused");
        end

        $display("PASS: CPU remained paused");

        // Resume execution
        @(negedge clk);
        cpu_enable = 1;

        // ST should now be enabled
        #1;
        if (dut.control_inst.mem_write !== 1'b1)
            $fatal(1, "FAIL: Store not enabled after resume");

        // Commit the store on the next rising edge
        @(posedge clk);
        #1;

        if (dut.dmem_inst.memory[20] !== 16'd50)
            $fatal(1, "FAIL: Store did not complete");

        $display("PASS: Store completed after resume");

        // Allow the remaining program to execute
        wait (halted === 1'b1);
        #1;

        if (dut.rf_inst.registers[2] !== 16'd50)
            $fatal(1, "FAIL: R2 should contain 50");

        if (pc_out !== 16'd3)
            $fatal(1, "FAIL: Final PC incorrect");

        $display("-----------------------------");
        $display("CPU CLOCK ENABLE TEST PASSED");
        $display("Memory[20] = %0d",
                 dut.dmem_inst.memory[20]);
        $display("R2 = %0d",
                 dut.rf_inst.registers[2]);
        $display("PC = %0d", pc_out);
        $display("-----------------------------");

        $finish;
    end

    // Simulation timeout
    initial begin
        #2000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule

