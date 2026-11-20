`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 02:25:30 PM
// Design Name: 
// Module Name: tb_alu
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



module tb_alu;

    logic [15:0] a;
    logic [15:0] b;
    logic [2:0]  alu_op;

    logic [15:0] result;
    logic        zero;

    // Device Under Test (DUT)
    alu dut (
        .a(a),
        .b(b),
        .alu_op(alu_op),
        .result(result),
        .zero(zero)
    );

    // Check the ALU against an expected result
    task automatic check(
        input logic [15:0] test_a,
        input logic [15:0] test_b,
        input logic [2:0]  test_op,
        input logic [15:0] expected
    );
        begin
            a = test_a;
            b = test_b;
            alu_op = test_op;

            #10;

            if (result !== expected ||
                zero !== (expected == 16'h0000)) begin

                $error("FAIL: A=%d B=%d OP=%b RESULT=%d EXPECTED=%d",
                       a, b, alu_op, result, expected);
            end
            else begin
                $display("PASS: A=%d B=%d OP=%b RESULT=%d ZERO=%b",
                         a, b, alu_op, result, zero);
            end
        end
    endtask

    initial begin
        // ADD
        check(16'd7, 16'd5, 3'b000, 16'd12);

        // SUB
        check(16'd15, 16'd6, 3'b001, 16'd9);

        // AND
        check(16'h00FF, 16'h0F0F, 3'b010, 16'h000F);

        // OR
        check(16'h00FF, 16'h0F0F, 3'b011, 16'h0FFF);

        // XOR
        check(16'h00FF, 16'h0F0F, 3'b100, 16'h0FF0);

        // Zero flag
        check(16'd5, 16'd5, 3'b001, 16'd0);

        // 16-bit overflow / wraparound
        check(16'hFFFF, 16'd1, 3'b000, 16'h0000);

        // 16-bit subtraction underflow
        check(16'd0, 16'd1, 3'b001, 16'hFFFF);

        // Invalid operation uses default output
        check(16'd10, 16'd20, 3'b111, 16'd0);

        $display("ALU TESTBENCH COMPLETED");
        $finish;
    end

endmodule
