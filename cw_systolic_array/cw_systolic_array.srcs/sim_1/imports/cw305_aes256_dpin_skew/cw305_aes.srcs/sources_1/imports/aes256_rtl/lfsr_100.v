
module lfsr_100 (
    input clk,
    input rst_n,
    output reg [99:0] lfsr
);
    // Feedback equation based on a primitive polynomial for 100-bit LFSR
    wire feedback = lfsr[99] ^ lfsr[63] ^ lfsr[62] ^ lfsr[60];

    // Shift register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= 100'd1; // Initialize to a non-zero value
        end else begin
            lfsr <= {lfsr[98:0], feedback};
        end
    end
endmodule
