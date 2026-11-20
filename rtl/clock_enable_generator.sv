`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 12:56:35 AM
// Design Name: 
// Module Name: clock_enable_generator
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



module clock_enable_generator #(
    parameter int DIVISOR = 125_000_000
)(
    input  logic clk,
    input  logic reset,
    output logic cpu_enable
);

    localparam int COUNTER_WIDTH =
        (DIVISOR > 1) ? $clog2(DIVISOR) : 1;

    logic [COUNTER_WIDTH-1:0] counter;

    // Generate a one-clock-wide enable pulse
    assign cpu_enable = (counter == DIVISOR - 1);

    always_ff @(posedge clk) begin
        if (reset)
            counter <= '0;
        else if (cpu_enable)
            counter <= '0;
        else
            counter <= counter + 1'b1;
    end

endmodule

