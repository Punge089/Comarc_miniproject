// ============================================================
// File        : register.v
// Module      : register (Generic 8-bit Register)
// Description : Reusable 8-bit register for SAP-1.
//               Used twice: once for A register, once for B register.
//
// A Register:
//   - Holds the first operand for ALU operations.
//   - Also stores the ALU result after each operation.
//   - Controlled by La (Load A) and Ea (Enable A to bus).
//
// B Register:
//   - Holds the second operand for ALU operations.
//   - Controlled by Lb (Load B). B never drives the bus directly.
//
// Control Signal (L_reg):
//   - When L_reg=1 on rising clock edge, the register latches the
//     current bus value.
//   - When L_reg=0: the register holds its value unchanged.
// ============================================================
module register (
    input        clk,          // System clock
    input        rst,          // Active-high reset
    input        L_reg,        // Load signal (La for A reg, Lb for B reg)
    input  [7:0] bus_in,       // 8-bit shared bus input
    output reg [7:0] reg_val   // Stored register value
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            reg_val <= 8'h00;   // Reset to 0
        else if (L_reg)
            reg_val <= bus_in;  // L_reg=1: latch bus value
        // If L_reg=0: hold current value
    end

endmodule
