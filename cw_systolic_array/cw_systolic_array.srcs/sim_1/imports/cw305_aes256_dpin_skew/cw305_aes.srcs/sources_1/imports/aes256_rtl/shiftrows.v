`timescale 1ns / 1ns
module shiftrows (
	input wire [127:0] istate,

	output wire [127:0] ostate
);

wire [7:0] s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15;

assign {s0, s1, s2, s3, s4, s5, s6, s7, s8, s9, s10, s11, s12, s13, s14, s15} = istate;
assign ostate = {s0, s5, s10, s15, s4, s9, s14, s3, s8, s13, s2, s7, s12, s1, s6, s11};
endmodule
