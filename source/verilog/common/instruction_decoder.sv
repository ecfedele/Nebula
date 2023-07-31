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
    output wire        n_bad_inst
);

    import instruction_utilities::*;
    alu_op_type alu_subcode;
    fpu_op_type fpu_subcode;
    mem_op_type mem_subcode;

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
                // -------------------------------------- //
                LOAD: begin
                    inst_type = 4'b0001;
                    alu_op    = IOP_NULL;
                    fpu_op    = IOP_NULL;
                    immed     = (BITS == 32) ? signx12w(imm11) : signx12d(imm11);
                    reg_d     = instruction[11: 7];
                    reg_s1    = instruction[19:15];
                    case (funct3)
                        3'b000: begin // LB
                            mem_op     = MEM_LB;
                            n_bad_inst = 1'b1;
                        end
                        3'b001: begin // LH
                            mem_op     = MEM_LH;
                            n_bad_inst = 1'b1;
                        end 
                        3'b010: begin // LW
                            mem_op     = MEM_LW;
                            n_bad_inst = 1'b1;
                        end
                        3'b011: begin // LD
                            mem_op     = MEM_LD;
                            n_bad_inst = (BITS == 32) ? 1'b0 : 1'b1;
                        end 
                        3'b100: begin // LBU
                            mem_op     = MEM_LBU;
                            n_bad_inst = 1'b1;
                        end
                        3'b101: begin // LHU
                            mem_op     = MEM_LHU;
                            n_bad_inst = 1'b1;
                        end 
                        3'b110: begin // LWU
                            mem_op     = MEM_LWU;
                            n_bad_inst = (BITS == 32) ? 1'b0 : 1'b1;
                        end
                        default: begin
                            n_bad_inst = 1'b0;
                        end
                    endcase
                end

                // LOAD_FP instructions
                // Includes FLW, FLD
                // -------------------------------------- //
                LOAD_FP: begin
                    alu_op    = IOP_NULL;
                    fpu_op    = IOP_NULL;
                    immed     = (BITS == 32) ? signx12w(imm11) : signx12d(imm11);
                    reg_d     = instruction[11: 7];
                    reg_s1    = instruction[19:15];
                    case (funct3)
                        3'b010: begin // FLW
                            inst_type = 4'b0101;
                            mem_op    = MEM_FLW;
                            n_bad_inst = 1'b1;
                        end
                        3'b011: begin // FLD
                            inst_type = 4'b0111;
                            mem_op    = MEM_FLD;
                            n_bad_inst = 1'b1;
                        end
                        default: begin
                            n_bad_inst = 1'b0;
                        end
                    endcase
                end

                // Invalid/unimplemented instructions
                // Includes all others, such as the RSVD0/1
                // and INST_48B/64B/VLIW opcodes
                // -------------------------------------- //
                default: begin
                    n_bad_inst = 1'b0;
                end

            endcase
        end
    end

endmodule