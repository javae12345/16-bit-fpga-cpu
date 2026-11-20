`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2026 03:18:08 AM
// Design Name: 
// Module Name: data_memory
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


module data_memory (
    input  logic        clk,
    input  logic        write_enable,
    input  logic [7:0]  addr,
    input  logic [15:0] write_data,
    output logic [15:0] read_data
);

    // 256 memory locations, each 16 bits wide
    logic [15:0] memory [0:255];

    // Synchronous write
    always_ff @(posedge clk) begin
        if (write_enable)
            memory[addr] <= write_data;
    end

    // Asynchronous read
    assign read_data = memory[addr];

endmodule