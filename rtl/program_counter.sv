`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 03:17:55 PM
// Design Name: 
// Module Name: program_counter
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


module program_counter(
    input  logic        clk,
    input  logic        reset,
    input  logic        enable,
    input  logic        jump,
    input  logic [15:0] jump_addr,

    output logic [15:0] pc
);

    always_ff @(posedge clk) begin
        if (reset)
            pc <= 16'd0;

        else if (jump)
            pc <= jump_addr;

        else if (enable)
            pc <= pc + 16'd1;

        // Otherwise, PC holds its value
    end

endmodule
