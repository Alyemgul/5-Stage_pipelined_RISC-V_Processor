module data_memory (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);

    reg [31:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = 32'd0;
    end

    always @(posedge clk) begin
        if (mem_write)
            mem[addr[31:2]] <= write_data;
    end

    assign read_data = mem_read ? mem[addr[31:2]] : 32'd0;

endmodule