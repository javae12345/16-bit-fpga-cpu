`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_instruction_memory
// Description: Checks the ROM contents against the program currently coded in
//              instruction_memory.sv (the UART echo program). Update the table
//              below whenever the program changes.
//////////////////////////////////////////////////////////////////////////////////

module tb__cl_instruction_mem;

    logic [7:0]  addr;
    logic [15:0] instruction;

    int errors = 0;

    instruction_memory dut (
        .addr(addr),
        .instruction(instruction)
    );

    task automatic check_instruction(
        input logic [7:0]  test_addr,
        input logic [15:0] expected
    );
        addr = test_addr;
        #10;
        if (instruction !== expected) begin
            $error("FAIL: Address=%0d, Expected=%h, Got=%h",
                   addr, expected, instruction);
            errors++;
        end
        else
            $display("PASS: Address=%0d, Instruction=%h", addr, instruction);
    endtask

    initial begin
        check_instruction(8'd0,  16'h5000);  // LDI R0, 0
        check_instruction(8'd1,  16'h5601);  // LDI R3, 1

        // WAIT_RX
        check_instruction(8'd2,  16'h62FD);  // LD  R1, [253]   RX status
        check_instruction(8'd3,  16'h2258);  // AND R1, R1, R3  test rx_ready
        check_instruction(8'd4,  16'h8202);  // BEQ R1, R0, 2   wait for data

        check_instruction(8'd5,  16'h64FC);  // LD  R2, [252]   read character

        // WAIT_TX
        check_instruction(8'd6,  16'h68FB);  // LD  R4, [251]   TX status
        check_instruction(8'd7,  16'h2918);  // AND R4, R4, R3  test tx_ready
        check_instruction(8'd8,  16'h8806);  // BEQ R4, R0, 6   wait until idle

        check_instruction(8'd9,  16'h74FE);  // ST  R2, [254]   send character
        check_instruction(8'd10, 16'h74FF);  // ST  R2, [255]   display on LEDs
        check_instruction(8'd11, 16'h9002);  // JMP 2           receive next

        // Everything after the program is zero-filled
        check_instruction(8'd12,  16'h0000);
        check_instruction(8'd128, 16'h0000);
        check_instruction(8'd255, 16'h0000);

        if (errors == 0)
            $display("ALL INSTRUCTION MEMORY TESTS PASSED");
        else
            $fatal(1, "%0d INSTRUCTION MEMORY TEST FAILURE(S)", errors);
        $finish;
    end

endmodule