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
    input  logic [31:0] instruction,
    input  logic        clk, n_rst,
    input  logic        n_irdy, n_stall,
    output logic        alu_in, mem_in, fpu_in, fpu_sd
    output logic [ 6:0] alu_op, mem_op,
    output logic [ 4:0] fpu_op, 
    output logic [ 4:0] reg_d, reg_s1, reg_s2, reg_s3,
    output logic [ 2:0] reg_conf,
    output logic [31:0] immed,
    output logic        n_bad_inst
);

    import instruction_utilities::*;
    alu_op_type alu_subcode;
    fpu_op_type fpu_subcode;
    mem_op_type mem_subcode;

    always @ (posedge clk or n_rst)
    begin
        if (n_rst == 1'b0) begin

        end else begin

        end
    end

endmodule