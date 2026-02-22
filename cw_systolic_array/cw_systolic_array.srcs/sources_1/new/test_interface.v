module bram_tdp_32 #(
    parameter ADDR_W = 16,
    parameter DEPTH  = 4096
)(
    input  wire                clk,
    // Port A (Used by IP)
    input  wire                en_a,
    input  wire [3:0]          we_a,   // Byte-write enables
    input  wire [ADDR_W-1:0]   addr_a,
    input  wire [31:0]         din_a,
    output reg  [31:0]         dout_a,

    // Port B (Used by Host)
    input  wire                en_b,
    input  wire [3:0]          we_b,
    input  wire [ADDR_W-1:0]   addr_b,
    input  wire [31:0]         din_b,
    output reg  [31:0]         dout_b
);
    (* ram_style = "block" *) reg [31:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (en_a) begin
            if (we_a[0]) mem[addr_a][7:0]   <= din_a[7:0];
            if (we_a[1]) mem[addr_a][15:8]  <= din_a[15:8];
            if (we_a[2]) mem[addr_a][23:16] <= din_a[23:16];
            if (we_a[3]) mem[addr_a][31:24] <= din_a[31:24];
            dout_a <= mem[addr_a];
        end
    end

    always @(posedge clk) begin
        if (en_b) begin
            if (we_b[0]) mem[addr_b][7:0]   <= din_b[7:0];
            if (we_b[1]) mem[addr_b][15:8]  <= din_b[15:8];
            if (we_b[2]) mem[addr_b][23:16] <= din_b[23:16];
            if (we_b[3]) mem[addr_b][31:24] <= din_b[31:24];
            dout_b <= mem[addr_b];
        end
    end
endmodule

module bram_tdp_8 #(
    parameter ADDR_W = 16,
    parameter DEPTH = 4096
    )(
    input wire clk,
    input wire en_a,
    input wire we_a,
    input wire [ADDR_W-1:0] addr_a,
    input wire [7:0] din_a,
    output reg [7:0] dout_a,
    
    
    input wire en_b,
    input wire we_b,
    input wire [ADDR_W-1:0] addr_b,
    input wire [7:0] din_b,
    output reg [7:0] dout_b
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



module dut (
    input  wire                         clk,
    input  wire                         clk_skewed,
    input  wire                         rst_n,
    input  wire [`PT_WIDTH-1:0]          i_text,
    input  wire [`KEY_WIDTH-1:0]         key,
    input  wire                         load_i,
    input  wire [`MYREG_WIDTH-1:0]       myreg1,
    input  wire [`MYREG_WIDTH-1:0]       myreg2,
    input  wire [`MYREG_WIDTH-1:0]       myreg3,
    input  wire [`ADDRESS_REG_WIDTH-1:0] address_reg,
    input  wire [`STATUS_REG_WIDTH-1:0]  status_reg,
    output reg  [`CT_WIDTH-1:0]          o_text,
    output wire                         busy_o,
    output wire [`DEBUG_WIDTH-1:0]       debug
);

    localparam integer ADDR_W      = `ADDRESS_REG_WIDTH; 
    localparam integer DEPTH_AB    = 4096;
    localparam integer XFER_BYTES  = 128; 
    localparam integer XFER_WORDS  = 32;  

    // States
    localparam [3:0] S_IDLE     = 4'd0;
    localparam [3:0] S_LOAD     = 4'd1;
    localparam [3:0] S_RD_PRIM   = 4'd2;
    localparam [3:0] S_RD_WAIT   = 4'd3;
    localparam [3:0] S_RD_CAP    = 4'd4;
    localparam [3:0] S_IP_RST    = 4'd5;
    localparam [3:0] S_IP_START  = 4'd6;
    localparam [3:0] S_IP_WAIT   = 4'd7;

    reg  [3:0] state;
    reg  [2:0] op_q; 
    reg  [ADDR_W-1:0] base_q; 
    reg  [7:0] idx_q;      
    reg  [`CT_WIDTH-1:0] pack_q;

    // IP Control Signals
    reg ap_start, ap_rst_reg;
    wire ap_done, ap_idle, ap_ready, ap_local_block, ap_local_deadlock;
    
    // IP Feedback Wires
    wire [7:0]  A_mem_Dout_A;
    wire [7:0]  B_mem_Dout_A;
    wire [31:0] C_mem_Dout_A;

    // BRAM Control Registers (Port B)
    reg A_en_b, A_we_b, B_en_b, B_we_b, C_en_b;
    reg [3:0] C_we_b; // 4-bit write enable for 32-bit BRAM
    reg [ADDR_W-1:0] A_addr_b, B_addr_b, C_addr_b;
    reg [7:0] A_din_b, B_din_b;
    reg [31:0] C_din_b;
    wire [7:0] A_dout_b, B_dout_b;
    wire [31:0] C_dout_b;

    // IP Memory Interface Wires
    wire A_mem_EN_A, B_mem_EN_A, C_mem_EN_A;
    wire [0:0] A_mem_WEN_A, B_mem_WEN_A;
    wire [3:0] C_mem_WEN_A;
    wire [31:0] A_mem_Addr_A, B_mem_Addr_A, C_mem_Addr_A, C_mem_Din_A;
    wire [7:0] A_mem_Din_A, B_mem_Din_A;

    // --- BRAM A/B Instances ---
    bram_tdp_8 #(.ADDR_W(ADDR_W), .DEPTH(DEPTH_AB)) bramA (
        .clk(clk),
        .en_a(A_mem_EN_A), .we_a(A_mem_WEN_A), .addr_a(A_mem_Addr_A[ADDR_W-1:0]), .din_a(A_mem_Din_A), .dout_a(A_mem_Dout_A),
        .en_b(A_en_b),     .we_b(A_we_b),     .addr_b(A_addr_b),                .din_b(A_din_b),     .dout_b(A_dout_b)
    );

    bram_tdp_8 #(.ADDR_W(ADDR_W), .DEPTH(DEPTH_AB)) bramB (
        .clk(clk),
        .en_a(B_mem_EN_A), .we_a(B_mem_WEN_A), .addr_a(B_mem_Addr_A[ADDR_W-1:0]), .din_a(B_mem_Din_A), .dout_a(B_mem_Dout_A),
        .en_b(B_en_b),     .we_b(B_we_b),     .addr_b(B_addr_b),                .din_b(B_din_b),     .dout_b(B_dout_b)
    );

    // --- BRAM C Instance ---
    bram_tdp_32 #(.ADDR_W(ADDR_W), .DEPTH(DEPTH_AB)) bramC (
        .clk(clk),
        .en_a(C_mem_EN_A), 
        .we_a(C_mem_WEN_A),               // Connect IP's 4-bit byte-enable
        .addr_a(C_mem_Addr_A[ADDR_W+1:2]), // Word alignment (truncates bottom 2 bits)
        .din_a(C_mem_Din_A), 
        .dout_a(C_mem_Dout_A),
        .en_b(C_en_b),     
        .we_b(C_we_b),                    // Host write enable
        .addr_b(C_addr_b),                
        .din_b(C_din_b),     
        .dout_b(C_dout_b)
    );

    // --- Systolic IP Instance ---
    systolic_4x4_0 systolic_inst (
        .ap_local_block(ap_local_block), .ap_local_deadlock(ap_local_deadlock),
        .ap_clk(clk), .ap_rst(ap_rst_reg), .ap_start(ap_start), .ap_done(ap_done),
        .ap_idle(ap_idle), .ap_ready(ap_ready),
        .A_mem_Clk_A(), .A_mem_Rst_A(), .A_mem_EN_A(A_mem_EN_A), .A_mem_WEN_A(A_mem_WEN_A),
        .A_mem_Addr_A(A_mem_Addr_A), .A_mem_Din_A(A_mem_Din_A), .A_mem_Dout_A(A_mem_Dout_A),
        .B_mem_Clk_A(), .B_mem_Rst_A(), .B_mem_EN_A(B_mem_EN_A), .B_mem_WEN_A(B_mem_WEN_A),
        .B_mem_Addr_A(B_mem_Addr_A), .B_mem_Din_A(B_mem_Din_A), .B_mem_Dout_A(B_mem_Dout_A),
        .C_mem_Clk_A(), .C_mem_Rst_A(), .C_mem_EN_A(C_mem_EN_A), .C_mem_WEN_A(C_mem_WEN_A),
        .C_mem_Addr_A(C_mem_Addr_A), .C_mem_Din_A(C_mem_Din_A), .C_mem_Dout_A(C_mem_Dout_A)
    );

    assign busy_o = (state != S_IDLE);

    wire [7:0] byte_from_myreg1 = myreg1 >> ((`MYREG_WIDTH - 8) - (idx_q << 3));
    wire [7:0] byte_from_myreg2 = myreg2 >> ((`MYREG_WIDTH - 8) - (idx_q << 3));

    reg load_i_d;
    wire load_pulse = load_i & ~load_i_d;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) load_i_d <= 1'b0;
        else        load_i_d <= load_i;
    end

    // Port B Drive
    always @(*) begin
        A_en_b = 1'b0; A_we_b = 1'b0; A_addr_b = 0; A_din_b = 0;
        B_en_b = 1'b0; B_we_b = 1'b0; B_addr_b = 0; B_din_b = 0;
        C_en_b = 1'b0; C_we_b = 4'b0; C_addr_b = 0; C_din_b = 0;

        case (state)
            S_LOAD: begin
                A_en_b = 1'b1; A_we_b = 1'b1; A_addr_b = base_q + idx_q; A_din_b = byte_from_myreg1;
                B_en_b = 1'b1; B_we_b = 1'b1; B_addr_b = base_q + idx_q; B_din_b = byte_from_myreg2;
            end
            S_RD_PRIM, S_RD_WAIT, S_RD_CAP: begin
                if (op_q == 3'd1)      begin A_en_b = 1'b1; A_addr_b = base_q + idx_q; end
                else if (op_q == 3'd2) begin B_en_b = 1'b1; B_addr_b = base_q + idx_q; end
                else if (op_q == 3'd4) begin C_en_b = 1'b1; C_addr_b = base_q + idx_q; end
            end
            default: ;
        endcase
    end

    // Main FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE; base_q <= 0; idx_q <= 0; o_text <= 0; 
            ap_start <= 1'b0; ap_rst_reg <= 1'b1;
        end else begin
            case (state)
                S_IDLE: begin
                    idx_q <= 0; ap_start <= 1'b0;
                    if (load_pulse) begin
                        base_q <= address_reg[ADDR_W-1:0];
                        case (status_reg[2:0])
                            3'd0: begin op_q <= 3'd0; state <= S_LOAD; end
                            3'd1: begin op_q <= 3'd1; state <= S_RD_PRIM; end
                            3'd2: begin op_q <= 3'd2; state <= S_RD_PRIM; end
                            3'd3: begin ap_rst_reg <= 1'b0; state <= S_IP_RST; end 
                            3'd4: begin op_q <= 3'd4; state <= S_RD_PRIM; end 
                            default: state <= S_IDLE;
                        endcase
                    end
                end

                S_LOAD: begin
                    o_text <= { {(`CT_WIDTH-ADDR_W){1'b0}}, (base_q + idx_q) };
                    if (idx_q == (XFER_BYTES-1)) state <= S_IDLE;
                    else                         idx_q <= idx_q + 1;
                end

                S_IP_RST: begin
                    ap_rst_reg <= 1'b1; 
                    state <= S_IP_START;
                end

                S_IP_START: begin
                    ap_rst_reg <= 1'b0;
                    ap_start   <= 1'b1;
                    state      <= S_IP_WAIT;
                end

                S_IP_WAIT: begin
                    if (ap_done) begin
                        ap_start <= 1'b0;
                        state    <= S_IDLE;
                    end
                end

                S_RD_PRIM: state <= S_RD_WAIT;
                S_RD_WAIT: state <= S_RD_CAP;

                S_RD_CAP: begin
                    if (op_q == 3'd1)      pack_q <= (pack_q << 8)  | A_dout_b;
                    else if (op_q == 3'd2) pack_q <= (pack_q << 8)  | B_dout_b;
                    else if (op_q == 3'd4) pack_q <= (pack_q << 32) | C_dout_b; 

                    if ((op_q == 3'd4 && idx_q == (XFER_WORDS-1)) || (op_q != 3'd4 && idx_q == (XFER_BYTES-1))) begin
                        if (op_q == 3'd1)      o_text <= (pack_q << 8)  | A_dout_b;
                        else if (op_q == 3'd2) o_text <= (pack_q << 8)  | B_dout_b;
                        else if (op_q == 3'd4) o_text <= (pack_q << 32) | C_dout_b;
                        state <= S_IDLE;
                    end else begin
                        idx_q <= idx_q + 1;
                        state <= S_RD_PRIM;
                    end
                end
                default: state <= S_IDLE;
            endcase
        end
    end

    assign debug = C_mem_Dout_A[`DEBUG_WIDTH-1:0];
endmodule


///********** WORKING WITH BRAM A AND BRAM B *************
//module dut (
//    input  wire                         clk,
//    input  wire                         clk_skewed, // Reserved for clock tree analysis
//    input  wire                         rst_n,
//    input  wire [`PT_WIDTH-1:0]          i_text,
//    input  wire [`KEY_WIDTH-1:0]         key,
//    input  wire                         load_i,
//    input  wire [`MYREG_WIDTH-1:0]       myreg1,
//    input  wire [`MYREG_WIDTH-1:0]       myreg2,
//    input  wire [`MYREG_WIDTH-1:0]       myreg3,
//    input  wire [`ADDRESS_REG_WIDTH-1:0] address_reg,
//    input  wire [`STATUS_REG_WIDTH-1:0]  status_reg,
//    output reg  [`CT_WIDTH-1:0]          o_text,
//    output wire                         busy_o,
//    output wire [`DEBUG_WIDTH-1:0]       debug
//);

//    localparam integer ADDR_W      = `ADDRESS_REG_WIDTH; 
//    localparam integer DEPTH_AB    = 4096;
//    localparam integer XFER_BYTES  = 128;

//    localparam [3:0] S_IDLE    = 4'd0;
//    localparam [3:0] S_LOAD    = 4'd1;
//    localparam [3:0] S_RD_PRIM = 4'd2;
//    localparam [3:0] S_RD_WAIT = 4'd3;
//    localparam [3:0] S_RD_CAP  = 4'd4;

//    reg  [3:0] state;
//    reg  [1:0] op_q;      
//    reg  [ADDR_W-1:0] base_q; 
//    reg  [7:0] idx_q;      
//    reg  [`CT_WIDTH-1:0] pack_q;

//    // BRAM B-port signals
//    reg                A_en_b, A_we_b;
//    reg  [ADDR_W-1:0]  A_addr_b;
//    reg  [7:0]         A_din_b;
//    wire [7:0]         A_dout_b;

//    reg                B_en_b, B_we_b;
//    reg  [ADDR_W-1:0]  B_addr_b;
//    reg  [7:0]         B_din_b;
//    wire [7:0]         B_dout_b;

//    // Port A signals (Static/Unused)
//    wire               A_en_a   = 1'b0;
//    wire               A_we_a   = 1'b0;
//    wire [ADDR_W-1:0]  A_addr_a = {ADDR_W{1'b0}};
//    wire [7:0]         A_din_a  = 8'h00;
//    wire [7:0]         A_dout_a;

//    wire               B_en_a   = 1'b0;
//    wire               B_we_a   = 1'b0;
//    wire [ADDR_W-1:0]  B_addr_a = {ADDR_W{1'b0}};
//    wire [7:0]         B_din_a  = 8'h00;
//    wire [7:0]         B_dout_a;

//    // BRAM Instances
//    bram_tdp_8 #(.ADDR_W(ADDR_W), .DEPTH(DEPTH_AB)) bramA (
//        .clk(clk),
//        .en_a(A_en_a), .we_a(A_we_a), .addr_a(A_addr_a), .din_a(A_din_a), .dout_a(A_dout_a),
//        .en_b(A_en_b), .we_b(A_we_b), .addr_b(A_addr_b), .din_b(A_din_b), .dout_b(A_dout_b)
//    );

//    bram_tdp_8 #(.ADDR_W(ADDR_W), .DEPTH(DEPTH_AB)) bramB (
//        .clk(clk),
//        .en_a(B_en_a), .we_a(B_we_a), .addr_a(B_addr_a), .din_a(B_din_a), .dout_a(B_dout_a),
//        .en_b(B_en_b), .we_b(B_we_b), .addr_b(B_addr_b), .din_b(B_din_b), .dout_b(B_dout_b)
//    );

//    assign busy_o = (state != S_IDLE);

//    // Optimized indexing: Extracting byte from MSB-first register
//    // Math: (Total_Width - 8) - (index * 8)
//    wire [7:0] byte_from_myreg1 = myreg1 >> ((`MYREG_WIDTH - 8) - (idx_q << 3));
//    wire [7:0] byte_from_myreg2 = myreg2 >> ((`MYREG_WIDTH - 8) - (idx_q << 3));

//    reg load_i_d;
//    wire load_pulse = load_i & ~load_i_d;

//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) load_i_d <= 1'b0;
//        else        load_i_d <= load_i;
//    end

//    // Combinational BRAM Drive
//    always @(*) begin
//        A_en_b   = 1'b0; A_we_b = 1'b0; A_addr_b = {ADDR_W{1'b0}}; A_din_b = 8'h00;
//        B_en_b   = 1'b0; B_we_b = 1'b0; B_addr_b = {ADDR_W{1'b0}}; B_din_b = 8'h00;

//        case (state)
//            S_LOAD: begin
//                A_en_b = 1'b1; A_we_b = 1'b1; A_addr_b = base_q + idx_q; A_din_b = byte_from_myreg1;
//                B_en_b = 1'b1; B_we_b = 1'b1; B_addr_b = base_q + idx_q; B_din_b = byte_from_myreg2;
//            end
//            S_RD_PRIM, S_RD_WAIT, S_RD_CAP: begin
//                if (op_q == 2'd1) begin
//                    A_en_b = 1'b1; A_addr_b = base_q + idx_q;
//                end else if (op_q == 2'd2) begin
//                    B_en_b = 1'b1; B_addr_b = base_q + idx_q;
//                end
//            end
//            default: ;
//        endcase
//    end

//    // Main FSM
//    always @(posedge clk or negedge rst_n) begin
//        if (!rst_n) begin
//            state  <= S_IDLE;
//            op_q   <= 2'd0;
//            base_q <= {ADDR_W{1'b0}};
//            idx_q  <= 8'd0;
//            pack_q <= {`CT_WIDTH{1'b0}};
//            o_text <= {`CT_WIDTH{1'b0}};
//        end else begin
//            case (state)
//                S_IDLE: begin
//                    idx_q <= 8'd0;
//                    if (load_pulse) begin
//                        base_q <= address_reg[ADDR_W-1:0];
//                        o_text <= {`CT_WIDTH{1'b0}};
//                        case (status_reg[1:0])
//                            2'd0: begin op_q <= 2'd0; state <= S_LOAD;    end
//                            2'd1: begin op_q <= 2'd1; state <= S_RD_PRIM; end
//                            2'd2: begin op_q <= 2'd2; state <= S_RD_PRIM; end
//                            default: state <= S_IDLE;
//                        endcase
//                    end
//                end

//                S_LOAD: begin
//                    o_text <= { {(`CT_WIDTH-ADDR_W){1'b0}}, (base_q + idx_q) };
//                    if (idx_q == (XFER_BYTES-1)) state <= S_IDLE;
//                    else                         idx_q <= idx_q + 1;
//                end

//                S_RD_PRIM: state <= S_RD_WAIT;
//                S_RD_WAIT: state <= S_RD_CAP;

//                S_RD_CAP: begin
//                    if (op_q == 2'd1)      pack_q <= (pack_q << 8) | A_dout_b;
//                    else if (op_q == 2'd2) pack_q <= (pack_q << 8) | B_dout_b;

//                    if (idx_q == (XFER_BYTES-1)) begin
//                        o_text <= (op_q == 2'd1) ? ((pack_q << 8) | A_dout_b) : ((pack_q << 8) | B_dout_b);
//                        state <= S_IDLE;
//                    end else begin
//                        idx_q <= idx_q + 1;
//                        state <= S_RD_PRIM;
//                    end
//                end
//                default: state <= S_IDLE;
//            endcase
//        end
//    end

//    // Consolidated Debug Assignment (NO MULTI-DRIVER)
//    // Adjust bit padding based on your DEBUG_WIDTH
//    assign debug = {
//        {( `DEBUG_WIDTH - (1 + ADDR_W + 4) ){1'b0}}, // Padding
//        busy_o,           // bit [ADDR_W+4]
//        address_reg,      // bits [ADDR_W+3 : 4]
//        state             // bits [3:0]
//    };

//endmodule


 