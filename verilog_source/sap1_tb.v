`timescale 1ns / 1ps

module sap1_tb;
    reg clk;
    reg rst;
    wire [7:0] bus;
    wire [3:0] pc_out;
    wire [3:0] mar_out;
    wire [7:0] ir_out;
    wire [7:0] a_out;
    wire [7:0] b_out;
    wire [7:0] alu_out;
    wire [2:0] t_state;
    wire       hlt;

    wire Cp, Ep, Lm, CE, Li, Ei, La, Ea, Su, Eu, Lb, Mu, Du;

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

    //Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    //Reset the CPU 
    task do_reset;
        begin
            rst = 1;
            @(posedge clk); #1;
            @(posedge clk); #1;
            rst = 0;
        end
    endtask

    // Wait N clock cycles
    task wait_cycles;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
            #1;
        end
    endtask

    //Print current state
    task print_state;
        input [63:0] label;   
        begin
            $display("T=%0d | PC=%02h MAR=%02h IR=%02h BUS=%02h | A=%02h B=%02h ALU=%02h | hlt=%b",
                     t_state, pc_out, mar_out, ir_out, bus,
                     a_out, b_out, alu_out, hlt);
        end
    endtask

    initial begin

        $dumpfile("sap1_waveform.vcd");
        $dumpvars(0, sap1_tb);

        $display("======================================================");
        $display("  SAP-1 Simulation — All Tests");
        $display("======================================================");

        // TEST 1: LDA 3, ADD 6  
        $display("\n--- TEST 1: LDA 3 then ADD 6 ---");
        $display("Memory[0]=LDA 3 (0x03), Memory[1]=ADD 6 (0x16)");
        $display("Expected: A = 4 + 5 = 9 (0x09)");

        do_reset;

        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'd9)
            $display("*** TEST 1 PASSED ***");
        else
            $display("*** TEST 1 FAILED *** (expected 9, got %0d)", a_out);

        // TEST 2: LDA 3, SUB 6
        $display("\n--- TEST 2: LDA 3 then SUB 6 ---");
        $display("Memory[0]=LDA 3 (0x03), Memory[1]=SUB 6 (0x26)");
        $display("Expected: A = 4 - 5 = 0xFF (255 unsigned, -1 signed)");


        DUT.u_mem.ram[1] = 8'h26;   //SUB 6

        do_reset;
        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'hFF)
            $display("*** TEST 2 PASSED ***");
        else
            $display("*** TEST 2 FAILED *** (expected 0xFF=255, got %0d)", a_out);

        // TEST 3: LDA 3, MUL 6
        $display("\n--- TEST 3: LDA 3 then MUL 6 ---");
        $display("Memory[0]=LDA 3 (0x03), Memory[1]=MUL 6 (0x36)");
        $display("Expected: A = 4 * 5 = 20 (0x14)");

        DUT.u_mem.ram[1] = 8'h36;   //MUL 6

        do_reset;
        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'd20)
            $display("*** TEST 3 PASSED ***");
        else
            $display("*** TEST 3 FAILED *** (expected 20, got %0d)", a_out);

        // TEST 4: LDA 3, DIV 6
        $display("\n--- TEST 4: LDA 3 then DIV 6 ---");
        $display("Memory[0]=LDA 3 (0x03), Memory[1]=DIV 6 (0x46)");
        $display("Expected: A = 4 / 5 = 0 (integer quotient)");

        DUT.u_mem.ram[1] = 8'h46;   //DIV 6

        do_reset;
        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'd0)
            $display("*** TEST 4 PASSED ***");
        else
            $display("*** TEST 4 FAILED *** (expected 0, got %0d)", a_out);

        // TEST 5: LDA 6, DIV 3  (swapped operands, tests DIV properly)
        $display("\n--- TEST 5: LDA 6 then DIV 3 (swapped operands) ---");
        $display("Memory[0]=LDA 6 (0x06), Memory[1]=DIV 3 (0x43)");
        $display("Expected: A = 5 / 4 = 1 (integer quotient)");

        DUT.u_mem.ram[0] = 8'h06;   // LDA 6 
        DUT.u_mem.ram[1] = 8'h43;   //DIV 3  

        do_reset;
        wait_cycles(15);

        $display("Result: A = %0d (hex: 0x%02h)", a_out, a_out);
        if (a_out == 8'd1)
            $display("*** TEST 5 PASSED ***");
        else
            $display("*** TEST 5 FAILED *** (expected 1, got %0d)", a_out);

        // TEST 6: LDA 3, MUL 3  (square a number: 4 * 4 = 16)
        $display("\n--- TEST 6: LDA 3 then MUL 3 (square of 4) ---");
        $display("Expected: A = 4 * 4 = 16 (0x10)");

        DUT.u_mem.ram[0] = 8'h03;   //LDA 3  
        DUT.u_mem.ram[1] = 8'h33;   //MUL 3  

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

endmodule
