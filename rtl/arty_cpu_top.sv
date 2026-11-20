`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 01:04:22 AM
// Design Name: 
// Module Name: arty_cpu_top
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



module arty_cpu_top (
    input  logic       clk,
    input  logic       btn0,


    input  logic       uart_rx_pin,
    output logic       uart_tx_pin,
    
    output logic [3:0] led
);

    logic reset;
    logic cpu_enable;
    
    logic [15:0] pc;
    logic [15:0] instruction;
    
    logic halted;
    logic uart_busy;
    
    assign reset = btn0;
    
    // 10,000 CPU state transitions per second
    clock_enable_generator #(
        .DIVISOR(125)
    ) clock_gen (
        .clk(clk),
        .reset(reset),
        .cpu_enable(cpu_enable)
    );

    cpu_top cpu_inst (
        .clk(clk),
        .reset(reset),
        .cpu_enable(cpu_enable),
        
        .uart_rx_in(uart_rx_pin),
        .uart_tx_out(uart_tx_pin),
        .uart_busy(uart_busy),
        
        .pc_out(pc),
        .instruction_out(instruction),
        .halted(halted),
        .gpio_led(led)
    );

endmodule

