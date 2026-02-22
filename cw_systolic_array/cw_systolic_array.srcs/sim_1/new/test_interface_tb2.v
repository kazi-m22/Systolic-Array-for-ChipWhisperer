//`timescale 1ns / 1ps

//module aes_tb;

//    // Testbench signals
//    reg clk;
//    reg load_i;
//    reg [255:0] key_i;
//    reg [127:0] data_i;
//    reg [1:0] size_i;
//    reg dec_i;
//    reg rst_n;
//    wire [127:0] data_o;
//    wire busy_o;
//    wire data_o1, data_o2;
    
//    // Instantiate the AES core module
    
//    dut dut (
//       .clk          (clk),
//       .clk_skewed   (clk), // assuming this does not matter
//       .rst_n        (rst_n),
//       .i_text       (data_i),
//       .key          (key_i),      
//       .load_i       (load_i),
//       .o_text       (data_o),
//       .busy_o       (busy_o) 
//    ); 


//   integer clk_counter =0;
   
//    initial begin 
//        clk <= 0;    
//        forever #5 clk <= ~clk;
//    end 
    
//    initial begin 
//        forever @(posedge clk) clk_counter <= clk_counter+1;
//    end 
    
//    initial begin
//        // Initialize signals
//        rst_n <= 0;
//        clk <= 0;
//        load_i <= 0;
//        data_i <= 128'h00;
//        size_i <= 2'b10; // AES-256
//        dec_i <= 0;
//        key_i <= 256'h0;
//        @(posedge clk);
//        rst_n <= 1; 
//        @(posedge clk); 
  

//        load_i <= 1;
 

//        @(posedge clk);
//        load_i <= 0; 
//        @(posedge clk);
//        @(posedge clk);  
    
        
//        while (~busy_o) begin 
//            @(posedge clk); 
//        end 
        
//        while (busy_o) begin 
//            load_i <= 0; 
//            @(posedge clk); 
//        end 
//        // Check output
//        $display("Encrypted Data: %h", data_o);
        
//        load_i <= 1;
//        @(posedge clk);
//                while (~busy_o) begin 
    
//            @(posedge clk); 
//        end 
        
//        while (busy_o) begin 
//            load_i <= 0; 
//            @(posedge clk); 
//        end 
            
//           repeat(5000) @(posedge clk);

//        $finish;
//    end

//endmodule

`timescale 1ns / 1ps
`include "C:/Users/kmejbaulislam/Documents/Research/Dipal_project/d_pin_skew/d_pin_skew.srcs/sources_1/imports/fpgas/aes/hdl/cw305_aes_defines.v"


//`define MYREG_WIDTH                     1024
//`define PT_WIDTH                        128
//`define KEY_WIDTH                       128
//`define CT_WIDTH                        128

module tb_dut;

    reg                     clk;
    reg                     clk_skewed;
    reg                     rst_n;
    reg  [`PT_WIDTH-1:0]    i_text;
    reg  [`KEY_WIDTH-1:0]   key;
    reg                     load_i;
    reg  [`MYREG_WIDTH-1:0] myreg;
    wire [`CT_WIDTH-1:0]    o_text;
    wire                    busy_o;

    // instantiate dut
    dut u_dut (
        .clk       (clk),
        .clk_skewed(clk_skewed),
        .rst_n     (rst_n),
        .i_text    (i_text),
        .key       (key),
        .load_i    (load_i),
        .myreg     (myreg),
        .o_text    (o_text),
        .busy_o    (busy_o)
    );

    // 100 MHz clock
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // dummy skewed clock
    initial begin
        clk_skewed = 1'b0;
        forever #5 clk_skewed = ~clk_skewed;
    end

    localparam integer IMG_CHUNKS = 7; // 784 / 128 rounded up

    integer c;

    initial begin
        // init
        rst_n   = 1'b0;
        load_i  = 1'b0;
        i_text  = {`PT_WIDTH{1'b0}};
        key     = {`KEY_WIDTH{1'b0}};
        myreg   = {`MYREG_WIDTH{1'b0}};

        // reset
        #40;
        rst_n = 1'b1;
        #20;

        $display("=== Loading image chunks ===");

        // 7 chunks: load_i with i_text != all ones
        for (c = 0; c < IMG_CHUNKS; c = c + 1) begin
            myreg  = {`MYREG_WIDTH{1'b0}} | c;   // different pattern per chunk
            i_text = {`PT_WIDTH{1'b0}};          // NOT all ones -> load mode

            @(posedge clk);
            load_i <= 1'b1;
            @(posedge clk);
            load_i <= 1'b0;

            // wait for FSM to go S_LOAD (busy_o = 1) then back to S_IDLE (busy_o = 0)
            wait (busy_o == 1'b1);
            wait (busy_o == 1'b0);

            $display("[%0t] chunk %0d done, busy_o returned low", $time, c);
            #10;
        end

        $display("=== Starting inference (all-ones text) ===");

        // start the IP: i_text = all ones, single load_i pulse
        myreg  = {`MYREG_WIDTH{1'b0}};      // don't care
        i_text = {`PT_WIDTH{1'b1}};         // ALL ONES -> cmd_start = 1

        @(posedge clk);
        load_i <= 1'b1;
        @(posedge clk);
        load_i <= 1'b0;

        // wait for run+read (busy_o high) then completion (busy_o low)
        wait (busy_o == 1'b1);
        $display("[%0t] busy_o asserted (RUN/READ)", $time);
        wait (busy_o == 1'b0);
        $display("[%0t] busy_o deasserted, o_text = %h", $time, o_text);

        #40;
        $finish;
    end

    // monitor internal done + state for debugging
    always @(posedge clk) begin
        if (rst_n) begin
            $display("[%0t] state=%0d load_i=%b busy_o=%b done_int=%b image_ready=%b",
                     $time,
                     u_dut.state,
                     load_i,
                     busy_o,
                     u_dut.done,
                     u_dut.image_ready);
        end
    end

endmodule
