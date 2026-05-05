`timescale 1ns/1ps

module cpu (
    input wire clk,
    input wire reset,
    output wire halt,
    output wire [7:0] bus,
    output wire [3:0] pc,
    output wire [3:0] mar,
    output wire [7:0] ir,
    output wire [7:0] a_reg,
    output wire [7:0] b_reg,
    output wire [7:0] alu_result,
    output wire [2:0] t_state,
    output wire pc_out,
    output wire pc_inc,
    output wire mar_load,
    output wire mem_out,
    output wire ir_load,
    output wire ir_out,
    output wire a_load,
    output wire a_out,
    output wire b_load,
    output wire alu_out,
    output wire [1:0] alu_sel
);
    wire [7:0] memory_data;
    wire [3:0] opcode;

    assign opcode = ir[7:4];

    control_unit cu (
        .clk(clk),
        .reset(reset),
        .opcode(opcode),
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
        .alu_sel(alu_sel),
        .halt(halt),
        .t_state(t_state)
    );

    program_counter pc_unit (
        .clk(clk),
        .reset(reset),
        .increment(pc_inc),
        .count(pc)
    );

    register4 mar_unit (
        .clk(clk),
        .reset(reset),
        .load(mar_load),
        .data_in(bus[3:0]),
        .data_out(mar)
    );

    memory mem_unit (
        .address(mar),
        .data_out(memory_data)
    );

    register8 ir_unit (
        .clk(clk),
        .reset(reset),
        .load(ir_load),
        .data_in(bus),
        .data_out(ir)
    );

    register8 a_unit (
        .clk(clk),
        .reset(reset),
        .load(a_load),
        .data_in(bus),
        .data_out(a_reg)
    );

    register8 b_unit (
        .clk(clk),
        .reset(reset),
        .load(b_load),
        .data_in(bus),
        .data_out(b_reg)
    );

    alu alu_unit (
        .a(a_reg),
        .b(b_reg),
        .alu_sel(alu_sel),
        .result(alu_result)
    );

    bus_mux bus_unit (
        .pc_data({4'b0000, pc}),
        .mem_data(memory_data),
        .ir_data({4'b0000, ir[3:0]}),
        .alu_data(alu_result),
        .a_data(a_reg),
        .pc_out(pc_out),
        .mem_out(mem_out),
        .ir_out(ir_out),
        .alu_out(alu_out),
        .a_out(a_out),
        .bus(bus)
    );
endmodule
