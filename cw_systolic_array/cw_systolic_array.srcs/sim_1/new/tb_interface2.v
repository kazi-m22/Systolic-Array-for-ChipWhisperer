`timescale 1ns/1ps

`ifndef PT_WIDTH
`define PT_WIDTH   128
`endif
`ifndef KEY_WIDTH
`define KEY_WIDTH  256
`endif
`ifndef MYREG_WIDTH
`define MYREG_WIDTH 1024
`endif
`ifndef CT_WIDTH
`define CT_WIDTH   128
`endif

module tb_dut_hostlike;

  // ---------------- clocks / reset ----------------
  reg clk;
  reg clk_skewed;
  reg rst_n;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk; // 100 MHz
  end

  initial begin
    clk_skewed = 1'b0;
    forever #5 clk_skewed = ~clk_skewed;
  end

  // ---------------- DUT I/O ----------------
  reg  [`PT_WIDTH-1:0]     i_text;
  reg  [`KEY_WIDTH-1:0]    key;
  reg                      load_i;
  reg  [`MYREG_WIDTH-1:0]  myreg1;
  reg  [`MYREG_WIDTH-1:0]  myreg2;
  reg  [`MYREG_WIDTH-1:0]  myreg3;
  wire [`CT_WIDTH-1:0]     o_text;
  wire                     busy_o;

  dut u_dut (
    .clk(clk),
    .clk_skewed(clk_skewed),
    .rst_n(rst_n),
    .i_text(i_text),
    .key(key),
    .load_i(load_i),
    .myreg1(myreg1),
    .myreg2(myreg2),
    .myreg3(myreg3),
    .o_text(o_text),
    .busy_o(busy_o)
  );

  // ---------------- host-like "register file" model ----------------
  // Mimics:
  //   addr = (reg << 7) | off
  //   dev.fpga_write(addr, bytes)
  // and then trigger_load_i pulses load_i and reads o_text (16B)
  //
  localparam integer BYTECNT_BITS = 7;
  localparam integer CHUNK_FWSAFE = 47;

  localparam integer REG_MYREG1 = 8'h0c;
  localparam integer REG_MYREG2 = 8'h0d;

  // two 128B "register images" that software fills with writes
  reg [1023:0] regimg_myreg1;
  reg [1023:0] regimg_myreg2;

  integer guard;
  integer t;

  // ---------------- helpers ----------------
  task do_fpga_write;
    input [15:0] addr;   // (reg<<7)|off
    input integer nbytes;
    input [8*256-1:0] data_packed; // up to 256B payload packed little-endian in this vector
    integer k;
    integer regsel;
    integer off;
    reg [7:0] b;
    begin
      regsel = addr >> BYTECNT_BITS;
      off    = addr & ((1<<BYTECNT_BITS)-1);

      for (k = 0; k < nbytes; k = k + 1) begin
        b = data_packed[(k*8) +: 8];

        if (regsel == REG_MYREG1) begin
          if ((off + k) < 128) regimg_myreg1[((off+k)*8) +: 8] = b;
        end else if (regsel == REG_MYREG2) begin
          if ((off + k) < 128) regimg_myreg2[((off+k)*8) +: 8] = b;
        end
      end
    end
  endtask

  // host write_bytes(dev, reg, data, chunk=47)
  task write_bytes_hostlike;
    input [7:0] regid;
    input integer total_len;
    input [8*128-1:0] data_128B; // exactly 128B used here
    integer off;
    integer n;
    reg [15:0] addr;
    reg [8*256-1:0] tmp;
    begin
      off = 0;
      while (off < total_len) begin
        n = (total_len - off > CHUNK_FWSAFE) ? CHUNK_FWSAFE : (total_len - off);
        addr = (regid << BYTECNT_BITS) | off[6:0];

        tmp = { (8*256){1'b0} };
        // pack n bytes starting at off into tmp[0 +: n*8]
        begin : pack_loop
          integer k;
          for (k = 0; k < n; k = k + 1)
            tmp[(k*8) +: 8] = data_128B[((off+k)*8) +: 8];
        end

        do_fpga_write(addr, n, tmp);
        off = off + n;
      end
    end
  endtask

  function [1023:0] pack_reg_1024_from_payload;
    input [8*126-1:0] payload126; // byte0 at [7:0]
    input [15:0] addr16;          // little-endian bytes appended
    reg [1023:0] tmp;
    integer k;
    begin
      tmp = 1024'd0;
      // payload bytes 0..125
      for (k = 0; k < 126; k = k + 1)
        tmp[(k*8) +: 8] = payload126[(k*8) +: 8];

      // addr bytes at 126,127 (little-endian)
      tmp[(126*8) +: 8] = addr16[7:0];
      tmp[(127*8) +: 8] = addr16[15:8];

      pack_reg_1024_from_payload = tmp;
    end
  endfunction

  // create A_bytes = np.arange(4096)-128 mod 256, as int8
  function [7:0] A_byte_at;
    input integer idx;
    integer v;
    begin
      v = idx - 128;
      A_byte_at = v[7:0]; // two's complement wraps like int8
    end
  endfunction

  // deterministic "random-like" B: simple LCG
  function [7:0] B_byte_at;
    input integer idx;
    reg [31:0] x;
    begin
      x = 32'h1234_5678 ^ idx[31:0];
      x = x * 32'd1103515245 + 32'd12345;
      B_byte_at = x[15:8];
    end
  endfunction

  task trigger_load_i;
    begin
      // mimic cw.capture_trace trigger: one-cycle load_i pulse
      @(posedge clk);
      load_i <= 1'b1;

      // on same cycle, push the current reg images into DUT inputs
      myreg1 <= regimg_myreg1;
      myreg2 <= regimg_myreg2;

      @(posedge clk);
      load_i <= 1'b0;
    end
  endtask

  task wait_busy_done;
    begin
      guard = 0;
      while (!busy_o && guard < 2000) begin
        @(posedge clk);
        guard = guard + 1;
      end
      guard = 0;
      while (busy_o && guard < 50000) begin
        @(posedge clk);
        guard = guard + 1;
      end
      if (guard >= 50000) begin
        $display("[%0t] ERROR: busy_o stuck", $time);
        $finish;
      end
    end
  endtask

  // ---------------- main ----------------
  integer base;
  integer i;
  integer k;
  reg [8*126-1:0] a_payload;
  reg [8*126-1:0] b_payload;
  reg [1023:0] w1;
  reg [1023:0] w2;

  reg [1023:0] readback_cmd1;
  reg [1023:0] readback_cmd2;

  initial begin
    $dumpfile("tb_dut_hostlike.vcd");
    $dumpvars(0, tb_dut_hostlike);

    // init
    rst_n = 1'b0;
    i_text = 0;
    key = 0;
    load_i = 0;
    myreg1 = 0;
    myreg2 = 0;
    myreg3 = 0;

    regimg_myreg1 = 0;
    regimg_myreg2 = 0;

    repeat (5) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    // ------------------- LOAD A/B exactly like your Python loop -------------------
    // TOTAL_LOADS = ceil(4096/126) = 33
    for (t = 0; t < 33; t = t + 1) begin
      base = t * 126;

      // build 126B payload slices, zero-pad past 4096
      for (k = 0; k < 126; k = k + 1) begin
        if ((base + k) < 4096) begin
          a_payload[(k*8) +: 8] = A_byte_at(base + k);
          b_payload[(k*8) +: 8] = B_byte_at(base + k);
        end else begin
          a_payload[(k*8) +: 8] = 8'h00;
          b_payload[(k*8) +: 8] = 8'h00;
        end
      end

      // pack_reg_1024(payload_126, base) where addr16=base & 0x0FFF
      w1 = pack_reg_1024_from_payload(a_payload, base[15:0]);
      w2 = pack_reg_1024_from_payload(b_payload, base[15:0]);

      // write_bytes(target, REG_MYREG1, w1)  (128B)
      write_bytes_hostlike(REG_MYREG1, 128, w1);

      // write_bytes(target, REG_MYREG2, w2)  (128B)
      write_bytes_hostlike(REG_MYREG2, 128, w2);

      // trigger_load_i
      trigger_load_i();
      wait_busy_done();

      $display("load %02d base=%4d textout=%h", t, base, o_text);
    end

    // ------------------- READBACK TRIGGER like your Python -------------------
    // readback_cmd1 = payload zeros + b"\xff\xff" (addr field)
    // readback_cmd2 = payload zeros + b"\x55\x55"
    readback_cmd1 = 1024'd0;
    readback_cmd2 = 1024'd0;

    // addr bytes at end (little-endian)
    readback_cmd1[(126*8) +: 8] = 8'hff;
    readback_cmd1[(127*8) +: 8] = 8'hff;

    readback_cmd2[(126*8) +: 8] = 8'h55;
    readback_cmd2[(127*8) +: 8] = 8'h55;

    // NOTE: your Python writes MYREG2 with cmd1 and MYREG1 with cmd2
    write_bytes_hostlike(REG_MYREG2, 128, readback_cmd1);
    write_bytes_hostlike(REG_MYREG1, 128, readback_cmd2);

    trigger_load_i();
    wait_busy_done();

    $display("readback A[0..15] = %h", o_text);

    $finish;
  end

endmodule