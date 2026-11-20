`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 05:53:37 PM
// Design Name: 
// Module Name: tb_instruction_decoder
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


module tb_instruction_decoder;
    logic [15:0] instruction;
    logic [15:0] immediate;
     logic [3:0] opcode;
     logic [2:0] rd;
     logic [2:0] rs1;
     logic [2:0] rs2;

    instruction_decoder dut(
    .instruction(instruction),
    .immediate(immediate),
    .opcode(opcode),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2)
    
    );
    
    task automatic check(
        input logic [15:0] test_instruction,
        input logic [3:0] expected_opcode,
        input logic [2:0] expected_rd,
        input logic [2:0] expected_rs1,
        input logic [2:0] expected_rs2
    );
    begin
        instruction = test_instruction;
    
        #10;
        if (opcode !== expected_opcode ||
            rd     !== expected_rd ||
            rs1    !== expected_rs1 ||
            rs2    !== expected_rs2)
        begin
            $fatal(1, "FAIL: Instruction=%h", instruction);
        end
        else begin
            $display("PASS: Instruction=%h", instruction);
        end
   end     
   endtask
   
   initial begin

    check(16'h0650, 4'd0, 3'd3, 3'd1, 3'd2);
    check(16'h1650, 4'd1, 3'd3, 3'd1, 3'd2);
    check(16'h4650, 4'd4, 3'd3, 3'd1, 3'd2);
    instruction = 16'h5207;
#10;

if (opcode !== 4'h5 ||
    rd !== 3'd1 ||
    immediate !== 16'd7)
    $fatal(1, "LDI decoder test failed");

$display("PASS: LDI decoder");
    $display("ALL INSTRUCTION DECODER TESTS PASSED");
    $finish;
    end
    
endmodule
