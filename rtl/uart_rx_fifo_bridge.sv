`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 10:08:04 PM
// Design Name: 
// Module Name: uart_rx_fifo_bridge
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


module uart_rx_fifo_bridge (
    input  logic        clk,
    input  logic        reset,

    // UART receiver inputs
    input  logic [7:0]  rx_byte,
    input  logic        data_valid,

    // CPU input: completed load from address 252
    input  logic        read_ack,

    // CPU outputs
    output logic [7:0]  rx_data,
    output logic        rx_ready,
    output logic        rx_overrun,
    output logic [3:0]  rx_count
);

    logic fifo_full;
    logic fifo_empty;
    logic fifo_write;
    logic fifo_read;

    // New UART bytes enter the FIFO.
    assign fifo_write = data_valid;

    // Only remove a byte if the CPU reads address 252.
    assign fifo_read = read_ack;

    uart_fifo #(
        .DEPTH(8)
    ) fifo_inst (
        .clk(clk),
        .reset(reset),

        .write_enable(fifo_write),
        .write_data(rx_byte),

        .read_enable(fifo_read),
        .read_data(rx_data),

        .full(fifo_full),
        .empty(fifo_empty),
        .count(rx_count)
    );

    // Data is available whenever FIFO is not empty.
    assign rx_ready = !fifo_empty;

    // Remember if incoming data was dropped.
    always_ff @(posedge clk) begin
        if (reset)
            rx_overrun <= 1'b0;
        else begin
            // Reading data acknowledges an earlier overrun.
            if (read_ack)
                rx_overrun <= 1'b0;

            // New overrun takes priority.
            if (data_valid && fifo_full)
                rx_overrun <= 1'b1;
        end
    end

endmodule
