module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        alu_src,
    output reg        branch,
    output reg [3:0]  alu_ctrl
);

    always @(*) begin
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        branch     = 1'b0;
        alu_ctrl   = 4'b0000;

        case (opcode)

            7'b0110011: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;

                case (funct3)
                    3'b000: begin
                        if (funct7 == 7'b0100000)
                            alu_ctrl = 4'b0001; // SUB
                        else
                            alu_ctrl = 4'b0000; // ADD
                    end
                    3'b111: alu_ctrl = 4'b0010; // AND
                    3'b110: alu_ctrl = 4'b0011; // OR
                    3'b100: alu_ctrl = 4'b0100; // XOR
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            7'b0010011: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = 4'b0000;
            end

            7'b0000011: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_src    = 1'b1;
                alu_ctrl   = 4'b0000;
            end

            7'b0100011: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = 4'b0000;
            end

            7'b1100011: begin
                branch   = 1'b1;
                alu_src  = 1'b0;
                alu_ctrl = 4'b0001;
            end

            default: begin
                reg_write  = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                mem_to_reg = 1'b0;
                alu_src    = 1'b0;
                branch     = 1'b0;
                alu_ctrl   = 4'b0000;
            end
        endcase
    end

endmodule