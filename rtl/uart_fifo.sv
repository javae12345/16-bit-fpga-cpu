`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 09:45:00 PM
// Design Name: 
// Module Name: uart_fifo
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



module uart_fifo #(
    parameter int DEPTH = 8
)(
    input  logic       clk,
    input  logic       reset,

    // UART receiver side
    input  logic       write_enable,
    input  logic [7:0] write_data,

    // CPU side
    input  logic       read_enable,
    output logic [7:0] read_data,

    // Status
    output logic       full,
    output logic       empty,
    output logic [$clog2(DEPTH+1)-1:0] count
);

    localparam int PTR_WIDTH = $clog2(DEPTH);

    logic [7:0] memory [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] write_ptr;
    logic [PTR_WIDTH-1:0] read_ptr;

    logic do_write;
    logic do_read;

    // Status flags
    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    // Only accept operations when permitted.
    assign do_write = write_enable && !full;
    assign do_read  = read_enable && !empty;

    // Oldest byte is available at the output.
    assign read_data = empty ? 8'h00 : memory[read_ptr];

    // FIFO storage and pointers
    always_ff @(posedge clk) begin
        if (reset) begin
            write_ptr <= '0;
            read_ptr  <= '0;
            count     <= '0;
        end
        else begin

            if (do_write) begin
                memory[write_ptr] <= write_data;

                if (write_ptr == DEPTH - 1)
                    write_ptr <= '0;
                else
                    write_ptr <= write_ptr + 1'b1;
            end

            if (do_read) begin
                if (read_ptr == DEPTH - 1)
                    read_ptr <= '0;
                else
                    read_ptr <= read_ptr + 1'b1;
            end

            // Update the number of stored bytes.
            case ({do_write, do_read})

                2'b10: count <= count + 1'b1;

                2'b01: count <= count - 1'b1;

                // Both operations or neither:
                // Count does not change.
                default: count <= count;

            endcase
        end
    end

endmodule

