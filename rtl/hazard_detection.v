module hazard_detection (
    input  wire       id_ex_mem_read,
    input  wire [4:0] id_ex_rd,
    input  wire [4:0] if_id_rs1,
    input  wire [4:0] if_id_rs2,
    output reg        stall,
    output reg        pc_write,
    output reg        if_id_write,
    output reg        control_mux_sel
);

    always @(*) begin
        stall           = 1'b0;
        pc_write        = 1'b1;
        if_id_write     = 1'b1;
        control_mux_sel = 1'b0;

        // load-use hazard
        if (id_ex_mem_read &&
           ((id_ex_rd == if_id_rs1 && if_id_rs1 != 5'd0) ||
            (id_ex_rd == if_id_rs2 && if_id_rs2 != 5'd0))) begin
            stall           = 1'b1;
            pc_write        = 1'b0;
            if_id_write     = 1'b0;
            control_mux_sel = 1'b1; // inject bubble into ID/EX
        end
    end

endmodule