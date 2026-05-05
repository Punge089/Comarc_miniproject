`timescale 1ns/1ps

module control_unit (
    input wire clk,
    input wire reset,
    input wire [3:0] opcode,
    output reg pc_out,
    output reg pc_inc,
    output reg mar_load,
    output reg mem_out,
    output reg ir_load,
    output reg ir_out,
    output reg a_load,
    output reg a_out,
    output reg b_load,
    output reg alu_out,
    output reg [1:0] alu_sel,
    output wire halt,
    output reg [2:0] t_state
);
    localparam T0 = 3'd0;
    localparam T1 = 3'd1;
    localparam T2 = 3'd2;
    localparam T3 = 3'd3;
    localparam T4 = 3'd4;

    localparam OP_LDA = 4'h1;
    localparam OP_ADD = 4'h2;
    localparam OP_SUB = 4'h3;
    localparam OP_MUL = 4'h4;
    localparam OP_DIV = 4'h5;
    localparam OP_HLT = 4'hF;

    reg halted;
    reg instruction_done;

    assign halt = halted;

    always @(*) begin
        pc_out = 1'b0;
        pc_inc = 1'b0;
        mar_load = 1'b0;
        mem_out = 1'b0;
        ir_load = 1'b0;
        ir_out = 1'b0;
        a_load = 1'b0;
        a_out = 1'b0;
        b_load = 1'b0;
        alu_out = 1'b0;
        alu_sel = 2'b00;
        instruction_done = 1'b0;

        if (!halted) begin
            case (t_state)
                T0: begin
                    // Fetch 1: PC -> MAR
                    pc_out = 1'b1;
                    mar_load = 1'b1;
                end

                T1: begin
                    // Fetch 2: RAM[MAR] -> IR, then PC++
                    mem_out = 1'b1;
                    ir_load = 1'b1;
                    pc_inc = 1'b1;
                end

                T2: begin
                    case (opcode)
                        OP_LDA, OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin
                            // Operand address from IR[3:0] -> MAR
                            ir_out = 1'b1;
                            mar_load = 1'b1;
                        end
                        OP_HLT: begin
                            instruction_done = 1'b1;
                        end
                        default: begin
                            instruction_done = 1'b1;
                        end
                    endcase
                end

                T3: begin
                    case (opcode)
                        OP_LDA: begin
                            // RAM[MAR] -> A
                            mem_out = 1'b1;
                            a_load = 1'b1;
                            instruction_done = 1'b1;
                        end
                        OP_ADD, OP_SUB, OP_MUL, OP_DIV: begin
                            // RAM[MAR] -> B
                            mem_out = 1'b1;
                            b_load = 1'b1;
                        end
                        default: begin
                            instruction_done = 1'b1;
                        end
                    endcase
                end

                T4: begin
                    case (opcode)
                        OP_ADD: begin
                            alu_sel = 2'b00;
                            alu_out = 1'b1;
                            a_load = 1'b1;
                            instruction_done = 1'b1;
                        end
                        OP_SUB: begin
                            alu_sel = 2'b01;
                            alu_out = 1'b1;
                            a_load = 1'b1;
                            instruction_done = 1'b1;
                        end
                        OP_MUL: begin
                            alu_sel = 2'b10;
                            alu_out = 1'b1;
                            a_load = 1'b1;
                            instruction_done = 1'b1;
                        end
                        OP_DIV: begin
                            alu_sel = 2'b11;
                            alu_out = 1'b1;
                            a_load = 1'b1;
                            instruction_done = 1'b1;
                        end
                        default: begin
                            instruction_done = 1'b1;
                        end
                    endcase
                end

                default: begin
                    instruction_done = 1'b1;
                end
            endcase
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            t_state <= T0;
            halted <= 1'b0;
        end else if (!halted) begin
            if (t_state == T2 && opcode == OP_HLT) begin
                halted <= 1'b1;
                t_state <= T2;
            end else if (instruction_done) begin
                t_state <= T0;
            end else begin
                t_state <= t_state + 3'd1;
            end
        end
    end
endmodule
