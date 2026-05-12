module instruction_register (
    input        clk,          //clock
    input        rst,          //reset
    input        Li,           // Load IR
    input  [7:0] bus_in,       // 8-bit shared bus input
    output reg [7:0] ir_val,   // Stored instruction byte
    output [3:0] ir_opcode,    // Upper 4 bits: opcode 
    output [3:0] ir_addr       // Lower 4 bits: address field 
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            ir_val <= 8'h00;   
        else if (Li)
            ir_val <= bus_in;  
    end

    assign ir_opcode = ir_val[7:4]; 
    assign ir_addr   = ir_val[3:0]; 

endmodule
