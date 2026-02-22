`timescale 1ns / 1ns
module aes_round (
	input [127:0] i_text,
	input [127:0] round_key,
	input [3:0] round,
	output wire [127:0] o_text
);
 
wire [127:0] subbytes_text, shiftrows_text, mixcolumns_text, subbytes_text_rand;
 
// Sub bytes computation for Encryption
 subbytes U1 (.istate(i_text), .ostate(subbytes_text));
 
// Shift Rows for Encryption
 shiftrows U2 (.istate(subbytes_text), .ostate(shiftrows_text));
 
// Mix Columns for Encryption
 mixcolumns U3 (.istate(shiftrows_text), .bypass(round==4'd13), .ostate(mixcolumns_text));

 
// Add Roundkey for Encryption
 addroundkey U5 (.istate(mixcolumns_text), .key(round_key), .ostate(o_text));
 

endmodule
