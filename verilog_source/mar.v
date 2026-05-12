module mar (
    input        clk,       // clock
    input        rst,       // reset
    input        Lm,        // Load MAR: latch bus value when Lm=1
    input  [7:0] bus_in,    // 8-bit shared bus input
    output reg [3:0] mar_val // Stored address 
);

    always @(posedge clk or posedge rst) begin
        if (rst)
            mar_val <= 4'b0000;         
        else if (Lm)
            mar_val <= bus_in[3:0];    
    end

endmodule
