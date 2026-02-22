`timescale 1ns / 1ns
module addroundkey (
	input wire [127:0] istate,
	input wire [127:0] key,

	output wire [127:0] ostate
);

assign ostate = istate ^ key;

endmodule
