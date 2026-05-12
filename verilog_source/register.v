module register (
    input        clk,          // clock
    input        rst,          // reset
    input        L_reg,        // Load signal 
    input  [7:0] bus_in,       // 8-bit shared bus input
    output reg [7:0] reg_val   // Stored register value
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            reg_val <= 8'h00;  
        else if (L_reg)
            reg_val <= bus_in;  
    end

endmodule
