module memory (
    input  [3:0] mar_val,     //Address from MAR 
    output [7:0] mem_data     //Data output 
);

    reg [7:0] ram [0:15];  
    initial begin
        ram[0]  = 8'h03;  // LDA 3  
        ram[1]  = 8'h16;  // ADD 6  
        ram[2]  = 8'hF0;  // HLT    
        ram[3]  = 8'h04;  // Data = 4 (first operand)
        ram[4]  = 8'h00; 
        ram[5]  = 8'h00;  
        ram[6]  = 8'h05;  // Data = 5 (second operand)
        ram[7]  = 8'h00;  
        ram[8]  = 8'h00;  
        ram[9]  = 8'h00;  
        ram[10] = 8'h00;  
        ram[11] = 8'h00;  
        ram[12] = 8'h00;  
        ram[13] = 8'h00;  
        ram[14] = 8'h00;  
        ram[15] = 8'h00;  
    end
    assign mem_data = ram[mar_val];

endmodule
