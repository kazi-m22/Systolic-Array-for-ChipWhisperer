// ---------------- TRUE DUAL PORT BRAM: 8-bit ----------------
`include "C:/Users/kmejbaulislam/Documents/Research/Dipal_project/d_pin_skew/d_pin_skew.srcs/sources_1/imports/fpgas/aes/hdl/cw305_aes_defines.v"
module bram_tdp_8 #(
    parameter ADDR_W = 12,
    parameter DEPTH  = 4096
)(
    input  wire                clk,
    input  wire                en_a,
    input  wire                we_a,
    input  wire [ADDR_W-1:0]   addr_a,
    input  wire [7:0]          din_a,
    output reg  [7:0]          dout_a,

    input  wire                en_b,
    input  wire                we_b,
    input  wire [ADDR_W-1:0]   addr_b,
    input  wire [7:0]          din_b,
    output reg  [7:0]          dout_b
);
    (* ram_style = "block" *) reg [7:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (en_a) begin
            if (we_a) mem[addr_a] <= din_a;
            dout_a <= mem[addr_a]; 
        end
    end

    always @(posedge clk) begin
        if (en_b) begin
            if (we_b) mem[addr_b] <= din_b;
            dout_b <= mem[addr_b];
        end
    end
endmodule

// ---------------- DUT ----------------
module dut (
    input  wire                     clk,
    input  wire                     clk_skewed, // Unused in this logic
    input  wire                     rst_n,
    input  wire [`PT_WIDTH-1:0]      i_text,
    input  wire [`KEY_WIDTH-1:0]     key,
    input  wire                     load_i,
    input  wire [`MYREG_WIDTH-1:0]  myreg1,
    input  wire [`MYREG_WIDTH-1:0]  myreg2,
    input  wire [`MYREG_WIDTH-1:0]  myreg3,
    output reg  [`CT_WIDTH-1:0]     o_text,
    output wire                     busy_o
);

    localparam integer AB_ADDR_W   = 12;
    localparam integer DEPTH_BYTES = 4096;
    localparam integer DATA_BYTES  = 126;

    // FSM states
    localparam [1:0] S_IDLE  = 2'b00;
    localparam [1:0] S_WRITE = 2'b01;
    localparam [1:0] S_RDBK  = 2'b10;
    localparam [1:0] S_DONE  = 2'b11;

    reg [1:0] state;
    assign busy_o = (state != S_IDLE);

    // BRAM signals
    reg                  A_en_b, A_we_b;
    reg  [AB_ADDR_W-1:0] A_addr_b;
    reg  [7:0]           A_din_b;
    wire [7:0]           A_dout_b;

    reg                  B_en_b, B_we_b;
    reg  [AB_ADDR_W-1:0] B_addr_b;
    reg  [7:0]           B_din_b;
    wire [7:0]           B_dout_b;

    bram_tdp_8 #(.ADDR_W(AB_ADDR_W), .DEPTH(DEPTH_BYTES)) bramA (
        .clk(clk),
        .en_a(1'b0), .we_a(1'b0), .addr_a({AB_ADDR_W{1'b0}}), .din_a(8'h00), .dout_a(),
        .en_b(A_en_b), .we_b(A_we_b), .addr_b(A_addr_b), .din_b(A_din_b), .dout_b(A_dout_b)
    );

    bram_tdp_8 #(.ADDR_W(AB_ADDR_W), .DEPTH(DEPTH_BYTES)) bramB (
        .clk(clk),
        .en_a(1'b0), .we_a(1'b0), .addr_a({AB_ADDR_W{1'b0}}), .din_a(8'h00), .dout_a(),
        .en_b(B_en_b), .we_b(B_we_b), .addr_b(B_addr_b), .din_b(B_din_b), .dout_b(B_dout_b)
    );

    // Command Decode
    wire [15:0] addr16_a = myreg1[1023:1008];
    wire [15:0] addr16_b = myreg2[1023:1008];
    wire cmdA      = (addr16_a == 16'hFFFF);
    wire cmdB      = (addr16_b == 16'h1111);
    wire both_cmd  = cmdA & cmdB;
    wire do_rdbk   = cmdA | cmdB;

    reg [`MYREG_WIDTH-1:0] r1_q, r2_q;
    reg [6:0]              byte_cnt;
    reg [AB_ADDR_W-1:0]    base_a, base_b;

    reg        rdbk_sel; 
    reg [4:0]  rd_idx;   
    reg [7:0]  rb [0:14]; // Store first 15 bytes

    wire [7:0] rdbk_dout = (rdbk_sel ? B_dout_b : A_dout_b);

    // BRAM Driving Logic
    always @(*) begin
        A_en_b = 1'b0; A_we_b = 1'b0; A_addr_b = 0; A_din_b = 8'h00;
        B_en_b = 1'b0; B_we_b = 1'b0; B_addr_b = 0; B_din_b = 8'h00;

        case (state)
            S_IDLE: begin
                if (load_i && do_rdbk && !both_cmd) begin
                    // Prime the address for the first read immediately
                    if (cmdB) begin B_en_b = 1'b1; B_addr_b = 0; end
                    else      begin A_en_b = 1'b1; A_addr_b = 0; end
                end
            end

            S_WRITE: begin
                A_en_b = 1'b1; A_we_b = 1'b1; A_addr_b = base_a + byte_cnt; A_din_b = (r1_q >> (byte_cnt * 8)) & 8'hFF;
                B_en_b = 1'b1; B_we_b = 1'b1; B_addr_b = base_b + byte_cnt; B_din_b = (r2_q >> (byte_cnt * 8)) & 8'hFF;
            end

            S_RDBK: begin
                // Drive address N+1 while we are capturing Data N
                if (rdbk_sel) begin
                    B_en_b   = 1'b1;
                    B_addr_b = (rd_idx < 15) ? (rd_idx + 1) : 15;
                end else begin
                    A_en_b   = 1'b1;
                    A_addr_b = (rd_idx < 15) ? (rd_idx + 1) : 15;
                end
            end
            
            S_DONE: begin
                // Hold enable if needed, but address no longer matters
            end
        endcase
    end

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            o_text <= 0;
            byte_cnt <= 0;
            rd_idx <= 0;
            for (i=0; i<15; i=i+1) rb[i] <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    if (load_i) begin
                        if (both_cmd) begin
                            o_text <= {`CT_WIDTH{1'b1}};
                            state  <= S_DONE;
                        end else if (do_rdbk) begin
                            rdbk_sel <= cmdB;
                            rd_idx   <= 0;
                            state    <= S_RDBK;
                        end else begin
                            r1_q     <= myreg1;
                            r2_q     <= myreg2;
                            base_a   <= addr16_a[AB_ADDR_W-1:0];
                            base_b   <= addr16_b[AB_ADDR_W-1:0];
                            byte_cnt <= 0;
                            state    <= S_WRITE;
                        end
                    end
                end

                S_WRITE: begin
                    if (byte_cnt == (DATA_BYTES - 1)) state <= S_IDLE;
                    else byte_cnt <= byte_cnt + 1'b1;
                end

                S_RDBK: begin
                    // At this edge, BRAM has responded to address rd_idx
                    if (rd_idx < 15) begin
                        rb[rd_idx] <= rdbk_dout;
                        rd_idx     <= rd_idx + 1'b1;
                    end else begin
                        // rd_idx is 15. rdbk_dout is now the 16th byte (index 15)
                        o_text <= { rdbk_dout,
                                    rb[14], rb[13], rb[12], rb[11],
                                    rb[10], rb[9],  rb[8],  rb[7],
                                    rb[6],  rb[5],  rb[4],  rb[3],
                                    rb[2],  rb[1],  rb[0] };
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule