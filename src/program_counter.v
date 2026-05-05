`timescale 1ns/1ps

module program_counter (
    input wire clk,
    input wire reset,
    input wire increment,
    output reg [3:0] count
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            count <= 4'b0000;
        else if (increment)
            count <= count + 4'b0001;
    end
endmodule
