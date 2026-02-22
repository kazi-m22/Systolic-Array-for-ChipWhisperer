module aes_if (
    input wire CLK,    // Clock
    input wire CLK_SKEWED,
    input wire RST_N,  // Asynchronous reset active low
    input wire [386:0] SCAN_CHAIN,
    input wire ENABLE,
    output wire TRIGGER_EXT,
    output wire [386:0] CIPHERTEXT,
    output wire CT_OUT  
);

reg [127:0] plaintext;// plaintext_counter, next_plaintext_counter;
reg [255:0] key;
wire [255:0] sc_key;
wire plaintext_sel, key_sel;
wire ct_out_sel;

wire trigger, shift_done;
reg aes_enable;
reg mode, next_mode;
reg shift_enable;
wire ser_out;
wire [127:0] ct, ct_reg, sc_plaintext;


aes aes_module(.clk(CLK),.clk_skewed(CLK_SKEWED), .rst_n(RST_N), .i_text(plaintext), .key(key), .enable(aes_enable), .o_text(ct), .complete(trigger));
parallel_to_serial p2s(CLK, RST_N, ct, trigger, shift_enable, ct_reg, shift_done, ser_out);

//assign CIPHERTEXT = {259'b0, ct_reg};
assign CIPHERTEXT[127:0] = ct_reg;
assign {sc_plaintext, sc_key, plaintext_sel, key_sel, ct_out_sel} = SCAN_CHAIN;
assign CT_OUT = ct_out_sel ? ser_out : 1'b0;
assign TRIGGER_EXT = ct_out_sel ? shift_done : trigger;
// assign CIPHERTEXT = ct;

// Registers
always @(posedge CLK, negedge RST_N) begin
    if(RST_N == 1'b0) begin
        //plaintext_counter <= 128'b0;
        mode <= 1'b0;
    end else begin
        //plaintext_counter <= next_plaintext_counter;
        mode <= next_mode;
    end
end


// Plaintext Mux
always @(*) begin
    plaintext = ct_reg;
    if(plaintext_sel == 1'b1) begin
        plaintext = sc_plaintext;
    end
end

// Key Mux
always @(*) begin
    key = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
    if(key_sel == 1'b1) begin
        key = sc_key;
    end
end


// Mode FSM Next state logic
always @(*) begin
    next_mode = mode;
    case (mode)
        1'b0:begin 
            if(trigger && ct_out_sel) begin
                next_mode = 1'b1;
            end
        end
        1'b1:begin
            if(shift_done) begin
                next_mode = 1'b0;
            end
        end
        default : next_mode = mode;
    endcase
end

// Mode FSM output logic
always @(*) begin
    case (mode)
        1'b0:begin 
            aes_enable = ENABLE;
            shift_enable = 1'b0;
        end
        1'b1:begin
            aes_enable = 1'b0;
            shift_enable = 1'b1;
        end
        default :begin 
            aes_enable = 1'b0;
            shift_enable = 1'b0;
        end 
    endcase
end


/*
always @(*) begin
    next_plaintext_counter = plaintext_counter;
    if(trigger == 1'b1) begin
        next_plaintext_counter[7:0] = plaintext_counter[7:0] + 8'b1;
        next_plaintext_counter[15:8] = plaintext_counter[15:8] + 8'b1;
        next_plaintext_counter[23:16] = plaintext_counter[23:16] + 8'b1;
        next_plaintext_counter[31:24] = plaintext_counter[31:24] + 8'b1;
        next_plaintext_counter[39:32] = plaintext_counter[39:32] + 8'b1;
        next_plaintext_counter[47:40] = plaintext_counter[47:40] + 8'b1;
        next_plaintext_counter[55:48] = plaintext_counter[55:48] + 8'b1;
        next_plaintext_counter[63:56] = plaintext_counter[63:56] + 8'b1;
        next_plaintext_counter[71:64] = plaintext_counter[71:64] + 8'b1;
        next_plaintext_counter[79:72] = plaintext_counter[79:72] + 8'b1;
        next_plaintext_counter[87:80] = plaintext_counter[87:80] + 8'b1;
        next_plaintext_counter[95:88] = plaintext_counter[95:88] + 8'b1;
        next_plaintext_counter[103:96] = plaintext_counter[103:96] + 8'b1;
        next_plaintext_counter[111:104] = plaintext_counter[111:104] + 8'b1;
        next_plaintext_counter[119:112] = plaintext_counter[119:112] + 8'b1;
        next_plaintext_counter[127:120] = plaintext_counter[127:120] + 8'b1;
    end 
end
*/


endmodule