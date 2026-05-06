// ============================================================
// File        : sap1_tb.v
// Module      : sap1_tb (Testbench)
// Description : Comprehensive testbench for SAP-1 CPU.
//
// TEST CASES:
//   Test 1: LDA 3, ADD 6   → Expected: A = 4 + 5 = 9  (project spec)
//   Test 2: LDA 3, SUB 6   → Expected: A = 4 - 5 = 251 (underflow, 8-bit)
//   Test 3: LDA 3, MUL 6   → Expected: A = 4 * 5 = 20
//   Test 4: LDA 3, DIV 6   → Expected: A = 4 / 5 = 0  (integer division)
//   Test 5: LDA 6, DIV 3   → Expected: A = 5 / 4 = 1  (integer division)
//
// HOW TO USE IN VIVADO:
//   1. Add all .v files to your Vivado project.
//   2. Set sap1_tb as the simulation top module.
//   3. Run Behavioral Simulation.
//   4. In the waveform window, add these signals for screenshot:
//        clk, rst, t_state, bus, pc_out, mar_out, ir_out,
//        a_out, b_out, alu_out, hlt,
//        Cp, Ep, Lm, CE, Li, Ei, La, Lb, Eu, Su, Mu, Du
//   5. Set radix to "Hexadecimal" for bus, ir_out, a_out, b_out, alu_out.
//   6. Set radix to "Unsigned Decimal" for t_state, pc_out, mar_out.
//
// EXPECTED WAVEFORM VALUES (Test 1: LDA 3 then ADD 6):
//   T1: Ep=1, Lm=1 | bus=0x00, mar→0x00
//   T2: Cp=1       | bus=0x00, pc→0x01
//   T3: CE=1, Li=1 | bus=0x03, ir→0x03
//   T4: Ei=1, Lm=1 | bus=0x03, mar→0x03
//   T5: CE=1, La=1 | bus=0x04, a→0x04  ← LDA complete
//   T6: (none)     | a=0x04
//   T1: Ep=1, Lm=1 | bus=0x01, mar→0x01
//   T2: Cp=1       | bus=0x01, pc→0x02
//   T3: CE=1, Li=1 | bus=0x16, ir→0x16
//   T4: Ei=1, Lm=1 | bus=0x06, mar→0x06
//   T5: CE=1, Lb=1 | bus=0x05, b→0x05
//   T6: Eu=1, La=1 | bus=0x09, a→0x09  ← ADD complete (4+5=9)
// ============================================================
`timescale 1ns / 1ps

module sap1_tb;

    // --- Clock and Reset ---
    reg clk;
    reg rst;

    // --- DUT Output Wires ---
    wire [7:0] bus;
    wire [3:0] pc_out;
    wire [3:0] mar_out;
    wire [7:0] ir_out;
    wire [7:0] a_out;
    wire [7:0] b_out;
    wire [7:0] alu_out;
    wire [2:0] t_state;
    wire       hlt;

    // Control signal wires (for waveform visibility)
    wire Cp, Ep, Lm, CE, Li, Ei, La, Ea, Su, Eu, Lb, Mu, Du;

    // --- Instantiate DUT (Device Under Test) ---
    sap1_top DUT (
        .clk     (clk),
        .rst     (rst),
        .bus     (bus),
        .pc_out  (pc_out),
        .mar_out (mar_out),
        .ir_out  (ir_out),
        .a_out   (a_out),
        .b_out   (b_out),
        .alu_out (alu_out),
        .t_state (t_state),
        .hlt     (hlt),
        .Cp(Cp), .Ep(Ep), .Lm(Lm), .CE(CE), .Li(Li), .Ei(Ei),
        .La(La), .Ea(Ea), .Su(Su), .Eu(Eu), .Lb(Lb), .Mu(Mu), .Du(Du)
    );

    // --- Clock Generation: 10ns period (100MHz) ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Task: Reset the CPU ---
    task do_reset;
        begin
            rst = 1;
            @(posedge clk); #1;
            @(posedge clk); #1;
            rst = 0;
        end
    endtask

    // --- Task: Wait N clock cycles ---
    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
            #1;
        end
    endtask

    // --- Task: Print current state ---
    task print_state;
        input [63:0] label;   // Not used directly, just for grouping
        begin
            $display("T=%0d | PC=%02h MAR=%02h IR=%02h BUS=%02h | A=%02h B=%02h ALU=%02h | hlt=%b",
                     t_state, pc_out, mar_out, ir_out, bus,
                     a_out, b_out, alu_out, hlt);
        end
    endtask

    // ==========================================================
    // MAIN TEST SEQUENCE
    // ==========================================================
    initial begin
        // VCD dump for waveform viewing
        $dumpfile("sap1_waveform.vcd");
        $dumpvars(0, sap1_tb);

        $display("======================================================");
        $display("  SAP-1 Simulation — All Tests");
        $display("======================================================");

        // ----------------------------------------------------------
        // TEST 1: LDA 3, ADD 6  (project spec test)
        // Memory[3] = 4,  Memory[6] = 5
        // Expected: A = 4 + 5 = 9 = 0x09
        // ----------------------------------------------------------
        $display("\n--- TEST 1: LDA 3 then ADD 6 ---");
        $display("Memory[0]=LDA 3 (0x03), Memory[1]=ADD 6 (0x16)");
        $display("Expected: A = 4 + 5 = 9 (0x09)");

        // Memory is already loaded with the correct test program (in memory.v initial block)
        do_reset;

        // Run for 15 clock cycles (covers 2 full instructions = 12 T-states + buffer)
        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'd9)
            $display("*** TEST 1 PASSED ***");
        else
            $display("*** TEST 1 FAILED *** (expected 9, got %0d)", a_out);

        // ----------------------------------------------------------
        // TEST 2: LDA 3, SUB 6
        // Memory[3] = 4,  Memory[6] = 5
        // Expected: A = 4 - 5 = -1 = 255 (0xFF) in 8-bit two's complement
        // ----------------------------------------------------------
        $display("\n--- TEST 2: LDA 3 then SUB 6 ---");
        $display("Memory[0]=LDA 3 (0x03), Memory[1]=SUB 6 (0x26)");
        $display("Expected: A = 4 - 5 = 0xFF (255 unsigned, -1 signed)");

        // Change instruction at address 1 to SUB 6
        // SUB opcode = 0010, addr = 6 → 0010_0110 = 0x26
        DUT.u_mem.ram[1] = 8'h26;   // SUB 6

        do_reset;
        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'hFF)
            $display("*** TEST 2 PASSED ***");
        else
            $display("*** TEST 2 FAILED *** (expected 0xFF=255, got %0d)", a_out);

        // ----------------------------------------------------------
        // TEST 3: LDA 3, MUL 6
        // Memory[3] = 4,  Memory[6] = 5
        // Expected: A = 4 * 5 = 20 = 0x14
        // ----------------------------------------------------------
        $display("\n--- TEST 3: LDA 3 then MUL 6 ---");
        $display("Memory[0]=LDA 3 (0x03), Memory[1]=MUL 6 (0x36)");
        $display("Expected: A = 4 * 5 = 20 (0x14)");

        // MUL opcode = 0011, addr = 6 → 0011_0110 = 0x36
        DUT.u_mem.ram[1] = 8'h36;   // MUL 6

        do_reset;
        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'd20)
            $display("*** TEST 3 PASSED ***");
        else
            $display("*** TEST 3 FAILED *** (expected 20, got %0d)", a_out);

        // ----------------------------------------------------------
        // TEST 4: LDA 3, DIV 6
        // Memory[3] = 4,  Memory[6] = 5
        // Expected: A = 4 / 5 = 0 (integer division, 4 < 5)
        // ----------------------------------------------------------
        $display("\n--- TEST 4: LDA 3 then DIV 6 ---");
        $display("Memory[0]=LDA 3 (0x03), Memory[1]=DIV 6 (0x46)");
        $display("Expected: A = 4 / 5 = 0 (integer quotient)");

        // DIV opcode = 0100, addr = 6 → 0100_0110 = 0x46
        DUT.u_mem.ram[1] = 8'h46;   // DIV 6

        do_reset;
        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'd0)
            $display("*** TEST 4 PASSED ***");
        else
            $display("*** TEST 4 FAILED *** (expected 0, got %0d)", a_out);

        // ----------------------------------------------------------
        // TEST 5: LDA 6, DIV 3  (swapped operands, tests DIV properly)
        // Memory[3] = 4,  Memory[6] = 5
        // LDA 6 → A = 5, then DIV 3 → A = 5 / 4 = 1
        // Expected: A = 1
        // ----------------------------------------------------------
        $display("\n--- TEST 5: LDA 6 then DIV 3 (swapped operands) ---");
        $display("Memory[0]=LDA 6 (0x06), Memory[1]=DIV 3 (0x43)");
        $display("Expected: A = 5 / 4 = 1 (integer quotient)");

        DUT.u_mem.ram[0] = 8'h06;   // LDA 6  (0000_0110)
        DUT.u_mem.ram[1] = 8'h43;   // DIV 3  (0100_0011)

        do_reset;
        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'd1)
            $display("*** TEST 5 PASSED ***");
        else
            $display("*** TEST 5 FAILED *** (expected 1, got %0d)", a_out);

        // ----------------------------------------------------------
        // TEST 6: LDA 3, MUL 3  (square a number: 4 * 4 = 16)
        // ----------------------------------------------------------
        $display("\n--- TEST 6: LDA 3 then MUL 3 (square of 4) ---");
        $display("Expected: A = 4 * 4 = 16 (0x10)");

        DUT.u_mem.ram[0] = 8'h03;   // LDA 3  (0000_0011)
        DUT.u_mem.ram[1] = 8'h33;   // MUL 3  (0011_0011)

        do_reset;
        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'd16)
            $display("*** TEST 6 PASSED ***");
        else
            $display("*** TEST 6 FAILED *** (expected 16, got %0d)", a_out);

        $display("\n======================================================");
        $display("  All tests complete.");
        $display("======================================================");
        $finish;
    end

    // --- Continuous Monitor (prints every clock edge) ---
    // Uncomment the lines below to see cycle-by-cycle output.
    // This is very useful for debugging but produces a lot of output.
    /*
    initial begin
        $display("Time | T | PC  MAR  IR    Bus  | A    B    ALU  | Cp Ep Lm CE Li Ei La Lb Eu Su Mu Du");
        forever @(posedge clk) begin
            #1;
            $display("%4t | %0d | %h   %h    %h  %h | %h   %h   %h  | %b  %b  %b  %b  %b  %b  %b  %b  %b  %b  %b  %b",
                $time, t_state, pc_out, mar_out, ir_out, bus,
                a_out, b_out, alu_out,
                Cp, Ep, Lm, CE, Li, Ei, La, Lb, Eu, Su, Mu, Du);
        end
    end
    */

endmodule
