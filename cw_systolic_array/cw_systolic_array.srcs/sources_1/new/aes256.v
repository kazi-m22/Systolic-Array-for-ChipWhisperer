`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2025 05:01:04 PM
// Design Name: 
// Module Name: aes256
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module aes256 (
	input wire clk,    // Clock
    input wire clk_skewed, //test
	input wire rst_n,  // Asynchronous reset active low
	input wire [127:0] i_text,
	input wire [255:0] key,
	input wire load_i,
	output reg [127:0] o_text,
	output wire busy_o
);

reg enable, done;
wire complete; 
reg start_r; 
reg busy_r; 



always @(posedge clk) begin
    if (~rst_n) begin 
        busy_r <= 0; 
    end 
    else begin 
        if (load_i) begin 
            busy_r <= 1; 
            enable <= 1;
        end 
        else if (complete) begin 
            busy_r <= 0;
            enable <= 0;
        end 
   end 
end 


always @(posedge clk) begin
 done <= 0;
 if(~rst_n) begin
    o_text <= 0;
    done <= 0;
 end
 
 else if (enable == 1) begin
    o_text <= key[255:128];
    done <= 1;
 end

end

assign complete = done;
assign busy_o = busy_r; 


endmodule
