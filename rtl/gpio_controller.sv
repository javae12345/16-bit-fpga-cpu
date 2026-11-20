`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 04:38:53 PM
// Design Name: 
// Module Name: gpio_controller
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



module gpio_controller (
    input  logic        clk,
    input  logic        reset,
    input  logic        write_enable,
    input  logic [15:0] write_data,

    output logic [3:0]  led
);

    always_ff @(posedge clk) begin
        if (reset)
            led <= 4'b0000;

        else if (write_enable)
            led <= write_data[3:0];
    end

endmodule
