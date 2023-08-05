// ---------------------------------------------------------------------------------------------- //
// Title           : Utilities, Types, and Functions for RISC-V Subset G Instruction Decoding     //
// Project         : Nebula RV32 Core                                                             //
// Filename        : instruction_utilities.sv                                                     //
// Description     : Implements various custom types and functions used in the design of the      //
//                   Nebula instruction decoder.                                                  //
//                                                                                                //
// Main Author     : Elijah Creed Fedele                                                          //
// Creation Date   : July 29, 2023 23:19                                                          //
// Last Revision   : July 30, 2023 02:24                                                          //
// Version         : ---                                                                          //
// License         : CERN-OHL-S-2.0 (CERN OHL, v2.0, Strongly Reciprocal)                         //
// Copyright       : (C) 2023 Elijah Creed Fedele & Connor Clarke                                 //
//                                                                                                //
// Library/Package : instruction_utilities                                                        //
// Dependencies    : ---                                                                          //
// Initialization  : ---                                                                          //
// Notes           : Intended for inclusion in synthesizable files.                               //
//                   Primary simulation/synthesis targets are Vivado & Quartus Prime.             //
// ---------------------------------------------------------------------------------------------- //

package instruction_utilities;

// ---------------------------------------------------------------------------------------------- //
// RISC-V opcode allocations                                                                      //
// Contains a complete list of all 32-bit RISC-V instruction opcodes. Note that Nebula still only //
// supports the RV32G subset, and will emit a bad_instruction signal on any unsupported encoding. //
// ---------------------------------------------------------------------------------------------- //
typedef enum logic [6:0] {
    LOAD   = 7'b0000011, LOAD_FP  = 7'b0000111, CUSTOM_0    = 7'b0001011, MISC_MEM  = 7'b0001111,
    OP_IMM = 7'b0010011, AUIPC    = 7'b0010111, OP_IMM_32   = 7'b0011011, INST_48B0 = 7'b0011111,
    STORE  = 7'b0100011, STORE_FP = 7'b0100111, CUSTOM_1    = 7'b0101011, AMO       = 7'b0101111,
    OP     = 7'b0110011, LUI      = 7'b0110111, OP_32       = 7'b0111011, INST_64B  = 7'b0111111,
    MADD   = 7'b1000011, MSUB     = 7'b1000111, NMSUB       = 7'b1001011, NMADD     = 7'b1001111, 
    OP_FP  = 7'b1010011, RSVD0    = 7'b1010111, RV128_CUST2 = 7'b1011011, INST_48B1 = 7'b1011111, 
    BRANCH = 7'b1100011, JALR     = 7'b1100111, RSVD1       = 7'b1101011, JAL       = 7'b1101111, 
    SYSTEM = 7'b1110011, RSVD2    = 7'b1110111, RV128_CUST3 = 7'b1111011, INST_VLIW = 7'b1111111
} rv_opcode_e;

