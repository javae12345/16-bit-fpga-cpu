`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 03:27:23 PM
// Design Name: 
// Module Name: instruction_memory
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


module instruction_memory(
    input logic [7:0] addr,
    output logic [15:0] instruction
    );
    
    logic [15:0] memory [255:0];
    
    
    initial begin
        integer i;
        for(i = 0; i < 256; i = i + 1) begin
            memory[i] = 16'b0;
        end

        memory[0]  = 16'h5000; // LDI R0, 0
        memory[1]  = 16'h5601; // LDI R3, 1
        
        // WAIT_RX:
        memory[2]  = 16'h62FD; // LD  R1, [253]   RX status
        memory[3]  = 16'h2258; // AND R1, R1, R3  Test rx_ready
        memory[4]  = 16'h8202; // BEQ R1, R0, 2   Wait for data
        
        memory[5]  = 16'h64FC; // LD  R2, [252]   Read character
        
        // WAIT_TX:
        memory[6]  = 16'h68FB; // LD  R4, [251]   TX status
        memory[7]  = 16'h2918; // AND R4, R4, R3  Test tx_ready
        memory[8]  = 16'h8806; // BEQ R4, R0, 6   Wait until idle
        
        memory[9]  = 16'h74FE; // ST  R2, [254]   Send character
        memory[10] = 16'h74FF; // ST  R2, [255]   Display on LEDs
        memory[11] = 16'h9002; // JMP 2           Receive next

    end
    
    assign instruction = memory[addr];
    

endmodule
