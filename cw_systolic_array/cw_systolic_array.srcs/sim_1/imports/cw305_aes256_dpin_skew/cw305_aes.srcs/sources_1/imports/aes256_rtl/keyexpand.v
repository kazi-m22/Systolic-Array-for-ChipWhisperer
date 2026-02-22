`timescale 1ns / 1ns
module keyexpand (
	
	input wire [255:0] ikey,
	input wire [3:0] round,

	output wire [127:0] okey
);

wire [31:0] k0, k1, k2, k3, k4, k5, k6, k7;
reg [31:0] v0, v1, v2, v3;

reg [31:0] Rcon; //Round Constant

wire [7:0] o0;
wire [7:0] o1;
wire [7:0] o2;
wire [7:0] o3;

assign {k0, k1, k2, k3, k4, k5, k6, k7} = ikey;

sbox sbox0(.index(k7[7:0]), .o(o3));
sbox sbox1(.index(k7[15:8]), .o(o2));
sbox sbox2(.index(k7[23:16]), .o(o1));
sbox sbox3(.index(k7[31:24]), .o(o0));

always @(*) begin
	// Round key generation changes alternate rounds
	if(round[0] == 1'b0) begin
		v0 = k0 ^ {o1, o2, o3, o0} ^ Rcon;
		v1 = k1 ^ v0;
		v2 = k2 ^ v1;
		v3 = k3 ^ v2;
	end else begin 
		v0 = k0 ^ {o0, o1, o2, o3};
		v1 = k1 ^ v0;
		v2 = k2 ^ v1;
		v3 = k3 ^ v2;
	end

end

assign okey = {v0, v1, v2, v3};


always @(*) begin
	case (round)
		4'h0 : Rcon = {8'h01, 24'h0};
		4'h2 : Rcon = {8'h02, 24'h0};
		4'h4 : Rcon = {8'h04, 24'h0};
		4'h6 : Rcon = {8'h08, 24'h0};
		4'h8 : Rcon = {8'h10, 24'h0};
		4'ha : Rcon = {8'h20, 24'h0};
		4'hc : Rcon = {8'h40, 24'h0};
		default : Rcon = {8'h01, 24'h0};
	endcase
end
endmodule
