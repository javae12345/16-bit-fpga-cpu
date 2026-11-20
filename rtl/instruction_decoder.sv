`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 05:43:03 PM
// Design Name: 
// Module Name: instruction_decoder
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




module instruction_decoder (
    input  logic [15:0] instruction,

    output logic [3:0]  opcode,
    output logic [2:0]  rd,
    output logic [2:0]  rs1,
    output logic [2:0]  rs2,

    output logic [15:0] immediate,
    output logic [7:0]  mem_addr,
    output logic        mem_addr_valid,

    output logic [15:0] branch_addr,
    output logic [15:0] jump_addr,
    output logic        jump_addr_valid
);

    assign opcode = instruction[15:12];

    // Register fields
    assign rd  = instruction[11:9];
    assign rs1 = instruction[8:6];
    assign rs2 = instruction[5:3];

    // LDI
    assign immediate = {7'b0, instruction[8:0]};

    // LD and ST
    assign mem_addr = instruction[7:0];
    assign mem_addr_valid = ~instruction[8];

    // BEQ: 6-bit absolute destination
    assign branch_addr = {10'b0, instruction[5:0]};

    // JMP: 8-bit absolute destination
    assign jump_addr = {8'b0, instruction[7:0]};

    // Upper reserved JMP bits must be zero
    assign jump_addr_valid = (instruction[11:8] == 4'b0);

endmodule


