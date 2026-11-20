`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 09:54:57 PM
// Design Name: 
// Module Name: tb_uart_fifo
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




module tb_uart_fifo;

    logic clk = 0;
    logic reset;

    logic write_enable;
    logic [7:0] write_data;

    logic read_enable;
    logic [7:0] read_data;

    logic full;
    logic empty;
    logic [3:0] count;

    always #5 clk = ~clk;

    uart_fifo #(
        .DEPTH(8)
    ) dut (
        .clk(clk),
        .reset(reset),
        .write_enable(write_enable),
        .write_data(write_data),
        .read_enable(read_enable),
        .read_data(read_data),
        .full(full),
        .empty(empty),
        .count(count)
    );

    // Write one byte to the FIFO
    task automatic push(input logic [7:0] value);
        @(negedge clk);
        write_data   = value;
        write_enable = 1'b1;
        read_enable  = 1'b0;

        @(posedge clk);
        #1;
        $display("PUSH: %h, count = %0d",
                 value, count);
    endtask

    // Read and verify the oldest byte
    task automatic pop(input logic [7:0] expected);
        @(negedge clk);
        write_enable = 1'b0;
        read_enable  = 1'b1;

        if (empty)
            $fatal(1, "FAIL: FIFO unexpectedly empty");

        if (read_data !== expected)
            $fatal(1,
                "FAIL: Expected %h, got %h",
                expected, read_data);

        @(posedge clk);
        #1;
        $display("POP:  %h, count = %0d",
                 expected, count);
    endtask

    initial begin
        reset = 1'b1;
        write_enable = 1'b0;
        read_enable = 1'b0;
        write_data = 8'h00;

        repeat (3) @(negedge clk);
        reset = 1'b0;

        // TEST 1: Empty FIFO
        if (!empty || count != 0)
            $fatal(1, "FAIL: FIFO should be empty");

        // TEST 2: Write A, B, C
        push(8'h41);
        push(8'h42);
        push(8'h43);

        if (count !== 3)
            $fatal(1, "FAIL: Count should be 3");

        // Read A, B, C in order
        pop(8'h41);
        pop(8'h42);
        pop(8'h43);

        if (!empty || count != 0)
            $fatal(1, "FAIL: FIFO should be empty");

        $display("TEST 1-2 PASSED");

        // TEST 3: Fill FIFO to capacity
        for (int i = 0; i < 8; i++)
            push(8'h50 + i);

        if (!full || count != 8)
            $fatal(1, "FAIL: FIFO should be full");

        // TEST 4: Write while full must be rejected
        push(8'hFF);

        if (!full || count != 8)
            $fatal(1, "FAIL: FIFO overflow handling");

        // Remove first three values
        pop(8'h50);
        pop(8'h51);
        pop(8'h52);

        // TEST 5: Pointer wraparound
        push(8'h60);
        push(8'h61);
        push(8'h62);

        if (!full)
            $fatal(1, "FAIL: FIFO should be full");

        // Verify remaining order
        pop(8'h53);
        pop(8'h54);
        pop(8'h55);
        pop(8'h56);
        pop(8'h57);
        pop(8'h60);
        pop(8'h61);
        pop(8'h62);

        if (!empty)
            $fatal(1, "FAIL: FIFO should be empty");

        $display("TEST 3-5 PASSED");

        // TEST 6: Simultaneous read and write
        push(8'hA0);
        push(8'hA1);

        @(negedge clk);
        write_enable = 1'b1;
        write_data   = 8'hA2;
        read_enable  = 1'b1;

        if (read_data !== 8'hA0)
            $fatal(1, "FAIL: Simultaneous read data");

        @(posedge clk);
        #1;

        if (count !== 2)
            $fatal(1, "FAIL: Simultaneous count");

        pop(8'hA1);
        pop(8'hA2);

        if (!empty)
            $fatal(1, "FAIL: FIFO should be empty");

        $display("----------------------------");
        $display("UART FIFO TEST PASSED");
        $display("----------------------------");

        $finish;
    end

    initial begin
        #5000;
        $fatal(1, "FAIL: Simulation timeout");
    end

endmodule
