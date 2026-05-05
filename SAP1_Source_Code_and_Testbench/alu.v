`timescale 1ns/1ps

module alu (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire [1:0] alu_sel,
    output reg [7:0] result
);
    always @(*) begin
        case (alu_sel)
            2'b00: result = a + b;                       // ADD
            2'b01: result = a - b;                       // SUB
            2'b10: result = a * b;                       // MUL, lower 8 bits kept
            2'b11: result = (b == 8'b0) ? 8'b0 : a / b;  // DIV, safe divide-by-zero
            default: result = 8'b0;
        endcase
    end
endmodule
