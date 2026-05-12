module program_counter (
    input        clk,      // clock
    input        rst,      //reset
    input        Cp,       //Count Pulse: increment PC when Cp=1
    output reg [3:0] pc_val //Current PC value 
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_val <= 4'b0000;   
        else if (Cp)
            pc_val <= pc_val + 1'b1;  
    end

endmodule
