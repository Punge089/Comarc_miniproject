module sap1_top (
    input        clk,       // clock 
    input        rst,       //reset

    output [7:0] bus,       // Current bus value
    output [3:0] pc_out,    // Program Counter value
    output [3:0] mar_out,   // Memory Address Register value
    output [7:0] ir_out,    // Instruction Register value
    output [7:0] a_out,     // A Register value
    output [7:0] b_out,     // B Register value
    output [7:0] alu_out,   // ALU result
    output [2:0] t_state,   // Current T-state 
    output       hlt,       // Halt flag
    output Cp, Ep, Lm, CE, Li, Ei, La, Ea, Su, Eu, Lb, Mu, Du
);

    wire [3:0] pc_val;      // PC output 
    wire [3:0] mar_val;     // MAR output 
    wire [7:0] ir_val;      // IR output 
    wire [3:0] ir_opcode;   // IR[7:4] 
    wire [3:0] ir_addr;     // IR[3:0] 
    wire [7:0] a_val;       // A register output 
    wire [7:0] b_val;       // B register output 
    wire [7:0] alu_result;  // ALU output
    wire [7:0] mem_data;    // Memory output 

    assign bus = Ep ? {4'b0000, pc_val} :  
                 CE ? mem_data           :  
                 Ei ? {4'b0000, ir_addr} :  
                 Ea ? a_val              : 
                 Eu ? alu_result         :  
                 8'h00;                     

    program_counter u_pc (
        .clk    (clk),
        .rst    (rst),
        .Cp     (Cp),      
        .pc_val (pc_val)    
    );

    mar u_mar (
        .clk     (clk),
        .rst     (rst),
        .Lm      (Lm),     
        .bus_in  (bus),      
        .mar_val (mar_val)   
    );

    instruction_register u_ir (
        .clk       (clk),
        .rst       (rst),
        .Li        (Li),       
        .bus_in    (bus),      
        .ir_val    (ir_val),   
        .ir_opcode (ir_opcode),// Upper 4 bits 
        .ir_addr   (ir_addr)   // Lower 4 bits 
    );

    // A Register
    register u_a (
        .clk     (clk),
        .rst     (rst),
        .L_reg   (La),     
        .bus_in  (bus),     
        .reg_val (a_val)  
    );

    // B Register
    register u_b (
        .clk     (clk),
        .rst     (rst),
        .L_reg   (Lb),   
        .bus_in  (bus),     
        .reg_val (b_val)    
    );

    // ALU
    alu u_alu (
        .a_val      (a_val),      
        .b_val      (b_val),     
        .Su         (Su),       
        .Mu         (Mu),       
        .Du         (Du),        
        .alu_result (alu_result)  
    );

    // Memory
    memory u_mem (
        .mar_val  (mar_val),  
        .mem_data (mem_data)  
    );

    // Control Unit
    control_unit u_cu (
        .clk     (clk),
        .rst     (rst),
        .opcode  (ir_opcode),

        // Control signal outputs
        .Cp(Cp), .Ep(Ep), .Lm(Lm), .CE(CE),
        .Li(Li), .Ei(Ei), .La(La), .Ea(Ea),
        .Su(Su), .Eu(Eu), .Lb(Lb), .Mu(Mu), .Du(Du),

        .hlt     (hlt),
        .t_state (t_state)
    );

    assign pc_out  = pc_val;
    assign mar_out = mar_val;
    assign ir_out  = ir_val;
    assign a_out   = a_val;
    assign b_out   = b_val;
    assign alu_out = alu_result;

endmodule
