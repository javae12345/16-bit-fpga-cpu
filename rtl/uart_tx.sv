`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2026 05:31:19 PM
// Design Name: 
// Module Name: uart_tx
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



module uart_tx #(
    parameter int CLK_FREQ = 125_000_000,
    parameter int BAUD_RATE = 115_200
)(
    input  logic       clk,
    input  logic       reset,
    input  logic       start,
    input  logic [7:0] data_in,

    output logic       tx,
    output logic       busy
);

    localparam int CLKS_PER_BIT =
        CLK_FREQ / BAUD_RATE;

    localparam int COUNT_WIDTH =
        $clog2(CLKS_PER_BIT + 1);

    typedef enum logic [1:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    } state_t;

    state_t state;

    logic [COUNT_WIDTH-1:0] baud_count;
    logic [2:0] bit_index;
    logic [7:0] data_buffer;

    always_ff @(posedge clk) begin
        if (reset) begin
            state       <= IDLE;
            baud_count  <= '0;
            bit_index   <= '0;
            data_buffer <= '0;
        end
        else begin
            case (state)

                IDLE: begin
                    baud_count <= '0;
                    bit_index  <= '0;

                    if (start) begin
                        data_buffer <= data_in;
                        state <= START_BIT;
                    end
                end

                START_BIT: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= '0;
                        state <= DATA_BITS;
                    end
                    else
                        baud_count <= baud_count + 1'b1;
                end

                DATA_BITS: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= '0;

                        if (bit_index == 3'd7)
                            state <= STOP_BIT;
                        else
                            bit_index <= bit_index + 1'b1;
                    end
                    else
                        baud_count <= baud_count + 1'b1;
                end

                STOP_BIT: begin
                    if (baud_count == CLKS_PER_BIT - 1) begin
                        baud_count <= '0;
                        state <= IDLE;
                    end
                    else
                        baud_count <= baud_count + 1'b1;
                end

                default: state <= IDLE;
            endcase
        end
    end

    always_comb begin
        tx = 1'b1;

        case (state)
            START_BIT: tx = 1'b0;
            DATA_BITS: tx = data_buffer[bit_index];
            default:   tx = 1'b1;
        endcase
    end

    assign busy = (state != IDLE);

endmodule

