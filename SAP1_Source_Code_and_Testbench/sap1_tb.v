`timescale 1ns/1ps

module sap1_tb;
    reg clk;
    reg reset;

    wire halt;
    wire [7:0] bus;
    wire [3:0] pc;
    wire [3:0] mar;
    wire [7:0] ir;
    wire [7:0] a_reg;
    wire [7:0] b_reg;
    wire [7:0] alu_result;
    wire [2:0] t_state;
    wire pc_out, pc_inc, mar_load, mem_out, ir_load, ir_out;
    wire a_load, a_out, b_load, alu_out;
    wire [1:0] alu_sel;

    cpu uut (
        .clk(clk),
        .reset(reset),
        .halt(halt),
        .bus(bus),
        .pc(pc),
        .mar(mar),
        .ir(ir),
        .a_reg(a_reg),
        .b_reg(b_reg),
        .alu_result(alu_result),
        .t_state(t_state),
        .pc_out(pc_out),
        .pc_inc(pc_inc),
        .mar_load(mar_load),
        .mem_out(mem_out),
        .ir_load(ir_load),
        .ir_out(ir_out),
        .a_load(a_load),
        .a_out(a_out),
        .b_load(b_load),
        .alu_out(alu_out),
        .alu_sel(alu_sel)
    );

    localparam OP_LDA = 4'h1;
    localparam OP_ADD = 4'h2;
    localparam OP_SUB = 4'h3;
    localparam OP_MUL = 4'h4;
    localparam OP_DIV = 4'h5;
    localparam OP_HLT = 4'hF;

    always #5 clk = ~clk;

    task load_program;
        input [3:0] operation_opcode;
        input [7:0] data_a;
        input [7:0] data_b;
        integer i;
        begin
            for (i = 0; i < 16; i = i + 1)
                uut.mem_unit.mem[i] = 8'h00;

            uut.mem_unit.mem[0] = {OP_LDA, 4'h3};          // LDA 3
            uut.mem_unit.mem[1] = {operation_opcode, 4'h6}; // ADD/SUB/MUL/DIV 6
            uut.mem_unit.mem[2] = {OP_HLT, 4'h0};          // HLT
            uut.mem_unit.mem[3] = data_a;
            uut.mem_unit.mem[6] = data_b;
        end
    endtask

    task run_test;
        input [127:0] test_name;
        input [3:0] operation_opcode;
        input [7:0] data_a;
        input [7:0] data_b;
        input [7:0] expected;
        integer cycle_count;
        begin
            load_program(operation_opcode, data_a, data_b);

            reset = 1'b1;
            #12;
            reset = 1'b0;

            cycle_count = 0;
            while (!halt && cycle_count < 40) begin
                @(posedge clk);
                cycle_count = cycle_count + 1;
                $display("%0t %-16s T=%0d PC=%h MAR=%h IR=%h BUS=%h A=%h B=%h ALU=%h ctrl: po=%b ml=%b mo=%b il=%b io=%b al=%b bl=%b uo=%b sel=%b",
                         $time, test_name, t_state, pc, mar, ir, bus, a_reg, b_reg, alu_result,
                         pc_out, mar_load, mem_out, ir_load, ir_out, a_load, b_load, alu_out, alu_sel);
            end

            #1;
            if (a_reg === expected)
                $display("PASS: %s, final A = %0d (0x%h)", test_name, a_reg, a_reg);
            else begin
                $display("FAIL: %s, final A = %0d (0x%h), expected %0d (0x%h)", test_name, a_reg, a_reg, expected, expected);
                $stop;
            end
            #20;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b0;

        $dumpfile("sap1_waveform.vcd");
        $dumpvars(0, sap1_tb);

        run_test("ADD: 4 + 5", OP_ADD, 8'd4, 8'd5, 8'd9);
        run_test("SUB: 9 - 2", OP_SUB, 8'd9, 8'd2, 8'd7);
        run_test("MUL: 4 * 5", OP_MUL, 8'd4, 8'd5, 8'd20);
        run_test("DIV: 10 / 2", OP_DIV, 8'd10, 8'd2, 8'd5);

        $display("All SAP-1 tests passed.");
        $finish;
    end
endmodule
