`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/07/2025 11:15:43 AM
// Design Name: 
// Module Name: mux2x1
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


module mux2x1 # (parameter WIDTH = 4)
    (
        input logic [WIDTH-1:0] in0, 
        input logic [WIDTH-1:0] in1, 
        input logic sel,
        output logic [WIDTH-1:0] out 
    );
    
    assign out = sel ? in0 : in1; 
endmodule
