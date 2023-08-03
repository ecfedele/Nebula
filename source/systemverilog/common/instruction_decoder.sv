// ---------------------------------------------------------------------------------------------- //
// Title           : Instruction Decoder, Single-Issue, RISC-V Subset RV32G                       //
// Project         : Nebula RV32 Core                                                             //
// Filename        : instruction_decoder.sv                                                       //
// Description     : Implements an RV32G-compatible instruction decoder.                          //
//                                                                                                //
// Main Author     : Elijah Creed Fedele                                                          //
// Creation Date   : July 29, 2023 23:19                                                          //
// Last Revision   : July 30, 2023 02:24                                                          //
// Version         : ---                                                                          //
// License         : CERN-OHL-S-2.0 (CERN OHL, v2.0, Strongly Reciprocal)                         //
// Copyright       : (C) 2023 Elijah Creed Fedele & Connor Clarke                                 //
//                                                                                                //
// Library/Package : ---                                                                          //
// Dependencies    : instruction_utilities                                                        //
// Initialization  : ---                                                                          //
// Notes           : Primary simulation/synthesis targets are Vivado & Quartus Prime.             //
// ---------------------------------------------------------------------------------------------- //

module instruction_decoder #(parameter BITS = 32) (
    input  wire [31:0] instruction,
    input  wire        clk, n_rst,
    input  wire        n_irdy, n_stall,
    output wire [ 3:0] inst_type,                       // {alu_in, fpu_in, fpu_sd, mem_in}
    output wire [ 6:0] alu_op,
    output wire [ 5:0] mem_op, fpu_op, 
    output wire [ 4:0] reg_d, reg_s1, reg_s2, reg_s3,
    output wire [ 2:0] reg_conf,
    output wire [31:0] immed,
    output wire [ 3:0] fence_pred, fence_succ,
    output wire        fence, n_bad_inst
);

    import instruction_utilities::*;
    wire [ 6:0] opcode;
    wire [ 6:0] funct7;
    wire [ 2:0] funct3;
    wire [11:0] imm11;
    
    assign opcode = instruction[ 6: 0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];
    assign imm11  = instruction[31:20];


    always @ (posedge clk or n_rst)
    begin
        if (n_rst == 1'b0) begin

        end else begin
            case (opcode)

                // LOAD instructions
                // Includes LB, LH, LW, LD, LBU, LHU, LWU
                // These instructions load data constants of various length into integer registers.
                // ------------------------------------------------------------------------------ //
                LOAD: begin
                    inst_type <= 4'b0001;
                    alu_op    <= ALU_SUBCODE.IOP_NULL;
                    fpu_op    <= FPU_SUBCODE.FPU_NULL;
                    immed     <= (BITS == 32) ? signx12w(imm11) : signx12d(imm11);
                    reg_d     <= instruction[11: 7];
                    reg_s1    <= instruction[19:15];
                    case (funct3)
                        3'b000: begin // LB
                            mem_op     <= MEM_SUBCODE.MEM_LB;
                            n_bad_inst <= 1'b1;
                        end
                        3'b001: begin // LH
                            mem_op     <= MEM_SUBCODE.MEM_LH;
                            n_bad_inst <= 1'b1;
                        end 
                        3'b010: begin // LW
                            mem_op     <= MEM_SUBCODE.MEM_LW;
                            n_bad_inst <= 1'b1;
                        end
                        3'b011: begin // LD
                            mem_op     <= MEM_SUBCODE.MEM_LD;
                            n_bad_inst <= (BITS == 32) ? 1'b0 : 1'b1;
                        end 
                        3'b100: begin // LBU
                            mem_op     <= MEM_SUBCODE.MEM_LBU;
                            n_bad_inst <= 1'b1;
                        end
                        3'b101: begin // LHU
                            mem_op     <= MEM_SUBCODE.MEM_LHU;
                            n_bad_inst <= 1'b1;
                        end 
                        3'b110: begin // LWU
                            mem_op     <= MEM_SUBCODE.MEM_LWU;
                            n_bad_inst <= (BITS == 32) ? 1'b0 : 1'b1;
                        end
                        default: begin
                            n_bad_inst <= 1'b0;
                        end
                    endcase
                end

                // LOAD_FP instructions
                // Includes FLW, FLD
                // These instructions load floating-point data into FPU registers.
                // ------------------------------------------------------------------------------ //
                LOAD_FP: begin
                    alu_op    <= ALU_SUBCODE.IOP_NULL;
                    fpu_op    <= FPU_SUBCODE.FPU_NULL;
                    immed     <= (BITS == 32) ? signx12w(imm11) : signx12d(imm11);
                    reg_d     <= instruction[11: 7];
                    reg_s1    <= instruction[19:15];
                    case (funct3)
                        3'b010: begin // FLW
                            inst_type  <= 4'b0101;
                            mem_op     <= MEM_SUBCODE.MEM_FLW;
                            n_bad_inst <= 1'b1;
                        end
                        3'b011: begin // FLD
                            inst_type  <= 4'b0111;
                            mem_op     <= MEM_SUBCODE.MEM_FLD;
                            n_bad_inst <= 1'b1;
                        end
                        default: begin
                            n_bad_inst <= 1'b0;
                        end
                    endcase
                end

                // MISC_MEM instructions
                // Includes FENCE, FENCE.I
                // These instructions are used to enforce memory barriers; they send signals 
                // internally to the control unit/MMU and, from the perspective of execution, are
                // coded as a NOP (ADDI %x0, %x0, 0).
                // ------------------------------------------------------------------------------ //
                MISC_MEM: begin
                    fence     <= 1'b1;
                    inst_type <= 4'b1000;
                    alu_op    <= ALU_SUBCODE.IOP_ADDI;
                    fpu_op    <= FPU_SUBCODE.FPU_NULL;
                    mem_op    <= MEM_SUBCODE.MEM_NULL;
                    reg_d     <= 5'b00000;
                    reg_s1    <= 5'b00000;
                    immed     <= 32'h00000000;
                    if (!instruction[11:7] && !instruction[19:15] && !instruction[31:28]) begin
                        case (funct3)
                            3'b000: begin 
                                fence_pred <= instruction[27:24];
                                fence_succ <= instruction[23:20];
                                n_bad_inst <= 1'b1;
                            end 
                            3'b001: begin 
                                fence_pred <= 4'b0000;
                                fence_succ <= 4'b0000;
                                n_bad_inst <= 1'b1;
                            end
                            default: begin
                                fence_pred <= 4'b0000;
                                fence_succ <= 4'b0000;
                                n_bad_inst <= 1'b0;
                            end
                        endcase
                    end else begin
                        n_bad_inst <= 1'b0;
                    end
                end

                // OP instructions
                // Includes ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                // ------------------------------------------------------------------------------ //
                OP: begin 
                    inst_type <= 4'b1000;
                    mem_op    <= MEM_NULL; 
                    fpu_op    <= FPU_NULL;
                    reg_d     <= instruction[11: 7];
                    reg_s1    <= instruction[19:15];
                    reg_s2    <= instruction[24:20];
                    case (funct3)
                        3'b000: begin // ADD, SUB

                        end
                        3'b001: begin end
                        3'b010: begin end
                        3'b011: begin end
                        3'b100: begin end
                        3'b101: begin end
                        3'b110: begin end
                        3'b111: begin end 
                    endcase
                end

                OP_32: begin 

                end

                OP_FP: begin 

                end

                // OP_IMM instructions
                // Includes ADDI, SLTI, SLTIU, ANDI, ORI, XORI, SLLI, SRLI, SRAI
                // TODO: The SRLI, SRAI discrimination logic is likely to not pass functional 
                // verification tests. It selects the upper 6 bits of the 7-bit selector, which 
                // means that a change in bit 25 goes unnoticed. This is a first attempt to maintain 
                // conformity with the RV64 opcode format modification, but should be firmly patched 
                // by checking against the value of parameter BITS.
                // ------------------------------------------------------------------------------ //
                OP_IMM: begin
                    inst_type <= 4'b1000;
                    mem_op    <= MEM_NULL; 
                    fpu_op    <= FPU_NULL;
                    immed     <= (BITS == 32) ? signx12w(imm11) : signx12d(imm11);
                    reg_d     <= instruction[11: 7];
                    reg_s1    <= instruction[19:15];
                    case (funct3)
                        3'b000: begin // ADDI
                            alu_op     <= IOP_ADDI;
                            n_bad_inst <= 1'b1;
                        end
                        3'b001: begin // SLLI
                            alu_op     <= IOP_SLLI;
                            n_bad_inst <= 1'b1;
                        end
                        3'b010: begin // SLTI
                            alu_op     <= IOP_SLTI;
                            n_bad_inst <= 1'b1;
                        end
                        3'b011: begin // SLTIU
                            alu_op     <= IOP_SLTIU;
                            n_bad_inst <= 1'b1;
                        end
                        3'b100: begin // XORI
                            alu_op     <= IOP_XORI;
                            n_bad_inst <= 1'b1;
                        end
                        3'b101: begin // SRLI, SRAI 
                            case (instruction[31:26])
                                6'b000000: begin 
                                    alu_op     <= IOP_SRLI;
                                    n_bad_inst <= 1'b1;
                                end
                                6'b010000: begin 
                                    alu_op     <= IOP_SRAI;
                                    n_bad_inst <= 1'b1;
                                end
                                default: begin 
                                    n_bad_inst <= 1'b0;
                                end
                            endcase
                        end
                        3'b110: begin // ORI 
                            alu_op     <= IOP_ORI;
                            n_bad_inst <= 1'b1;
                        end
                        3'b111: begin // ANDI 
                            alu_op     <= IOP_ANDI;
                            n_bad_inst <= 1'b1;
                        end
                    endcase
                end

                OP_IMM_32: begin 

                end

                // Invalid/unimplemented instructions
                // Includes all others, such as the RSVD0/1 and INST_48B/64B/VLIW opcodes
                // ------------------------------------------------------------------------------ //
                default: begin
                    n_bad_inst <= 1'b0;
                end

            endcase
        end
    end

endmodule