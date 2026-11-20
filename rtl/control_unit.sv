`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 06:17:24 PM
// Design Name: 
// Module Name: control_unit
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




module control_unit (
    input  logic       clk,
    input  logic       reset,
    input  logic [3:0] opcode,

    input  logic       mem_addr_valid,
    input  logic       jump_addr_valid,
    input  logic       branch_equal,
    input logic        cpu_enable,

    output logic       pc_enable,
    output logic       pc_jump,
    output logic       reg_write,
    output logic       mem_write,
    output logic [2:0] alu_op,
    output logic [1:0] writeback_sel,
    output logic       halted
);

    typedef enum logic [1:0] {
        FETCH     = 2'b00,
        EXECUTE   = 2'b01,
        WRITEBACK = 2'b10,
        HALTED    = 2'b11
    } state_t;

    state_t state, next_state;

    // State register
    always_ff @(posedge clk) begin
        if (reset)
            state <= FETCH;
        else if (cpu_enable)
            state <= next_state;
    end

    // Next-state logic
    always_comb begin
        next_state = state;

        case (state)
            FETCH: begin
                next_state = EXECUTE;
            end

            EXECUTE: begin
                if (opcode <= 4'h9) begin
                    if ((opcode == 4'h6 ||
                         opcode == 4'h7) &&
                         !mem_addr_valid)
                        next_state = HALTED;

                    else if (opcode == 4'h9 &&
                             !jump_addr_valid)
                        next_state = HALTED;

                    else
                        next_state = WRITEBACK;
                end
                else begin
                    next_state = HALTED;
                end
            end

            WRITEBACK: begin
                next_state = FETCH;
            end

            HALTED: begin
                next_state = HALTED;
            end

            default: begin
                next_state = FETCH;
            end
        endcase
    end

    // Output control signals
    always_comb begin
        pc_enable     = 1'b0;
        pc_jump       = 1'b0;
        reg_write     = 1'b0;
        mem_write     = 1'b0;
        alu_op        = 3'b000;
        writeback_sel = 2'b00;
        halted        = 1'b0;

        case (state)

            EXECUTE: begin
                if (opcode <= 4'h4)
                    alu_op = opcode[2:0];
            end

            WRITEBACK: begin
                if (!reset) begin

                    case (opcode)

                        // Arithmetic and logic
                        4'h0, 4'h1, 4'h2,
                        4'h3, 4'h4: begin
                            reg_write = 1'b1;
                            alu_op = opcode[2:0];
                            pc_enable = 1'b1;
                        end

                        // Load immediate
                        4'h5: begin
                            reg_write = 1'b1;
                            writeback_sel = 2'b01;
                            pc_enable = 1'b1;
                        end

                        // Load from memory
                        4'h6: begin
                            if (mem_addr_valid) begin
                                reg_write = 1'b1;
                                writeback_sel = 2'b10;
                                pc_enable = 1'b1;
                            end
                        end

                        // Store to memory
                        4'h7: begin
                            if (mem_addr_valid) begin
                                mem_write = 1'b1;
                                pc_enable = 1'b1;
                            end
                        end

                        // BEQ
                        4'h8: begin
                            if (branch_equal)
                                pc_jump = 1'b1;
                            else
                                pc_enable = 1'b1;
                        end

                        // JMP
                        4'h9: begin
                            if (jump_addr_valid)
                                pc_jump = 1'b1;
                        end

                        default: begin
                            // No operation
                        end
                    endcase
                    
                end
            end

            HALTED: begin
                halted = 1'b1;
            end

            default: begin
                // Default signals
            end
        endcase
        // Prevent state changes while CPU is paused or reset
        if (!cpu_enable || reset) begin
            pc_enable = 1'b0;
            pc_jump   = 1'b0;
            reg_write = 1'b0;
            mem_write = 1'b0;
        end 
    end

endmodule


