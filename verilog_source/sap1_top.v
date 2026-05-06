// ============================================================
// File        : sap1_top.v
// Module      : sap1_top (Top-Level CPU)
// Description : Top-level module that connects all SAP-1 submodules
//               via a shared 8-bit bus (mux-based implementation).
//
// Bus Design:
//   The single shared bus carries data between modules.
//   ONLY ONE module drives the bus at a time, selected by control signals:
//     Ep=1 → PC value  (upper 4 bits padded with zeros)
//     CE=1 → Memory data
//     Ei=1 → IR lower 4 bits (address field, upper 4 bits zero-padded)
//     Ea=1 → A register value
//     Eu=1 → ALU result
//   If none of the above: bus = 0x00 (idle)
//
// Module Connections:
//   +------------------+       8-bit bus        +------------------+
//   |  program_counter |---[Ep]---------------->|                  |
//   |  mar             |<--[Lm]-----------------|                  |
//   |  instruction_reg |<--[Li]--[Ei]-----------|    SHARED BUS    |
//   |  register (A)    |<--[La]--[Ea]---------->|                  |
//   |  register (B)    |<--[Lb]-----------------|                  |
//   |  alu             |---[Eu]---------------->|                  |
//   |  memory          |---[CE]---------------->|                  |
//   +------------------+                        +------------------+
//
// All debug signals are exposed as outputs for Vivado waveform analysis.
// ============================================================
module sap1_top (
    input        clk,       // System clock (10ns period in testbench)
    input        rst,       // Active-high synchronous reset

    // --- Debug Outputs (connect all to waveform in Vivado) ---
    output [7:0] bus,       // Current bus value
    output [3:0] pc_out,    // Program Counter value
    output [3:0] mar_out,   // Memory Address Register value
    output [7:0] ir_out,    // Instruction Register value
    output [7:0] a_out,     // A Register value
    output [7:0] b_out,     // B Register value
    output [7:0] alu_out,   // ALU result (combinational)
    output [2:0] t_state,   // Current T-state (1-6)
    output       hlt,       // Halt flag

    // --- Control Signals (expose for waveform visibility) ---
    output Cp, Ep, Lm, CE, Li, Ei, La, Ea, Su, Eu, Lb, Mu, Du
);

    // --------------------------------------------------------
    // Internal wire connections between modules
    // --------------------------------------------------------
    wire [3:0] pc_val;      // PC output → bus mux, debug
    wire [3:0] mar_val;     // MAR output → memory address input
    wire [7:0] ir_val;      // IR output → debug
    wire [3:0] ir_opcode;   // IR[7:4] → control unit
    wire [3:0] ir_addr;     // IR[3:0] → bus mux (when Ei=1)
    wire [7:0] a_val;       // A register output → ALU, bus mux
    wire [7:0] b_val;       // B register output → ALU
    wire [7:0] alu_result;  // ALU output → bus mux
    wire [7:0] mem_data;    // Memory output → bus mux

    // --------------------------------------------------------
    // BUS MUX — Exactly one source drives bus at each step
    // Priority matches the T-state sequence:
    //   T1: Ep (PC → bus)
    //   T3: CE (Mem → bus)
    //   T4: Ei (IR addr → bus)
    //   T5: CE (Mem → bus)    [for all instructions]
    //   T6: Eu (ALU → bus)    [for ADD/SUB/MUL/DIV]
    // Ea is available if future instructions need A on bus.
    // --------------------------------------------------------
    assign bus = Ep ? {4'b0000, pc_val} :  // PC value (zero-padded to 8 bits)
                 CE ? mem_data           :  // Memory data
                 Ei ? {4'b0000, ir_addr} :  // IR address field (zero-padded)
                 Ea ? a_val              :  // A register value
                 Eu ? alu_result         :  // ALU result
                 8'h00;                     // Bus idle (no driver)

    // --------------------------------------------------------
    // Submodule Instantiations
    // --------------------------------------------------------

    // Program Counter: tracks which instruction address to fetch next
    program_counter u_pc (
        .clk    (clk),
        .rst    (rst),
        .Cp     (Cp),        // Control unit increments PC at T2
        .pc_val (pc_val)     // Output to bus mux (used when Ep=1 at T1)
    );

    // Memory Address Register: holds the address for memory to read
    mar u_mar (
        .clk     (clk),
        .rst     (rst),
        .Lm      (Lm),       // Latch bus at T1 (PC addr) and T4 (operand addr)
        .bus_in  (bus),      // Receives address from bus
        .mar_val (mar_val)   // Output to memory module
    );

    // Instruction Register: holds the current instruction being executed
    instruction_register u_ir (
        .clk       (clk),
        .rst       (rst),
        .Li        (Li),       // Latch bus at T3 (instruction byte)
        .bus_in    (bus),      // Receives instruction from bus
        .ir_val    (ir_val),   // Full 8-bit stored instruction
        .ir_opcode (ir_opcode),// Upper 4 bits → control unit for decoding
        .ir_addr   (ir_addr)   // Lower 4 bits → bus mux (used when Ei=1 at T4)
    );

    // A Register: stores first operand and final result
    register u_a (
        .clk     (clk),
        .rst     (rst),
        .L_reg   (La),      // La=1: latch from bus (at T5 for LDA, T6 for others)
        .bus_in  (bus),     // Data from bus
        .reg_val (a_val)    // A value → ALU, bus mux (when Ea=1)
    );

    // B Register: stores second operand for ALU
    register u_b (
        .clk     (clk),
        .rst     (rst),
        .L_reg   (Lb),      // Lb=1: latch from bus (at T5 for ADD/SUB/MUL/DIV)
        .bus_in  (bus),     // Data from bus
        .reg_val (b_val)    // B value → ALU only (B never drives bus directly)
    );

    // ALU: performs arithmetic operation, result available combinationally
    alu u_alu (
        .a_val      (a_val),      // Current A register value
        .b_val      (b_val),      // Current B register value
        .Su         (Su),         // Subtract mode (set at T6 for SUB)
        .Mu         (Mu),         // Multiply mode (set at T6 for MUL)
        .Du         (Du),         // Divide mode (set at T6 for DIV)
        .alu_result (alu_result)  // Result → bus mux (when Eu=1 at T6)
    );

    // Memory: 16 bytes of read-only program/data storage
    memory u_mem (
        .mar_val  (mar_val),  // Address from MAR
        .mem_data (mem_data)  // Data output → bus mux (when CE=1)
    );

    // Control Unit: generates all control signals based on T-state + opcode
    control_unit u_cu (
        .clk     (clk),
        .rst     (rst),
        .opcode  (ir_opcode), // From IR[7:4] after T3

        // Control signal outputs → modules + bus mux
        .Cp(Cp), .Ep(Ep), .Lm(Lm), .CE(CE),
        .Li(Li), .Ei(Ei), .La(La), .Ea(Ea),
        .Su(Su), .Eu(Eu), .Lb(Lb), .Mu(Mu), .Du(Du),

        .hlt     (hlt),
        .t_state (t_state)
    );

    // --- Connect internal wires to debug outputs ---
    assign pc_out  = pc_val;
    assign mar_out = mar_val;
    assign ir_out  = ir_val;
    assign a_out   = a_val;
    assign b_out   = b_val;
    assign alu_out = alu_result;

endmodule
