`timescale 1ns/1ps

module register8 (
    input wire clk,
    input wire reset,
    input wire load,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            data_out <= 8'b00000000;
        else if (load)
            data_out <= data_in;
    end
endmodule
