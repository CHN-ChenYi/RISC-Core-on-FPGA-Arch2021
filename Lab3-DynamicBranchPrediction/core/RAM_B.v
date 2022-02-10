`timescale 1ns / 1ps

module RAM_B(
    input [31:0] addra,
    input clka,      // normal clock
    input[31:0] dina,
    input wea, 
    output[31:0] douta,
    output [7:0] sim_uart_char_out,
    output sim_uart_char_valid,
    input[2:0] mem_u_b_h_w
);
    localparam SIZE = 256;
    localparam ADDR_LINE = $clog2(SIZE);
    localparam SIM_UART_ADDR = 32'h10000000;

    reg[7:0] data[0:SIZE-1];

    initial	begin
        $readmemh("ram.hex", data);
    end

    always @ (negedge clka) begin
        if (wea & (addra != SIM_UART_ADDR)) begin
            data[addra[ADDR_LINE-1:0]] <= dina[7:0];
            if(mem_u_b_h_w[0] | mem_u_b_h_w[1])
                data[addra[ADDR_LINE-1:0] + 1] <= dina[15:8];
            if(mem_u_b_h_w[1]) begin
                data[addra[ADDR_LINE-1:0] + 2] <= dina[23:16];
                data[addra[ADDR_LINE-1:0] + 3] <= dina[31:24];
            end
        end
    end

    
    assign douta = addra == SIM_UART_ADDR ? 32'b0 :
        mem_u_b_h_w[1] ? {data[addra[ADDR_LINE-1:0] + 3], data[addra[ADDR_LINE-1:0] + 2],
                    data[addra[ADDR_LINE-1:0] + 1], data[addra[ADDR_LINE-1:0]]} :
        mem_u_b_h_w[0] ? {mem_u_b_h_w[2] ? 16'b0 : {16{data[addra[ADDR_LINE-1:0] + 1][7]}},
                    data[addra[ADDR_LINE-1:0] + 1], data[addra[ADDR_LINE-1:0]]} :
        {mem_u_b_h_w[2] ? 24'b0 : {24{data[addra[ADDR_LINE-1:0]][7]}}, data[addra[ADDR_LINE-1:0]]};
    
    reg uart_addr_valid;
    reg [7:0] uart_char;
    initial begin
        uart_addr_valid <= 0;
    end
    assign sim_uart_char_valid = uart_addr_valid;
    assign sim_uart_char_out   = uart_char;
    always @(posedge clka) begin
        uart_addr_valid <= wea & (addra == SIM_UART_ADDR);
        uart_char <= dina[7:0];
        if (sim_uart_char_valid) begin
            $write("%c", sim_uart_char_out);
        end
    end
endmodule