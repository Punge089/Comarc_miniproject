// ============================================================
// File        : control_unit.v
// Module      : control_unit
// Description : Hardwired Control Unit for SAP-1.
//
// This module is the "brain" of the CPU. It generates ALL control
// signals at the correct timing step (T-state) for each instruction.
//
// How it works:
//   1. A T-state counter advances by 1 on every rising clock edge.
//   2. T1, T2, T3 are the FETCH cycle (same for ALL instructions).
//   3. T4, T5, T6 are the EXECUTE cycle (depends on the opcode).
//   4. After T6, the counter resets to T1 for the next instruction.
//
// Instruction Opcodes (upper 4 bits of IR):
//   0000 = LDA  (Load A from memory)
//   0001 = ADD  (Add memory to A)
//   0010 = SUB  (Subtract memory from A)
//   0011 = MUL  (Multiply A by memory) [extended]
//   0100 = DIV  (Divide A by memory) [extended]
//   1111 = HLT  (Halt CPU)
//
// Control Signal Reference:
//   Cp  - PC Count Pulse: PC increments by 1
//   Ep  - PC Enable: PC value goes onto bus
//   Lm  - MAR Load: MAR latches bus value
//   CE  - Memory Chip Enable: Memory[MAR] goes onto bus
//   Li  - IR Load: IR latches bus value
//   Ei  - IR Enable: IR[3:0] (address field) goes onto bus
//   La  - A Register Load: A latches bus value
//   Ea  - A Register Enable: A value goes onto bus
//   Su  - ALU Subtract mode
//   Eu  - ALU Enable: ALU result goes onto bus
//   Lb  - B Register Load: B latches bus value
//   Mu  - ALU Multiply mode [extended]
//   Du  - ALU Divide mode [extended]
//
// T-State / Control Signal Table:
// -------+--------+-----+-----+----+----+----+----+----+----+----+----+----+----+----
//  Step  | Phase  |  Cp |  Ep | Lm | CE | Li | Ei | La | Ea | Su | Eu | Lb | Mu | Du
// -------+--------+-----+-----+----+----+----+----+----+----+----+----+----+----+----
//  T1    | Fetch  |   0 |   1 |  1 |  0 |  0 |  0 |  0 |  0 |  0 |  0 |  0 |  0 |  0
//  T2    | Fetch  |   1 |   0 |  0 |  0 |  0 |  0 |  0 |  0 |  0 |  0 |  0 |  0 |  0
//  T3    | Fetch  |   0 |   0 |  0 |  1 |  1 |  0 |  0 |  0 |  0 |  0 |  0 |  0 |  0
//  T4    | Exec   |   0 |   0 |  1 |  0 |  0 |  1 |  0 |  0 |  0 |  0 |  0 |  0 |  0
//  T5 LDA| Exec   |   0 |   0 |  0 |  1 |  0 |  0 |  1 |  0 |  0 |  0 |  0 |  0 |  0
//  T5 ADD| Exec   |   0 |   0 |  0 |  1 |  0 |  0 |  0 |  0 |  0 |  0 |  1 |  0 |  0
//  T5 SUB| Exec   |   0 |   0 |  0 |  1 |  0 |  0 |  0 |  0 |  0 |  0 |  1 |  0 |  0
//  T5 MUL| Exec   |   0 |   0 |  0 |  1 |  0 |  0 |  0 |  0 |  0 |  0 |  1 |  0 |  0
//  T5 DIV| Exec   |   0 |   0 |  0 |  1 |  0 |  0 |  0 |  0 |  0 |  0 |  1 |  0 |  0
//  T6 ADD| Exec   |   0 |   0 |  0 |  0 |  0 |  0 |  1 |  0 |  0 |  1 |  0 |  0 |  0
//  T6 SUB| Exec   |   0 |   0 |  0 |  0 |  0 |  0 |  1 |  0 |  1 |  1 |  0 |  0 |  0
//  T6 MUL| Exec   |   0 |   0 |  0 |  0 |  0 |  0 |  1 |  0 |  0 |  1 |  0 |  1 |  0
//  T6 DIV| Exec   |   0 |   0 |  0 |  0 |  0 |  0 |  1 |  0 |  0 |  1 |  0 |  0 |  1
// ============================================================
module control_unit (
    input        clk,       // System clock
    input        rst,       // Active-high reset
    input  [3:0] opcode,    // Current instruction opcode from IR[7:4]

    // --- Control Signal Outputs ---
    output reg   Cp,        // PC Count Pulse
    output reg   Ep,        // PC Enable to bus
    output reg   Lm,        // MAR Load from bus
    output reg   CE,        // Memory Chip Enable to bus
    output reg   Li,        // IR Load from bus
    output reg   Ei,        // IR Enable (addr field) to bus
    output reg   La,        // A Register Load from bus
    output reg   Ea,        // A Register Enable to bus
    output reg   Su,        // ALU Subtract mode
    output reg   Eu,        // ALU Enable to bus
    output reg   Lb,        // B Register Load from bus
    output reg   Mu,        // ALU Multiply mode (extended)
    output reg   Du,        // ALU Divide mode (extended)

    output reg   hlt,             // Halt signal: CPU stops when hlt=1
    output reg [2:0] t_state      // Current T-state (1 to 6) for debugging
);

    // --- Instruction Opcode Constants ---
    localparam LDA = 4'b0000;
    localparam ADD = 4'b0001;
    localparam SUB = 4'b0010;
    localparam MUL = 4'b0011;
    localparam DIV = 4'b0100;
    localparam HLT = 4'b1111;

    // --- Halt Register ---
    // Once HLT is detected, this register latches and holds high.
    // This prevents the T-state counter from advancing.
    reg halt_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            halt_reg <= 1'b0;
        // Detect HLT opcode at T3 (just after instruction is loaded into IR)
        else if (opcode == HLT && t_state == 3'd3)
            halt_reg <= 1'b1;
    end

    // --- T-State Counter ---
    // Advances on every rising clock edge unless halted.
    // Resets to T1 after T6.
    always @(posedge clk or posedge rst) begin
        if (rst)
            t_state <= 3'd1;        // Start at T1 after reset
        else if (!halt_reg) begin
            if (t_state == 3'd6)
                t_state <= 3'd1;    // Wrap back to T1 after T6
            else
                t_state <= t_state + 1'b1;
        end
        // If halt_reg=1: t_state freezes at current value
    end

    // --- Combinational Control Signal Generation ---
    // All signals are determined by the current t_state and opcode.
    always @(*) begin
        // Default: all signals LOW (inactive)
        Cp=0; Ep=0; Lm=0; CE=0; Li=0; Ei=0;
        La=0; Ea=0; Su=0; Eu=0; Lb=0; Mu=0; Du=0;
        hlt = halt_reg;  // hlt follows the registered halt flag

        case (t_state)

            // =====================================
            // T1 — FETCH STEP 1
            // Goal: Put PC address onto bus; MAR latches it.
            // Ep=1 → PC drives its value onto the bus.
            // Lm=1 → MAR latches bus value (= PC address).
            // =====================================
            3'd1: begin
                Ep = 1'b1;   // PC value → bus
                Lm = 1'b1;   // MAR ← bus (= PC address)
            end

            // =====================================
            // T2 — FETCH STEP 2
            // Goal: Increment PC so it points to next instruction.
            // Cp=1 → PC increments by 1.
            // Bus is NOT used this step.
            // =====================================
            3'd2: begin
                Cp = 1'b1;   // PC = PC + 1
            end

            // =====================================
            // T3 — FETCH STEP 3
            // Goal: Read instruction from memory; IR latches it.
            // CE=1 → Memory reads address in MAR and drives data to bus.
            // Li=1 → IR latches the instruction byte from bus.
            // After this step, the control unit knows the opcode.
            // =====================================
            3'd3: begin
                CE = 1'b1;   // Memory[MAR] → bus
                Li = 1'b1;   // IR ← bus (instruction byte)
            end

            // =====================================
            // T4 — EXECUTE STEP 1 (same for all instructions)
            // Goal: Put the operand address (from IR) onto bus; MAR latches it.
            // Ei=1 → IR drives only its lower 4 bits (address field) onto bus.
            // Lm=1 → MAR latches this address. Now MAR holds the data address.
            // =====================================
            3'd4: begin
                Ei = 1'b1;   // IR[3:0] (operand address) → bus
                Lm = 1'b1;   // MAR ← bus (= operand address)
            end

            // =====================================
            // T5 — EXECUTE STEP 2 (depends on opcode)
            // Goal: Read operand data from memory.
            //   LDA: data goes directly into A register (La=1).
            //   ADD/SUB/MUL/DIV: data goes into B register (Lb=1).
            // =====================================
            3'd5: begin
                case (opcode)
                    LDA: begin
                        CE = 1'b1;   // Memory[MAR] → bus (operand data)
                        La = 1'b1;   // A ← bus (LDA loads data directly into A)
                    end
                    ADD: begin
                        CE = 1'b1;   // Memory[MAR] → bus (second operand)
                        Lb = 1'b1;   // B ← bus (store second operand in B for ALU)
                    end
                    SUB: begin
                        CE = 1'b1;   // Memory[MAR] → bus (second operand)
                        Lb = 1'b1;   // B ← bus
                    end
                    MUL: begin
                        CE = 1'b1;   // Memory[MAR] → bus (second operand)
                        Lb = 1'b1;   // B ← bus
                    end
                    DIV: begin
                        CE = 1'b1;   // Memory[MAR] → bus (divisor)
                        Lb = 1'b1;   // B ← bus
                    end
                    HLT: begin
                        hlt = 1'b1;  // Halt immediately
                    end
                    default: begin end  // Unknown opcode: do nothing
                endcase
            end

            // =====================================
            // T6 — EXECUTE STEP 3 (depends on opcode)
            // Goal: Perform the ALU operation and store result in A.
            //   Eu=1 → ALU result goes onto bus (mode selected by Su/Mu/Du).
            //   La=1 → A latches the result from bus.
            //   LDA has no T6 action (data was already loaded in T5).
            // =====================================
            3'd6: begin
                case (opcode)
                    LDA: begin
                        // LDA is complete after T5. Nothing to do here.
                        // T-state will reset to T1 on next clock edge.
                    end
                    ADD: begin
                        Eu = 1'b1;   // ALU result → bus (addition: A + B)
                        La = 1'b1;   // A ← bus (store result in A)
                        // Su=0, Mu=0, Du=0 → ALU is in addition mode
                    end
                    SUB: begin
                        Su = 1'b1;   // ALU mode: subtraction (A - B)
                        Eu = 1'b1;   // ALU result → bus
                        La = 1'b1;   // A ← bus
                        // Su=1 is the KEY difference that makes this SUB not ADD
                    end
                    MUL: begin
                        Mu = 1'b1;   // ALU mode: multiplication (A * B, lower 8 bits)
                        Eu = 1'b1;   // ALU result → bus
                        La = 1'b1;   // A ← bus
                    end
                    DIV: begin
                        Du = 1'b1;   // ALU mode: integer division (A / B)
                        Eu = 1'b1;   // ALU result → bus
                        La = 1'b1;   // A ← bus
                    end
                    HLT: begin
                        hlt = 1'b1;  // Keep halted
                    end
                    default: begin end
                endcase
            end

            default: begin end  // Should never happen

        endcase
    end

endmodule
