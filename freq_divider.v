`timescale 1ns / 1ps
module freq_divider(
    input wire clk,
    output reg clk_out = 0
    );
    
    reg [2:0] counter = 0; // Use a 3-bit counter for dividing by 5
    
    always @(posedge clk)
    begin
        if (counter == 4) // Reset counter after 5 cycles
            counter <= 0;
        else
            counter <= counter + 1;
    end
    
    always @(posedge clk)
    begin
        if (counter == 0) // Toggle clk_out every 2.5 cycles
            clk_out <= ~clk_out;
    end
endmodule
