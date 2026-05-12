module alu (
    input  [7:0] a_val,          //Operand A 
    input  [7:0] b_val,          //Operand B 
    input        Su,              //Subtract mode select
    input        Mu,              //Multiply mode select
    input        Du,              //Divide mode select
    output reg [7:0] alu_result   //Computed result 
);

    always @(*) begin
        if (Du) begin
            if (b_val == 8'h00)
                alu_result = 8'h00;  
            else
                alu_result = a_val / b_val;  
        end
        else if (Mu) begin
            alu_result = a_val * b_val;  
        end
        else if (Su) begin
            alu_result = a_val - b_val;
        end
        else begin
            alu_result = a_val + b_val;
        end
    end

endmodule
