module instruction_memory (
    input  wire [31:0] addr,
    output wire [31:0] instr
);

    reg [31:0] mem [0:255];
    integer i;

    initial begin
        // Demo program:
        // x1 = 5
        mem[0]  = 32'h00500093; // addi x1, x0, 5

        // x2 = 10
        mem[1]  = 32'h00A00113; // addi x2, x0, 10

        // x3 = x1 + x2
        mem[2]  = 32'h002081B3; // add  x3, x1, x2

        // store x3 -> mem[0]
        mem[3]  = 32'h00302023; // sw   x3, 0(x0)

        // load mem[0] -> x4
        mem[4]  = 32'h00002203; // lw   x4, 0(x0)

        // load-use hazard: x5 = x4 + x1
        mem[5]  = 32'h001202B3; // add  x5, x4, x1

        // forwarding case: x6 = x5 + x2
        mem[6]  = 32'h00228333; // add  x6, x5, x2

        // if x6 == x6 branch +8
        mem[7]  = 32'h00630463; // beq  x6, x6, +8

        // should be flushed if branch taken
        mem[8]  = 32'h06300393; // addi x7, x0, 99

        // target
        mem[9]  = 32'h00100413; // addi x8, x0, 1

        mem[10] = 32'h00000013; // nop
        mem[11] = 32'h00000013; // nop

        for (i = 12; i < 256; i = i + 1)
            mem[i] = 32'h00000013; // nop
    end

    assign instr = mem[addr[31:2]];

endmodule