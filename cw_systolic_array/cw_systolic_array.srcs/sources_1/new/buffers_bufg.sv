`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.04.2025 21:56:16
// Design Name: 
// Module Name: buff_10
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


module buffers_bufg #(
    parameter NUM_BUFFERS=10,
    parameter  IO_WIDTH=4,
    parameter SEL_LENGTH=10)
    (input [SEL_LENGTH-1:0]sel,
    input [IO_WIDTH-1:0] in,
    output wire [IO_WIDTH:0] out
    );
   //wire[3:0]  out_del, out_del1, out_del2, out_del3, out_del4, out_del5, out_del6, out_del7, out_del8, out_del9;
   //reg[3:0] in_del1, in_del2, in_del3, in_del4, in_del5, in_del6, in_del7, in_del8, in_del9;
    // Delay stages using buffers (XOR with 0 to introduce delay)
     
    wire [IO_WIDTH-1:0] out_del_array [NUM_BUFFERS-1:0];
    wire [IO_WIDTH-1:0] in_del_array [NUM_BUFFERS+1:0]; 
    
    assign in_del_array[0] = in;
    
    /*
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : buffer_gen 
             (* KEEP, DONT_TOUCH *) LUT1 #(.INIT(2'b10)) u_buf0  (.I0(in[i]),      .O(out_del[i]));   // Buffer stage 1  
             (* KEEP, DONT_TOUCH *) LUT1 #(.INIT(2'b10)) u_buf1  (.I0(in_del1[i]), .O(out_del1[i]));  // Buffer stage 2  
             (* KEEP, DONT_TOUCH *) LUT1 #(.INIT(2'b10)) u_buf2  (.I0(in_del2[i]), .O(out_del2[i]));  // Buffer stage 3  
             (* KEEP, DONT_TOUCH *) LUT1 #(.INIT(2'b10)) u_buf3 (.I0(in_del3[i]), .O(out_del3[i]));  // Buffer stage 4  
             (* KEEP, DONT_TOUCH *) LUT1 #(.INIT(2'b10)) u_buf4 (.I0(in_del4[i]), .O(out_del4[i]));  // Buffer stage 5  
             (* KEEP, DONT_TOUCH *) LUT1 #(.INIT(2'b10)) u_buf5 (.I0(in_del5[i]), .O(out_del5[i]));  // Buffer stage 6  
             (* KEEP, DONT_TOUCH *) LUT1 #(.INIT(2'b10)) u_buf6 (.I0(in_del6[i]), .O(out_del6[i]));  // Buffer stage 7  
             (* KEEP, DONT_TOUCH *) LUT1 #(.INIT(2'b10)) u_buf7 (.I0(in_del7[i]), .O(out_del7[i]));  // Buffer stage 8  
             (* KEEP, DONT_TOUCH *) LUT1 #(.INIT(2'b10)) u_buf8 (.I0(in_del8[i]), .O(out_del8[i]));  // Buffer stage 9  
             (* KEEP, DONT_TOUCH *) LUT1 #(.INIT(2'b10)) u_buf9 (.I0(in_del9[i]), .O(out_del9[i]));  // Buffer stage 10  
        end
    endgenerate  
    */
    
    genvar i, j; 
    generate 
        for (i = 0; i < NUM_BUFFERS; i = i+1) begin : buffer_gen
            for (j= 0; j < IO_WIDTH; j = j + 1) begin 
                (* KEEP, DONT_TOUCH *) BUFG u_buf  (.I(in_del_array[i][j]),      .O(out_del_array[i][j]));   
            end 
        end 
    endgenerate 
    
   genvar k; 
   generate 
        for (k = 0; k < NUM_BUFFERS; k = k + 1) begin : mux_gen 
            mux2x1 #(.WIDTH(IO_WIDTH)) mux_inst (.in0(out_del_array[k]), .in1(in_del_array[k]), .sel(sel[k]), .out(in_del_array[k+1]));
        end 
   endgenerate 
   
   assign out = in_del_array[NUM_BUFFERS];
    /*
    always @(*) begin
        // Stage 1: Apply delay or bypass
        in_del1 = sel[0] ? out_del : in;

        // Stage 2: Apply delay or bypass
        in_del2 = sel[1] ? out_del1 : in_del1;

        // Stage 3: Apply delay or bypass
        in_del3 = sel[2] ? out_del2 : in_del2;

        // Stage 4: Apply delay or bypass
        in_del4 = sel[3] ? out_del3 : in_del3;

        // Stage 5: Apply delay or bypass
        in_del5 = sel[4] ? out_del4 : in_del4;

        // Stage 6: Apply delay or bypass
        in_del6 = sel[5] ? out_del5 : in_del5;

        // Stage 7: Apply delay or bypass
        in_del7 = sel[6] ? out_del6 : in_del6;

        // Stage 8: Apply delay or bypass
        in_del8 = sel[7] ? out_del7 : in_del7;

        // Stage 9: Apply delay or bypass
        in_del9 = sel[8] ? out_del8 : in_del8;

        // Final output selection
        out = sel[9] ? out_del9 : in_del9;
        //out = in_del1;
    end */
endmodule
