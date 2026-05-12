module control_unit (
    input        clk,       //clock
    input        rst,       //reset
    input  [3:0] opcode,    //Current instruction opcode 
    output reg   Cp,        //PC Count Pulse
    output reg   Ep,        //PC Enable to bus
    output reg   Lm,        //MAR Load from bus
    output reg   CE,        //Memory Chip Enable to bus
    output reg   Li,        //IR Load from bus
    output reg   Ei,        //IR Enable to bus
    output reg   La,        //A Register Load from bus
    output reg   Ea,        //A Register Enable to bus
    output reg   Su,        //ALU Subtract mode
    output reg   Eu,        //ALU Enable to bus
    output reg   Lb,        //B Register Load from bus
    output reg   Mu,        //ALU Multiply mode 
    output reg   Du,        //ALU Divide mode 
    output reg   hlt,             //Halt signal
    output reg [2:0] t_state      //Current T-state
);
    localparam LDA = 4'b0000;
    localparam ADD = 4'b0001;
    localparam SUB = 4'b0010;
    localparam MUL = 4'b0011;
    localparam DIV = 4'b0100;
    localparam HLT = 4'b1111;
    reg halt_reg;

    always @(posedge clk or posedge rst) begin
        if (rst)
            halt_reg <= 1'b0;
        else if (opcode == HLT && t_state == 3'd3)
            halt_reg <= 1'b1;
    end

    //T-State Counter 
    always @(posedge clk or posedge rst) begin
        if (rst)
            t_state <= 3'd1;        //Start at T1 after reset
        else if (!halt_reg) begin
            if (t_state == 3'd6)
                t_state <= 3'd1;    //Wrap back to T1 after T6
            else
                t_state <= t_state + 1'b1;
        end
    end

    //Combinational Control Signal Generation
    always @(*) begin
        Cp=0; Ep=0; Lm=0; CE=0; Li=0; Ei=0;
        La=0; Ea=0; Su=0; Eu=0; Lb=0; Mu=0; Du=0;
        hlt = halt_reg; 

        case (t_state)
            // T1 FETCH STEP 1
            3'd1: begin
                Ep = 1'b1;   //PC value 
                Lm = 1'b1;   //MAR 
            end
            // T2 FETCH STEP 2
            3'd2: begin
                Cp = 1'b1;   //PC = PC + 1
            end

            // T3 FETCH STEP 3
            3'd3: begin
                CE = 1'b1;   // Memory[MAR] 
                Li = 1'b1;   // IR 
            end
            // T4 EXECUTE STEP 1
            3'd4: begin
                Ei = 1'b1;   // IR[3:0]
                Lm = 1'b1;   // MAR 
            end

            // T5  EXECUTE STEP 2 
            3'd5: begin
                case (opcode)
                    LDA: begin
                        CE = 1'b1;   // Memory[MAR] 
                        La = 1'b1;   // A ← bus 
                    end
                    ADD: begin
                        CE = 1'b1;   // Memory[MAR] 
                        Lb = 1'b1;   // B ← bus
                    end
                    SUB: begin
                        CE = 1'b1;   // Memory[MAR]
                        Lb = 1'b1;   // B ← bus
                    end
                    MUL: begin
                        CE = 1'b1;   // Memory[MAR] 
                        Lb = 1'b1;   // B ← bus
                    end
                    DIV: begin
                        CE = 1'b1;   // Memory[MAR] 
                        Lb = 1'b1;   // B ← bus
                    end
                    HLT: begin
                        hlt = 1'b1;  // Halt 
                    end
                    default: begin end
                endcase
            end

            // T6 — EXECUTE STEP 3 (depends on opcode)
            3'd6: begin
                case (opcode)
                    LDA: begin
                    end
                    ADD: begin
                        Eu = 1'b1;   // ALU result 
                        La = 1'b1;   // A ← bus 
                    end
                    SUB: begin
                        Su = 1'b1;   // ALU mode: subtraction 
                        Eu = 1'b1;   // ALU result 
                        La = 1'b1;   // A ← bus
                    end
                    MUL: begin
                        Mu = 1'b1;   // ALU mode: multiplication 
                        Eu = 1'b1;   // ALU result
                        La = 1'b1;   // A ← bus
                    end
                    DIV: begin
                        Du = 1'b1;   // ALU mode: integer division
                        Eu = 1'b1;   // ALU result 
                        La = 1'b1;   // A ← bus
                    end
                    HLT: begin
                        hlt = 1'b1;  // Keep halted
                    end
                    default: begin end
                endcase
            end

            default: begin end 

        endcase
    end

endmodule
