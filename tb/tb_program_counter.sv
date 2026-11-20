`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 03:19:58 PM
// Design Name: 
// Module Name: tb_program_counter
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

module tb_program_counter;

    logic clk;
    logic reset;
    logic enable;
    logic jump;
    logic [15:0] jump_addr;
    logic [15:0] pc;

    // Instantiate DUT
    program_counter dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .jump(jump),
        .jump_addr(jump_addr),
        .pc(pc)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Check expected PC value
    task automatic check_pc(
        input logic [15:0] expected
    );
        begin
            #1;

            if (pc !== expected)
                $fatal(1,
                    "FAIL: PC=%0d, Expected=%0d",
                    pc, expected);
            else
                $display("PASS: PC=%0d", pc);
        end
    endtask

    initial begin

        // Initialize inputs
        reset = 1;
        enable = 0;
        jump = 0;
        jump_addr = 0;

        // TEST 1: Reset
        @(posedge clk);
        check_pc(0);

        @(negedge clk);
        reset = 0;

        // TEST 2: Increment
        enable = 1;

        @(posedge clk);
        check_pc(1);

        @(posedge clk);
        check_pc(2);

        @(posedge clk);
        check_pc(3);

        // TEST 3: Hold value
        @(negedge clk);
        enable = 0;

        @(posedge clk);
        check_pc(3);

        // TEST 4: Jump to address 100
        @(negedge clk);
        jump = 1;
        jump_addr = 16'd100;

        @(posedge clk);
        check_pc(100);

        // TEST 5: Jump has priority over enable
        @(negedge clk);
        enable = 1;
        jump_addr = 16'd200;

        @(posedge clk);
        check_pc(200);

        // TEST 6: Reset has highest priority
        @(negedge clk);
        reset = 1;

        @(posedge clk);
        check_pc(0);

        // TEST 7: Wraparound
        @(negedge clk);
        reset = 0;
        jump = 1;
        jump_addr = 16'hFFFF;

        @(posedge clk);
        check_pc(16'hFFFF);

        @(negedge clk);
        jump = 0;
        enable = 1;

        @(posedge clk);
        check_pc(0);

        $display("ALL PROGRAM COUNTER TESTS PASSED");
        $finish;

    end

endmodule
