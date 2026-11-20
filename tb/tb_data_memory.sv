`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2026 03:27:34 AM
// Design Name: 
// Module Name: tb_data_memory
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

module tb_data_memory;

    logic clk;
    logic write_enable;
    logic [7:0] addr;
    logic [15:0] write_data;
    logic [15:0] read_data;

    data_memory dut (
        .clk(clk),
        .write_enable(write_enable),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    // 100 MHz simulation clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Write data to a memory address
    task automatic write_mem(
        input logic [7:0] test_addr,
        input logic [15:0] test_data
    );
        begin
            @(negedge clk);
            addr = test_addr;
            write_data = test_data;
            write_enable = 1;

            @(posedge clk);
            #1;

            write_enable = 0;
        end
    endtask

    // Verify the value stored at an address
    task automatic check_mem(
        input logic [7:0] test_addr,
        input logic [15:0] expected
    );
        begin
            @(negedge clk);
            addr = test_addr;
            write_enable = 0;

            #1;

            if (read_data !== expected)
                $fatal(1,
                    "FAIL: Address=%0d Expected=%0d Got=%0d",
                    addr, expected, read_data);

            $display(
                "PASS: Address=%0d Data=%0d",
                addr, read_data);
        end
    endtask

    initial begin

        write_enable = 0;
        addr = 0;
        write_data = 0;

        // Test basic writes
        write_mem(8'd10, 16'd25);
        write_mem(8'd20, 16'd100);
        write_mem(8'd30, 16'd500);

        // Test reads
        check_mem(8'd10, 16'd25);
        check_mem(8'd20, 16'd100);
        check_mem(8'd30, 16'd500);

        // Test overwriting an address
        write_mem(8'd10, 16'd75);
        check_mem(8'd10, 16'd75);

        // Test write protection
        @(negedge clk);
        addr = 8'd20;
        write_data = 16'd999;
        write_enable = 0;

        @(posedge clk);
        #1;

        check_mem(8'd20, 16'd100);

        // Test highest valid address
        write_mem(8'd255, 16'hABCD);
        check_mem(8'd255, 16'hABCD);

        $display("ALL DATA MEMORY TESTS PASSED");
        $finish;

    end

    // Prevent simulation from running forever
    initial begin
        #10000;
        $fatal(1, "Simulation timeout");
    end

endmodule
