`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: tb_cpu_top
// Description: Program-level tests for cpu_top. Each test overwrites the
//              instruction memory contents through a hierarchical reference,
//              resets the CPU, runs until HALT, then checks registers, data
//              memory and PC.
//////////////////////////////////////////////////////////////////////////////////

module tb_cpu_top;

    logic        clk;
    logic        reset;
    logic        cpu_enable;

    logic [15:0] pc_out;
    logic [15:0] instruction_out;
    logic        halted;

    int errors = 0;

    // Instantiate CPU (cpu_enable held high so it runs at full clock speed)
    cpu_top dut (
        .clk(clk),
        .reset(reset),
        .cpu_enable(cpu_enable),
        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .halted(halted)
    );

    // 100 MHz clock
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------

    task automatic clear_memories;
        for (int i = 0; i < 256; i++) begin
            dut.imem_inst.memory[i] = 16'h0000;
            dut.dmem_inst.memory[i] = 16'h0000;
        end
    endtask

    task automatic load_instr(input int addr, input logic [15:0] word);
        dut.imem_inst.memory[addr] = word;
    endtask

    // Reset the CPU. Call this AFTER loading the program.
    task automatic reset_cpu;
        @(negedge clk);
        reset = 1;
        repeat (2) @(negedge clk);
        reset = 0;
    endtask

    // Run until halted (or timeout), then confirm it stays halted.
    task automatic run_until_halt(input string name, input int max_cycles);
        int cycles;
        logic [15:0] pc_at_halt;

        cycles = 0;
        while (halted !== 1'b1 && cycles < max_cycles) begin
            @(posedge clk);
            #1;
            cycles++;
        end

        if (halted !== 1'b1) begin
            $error("[%s] FAIL: CPU did not halt within %0d cycles", name, max_cycles);
            errors++;
        end
        else begin
            pc_at_halt = pc_out;
            repeat (5) @(posedge clk);
            #1;
            if (halted !== 1'b1 || pc_out !== pc_at_halt) begin
                $error("[%s] FAIL: CPU did not stay halted (PC %0d -> %0d)",
                       name, pc_at_halt, pc_out);
                errors++;
            end
        end
    endtask

    task automatic expect_reg(input string name, input int r, input logic [15:0] expected);
        if (dut.rf_inst.registers[r] !== expected) begin
            $error("[%s] FAIL: R%0d = %0d, expected %0d",
                   name, r, dut.rf_inst.registers[r], expected);
            errors++;
        end
    endtask

    task automatic expect_mem(input string name, input int a, input logic [15:0] expected);
        if (dut.dmem_inst.memory[a] !== expected) begin
            $error("[%s] FAIL: MEM[%0d] = %0d, expected %0d",
                   name, a, dut.dmem_inst.memory[a], expected);
            errors++;
        end
    endtask

    task automatic expect_pc(input string name, input logic [15:0] expected);
        if (pc_out !== expected) begin
            $error("[%s] FAIL: PC = %0d, expected %0d", name, pc_out, expected);
            errors++;
        end
    endtask

    // ---------------------------------------------------------------
    // Tests
    // ---------------------------------------------------------------

    // Arithmetic and logic: LDI, ADD, SUB, AND, OR, XOR, HALT
    task automatic test_alu_ops;
        clear_memories();
        load_instr(0, 16'h5207);  // LDI R1, 7
        load_instr(1, 16'h5405);  // LDI R2, 5
        load_instr(2, 16'h0650);  // ADD R3, R1, R2
        load_instr(3, 16'h1850);  // SUB R4, R1, R2
        load_instr(4, 16'h2A50);  // AND R5, R1, R2
        load_instr(5, 16'h3C50);  // OR  R6, R1, R2
        load_instr(6, 16'h4E50);  // XOR R7, R1, R2
        load_instr(7, 16'hF000);  // HALT
        reset_cpu();
        run_until_halt("alu_ops", 100);

        expect_reg("alu_ops", 1, 16'd7);
        expect_reg("alu_ops", 2, 16'd5);
        expect_reg("alu_ops", 3, 16'd12);
        expect_reg("alu_ops", 4, 16'd2);
        expect_reg("alu_ops", 5, 16'd5);
        expect_reg("alu_ops", 6, 16'd7);
        expect_reg("alu_ops", 7, 16'd2);
        expect_pc("alu_ops", 16'd7);
        $display("DONE: alu_ops");
    endtask

    // Store then load round trip
    task automatic test_load_store;
        clear_memories();
        load_instr(0, 16'h522A);  // LDI R1, 42
        load_instr(1, 16'h7205);  // ST  R1, [5]
        load_instr(2, 16'h6405);  // LD  R2, [5]
        load_instr(3, 16'h8285);  // BEQ R1, R2, 5
        load_instr(4, 16'hF000);  // HALT (fail path: mismatch)
        load_instr(5, 16'hF000);  // HALT (pass path)
        reset_cpu();
        run_until_halt("load_store", 100);

        expect_reg("load_store", 1, 16'd42);
        expect_reg("load_store", 2, 16'd42);
        expect_mem("load_store", 5, 16'd42);
        expect_pc("load_store", 16'd5);
        $display("DONE: load_store");
    endtask

    // BEQ taken, BEQ not taken, JMP (same program as the board test)
    task automatic test_branch_jump;
        clear_memories();
        load_instr(0, 16'h520A);  // LDI R1, 10
        load_instr(1, 16'h540A);  // LDI R2, 10
        load_instr(2, 16'h8285);  // BEQ R1, R2, 5   (taken)
        load_instr(3, 16'h5663);  // LDI R3, 99      (skipped)
        load_instr(4, 16'hF000);  // HALT            (skipped)
        load_instr(5, 16'h5601);  // LDI R3, 1
        load_instr(6, 16'h82C8);  // BEQ R1, R3, 8   (not taken: 10 != 1)
        load_instr(7, 16'h9009);  // JMP 9
        load_instr(8, 16'h564D);  // LDI R3, 77      (skipped)
        load_instr(9, 16'hF000);  // HALT
        reset_cpu();
        run_until_halt("branch_jump", 100);

        expect_reg("branch_jump", 1, 16'd10);
        expect_reg("branch_jump", 2, 16'd10);
        expect_reg("branch_jump", 3, 16'd1);
        expect_pc("branch_jump", 16'd9);
        $display("DONE: branch_jump");
    endtask

    // A loop: sum 3+2+1 using a counter, SUB, BEQ and JMP.
    //   R1 = counter (3), R2 = constant 1, R3 = sum, R4 = zero
    task automatic test_loop;
        clear_memories();
        load_instr(0, 16'h5203);  // LDI R1, 3
        load_instr(1, 16'h5401);  // LDI R2, 1
        load_instr(2, 16'h5600);  // LDI R3, 0
        load_instr(3, 16'h5800);  // LDI R4, 0
        load_instr(4, 16'h8308);  // BEQ R1, R4, 8   (exit when counter == 0)
        // ADD R3, R3, R1 : opcode 0, rd=3, rs1=3, rs2=1
        //   0000 011 011 001 000 = 0x06C8
        load_instr(5, 16'h06C8);  // ADD R3, R3, R1
        // SUB R1, R1, R2 : opcode 1, rd=1, rs1=1, rs2=2
        //   0001 001 001 010 000 = 0x1250
        load_instr(6, 16'h1250);  // SUB R1, R1, R2
        load_instr(7, 16'h9004);  // JMP 4
        load_instr(8, 16'hF000);  // HALT
        reset_cpu();
        run_until_halt("loop", 300);

        expect_reg("loop", 1, 16'd0);
        expect_reg("loop", 3, 16'd6);   // 3 + 2 + 1
        expect_pc("loop", 16'd8);
        $display("DONE: loop");
    endtask

    // Illegal opcode must halt without advancing the PC
    task automatic test_illegal_opcode;
        clear_memories();
        load_instr(0, 16'h5203);  // LDI R1, 3
        load_instr(1, 16'hA000);  // illegal opcode
        load_instr(2, 16'h5405);  // LDI R2, 5 (must never run)
        reset_cpu();
        run_until_halt("illegal_opcode", 100);

        expect_reg("illegal_opcode", 1, 16'd3);
        expect_reg("illegal_opcode", 2, 16'd0);
        expect_pc("illegal_opcode", 16'd1);
        $display("DONE: illegal_opcode");
    endtask

    // LD with the reserved address bit set must halt
    task automatic test_invalid_mem_address;
        clear_memories();
        load_instr(0, 16'h5203);  // LDI R1, 3
        load_instr(1, 16'h6300);  // LD with reserved bit 8 set
        load_instr(2, 16'h5405);  // LDI R2, 5 (must never run)
        reset_cpu();
        run_until_halt("invalid_mem_address", 100);

        expect_reg("invalid_mem_address", 2, 16'd0);
        expect_pc("invalid_mem_address", 16'd1);
        $display("DONE: invalid_mem_address");
    endtask

    // JMP with reserved bits set must halt
    task automatic test_invalid_jump;
        clear_memories();
        load_instr(0, 16'h5203);  // LDI R1, 3
        load_instr(1, 16'h9209);  // JMP with reserved bits set
        load_instr(2, 16'h5405);  // LDI R2, 5 (must never run)
        reset_cpu();
        run_until_halt("invalid_jump", 100);

        expect_reg("invalid_jump", 2, 16'd0);
        expect_pc("invalid_jump", 16'd1);
        $display("DONE: invalid_jump");
    endtask

    // Reset must recover from HALTED and restart the program
    task automatic test_reset_recovery;
        // Previous test left the CPU halted. Load a new program and reset.
        clear_memories();
        load_instr(0, 16'h5209);  // LDI R1, 9
        load_instr(1, 16'hF000);  // HALT
        reset_cpu();
        run_until_halt("reset_recovery", 100);

        expect_reg("reset_recovery", 1, 16'd9);
        expect_pc("reset_recovery", 16'd1);
        $display("DONE: reset_recovery");
    endtask

    // ---------------------------------------------------------------

    initial begin
        reset      = 1;
        cpu_enable = 1;

        // Wait past time 0 so the memories' initial blocks have run
        @(negedge clk);

        test_alu_ops();
        test_load_store();
        test_branch_jump();
        test_loop();
        test_illegal_opcode();
        test_invalid_mem_address();
        test_invalid_jump();
        test_reset_recovery();

        $display("-------------------------");
        if (errors == 0)
            $display("ALL CPU TESTS PASSED");
        else
            $fatal(1, "%0d CPU TEST FAILURE(S)", errors);
        $display("-------------------------");
        $finish;
    end

endmodule