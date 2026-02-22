`timescale 1ns / 1ns
module subbytes (
	input [127:0] istate,
	output [127:0] ostate
);

	genvar i;
	generate
		for (i=7; i<128;i=i+8) begin
			aes_sbox s (.U(istate[i -: 8]), .S(ostate[i -: 8]), .dec(1'b0));
		end
	endgenerate


endmodule

