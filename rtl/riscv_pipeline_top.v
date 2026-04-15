module riscv_pipeline_top (
    input wire clk,
    input wire rst
);

    // =========================================================
    // IF stage
    // =========================================================
    reg  [31:0] pc;
    wire [31:0] instr_if;
    wire [31:0] pc_plus4_if;
    wire [31:0] pc_next;
    wire        pc_write;

    // =========================================================
    // IF/ID pipeline register
    // =========================================================
    reg [31:0] if_id_pc;
    reg [31:0] if_id_instr;
    wire       if_id_write;

    // =========================================================
    // ID stage decode wires
    // =========================================================
    wire [6:0] id_opcode;
    wire [4:0] id_rd;
    wire [2:0] id_funct3;
    wire [4:0] id_rs1;
    wire [4:0] id_rs2;
    wire [6:0] id_funct7;

    wire [31:0] reg_read_data1;
    wire [31:0] reg_read_data2;

    wire        ctrl_reg_write;
    wire        ctrl_mem_read;
    wire        ctrl_mem_write;
    wire        ctrl_mem_to_reg;
    wire        ctrl_alu_src;
    wire        ctrl_branch;
    wire [3:0]  ctrl_alu_ctrl;

    wire [31:0] imm_i_type;
    wire [31:0] imm_s_type;
    wire [31:0] imm_b_type;
    reg  [31:0] id_imm;

    wire        stall;
    wire        control_mux_sel;

    // =========================================================
    // ID/EX pipeline register declarations
    // =========================================================
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_rs1_data;
    reg [31:0] id_ex_rs2_data;
    reg [31:0] id_ex_imm;
    reg [4:0]  id_ex_rs1;
    reg [4:0]  id_ex_rs2;
    reg [4:0]  id_ex_rd;
    reg [2:0]  id_ex_funct3;

    reg        id_ex_reg_write;
    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg        id_ex_mem_to_reg;
    reg        id_ex_alu_src;
    reg        id_ex_branch;
    reg [3:0]  id_ex_alu_ctrl;

    // =========================================================
    // EX stage declarations
    // =========================================================
    wire [1:0] forwardA;
    wire [1:0] forwardB;

    reg  [31:0] ex_operand_a;
    reg  [31:0] ex_operand_b_pre;
    wire [31:0] ex_operand_b;

    wire [31:0] alu_result_ex;
    wire        alu_zero_ex;
    wire [31:0] branch_target_ex;
    wire        branch_taken_ex;

    // =========================================================
    // EX/MEM pipeline register declarations
    // =========================================================
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_rs2_forwarded;
    reg [4:0]  ex_mem_rd;
    reg        ex_mem_reg_write;
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_write;
    reg        ex_mem_mem_to_reg;

    // =========================================================
    // MEM stage declarations
    // =========================================================
    wire [31:0] mem_read_data;

    // =========================================================
    // MEM/WB pipeline register declarations
    // =========================================================
    reg [31:0] mem_wb_read_data;
    reg [31:0] mem_wb_alu_result;
    reg [4:0]  mem_wb_rd;
    reg        mem_wb_reg_write;
    reg        mem_wb_mem_to_reg;

    // =========================================================
    // WB stage declarations
    // =========================================================
    wire [31:0] wb_write_data;

    // =========================================================
    // Simple assignments
    // =========================================================
    assign pc_plus4_if = pc + 32'd4;

    assign id_opcode = if_id_instr[6:0];
    assign id_rd     = if_id_instr[11:7];
    assign id_funct3 = if_id_instr[14:12];
    assign id_rs1    = if_id_instr[19:15];
    assign id_rs2    = if_id_instr[24:20];
    assign id_funct7 = if_id_instr[31:25];

    assign imm_i_type = {{20{if_id_instr[31]}}, if_id_instr[31:20]};
    assign imm_s_type = {{20{if_id_instr[31]}}, if_id_instr[31:25], if_id_instr[11:7]};
    assign imm_b_type = {{19{if_id_instr[31]}}, if_id_instr[31], if_id_instr[7], if_id_instr[30:25], if_id_instr[11:8], 1'b0};

    assign ex_operand_b     = id_ex_alu_src ? id_ex_imm : ex_operand_b_pre;
    assign branch_target_ex = id_ex_pc + id_ex_imm;
    assign branch_taken_ex  = id_ex_branch & alu_zero_ex;
    assign wb_write_data    = mem_wb_mem_to_reg ? mem_wb_read_data : mem_wb_alu_result;
    assign pc_next          = branch_taken_ex ? branch_target_ex : pc_plus4_if;

    // =========================================================
    // Module instantiations
    // =========================================================
    instruction_memory u_imem (
        .addr (pc),
        .instr(instr_if)
    );

    control_unit u_ctrl (
        .opcode     (id_opcode),
        .funct3     (id_funct3),
        .funct7     (id_funct7),
        .reg_write  (ctrl_reg_write),
        .mem_read   (ctrl_mem_read),
        .mem_write  (ctrl_mem_write),
        .mem_to_reg (ctrl_mem_to_reg),
        .alu_src    (ctrl_alu_src),
        .branch     (ctrl_branch),
        .alu_ctrl   (ctrl_alu_ctrl)
    );

    register_file u_rf (
        .clk        (clk),
        .rst        (rst),
        .reg_write  (mem_wb_reg_write),
        .rs1        (id_rs1),
        .rs2        (id_rs2),
        .rd         (mem_wb_rd),
        .write_data (wb_write_data),
        .read_data1 (reg_read_data1),
        .read_data2 (reg_read_data2)
    );

    hazard_detection u_hazard (
        .id_ex_mem_read  (id_ex_mem_read),
        .id_ex_rd        (id_ex_rd),
        .if_id_rs1       (id_rs1),
        .if_id_rs2       (id_rs2),
        .stall           (stall),
        .pc_write        (pc_write),
        .if_id_write     (if_id_write),
        .control_mux_sel (control_mux_sel)
    );

    forwarding_unit u_forward (
        .ex_mem_reg_write (ex_mem_reg_write),
        .mem_wb_reg_write (mem_wb_reg_write),
        .ex_mem_rd        (ex_mem_rd),
        .mem_wb_rd        (mem_wb_rd),
        .id_ex_rs1        (id_ex_rs1),
        .id_ex_rs2        (id_ex_rs2),
        .forwardA         (forwardA),
        .forwardB         (forwardB)
    );

    alu u_alu (
        .a        (ex_operand_a),
        .b        (ex_operand_b),
        .alu_ctrl (id_ex_alu_ctrl),
        .result   (alu_result_ex),
        .zero     (alu_zero_ex)
    );

    data_memory u_dmem (
        .clk        (clk),
        .mem_read   (ex_mem_mem_read),
        .mem_write  (ex_mem_mem_write),
        .addr       (ex_mem_alu_result),
        .write_data (ex_mem_rs2_forwarded),
        .read_data  (mem_read_data)
    );

    // =========================================================
    // Immediate selection
    // =========================================================
    always @(*) begin
        case (id_opcode)
            7'b0010011: id_imm = imm_i_type; // addi
            7'b0000011: id_imm = imm_i_type; // lw
            7'b0100011: id_imm = imm_s_type; // sw
            7'b1100011: id_imm = imm_b_type; // beq
            default:    id_imm = 32'd0;
        endcase
    end

    // =========================================================
    // Forwarding muxes
    // =========================================================
    always @(*) begin
        case (forwardA)
            2'b00: ex_operand_a = id_ex_rs1_data;
            2'b10: ex_operand_a = ex_mem_alu_result;
            2'b01: ex_operand_a = wb_write_data;
            default: ex_operand_a = id_ex_rs1_data;
        endcase

        case (forwardB)
            2'b00: ex_operand_b_pre = id_ex_rs2_data;
            2'b10: ex_operand_b_pre = ex_mem_alu_result;
            2'b01: ex_operand_b_pre = wb_write_data;
            default: ex_operand_b_pre = id_ex_rs2_data;
        endcase
    end

    // =========================================================
    // Sequential pipeline logic
    // =========================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'd0;

            if_id_pc    <= 32'd0;
            if_id_instr <= 32'h00000013;

            id_ex_pc         <= 32'd0;
            id_ex_rs1_data   <= 32'd0;
            id_ex_rs2_data   <= 32'd0;
            id_ex_imm        <= 32'd0;
            id_ex_rs1        <= 5'd0;
            id_ex_rs2        <= 5'd0;
            id_ex_rd         <= 5'd0;
            id_ex_funct3     <= 3'd0;
            id_ex_reg_write  <= 1'b0;
            id_ex_mem_read   <= 1'b0;
            id_ex_mem_write  <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;
            id_ex_alu_src    <= 1'b0;
            id_ex_branch     <= 1'b0;
            id_ex_alu_ctrl   <= 4'd0;

            ex_mem_alu_result    <= 32'd0;
            ex_mem_rs2_forwarded <= 32'd0;
            ex_mem_rd            <= 5'd0;
            ex_mem_reg_write     <= 1'b0;
            ex_mem_mem_read      <= 1'b0;
            ex_mem_mem_write     <= 1'b0;
            ex_mem_mem_to_reg    <= 1'b0;

            mem_wb_read_data  <= 32'd0;
            mem_wb_alu_result <= 32'd0;
            mem_wb_rd         <= 5'd0;
            mem_wb_reg_write  <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;
        end else begin
            // PC update
            if (pc_write)
                pc <= pc_next;

            // IF/ID update
            if (branch_taken_ex) begin
                if_id_pc    <= 32'd0;
                if_id_instr <= 32'h00000013;
            end else if (if_id_write) begin
                if_id_pc    <= pc;
                if_id_instr <= instr_if;
            end

            // ID/EX update
            if (branch_taken_ex || control_mux_sel) begin
                id_ex_pc         <= 32'd0;
                id_ex_rs1_data   <= 32'd0;
                id_ex_rs2_data   <= 32'd0;
                id_ex_imm        <= 32'd0;
                id_ex_rs1        <= 5'd0;
                id_ex_rs2        <= 5'd0;
                id_ex_rd         <= 5'd0;
                id_ex_funct3     <= 3'd0;
                id_ex_reg_write  <= 1'b0;
                id_ex_mem_read   <= 1'b0;
                id_ex_mem_write  <= 1'b0;
                id_ex_mem_to_reg <= 1'b0;
                id_ex_alu_src    <= 1'b0;
                id_ex_branch     <= 1'b0;
                id_ex_alu_ctrl   <= 4'd0;
            end else begin
                id_ex_pc         <= if_id_pc;
                id_ex_rs1_data   <= reg_read_data1;
                id_ex_rs2_data   <= reg_read_data2;
                id_ex_imm        <= id_imm;
                id_ex_rs1        <= id_rs1;
                id_ex_rs2        <= id_rs2;
                id_ex_rd         <= id_rd;
                id_ex_funct3     <= id_funct3;
                id_ex_reg_write  <= ctrl_reg_write;
                id_ex_mem_read   <= ctrl_mem_read;
                id_ex_mem_write  <= ctrl_mem_write;
                id_ex_mem_to_reg <= ctrl_mem_to_reg;
                id_ex_alu_src    <= ctrl_alu_src;
                id_ex_branch     <= ctrl_branch;
                id_ex_alu_ctrl   <= ctrl_alu_ctrl;
            end

            // EX/MEM update
            ex_mem_alu_result    <= alu_result_ex;
            ex_mem_rs2_forwarded <= ex_operand_b_pre;
            ex_mem_rd            <= id_ex_rd;
            ex_mem_reg_write     <= id_ex_reg_write;
            ex_mem_mem_read      <= id_ex_mem_read;
            ex_mem_mem_write     <= id_ex_mem_write;
            ex_mem_mem_to_reg    <= id_ex_mem_to_reg;

            // MEM/WB update
            mem_wb_read_data  <= mem_read_data;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_reg_write  <= ex_mem_reg_write;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
        end
    end

endmodule