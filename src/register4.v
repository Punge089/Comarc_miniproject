`timescale 1ns/1ps

module register4 (
    input wire clk,
    input wire reset,
    input wire load,
    input wire [3:0] data_in,
    output reg [3:0] data_out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            data_out <= 4'b0000;
        else if (load)
            data_out <= data_in;
    end
endmodule
