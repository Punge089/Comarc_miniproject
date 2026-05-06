// ============================================================
// File        : alu.v
// Module      : alu (Arithmetic Logic Unit)
// Description : 8-bit ALU for SAP-1 supporting 4 operations.
//
// Operations (selected by control signals):
//   Default (Su=0, Mu=0, Du=0) : ADDITION   → result = A + B
//   Su=1                        : SUBTRACTION → result = A - B
//   Mu=1                        : MULTIPLY    → result = A * B (lower 8 bits)
//   Du=1                        : DIVISION    → result = A / B (integer quotient)
//
// Control Signals:
//   Su (Subtract Unit) - When Su=1, ALU switches from ADD to SUB mode.
//   Mu (Multiply Unit) - When Mu=1, ALU performs multiplication (extended).
//   Du (Divide Unit)   - When Du=1, ALU performs integer division (extended).
//   Eu (Enable ALU)    - When Eu=1, the top module places alu_result onto bus.
//                        (Eu is used in sap1_top bus mux, not here.)
//
// Notes:
//   - This is a COMBINATIONAL module (no clock). The result is always available.
//   - For MUL: A 8-bit * 8-bit produces 16 bits, but we keep only the lower 8.
//     Overflow is lost (this is normal for an 8-bit system).
//   - For DIV: Integer division, remainder is discarded.
//     Division by zero returns 0 to avoid undefined behavior.
//   - Only one mode should be active at a time.
// ============================================================
module alu (
    input  [7:0] a_val,          // Operand A (from A register)
    input  [7:0] b_val,          // Operand B (from B register)
    input        Su,              // Subtract mode select
    input        Mu,              // Multiply mode select
    input        Du,              // Divide mode select
    output reg [7:0] alu_result   // Computed result (8-bit)
);

    always @(*) begin
        if (Du) begin
            // --- DIVISION MODE ---
            // Du=1 switches to integer division: result = A / B
            // Division by zero protection: return 0 if B is 0
            if (b_val == 8'h00)
                alu_result = 8'h00;   // Protect: B=0 would cause undefined behavior
            else
                alu_result = a_val / b_val;  // Integer quotient (remainder discarded)
        end
        else if (Mu) begin
            // --- MULTIPLICATION MODE ---
            // Mu=1 switches to multiplication: result = A * B (lower 8 bits only)
            // Example: 4 * 5 = 20 = 0x14 → alu_result = 0x14
            // Example: 100 * 100 = 10000, but 10000 mod 256 = 16 (overflow!)
            alu_result = a_val * b_val;  // Verilog automatically keeps lower 8 bits
        end
        else if (Su) begin
            // --- SUBTRACTION MODE ---
            // Su=1 switches to subtraction: result = A - B
            // Example: 9 - 5 = 4 → alu_result = 0x04
            alu_result = a_val - b_val;
        end
        else begin
            // --- ADDITION MODE (default) ---
            // Su=0, Mu=0, Du=0 → addition mode: result = A + B
            // Example: 4 + 5 = 9 → alu_result = 0x09
            alu_result = a_val + b_val;
        end
    end

endmodule
