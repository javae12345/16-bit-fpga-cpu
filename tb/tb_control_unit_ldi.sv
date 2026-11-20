`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2026 11:21:49 AM
// Design Name: 
// Module Name: tb_control_unit_ldi
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



`timescale 1ns / 1ps

module tb_control_unit_ldi;

    logic clk;
    logic reset;
    logic [3:0] opcode;

    logic pc_enable;
    logic reg_write;
    logic [2:0] alu_op;
    logic writeback_sel;
    logic halted;

    control_unit dut (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .pc_enable(pc_enable),
        .reg_write(reg_write),
        .alu_op(alu_op),
        .writeback_sel(writeback_sel),
        .halted(halted)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        reset = 1;
        opcode = 4'h5;

        // Reset into FETCH
        @(posedge clk);
        #1;
        if (reg_write !== 0 || writeback_sel !== 0)
            $fatal(1, "Reset test failed");

        @(negedge clk);
        reset = 0;

        // FETCH -> EXECUTE
        @(posedge clk);
        #1;

        if (reg_write !== 0 || pc_enable !== 0)
            $fatal(1, "EXECUTE test failed");

        // EXECUTE -> WRITEBACK
        @(posedge clk);
        #1;

        if (reg_write !== 1 ||
            pc_enable !== 1 ||
            writeback_sel !== 1 ||
            halted !== 0)
            $fatal(1, "LDI WRITEBACK test failed");

        $display("PASS: LDI WRITEBACK signals");

        // WRITEBACK -> FETCH
        @(posedge clk);
        #1;

        if (reg_write !== 0 ||
            pc_enable !== 0 ||
            writeback_sel !== 0)
            $fatal(1, "Return to FETCH failed");

        $display("ALL LDI CONTROL TESTS PASSED");
        $finish;
    end

endmodule