// ---------------------------------------------------------------------------------------------- //
// Integer operation (ALU) subcodes                                                               //
// This 7-bit subcode format encompasses the entirety of the "standard" RV32G and RV64G integer   //
// arithmetic operation set. This subcode format is, in general, of the format:                   //
//                                                                                                //
//     +-------------------------------+                                                          //
//     |   6   |   5   | 4  3  2  1  0 |                                                          //
//     | width | immed | function code |                                                          //
//     +-------------------------------+                                                          //
//                                                                                                //
// Here, the 'width' bit signifies a 64-bit operation (i.e. FUNCxW for RV64G). It is oriented as  // 
// MSB to enable RV32G functional units to simply ignore it and process only the lower six bits,  //
// as the RV32G master instruction decoder will issue an 'illegal instruction' signal if a 64-bit //
// version is encountered.                                                                        //
//                                                                                                //
// As the name implies, the 'immed' bit indicates to the execution unit that an immediate-encoded //
// version of the instruction is present. The subcodes below have been selected and mapped so     //
// that instructions featuring both register and immediate variants (ADD/ADDI, SLL/SLLI, etc.)    //
// differ only in their bit 5 value. This allows this bit to serve as a simple mux between the    //
// two sources. Note that some other decision logic will be necessary here as not all operations  //
// support immediate variants.                                                                    //
//                                                                                                //
// One unique gotcha is the dual definition of SLLI, SRLI, and SRAI in the RV64G instruction set. //
// The base RV32G set does not provide enough room in the instruction formats for the required    //
// 6-bit shamt field, which requires a separate shift encoding be defined in RV64G. Nonetheless,  //
// the 5-bit encodings remain valid, which present the interesting conundrum that two largely     //
// identical encodings exist for the same instruction. The decoder is responsible for handling    //
// this, issuing the IOP_SLLI, IOP_SRLI, and IOP_SRAI subcodes in both situations. In both cases, //
// the 5-bit or 6-bit shamt field is zero-extended to the immediate.                              //
// ---------------------------------------------------------------------------------------------- //
typedef enum logic [6:0] {
    IOP_ADD   = 7'b0000000, IOP_ADDI   = 7'b0100000, IOP_ADDW  = 7'b1000000, IOP_ADDIW = 7'b1100000,
    IOP_SUB   = 7'b0000001, IOP_SUBW   = 7'b1000001, IOP_SLT   = 7'b0000010, IOP_SLTI  = 7'b0100010,
    IOP_SLTU  = 7'b0000011, IOP_SLTIU  = 7'b0100011, IOP_MUL   = 7'b0000100, IOP_MULW  = 7'b1000100,
    IOP_MULH  = 7'b0000101, IOP_MULHSU = 7'b0000110, IOP_MULHU = 7'b0000111, IOP_DIV   = 7'b0001000,
    IOP_DIVW  = 7'b1001000, IOP_DIVU   = 7'b0001001, IOP_DIVUW = 7'b1001001, IOP_REM   = 7'b0001010,
    IOP_REMW  = 7'b1001010, IOP_REMU   = 7'b0001011, IOP_REMUW = 7'b1001011, IOP_AND   = 7'b0001100,
    IOP_ANDI  = 7'b0101100, IOP_OR     = 7'b0001101, IOP_ORI   = 7'b0101101, IOP_XOR   = 7'b0001110,
    IOP_XORI  = 7'b0101110, IOP_SLL    = 7'b0001111, IOP_SLLI  = 7'b0101111, IOP_SLLW  = 7'b1001111,
    IOP_SLLIW = 7'b1101111, IOP_SRL    = 7'b0010000, IOP_SRLI  = 7'b0110000, IOP_SRLW  = 7'b1010000,
    IOP_SRLIW = 7'b1110000, IOP_SRA    = 7'b0010001, IOP_SRAI  = 7'b0110001, IOP_SRAW  = 7'b1010001,
    IOP_SRAIW = 7'b1110001, IOP_NULL   = 7'b1111111
} alu_subcode_e;

// ---------------------------------------------------------------------------------------------- //
// Floating-point operation subcodes                                                              //
// These codes are used to instruct the floating-point unit, and are precision-agnostic. The only //
// means of difinitively determining which instruction the below subcodes belong to is to decode  //
// them in the presence of the 'S/D bit' or other precision indicator. The general format for the //
// encoding is as follows:                                                                        //
//                                                                                                //
//     +-----------------------+                                                                  //
//     |   5   | 4  3  2  1  0 |                                                                  //
//     | width | function code |                                                                  //
//     +-----------------------+                                                                  //
//                                                                                                //
// In general, the 'width' bit functions similarly to how it operates in the ALU and memory codes //
// in that it indicates whether an operation is only extant in RV64G or only operates on 64-bit   //
// integer registers. As such, it can be safely ignored by RV32G-only execution units, as the     //
// instruction decoder will suss out an invalid instruction prior to issue.                       //
//                                                                                                // 
// Some instructions are reordered from their ISA order to better fit the layout patterns of      //
// functional units designed by men and not machines. Additionally, care must be taken by FPU     //
// decoders, as four instructions (two pairings) possess only one interpretation and are agnostic //
// to precision-select switches:                                                                  //
//     - FMV.X.W (FPU_TXF2I) and FMV.W.X (FPU_TXI2F) are single-precision only                    //
//     - FMV.X.D (FPU_TXF2L) and FMV.D.X (FPU_TXL2F) are double-precision and 64-bit only         //
// ---------------------------------------------------------------------------------------------- //
typedef enum logic [5:0] {
    FPU_ADD   = 6'b000000, FPU_SUB   = 6'b000001, FPU_MUL   = 6'b000010, FPU_DIV   = 6'b000011,
    FPU_MADD  = 6'b000100, FPU_MSUB  = 6'b000101, FPU_NMADD = 6'b000110, FPU_NMSUB = 6'b000111,
    FPU_SQRT  = 6'b001000, FPU_SGNJ  = 6'b001001, FPU_SGNJN = 6'b001010, FPU_SGNJX = 6'b001011,
    FPU_MIN   = 6'b001100, FPU_MAX   = 6'b001101, FPU_EQ    = 6'b001110, FPU_LT    = 6'b001111,
    FPU_LE    = 6'b010000, FPU_CLASS = 6'b010001, FPU_F2IS  = 6'b010010, FPU_F2IU  = 6'b010011,
    FPU_I2FS  = 6'b010100, FPU_I2FU  = 6'b010101, FPU_TXF2I = 6'b010110, FPU_TXI2F = 6'b010111, 
    FPU_F2LS  = 6'b110010, FPU_F2LU  = 6'b110011, FPU_L2FS  = 6'b110100, FPU_L2FU  = 6'b110101, 
    FPU_TXF2L = 6'b110110, FPU_TXI2F = 6'b110111, FPU_NULL  = 6'b111111
} fpu_subcode_e;

