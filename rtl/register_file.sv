`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 02:54:23 PM
// Design Name: 
// Module Name: register_file
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


module register_file(
    input logic clk,
    input logic reset,
    input logic write_enable,
    input logic [2:0] write_addr,
    input logic [15:0] write_data,
    input logic [2:0] read_addr1,
    input logic [2:0] read_addr2,
    
    output logic [15:0] read_data1,
    output logic [15:0] read_data2
    );
    
    logic [15:0] registers [0:7];
    
    int i;
    
    always_ff @(posedge clk) begin
        if(reset) begin
            for (i = 0; i < 8; i = i+1)
                registers[i] <= 16'b0;
            end
            else if (write_enable) begin
                registers[write_addr] <= write_data;
            end
         end
         assign read_data1 = registers[read_addr1];
         assign read_data2 = registers[read_addr2];
endmodule
