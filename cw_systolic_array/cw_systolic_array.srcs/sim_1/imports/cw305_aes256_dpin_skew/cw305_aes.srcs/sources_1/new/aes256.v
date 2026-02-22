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
	output wire [127:0] o_text,
	output wire busy_o
);

parameter BUFFER_GROUPING = 4; 

reg enable;
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

assign busy_o = busy_r; 

reg [3:0] round;
reg [3:0] next_round;

reg [255:0] round_keys;
reg [255:0] next_round_keys;
reg [255:0] prev_keys;
wire [127:0] next_round_key;

reg [127:0] state;
wire [127:0] next_state;
reg [127:0] round_input;

reg [127:0] round_key;

//Countermeasure


    wire [99:0] lfsr_100_out; 
  wire [639:0]lfsr_640_out;
  wire [127:0] state_buff_out;
   wire [255:0] round_keys_buff_out;

    
    reg [255:0] round_keys_latch;
    reg [127:0] state_latch;
    
    
     
always @(posedge clk, negedge rst_n)begin 
	if(rst_n == 0) begin
		/* Reset regs */
		round <= 4'b0;
		round_keys <= 256'b0;
		state <= 128'b0;
	end
	else begin 
		/* update regs */
		round <= next_round;
		if(round[0])begin		
		round_keys <= next_round_keys;
		state <= next_state;
		end
		else begin
		round_keys[15:0] <= round_keys_buff_out[15:0];
		round_keys[127:16] <= round_keys[127:16];
		round_keys[143:128] <= round_keys_buff_out[143:128];
		round_keys[255:144] <= round_keys[255:144];
		
		//round_keys <= round_keys_buff_out; 
		//round_keys <= round_keys;
		
		//state <= state;
		state <= state_buff_out; 
		end

	end
end

always@(posedge clk)begin
    if(rst_n == 0)begin
        round_keys_latch = 256'b0;
        state_latch = 128'b0;
    end else if(enable & (round[0] == 1'b0)) begin //clk &
        round_keys_latch = next_round_keys;
        state_latch = next_state;        
    end  
      
end




assign o_text = state; 
//assign o_text = i_text;

keyexpand keyex(.ikey(prev_keys), .round(round), .okey(next_round_key));
aes_round aesround(.i_text(round_input), .round_key(round_key), .round(round), .o_text(next_state));


    
      lfsr_100 lfsr_100_inst (
        .clk(clk),
        .rst_n(rst_n),
        .lfsr(lfsr_100_out)
    );




genvar i;

generate
     for (i = 0; i < (128/BUFFER_GROUPING); i = i + 1) begin : buffers_gen
        buffers #(
                 .NUM_BUFFERS(1),
                .IO_WIDTH(BUFFER_GROUPING),
                 .SEL_LENGTH(10))
            round_input_buff (
                .sel(lfsr_100_out[(10*i) % 100 +: 10]), // Extract 10 bits for selection, reuse after 320 bits
                //.sel(10'hFFF),
                .in(state[BUFFER_GROUPING*i +: BUFFER_GROUPING]), // Extract 4-bit chunks explicitly
                .out(state_buff_out[BUFFER_GROUPING*i +: BUFFER_GROUPING]) // Assign 4-bit output range
        );
     end
    
 endgenerate   
    



// Instantiate buff_4 for prev_keys using generate block
generate
    for (i = 0; i < (256/BUFFER_GROUPING); i = i + 1) begin : prev_keys_gen
        buffers # (
             .NUM_BUFFERS(1),
            .IO_WIDTH(BUFFER_GROUPING),
             .SEL_LENGTH(10))
        prev_keys_buff (
            .sel(lfsr_100_out[(10*i) % 100 +: 10]), // Use 10 bits for each instance, reuse after 320 bits
            //.sel(10'hFFF), 
            .in(round_keys[BUFFER_GROUPING*i +: BUFFER_GROUPING]),
            .out(round_keys_buff_out[BUFFER_GROUPING*i +: BUFFER_GROUPING])
    );
    end
endgenerate 

    

    

//Countermeasure



// Round counter update
always @(*) begin
	if(enable) begin
		next_round = round + 3'h1;
	end else begin 
		next_round = 3'b0;
	end
end

// Round key either from original key(round 1) or key expansion
always @(*) begin
	if(round == 3'b0) begin
		round_key = key[127:0];
	end else begin
	    if(!round[0])//odd stages 
	       begin 
	       //round_key = round_keys_buff_out;
	       
	        round_key[15:0] = round_keys_buff_out[15:0];
            round_key[127:16] = round_keys[127:16];
            //round_key[135:128] = round_keys_buff_out[143:135];
            //round_key[255:136] = round_keys[255:136];
	   
	       //round_key = round_keys; 
	       end 
	    else
		   round_key = round_keys_latch[127:0];
	end
end

// Input to round either input xor key, or output of previous round
always @(*) begin
	if(round == 3'b0) begin
		round_input = i_text ^ key[255:128];
		round_input = i_text ^ key[255:128];
	end else begin 
	    if(!round[0]) begin  
	       //round_input = state;
	       round_input = state_buff_out; 
	      end
	    else
	       round_input = state_latch;
		
	end
end

// Input to key expansion either initial key, or previous round keys
always @(*) begin
	if(round == 3'b0) begin
		prev_keys = key;
	end else begin 
	    if(!round[0]) begin 
	      //prev_keys = round_keys_buff_out;
	       //prev_keys = round_keys;
	     
	     
            prev_keys[15:0] = round_keys_buff_out[15:0];
            prev_keys[127:16] = round_keys[127:16];
            prev_keys[143:128] = round_keys_buff_out[143:128];
            prev_keys[255:144] = round_keys[255:144];
	     end 
	    else
	       prev_keys = round_keys_latch;

	end
end


// Stored round keys updated w/ initial key or shifted 1 round key
always @(*) begin
	if(enable == 1'b1) begin
		if(round == 3'b0) begin
			next_round_keys = {key[127:0], next_round_key};
		end else begin
		  if(!round[0])
			next_round_keys = {round_keys[127:0], next_round_key};
	      else
	        next_round_keys = {round_keys_latch[127:0], next_round_key};
		end
	end else begin 
		next_round_keys = round_keys;
	end
end


assign complete = round == 4'd13;


endmodule
