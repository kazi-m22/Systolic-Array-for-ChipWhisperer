module parallel_to_serial (
    input wire clk,    // Clock
    input wire rst_n,  // Asynchronous reset active low
    input wire [127:0] par_in,
    input wire load_data,
    input wire shift_enable,
    output wire [127:0] par_out,
    output wire done,
    output wire ser_out 
);

reg [127:0] par_data, par_data_next;
reg [8:0] count, count_next;

assign done = (count == 8'd128);
assign ser_out = par_data[127];
assign par_out = par_data;

// Registers
always @(posedge clk, negedge rst_n) begin
    if(rst_n == 1'b0) begin
        par_data <= 128'b0;
        count <= 8'b0;
    end else begin
        par_data <= par_data_next;
        count <= count_next;
    end
end

// par_data next state logic
always @(*) begin
    par_data_next = par_data;
    if(load_data) begin
        par_data_next = par_in;
    end else if(shift_enable && count <= 8'd127) begin
        par_data_next = {par_data[126:0], 1'b0};
    end
end

// counter next state logic
always @(*) begin
    count_next = count;
    if(load_data) begin
        count_next = 8'b0;
    end else if(shift_enable) begin
        count_next = count + 8'b1;
    end

end

endmodule