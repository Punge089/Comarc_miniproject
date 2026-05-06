// ============================================================
// File        : mar.v
// Module      : mar (Memory Address Register)
// Description : 4-bit MAR for SAP-1
//
// Control Signals:
//   Lm (Load MAR) - When Lm=1 on rising clock edge, MAR latches the
//                   lower 4 bits of the bus. This stores an address
//                   so the memory knows where to read from next.
//
// The MAR is 4 bits because SAP-1 only has 16 addresses (0x0 to 0xF).
// ============================================================
module mar (
    input        clk,       // System clock
    input        rst,       // Active-high reset
    input        Lm,        // Load MAR: latch bus value when Lm=1
    input  [7:0] bus_in,    // 8-bit shared bus input
    output reg [3:0] mar_val // Stored address (only 4 bits needed)
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            mar_val <= 4'b0000;         // Reset MAR to address 0
        else if (Lm)
            mar_val <= bus_in[3:0];     // Lm=1: latch lower 4 bits of bus
        // If Lm=0: MAR holds its current address
    end

endmodule
