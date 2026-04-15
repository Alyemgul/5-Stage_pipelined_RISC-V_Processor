`timescale 1ns/1ps

module tb_riscv_pipeline;

    reg clk;
    reg rst;

    riscv_pipeline_top dut (
        .clk(clk),
        .rst(rst)
    );

    // clock generation
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_riscv_pipeline);
    end

    initial begin
        rst = 1'b1;
        #20;
        rst = 1'b0;

        // Let the program run
        #250;

        $display("======================================");
        $display("Simulation finished");
        $display("x1 = %0d", dut.u_rf.regs[1]);
        $display("x2 = %0d", dut.u_rf.regs[2]);
        $display("x3 = %0d", dut.u_rf.regs[3]);
        $display("x4 = %0d", dut.u_rf.regs[4]);
        $display("x5 = %0d", dut.u_rf.regs[5]);
        $display("x6 = %0d", dut.u_rf.regs[6]);
        $display("x7 = %0d", dut.u_rf.regs[7]);
        $display("x8 = %0d", dut.u_rf.regs[8]);
        $display("mem[0] = %0d", dut.u_dmem.mem[0]);
        $display("======================================");

        // Expected:
        // x1 = 5
        // x2 = 10
        // x3 = 15
        // mem[0] = 15
        // x4 = 15
        // x5 = 20
        // x6 = 30
        // x7 = 0   (flushed by branch)
        // x8 = 1

        $finish;
    end

endmodule