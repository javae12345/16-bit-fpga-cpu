`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 01:00:42 AM
// Design Name: 
// Module Name: tb_clock_enable_generator
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




module tb_clock_enable_generator;

    logic clk;
    logic reset;
    logic cpu_enable;

    int pulse_count;

    clock_enable_generator #(
        .DIVISOR(4)
    ) dut (
        .clk(clk),
        .reset(reset),
        .cpu_enable(cpu_enable)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        pulse_count = 0;

        // Initialize counter
        repeat (2) @(posedge clk);

        @(negedge clk);
        reset = 0;

        // Check 12 clock cycles
        for (int i = 0; i < 12; i++) begin

            // Sample enable before the active edge
            @(negedge clk);

            if (cpu_enable === 1'b1)
                pulse_count++;

            // Expect a pulse once every 4 cycles
            if (cpu_enable !== (i % 4 == 2))
                $fatal(1,
                    "FAIL: Cycle=%0d Enable=%b",
                    i, cpu_enable);
        end

        if (pulse_count !== 3)
            $fatal(1, "FAIL: Expected 3 pulses");

        $display("CLOCK ENABLE TEST PASSED");
        $display("Pulse count = %0d", pulse_count);

        $finish;
    end

endmodule

