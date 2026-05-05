`timescale 1ns/1ps

module memory (
    input wire [3:0] address,
    output wire [7:0] data_out
);
    reg [7:0] mem [0:15];

    initial begin
        mem[0]  = 8'h13; // LDA 3
        mem[1]  = 8'h26; // ADD 6
        mem[2]  = 8'hF0; // HLT
        mem[3]  = 8'h04; // data: 4
        mem[4]  = 8'h00;
        mem[5]  = 8'h00;
        mem[6]  = 8'h05; // data: 5
        mem[7]  = 8'h00;
        mem[8]  = 8'h00;
        mem[9]  = 8'h00;
        mem[10] = 8'h00;
        mem[11] = 8'h00;
        mem[12] = 8'h00;
        mem[13] = 8'h00;
        mem[14] = 8'h00;
        mem[15] = 8'h00;
    end

    // SAP-1 memory read is modeled as asynchronous for simple timing.
    assign data_out = mem[address];
endmodule
