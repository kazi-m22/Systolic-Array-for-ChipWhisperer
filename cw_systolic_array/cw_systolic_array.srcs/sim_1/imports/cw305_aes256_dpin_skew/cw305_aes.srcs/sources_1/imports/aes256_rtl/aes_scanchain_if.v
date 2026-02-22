module aes_scanchain_if (
    input wire CLK,    // Clock
    input wire CLK_SKEWED, // SKEWED CLK for AES Latch
    input wire RST_N,  // Asynchronous reset active low
    input wire ENABLE,

    input wire SC_CLK1, SC_CLK2,
    input wire SCAN_IN, UPDATE, CAPTURE,
    output wire SCAN_OUT,

    output wire TRIGGER,
    output wire CT_SER_OUT
);

wire [386:0] scan_array;
wire [386:0] ct;

aes_if aes_if0(CLK,CLK_SKEWED, RST_N, scan_array, ENABLE, TRIGGER, ct, CT_SER_OUT);
scan_chain_aes sc(.SC_CLK1(SC_CLK1),
               .SC_CLK2(SC_CLK2),
               .RST_N(RST_N),
               .SCAN_IN(SCAN_IN),
               .UPDATE(UPDATE),
               .CAPTURE(CAPTURE),
               .PAR_IN(ct),
               .SCAN_OUT(SCAN_OUT),
               .SCAN_REG(scan_array));
endmodule