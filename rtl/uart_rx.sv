`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 06:40:49 PM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx #(
    parameter int CLK_FREQ  = 125_000_000,
    parameter int BAUD_RATE = 115_200
)(
    input  logic       clk,
    input  logic       reset,
    input  logic       rx,

    output logic [7:0] data_out,
    output logic       data_valid
);

    localparam int CLKS_PER_BIT =
        CLK_FREQ / BAUD_RATE;

    localparam int HALF_BIT =
        CLKS_PER_BIT / 2;

    localparam int COUNT_WIDTH =
        $clog2(CLKS_PER_BIT + 1);

    typedef enum logic [1:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    } state_t;

    state_t state;

    logic rx_meta;
    logic rx_sync;

    logic [COUNT_WIDTH-1:0] baud_count;
    logic [2:0] bit_index;
    logic [7:0] data_buffer;

    // Synchronize the asynchronous RX input
    always_ff @(posedge clk) begin
        if (reset) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end
        else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    // UART receiver FSM
    always_ff @(posedge clk) begin
        if (reset) begin
            state       <= IDLE;
            baud_count  <= '0;
            bit_index   <= '0;
            data_buffer <= '0;
            data_out    <= '0;
            data_valid  <= 1'b0;
        end
        else begin
            // Default: data_valid is a one-clock pulse
            data_valid <= 1'b0;

            case (state)

                IDLE: begin
                    baud_count <= '0;
                    bit_index  <= '0;

                    if (rx_sync == 1'b0)
                        state <= START_BIT;
                end

                START_BIT: begin
                    // Verify the start bit near its middle
                    if (baud_count == HALF_BIT - 1) begin
                        baud_count <= '0;

                        if (rx_sync == 1'b0)
                            state <= DATA_BITS;
                        else
                            state <= IDLE;
                    end
                    else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                DATA_BITS: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= '0;

                        data_buffer[bit_index] <= rx_sync;

                        if (bit_index == 3'd7)
                            state <= STOP_BIT;
                        else
                            bit_index <= bit_index + 1'b1;
                    end
                    else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                STOP_BIT: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= '0;
                        state <= IDLE;

                        // Accept the byte only with a valid stop bit
                        if (rx_sync == 1'b1) begin
                            data_out   <= data_buffer;
                            data_valid <= 1'b1;
                        end
                    end
                    else begin
                        baud_count <= baud_count + 1'b1;
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule

