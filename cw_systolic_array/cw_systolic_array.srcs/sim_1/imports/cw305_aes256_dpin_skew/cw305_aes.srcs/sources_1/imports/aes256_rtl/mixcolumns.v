`timescale 1ns / 1ns
module mixcolumns (
	input wire [127:0] istate,
	input wire bypass,

	output wire [127:0] ostate
);

genvar i;
generate
for (i = 0; i < 16; i=i+4) begin
	wire [7:0] b0, b1, b2, b3;
	wire [7:0] mb0, mb1, mb2, mb3;
	assign {b0, b1, b2, b3} = istate[8*i+31:8*i];
	// Galois Multiplication
	assign mb0 = ({b0[6:0], 1'b0} ^ (8'h1b & {8{b0[7]}})) ^ ({b1[6:0], 1'b0} ^ (8'h1b & {8{b1[7]}}) ^ b1) ^ b2 ^ b3;
	assign mb1 = ({b1[6:0], 1'b0} ^ (8'h1b & {8{b1[7]}})) ^ ({b2[6:0], 1'b0} ^ (8'h1b & {8{b2[7]}}) ^ b2) ^ b3 ^ b0;
	assign mb2 = ({b2[6:0], 1'b0} ^ (8'h1b & {8{b2[7]}})) ^ ({b3[6:0], 1'b0} ^ (8'h1b & {8{b3[7]}}) ^ b3) ^ b0 ^ b1;
	assign mb3 = ({b3[6:0], 1'b0} ^ (8'h1b & {8{b3[7]}})) ^ ({b0[6:0], 1'b0} ^ (8'h1b & {8{b0[7]}}) ^ b0) ^ b1 ^ b2;


	assign ostate[8*i+31:8*i] = bypass ? istate[8*i+31:8*i] : {mb0, mb1, mb2, mb3};
end
endgenerate
endmodule
