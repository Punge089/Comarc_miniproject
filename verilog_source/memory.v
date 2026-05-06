// ============================================================
// File        : memory.v
// Module      : memory
// Description : 16x8 RAM (16 addresses, each 8-bit wide) for SAP-1.
//
// This is a READ-ONLY memory (ROM-like) for this implementation.
// The content is set during simulation using $readmemh or initial block.
//
// Control Signal:
//   CE (Chip Enable) - When CE=1, the top module places mem_data
//                      (the byte at address mar_val) onto the bus.
//                      (CE is used in sap1_top bus mux, not here.)
//
// Memory Map (Default Test Program):
//   Address | Hex  | Binary    | Meaning
//   --------|------|-----------|----------------------------
//   0x0     | 0x03 | 0000 0011 | LDA 3  (opcode=0000, addr=3)
//   0x1     | 0x16 | 0001 0110 | ADD 6  (opcode=0001, addr=6)
//   0x2     | 0xF0 | 1111 0000 | HLT    (opcode=1111)
//   0x3     | 0x04 | 0000 0100 | Data = 4
//   0x4     | 0x00 | 0000 0000 | Data = 0 (unused)
//   0x5     | 0x00 | 0000 0000 | Data = 0 (unused)
//   0x6     | 0x05 | 0000 0101 | Data = 5
//   0x7-0xF | 0x00 | 0000 0000 | Empty (unused)
//
// NOTE: To test different instructions (SUB, MUL, DIV), the testbench
//       directly overwrites ram[1] using hierarchical access:
//       DUT.u_mem.ram[1] = 8'hXX;
// ============================================================
module memory (
    input  [3:0] mar_val,     // Address from MAR (4-bit = 16 locations)
    output [7:0] mem_data     // Data output (placed on bus when CE=1 in top)
);

    reg [7:0] ram [0:15];    // 16 bytes of memory

    // --- Pre-load memory with default test program ---
    initial begin
        ram[0]  = 8'h03;  // LDA 3  → fetch & execute: load Mem[3] into A
        ram[1]  = 8'h16;  // ADD 6  → fetch & execute: A = A + Mem[6]
        ram[2]  = 8'hF0;  // HLT    → halt the CPU
        ram[3]  = 8'h04;  // Data = 4 (first operand)
        ram[4]  = 8'h00;  // unused
        ram[5]  = 8'h00;  // unused
        ram[6]  = 8'h05;  // Data = 5 (second operand)
        ram[7]  = 8'h00;  // unused
        ram[8]  = 8'h00;  // unused
        ram[9]  = 8'h00;  // unused
        ram[10] = 8'h00;  // unused
        ram[11] = 8'h00;  // unused
        ram[12] = 8'h00;  // unused
        ram[13] = 8'h00;  // unused
        ram[14] = 8'h00;  // unused
        ram[15] = 8'h00;  // unused
    end

    // Combinational read: output changes immediately when mar_val changes
    assign mem_data = ram[mar_val];

endmodule
