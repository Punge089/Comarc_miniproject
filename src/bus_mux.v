`timescale 1ns/1ps

module bus_mux (
    input wire [7:0] pc_data,
    input wire [7:0] mem_data,
    input wire [7:0] ir_data,
    input wire [7:0] alu_data,
    input wire [7:0] a_data,
    input wire pc_out,
    input wire mem_out,
    input wire ir_out,
    input wire alu_out,
    input wire a_out,
    output reg [7:0] bus
);
    always @(*) begin
        if (pc_out)
            bus = pc_data;
        else if (mem_out)
            bus = mem_data;
        else if (ir_out)
            bus = ir_data;
        else if (alu_out)
            bus = alu_data;
        else if (a_out)
            bus = a_data;
        else
            bus = 8'b00000000;
    end
endmodule
