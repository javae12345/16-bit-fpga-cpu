`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2026 12:47:46 AM
// Design Name: 
// Module Name: tb_control_unit
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

module tb_control_unit;

    logic       clk;
    logic       reset;
    logic [3:0] opcode;

    logic       mem_addr_valid;
    logic       jump_addr_valid;
    logic       branch_equal;
    logic       cpu_enable;

    logic       pc_enable;
    logic       pc_jump;
    logic       reg_write;
    logic       mem_write;
    logic [2:0] alu_op;
    logic [1:0] writeback_sel;
    logic       halted;

    int errors = 0;

    control_unit dut (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
        .mem_addr_valid(mem_addr_valid),
        .jump_addr_valid(jump_addr_valid),
        .branch_equal(branch_equal),
        .cpu_enable(cpu_enable),
        .pc_enable(pc_enable),
        .pc_jump(pc_jump),
        .reg_write(reg_write),
        .mem_write(mem_write),
        .alu_op(alu_op),
        .writeback_sel(writeback_sel),
        .halted(halted)
    );

    // 100 MHz simulation clock
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    // Compare every control output
    task automatic check(
        input string      tag,
        input logic       exp_pc,
        input logic       exp_jump,
        input logic       exp_rw,
        input logic       exp_mw,
        input logic [2:0] exp_alu,
        input logic [1:0] exp_wb,
        input logic       exp_halt
    );
        #1;
        if (pc_enable     !== exp_pc   ||
            pc_jump       !== exp_jump ||
            reg_write     !== exp_rw   ||
            mem_write     !== exp_mw   ||
            alu_op        !== exp_alu  ||
            writeback_sel !== exp_wb   ||
            halted        !== exp_halt) begin
            $error("[%s] FAIL: PC=%b JUMP=%b RW=%b MW=%b ALU=%b WB=%b HALT=%b",
                   tag, pc_enable, pc_jump, reg_write, mem_write,
                   alu_op, writeback_sel, halted);
            errors++;
        end
        else begin
            $display("PASS: %s", tag);
        end
    endtask

    // Reset into FETCH, leave inputs at their defaults, stop at a negedge
    task automatic reset_to_fetch;
        @(negedge clk);
        reset           = 1;
        cpu_enable      = 1;
        opcode          = 4'h0;
        mem_addr_valid  = 1;
        jump_addr_valid = 1;
        branch_equal    = 0;
        @(posedge clk);
        @(negedge clk);
        reset = 0;
    endtask

    // Present an instruction to the control unit (from the FETCH state)
    task automatic apply(
        input logic [3:0] op,
        input logic       mv,
        input logic       jv,
        input logic       eq
    );
        opcode          = op;
        mem_addr_valid  = mv;
        jump_addr_valid = jv;
        branch_equal    = eq;
    endtask

    // ---------------------------------------------------------------
    // Tests
    // ---------------------------------------------------------------

    // ADD, SUB, AND, OR, XOR
    task automatic test_alu_ops;
        for (int op = 0; op <= 4; op++) begin
            reset_to_fetch();
            apply(op[3:0], 1, 1, 0);

            check($sformatf("alu op %0d: FETCH", op), 0, 0, 0, 0, 3'b000, 2'b00, 0);
            @(posedge clk);
            check($sformatf("alu op %0d: EXECUTE", op), 0, 0, 0, 0, op[2:0], 2'b00, 0);
            @(posedge clk);
            check($sformatf("alu op %0d: WRITEBACK", op), 1, 0, 1, 0, op[2:0], 2'b00, 0);
            @(posedge clk);
            check($sformatf("alu op %0d: back to FETCH", op), 0, 0, 0, 0, 3'b000, 2'b00, 0);
        end
    endtask

    // LDI
    task automatic test_ldi;
        reset_to_fetch();
        apply(4'h5, 1, 1, 0);
        @(posedge clk);
        check("LDI: EXECUTE", 0, 0, 0, 0, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("LDI: WRITEBACK", 1, 0, 1, 0, 3'b000, 2'b01, 0);
        @(posedge clk);
        check("LDI: back to FETCH", 0, 0, 0, 0, 3'b000, 2'b00, 0);
    endtask

    // LD with a valid address
    task automatic test_ld;
        reset_to_fetch();
        apply(4'h6, 1, 1, 0);
        @(posedge clk);
        check("LD: EXECUTE", 0, 0, 0, 0, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("LD: WRITEBACK", 1, 0, 1, 0, 3'b000, 2'b10, 0);
        @(posedge clk);
        check("LD: back to FETCH", 0, 0, 0, 0, 3'b000, 2'b00, 0);
    endtask

    // ST with a valid address
    task automatic test_st;
        reset_to_fetch();
        apply(4'h7, 1, 1, 0);
        @(posedge clk);
        check("ST: EXECUTE", 0, 0, 0, 0, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("ST: WRITEBACK", 1, 0, 0, 1, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("ST: back to FETCH", 0, 0, 0, 0, 3'b000, 2'b00, 0);
    endtask

    // BEQ taken and not taken
    task automatic test_beq;
        // Taken
        reset_to_fetch();
        apply(4'h8, 1, 1, 1);
        @(posedge clk);
        check("BEQ taken: EXECUTE", 0, 0, 0, 0, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("BEQ taken: WRITEBACK", 0, 1, 0, 0, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("BEQ taken: back to FETCH", 0, 0, 0, 0, 3'b000, 2'b00, 0);

        // Not taken
        reset_to_fetch();
        apply(4'h8, 1, 1, 0);
        @(posedge clk);
        check("BEQ not taken: EXECUTE", 0, 0, 0, 0, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("BEQ not taken: WRITEBACK", 1, 0, 0, 0, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("BEQ not taken: back to FETCH", 0, 0, 0, 0, 3'b000, 2'b00, 0);
    endtask

    // JMP with valid reserved bits
    task automatic test_jmp;
        reset_to_fetch();
        apply(4'h9, 1, 1, 0);
        @(posedge clk);
        check("JMP: EXECUTE", 0, 0, 0, 0, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("JMP: WRITEBACK", 0, 1, 0, 0, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("JMP: back to FETCH", 0, 0, 0, 0, 3'b000, 2'b00, 0);
    endtask

    // HALT, illegal opcodes, and invalid operands all end in HALTED
    task automatic test_halt_case(
        input string      tag,
        input logic [3:0] op,
        input logic       mv,
        input logic       jv
    );
        reset_to_fetch();
        apply(op, mv, jv, 0);
        @(posedge clk);
        check({tag, ": EXECUTE"}, 0, 0, 0, 0, (op <= 4) ? op[2:0] : 3'b000, 2'b00, 0);
        @(posedge clk);
        check({tag, ": HALTED"}, 0, 0, 0, 0, 3'b000, 2'b00, 1);
        @(posedge clk);
        check({tag, ": stays HALTED"}, 0, 0, 0, 0, 3'b000, 2'b00, 1);
    endtask

    // cpu_enable low must freeze the state and gate every write/PC control
    task automatic test_cpu_enable_gating;
        reset_to_fetch();
        apply(4'h0, 1, 1, 0);
        @(posedge clk);                       // -> EXECUTE
        @(posedge clk);                       // -> WRITEBACK
        check("gating: WRITEBACK with enable", 1, 0, 1, 0, 3'b000, 2'b00, 0);

        @(negedge clk);
        cpu_enable = 0;
        check("gating: outputs blocked when paused", 0, 0, 0, 0, 3'b000, 2'b00, 0);

        repeat (3) @(posedge clk);
        check("gating: state held while paused", 0, 0, 0, 0, 3'b000, 2'b00, 0);

        @(negedge clk);
        cpu_enable = 1;
        check("gating: still in WRITEBACK after resume", 1, 0, 1, 0, 3'b000, 2'b00, 0);
        @(posedge clk);
        check("gating: advances to FETCH", 0, 0, 0, 0, 3'b000, 2'b00, 0);
    endtask

    // Reset must recover from HALTED
    task automatic test_reset_recovery;
        reset_to_fetch();
        apply(4'hF, 1, 1, 0);
        @(posedge clk);
        @(posedge clk);
        check("reset recovery: halted", 0, 0, 0, 0, 3'b000, 2'b00, 1);

        @(negedge clk);
        reset = 1;
        @(posedge clk);
        check("reset recovery: back in FETCH", 0, 0, 0, 0, 3'b000, 2'b00, 0);
    endtask

    // Reset during WRITEBACK must block the writes
    task automatic test_reset_blocks_writeback;
        reset_to_fetch();
        apply(4'h0, 1, 1, 0);
        @(posedge clk);
        @(posedge clk);
        check("reset in WRITEBACK: before", 1, 0, 1, 0, 3'b000, 2'b00, 0);
        @(negedge clk);
        reset = 1;
        check("reset in WRITEBACK: blocked", 0, 0, 0, 0, 3'b000, 2'b00, 0);
    endtask

    // ---------------------------------------------------------------

    initial begin
        reset = 1;
        cpu_enable = 1;
        opcode = 4'h0;
        mem_addr_valid = 1;
        jump_addr_valid = 1;
        branch_equal = 0;

        // Reset into FETCH: everything idle
        @(posedge clk);
        check("reset: idle outputs", 0, 0, 0, 0, 3'b000, 2'b00, 0);

        test_alu_ops();
        test_ldi();
        test_ld();
        test_st();
        test_beq();
        test_jmp();

        test_halt_case("HALT",              4'hF, 1, 1);
        test_halt_case("illegal opcode A",  4'hA, 1, 1);
        test_halt_case("LD invalid addr",   4'h6, 0, 1);
        test_halt_case("ST invalid addr",   4'h7, 0, 1);
        test_halt_case("JMP invalid bits",  4'h9, 1, 0);

        test_cpu_enable_gating();
        test_reset_recovery();
        test_reset_blocks_writeback();

        if (errors == 0)
            $display("ALL CONTROL UNIT TESTS PASSED");
        else
            $fatal(1, "%0d CONTROL UNIT TEST FAILURE(S)", errors);
        $finish;
    end

endmodule
