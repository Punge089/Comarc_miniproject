// ============================================================
// File        : program_counter.v
// Module      : program_counter
// Description : 4-bit Program Counter for SAP-1
//
// Control Signals:
//   Cp (Count Pulse)  - When Cp=1 on rising clock edge, PC increments by 1.
//                       This advances the PC to point to the next instruction.
//   Ep (Enable PC)    - When Ep=1, the top module places PC value onto bus.
//                       (Ep is used in sap1_top for bus mux, not here.)
//
// The PC is 4 bits wide because SAP-1 only has 16 memory locations (2^4 = 16).
// ============================================================
module program_counter (
    input        clk,      // System clock
    input        rst,      // Active-high synchronous reset
    input        Cp,       // Count Pulse: increment PC when Cp=1
    output reg [3:0] pc_val // Current PC value (connected to bus mux in top)
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_val <= 4'b0000;   // Reset PC to address 0x0
        else if (Cp)
            pc_val <= pc_val + 1'b1;  // Cp=1: increment PC by 1
        // If Cp=0 and no reset: PC holds its current value
    end

endmodule