// ---------------------------------------------------------------------------------------------- //
// Non-atomic load/store (memory) subcodes                                                        //
// These codes are passed to the load/store logic to effect data transfers into and out of the    //
// processor registers. This subcode possesses the format:                                        //        
//                                                                                                //
//     +----------------------------------------------+                                           //
//     |   5   |   4   |   3   |   2   |   1      0   |                                           //
//     | width | float | rd/wr | upper | operand size |                                           //
//     +----------------------------------------------+                                           //
//                                                                                                //
// The fields are as follows:                                                                     //
//     - width       : if set, indicates a RV64G-only instruction not present in RV32G            //
//     - float       : if set, the operation encoded is a FP operation and uses FP registers      //
//     - rd/wr       : if set, the operation reads from memory (load), otherwise a store          //
//     - upper       : indicates the 'upper' variant of an instruction                            //
//     - operand size: indicates the operand set; encoded as a two-bit selector:                  //
//                         { B = 2'b00, H = 2'b01, W = 2'b10, D = 2'b11 }                         //
//                                                                                                //
// Similarly to the ALU subcodes, the 'width' term is presented MSB-first to allow for 32-bit     //
// implementations to safely ignore it, as the instruction decoder is responsible for detecting   //
// the illegal instruction and flagging it.                                                       //
// ---------------------------------------------------------------------------------------------- //
typedef enum logic [5:0] {
    MEM_LB   = 6'b001000, MEM_LH   = 6'b001001, MEM_LW   = 6'b001010, MEM_LD   = 6'b101011,
    MEM_LBU  = 6'b001100, MEM_LHU  = 6'b001101, MEM_LWU  = 6'b101110, MEM_FLW  = 6'b011010,
    MEM_FLD  = 6'b011011, MEM_SB   = 6'b000000, MEM_SH   = 6'b000001, MEM_SW   = 6'b000010, 
    MEM_SD   = 6'b100011, MEM_FSW  = 6'b010010, MEM_FSD  = 6'b010011, MEM_NULL = 6'b111111
} mem_subcode_e;

// ---------------------------------------------------------------------------------------------- //
// Sign-extension and zero-extension functions                                                    //
// The following functions provide easy-to-use macros for sign extension and zero extension of    //
// immediate values of various widths.                                                            //
//     signx12w : sign extend 12-bit immediate to 32-bit word                                     //
//     signx12d : sign extend 12-bit immediate to 64-bit doubleword                               //
//     zerox12w : zero extend 12-bit immediate to 32-bit word                                     //
//     zerox12d : zero extend 12-bit immediate to 64-bit doubleword                               //
// ---------------------------------------------------------------------------------------------- //

function logic [31:0] signx12w (input logic [11:0] imm); 
    signext12w = (imm[11]) ? {20'hfffff, imm} : {20'h00000, imm};
endfunction

function logic [63:0] signx12d (input logic [11:0] imm); 
    signx12d = (imm[11]) ? {52'hfffffffffffff, imm} : {52'h0000000000000, imm};
endfunction

function logic [31:0] zerox12w (input logic [11:0] imm); 
    zerox12w = {20'h00000, imm};
endfunction

function logic [63:0] zerox12d (input logic [11:0] imm); 
    zerox12d = {52'h0000000000000, imm};
endfunction

endpackage