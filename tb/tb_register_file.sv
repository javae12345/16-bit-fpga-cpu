`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 02:59:32 PM
// Design Name: 
// Module Name: tb_register_file
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


module tb_register_file;
    // Inputs
    logic clk;
    logic reset;
    logic write_enable;

    logic [2:0] write_addr;
    logic [15:0] write_data;

    logic [2:0] read_addr1;
    logic [2:0] read_addr2;

    // Outputs
    logic [15:0] read_data1;
    logic [15:0] read_data2;
    
    register_file dut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );
        // Generate a clock with a 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;
    
    // Write a value into a register
    task automatic write_reg(
        input logic [2:0] addr,
        input logic [15:0] data
    );
        begin
            @(negedge clk);
            write_enable = 1;
            write_addr = addr;
            write_data = data;

            @(posedge clk);
            #1;

            write_enable = 0;
        end
    endtask
    
    // Check two registers simultaneously
    task automatic check_regs(
        input logic [2:0] addr1,
        input logic [2:0] addr2,
        input logic [15:0] expected1,
        input logic [15:0] expected2
    );
        begin
            read_addr1 = addr1;
            read_addr2 = addr2;

            #1;

            if (read_data1 !== expected1 ||
                read_data2 !== expected2) begin

                $fatal(1,
                    "FAIL: R%0d=%0d (expected %0d), R%0d=%0d (expected %0d)",
                    addr1, read_data1, expected1,
                    addr2, read_data2, expected2);
            end
            else begin
                $display(
                    "PASS: R%0d=%0d, R%0d=%0d",
                    addr1, read_data1,
                    addr2, read_data2);
            end
        end
    endtask
    initial begin

        // Initialize inputs
        reset = 1;
        write_enable = 0;
        write_addr = 0;
        write_data = 0;
        read_addr1 = 0;
        read_addr2 = 0;

        // Apply synchronous reset
        @(posedge clk);
        #1;
        reset = 0;

        // Check reset values
        check_regs(0, 1, 0, 0);
        check_regs(2, 3, 0, 0);
        check_regs(4, 5, 0, 0);
        check_regs(6, 7, 0, 0);

        // Write values
        write_reg(3, 25);
        write_reg(5, 100);
        write_reg(7, 500);

        // Check stored values
        check_regs(3, 5, 25, 100);
        check_regs(7, 3, 500, 25);

        // Check an untouched register
        check_regs(0, 1, 0, 0);

        // Test overwrite
        write_reg(3, 75);
        check_regs(3, 5, 75, 100);

        // Test write disabled
        @(negedge clk);
        write_enable = 0;
        write_addr = 5;
        write_data = 999;

        @(posedge clk);
        #1;

        check_regs(5, 7, 100, 500);

        $display("ALL REGISTER FILE TESTS PASSED");
        $finish;

    end
endmodule
