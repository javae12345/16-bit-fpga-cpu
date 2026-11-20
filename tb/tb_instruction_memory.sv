`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 05:20:33 PM
// Design Name: 
// Module Name: tb_instruction_memory
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


module tb_instruction_memory;
    logic [7:0] addr;
    logic [15:0] instruction;
    
    instruction_memory dut(
        .addr(addr),
        .instruction(instruction)
    );
    
    task automatic check_instruction(
        input logic [7:0] test_addr,
        input logic [15:0] expected
    );  
    begin
        addr = test_addr;
    
        #10;
        
        if(instruction !== expected)
            $fatal(1, "FAIL: Address=%0d, Expected=%h, Got=%h",
                    addr, expected, instruction);
        else
            $display("PASS: Address=%0d, Instruction=%h",
                     addr, instruction);
   end 
   endtask
   
   initial begin

    check_instruction(8'd0, 16'h1234);

    check_instruction(8'd1, 16'h5678);
    
    check_instruction(8'd2, 16'hABCD);
    
    check_instruction(8'd3, 16'hFFFF);
    
    check_instruction(8'd4, 16'h0000);
    
    check_instruction(8'd255, 16'h0000);

    $display("ALL INSTRUCTION MEMORY TESTS PASSED");
    $finish;

    end
   
endmodule
