module bram_byte #(
    parameter integer ADDR_W = 12,              // 2^12 = 4096 bytes
    parameter integer DEPTH  = 4096
) (
    input  wire                 clk,
    input  wire                 we,
    input  wire [ADDR_W-1:0]    addr,
    input  wire [7:0]           din,
    output reg  [7:0]           dout
);
    (* ram_style = "block" *) reg [7:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];
    end
endmodule