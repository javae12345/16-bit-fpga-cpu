`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/15/2026 12:40:12 AM
// Design Name: 
// Module Name: cpu_top
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



module cpu_top (
    input  logic        clk,
    input  logic        reset,
    input  logic        cpu_enable,

    input  logic        uart_rx_in,

    output logic [15:0] pc_out,
    output logic [15:0] instruction_out,
    output logic        halted,
    output logic [3:0]  gpio_led,
    output logic        uart_tx_out,
    output logic        uart_busy
);

    // Program counter
    logic [15:0] pc;
    logic pc_enable;
    logic pc_jump;
    logic [15:0] pc_jump_addr;

    // Instruction decoder
    logic [15:0] instruction;
    logic [3:0] opcode;
    logic [2:0] rd, rs1, rs2;
    logic [15:0] immediate;

    logic [7:0] mem_addr;
    logic mem_addr_valid;

    logic [15:0] branch_addr;
    logic [15:0] jump_addr;
    logic jump_addr_valid;

    // Register file
    logic reg_write;
    logic [2:0] read_addr1;
    logic [2:0] read_addr2;

    logic [15:0] reg_data1;
    logic [15:0] reg_data2;
    logic [15:0] write_data;

    // ALU
    logic [2:0] alu_op;
    logic [15:0] alu_result;
    logic alu_zero;

    // Memory and peripherals
    logic mem_write;
    logic ram_write;
    logic gpio_write;
    logic uart_start;

    logic [15:0] ram_read_data;
    logic [15:0] memory_read_data;

    // UART receiver
    logic [7:0] rx_byte;
    logic rx_data_valid;
    logic [7:0] rx_data;
    logic [3:0] rx_count;
    logic tx_ready;

    assign tx_ready = !uart_busy;
    logic rx_ready;
    logic rx_overrun;
    logic rx_read_ack;

    // Control
    logic [1:0] writeback_sel;
    logic branch_equal;

    // ----------------------------------
    // 1. Program counter
    // ----------------------------------
    program_counter pc_inst (
        .clk(clk),
        .reset(reset),
        .enable(pc_enable),
        .jump(pc_jump),
        .jump_addr(pc_jump_addr),
        .pc(pc)
    );

    // ----------------------------------
    // 2. Instruction memory
    // ----------------------------------
    instruction_memory imem_inst (
        .addr(pc[7:0]),
        .instruction(instruction)
    );

    // ----------------------------------
    // 3. Instruction decoder
    // ----------------------------------
    instruction_decoder decoder_inst (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .immediate(immediate),
        .mem_addr(mem_addr),
        .mem_addr_valid(mem_addr_valid),
        .branch_addr(branch_addr),
        .jump_addr(jump_addr),
        .jump_addr_valid(jump_addr_valid)
    );

    // ----------------------------------
    // 4. Register address selection
    // ----------------------------------
    always_comb begin
        read_addr1 = rs1;
        read_addr2 = rs2;

        if (opcode == 4'h7) begin
            read_addr1 = rd;
        end
        else if (opcode == 4'h8) begin
            read_addr1 = rd;
            read_addr2 = rs1;
        end
    end

    // ----------------------------------
    // 5. Register file
    // ----------------------------------
    register_file rf_inst (
        .clk(clk),
        .reset(reset),
        .write_enable(reg_write),
        .write_addr(rd),
        .write_data(write_data),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .read_data1(reg_data1),
        .read_data2(reg_data2)
    );

    // ----------------------------------
    // 6. ALU
    // ----------------------------------
    alu alu_inst (
        .a(reg_data1),
        .b(reg_data2),
        .alu_op(alu_op),
        .result(alu_result),
        .zero(alu_zero)
    );

    // ----------------------------------
    // 7. Write address decoder
    // ----------------------------------
    assign ram_write =
        mem_write && (mem_addr < 8'd251);
        
    assign gpio_write =
        mem_write && (mem_addr == 8'd255);

    assign uart_start =
        mem_write &&
        (mem_addr == 8'd254) &&
        !uart_busy;

    // ----------------------------------
    // 8. Data RAM
    // ----------------------------------
    data_memory dmem_inst (
        .clk(clk),
        .write_enable(ram_write),
        .addr(mem_addr),
        .write_data(reg_data1),
        .read_data(ram_read_data)
    );

    // ----------------------------------
    // 9. GPIO
    // ----------------------------------
    gpio_controller gpio_inst (
        .clk(clk),
        .reset(reset),
        .write_enable(gpio_write),
        .write_data(reg_data1),
        .led(gpio_led)
    );

    // ----------------------------------
    // 10. UART transmitter
    // ----------------------------------
    uart_tx #(
        .CLK_FREQ(125_000_000),
        .BAUD_RATE(115_200)
    ) uart_tx_inst (
        .clk(clk),
        .reset(reset),
        .start(uart_start),
        .data_in(reg_data1[7:0]),
        .tx(uart_tx_out),
        .busy(uart_busy)
    );

    // ----------------------------------
    // 11. UART receiver
    // ----------------------------------
    uart_rx #(
        .CLK_FREQ(125_000_000),
        .BAUD_RATE(115_200)
    ) uart_rx_inst (
        .clk(clk),
        .reset(reset),
        .rx(uart_rx_in),
        .data_out(rx_byte),
        .data_valid(rx_data_valid)
    );

    // ----------------------------------
    // 12. RX holding registers
    // ----------------------------------

    uart_rx_fifo_bridge rx_fifo_inst (
        .clk(clk),
        .reset(reset),
    
        .rx_byte(rx_byte),
        .data_valid(rx_data_valid),
    
        .read_ack(rx_read_ack),
    
        .rx_data(rx_data),
        .rx_ready(rx_ready),
        .rx_overrun(rx_overrun),
        .rx_count(rx_count)
    );
    

    // A completed CPU load from address 252
    // consumes the received byte.
    assign rx_read_ack =
        reg_write &&
        (opcode == 4'h6) &&
        (mem_addr == 8'd252);

    // ----------------------------------
    // 13. Memory read multiplexer
    // ----------------------------------

    always_comb begin
        case (mem_addr)
    
            // UART TX status
            8'd251: begin
                memory_read_data =
                    {15'b0, tx_ready};
            end
    
            // UART RX data
            8'd252: begin
                memory_read_data =
                    {8'b0, rx_data};
            end
    
            // UART RX status
            8'd253: begin
                memory_read_data =
                    {10'b0, rx_count, rx_overrun, rx_ready};
            end
    
            // Write-only peripherals
            8'd254, 8'd255: begin
                memory_read_data = 16'b0;
            end
    
            // Normal RAM
            default: begin
                memory_read_data = ram_read_data;
            end
    
        endcase
    end
    

    // ----------------------------------
    // 14. Branch and jump logic
    // ----------------------------------
    assign branch_equal =
        (reg_data1 == reg_data2);

    assign pc_jump_addr =
        (opcode == 4'h8)
        ? branch_addr
        : jump_addr;

    // ----------------------------------
    // 15. Control unit
    // ----------------------------------
    control_unit control_inst (
        .clk(clk),
        .reset(reset),
        .cpu_enable(cpu_enable),
        .opcode(opcode),
        .mem_addr_valid(mem_addr_valid),
        .jump_addr_valid(jump_addr_valid),
        .branch_equal(branch_equal),

        .pc_enable(pc_enable),
        .pc_jump(pc_jump),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .alu_op(alu_op),
        .writeback_sel(writeback_sel),
        .halted(halted)
    );

    // ----------------------------------
    // 16. Writeback multiplexer
    // ----------------------------------
    always_comb begin
        case (writeback_sel)
            2'b00: write_data = alu_result;
            2'b01: write_data = immediate;
            2'b10: write_data = memory_read_data;
            default: write_data = 16'b0;
        endcase
    end

    // Debug outputs
    assign pc_out = pc;
    assign instruction_out = instruction;

endmodule





