// ============================================================
// File        : instruction_register.v
// Module      : instruction_register (IR)
// Description : 8-bit Instruction Register for SAP-1
//
// The IR stores the current instruction byte fetched from memory.
// An instruction byte has two parts:
//   [7:4] = opcode  (upper 4 bits) - tells the CPU WHAT to do
//   [3:0] = address (lower 4 bits) - tells the CPU WHERE the data is
//
// Control Signals:
//   Li (Load IR)    - When Li=1 on rising clock edge, IR latches the
//                     full 8-bit instruction byte from the bus.
//   Ei (Enable IR)  - When Ei=1, the top module places only the lower
//                     4 bits (address field) onto the bus.
//                     This is used in T4 to put the operand address
//                     onto the bus so the MAR can latch it.
// ============================================================
module instruction_register (
    input        clk,          // System clock
    input        rst,          // Active-high reset
    input        Li,           // Load IR: latch bus value when Li=1
    input  [7:0] bus_in,       // 8-bit shared bus input
    output reg [7:0] ir_val,   // Stored instruction byte
    output [3:0] ir_opcode,    // Upper 4 bits: opcode (sent to control unit)
    output [3:0] ir_addr       // Lower 4 bits: address field (sent to bus when Ei=1)
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            ir_val <= 8'h00;    // Reset IR to 0
        else if (Li)
            ir_val <= bus_in;   // Li=1: latch entire instruction from bus
        // If Li=0: IR holds its current instruction
    end

    // These are combinational assignments — always valid
    assign ir_opcode = ir_val[7:4];  // Upper nibble → control unit decodes instruction
    assign ir_addr   = ir_val[3:0];  // Lower nibble → bus when Ei=1 (used in T4)

endmodule
