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

    // RISC-V opcode allocations
    // Contains a complete list of all 32-bit RISC-V instruction opcodes. Note that Nebula still only
    // supports the RV32G subset, and will emit a bad_instruction signal on any unsupported encoding.
    enum logic [6:0] {
        LOAD   = 7'b0000011, LOAD_FP  = 7'b0000111, CUSTOM_0    = 7'b0001011, MISC_MEM  = 7'b0001111,
        OP_IMM = 7'b0010011, AUIPC    = 7'b0010111, OP_IMM_32   = 7'b0011011, INST_48B0 = 7'b0011111,
        STORE  = 7'b0100011, STORE_FP = 7'b0100111, CUSTOM_1    = 7'b0101011, AMO       = 7'b0101111,
        OP     = 7'b0110011, LUI      = 7'b0110111, OP_32       = 7'b0111011, INST_64B  = 7'b0111111,
        MADD   = 7'b1000011, MSUB     = 7'b1000111, NMSUB       = 7'b1001011, NMADD     = 7'b1001111, 
        OP_FP  = 7'b1010011, RSVD0    = 7'b1010111, RV128_CUST2 = 7'b1011011, INST_48B1 = 7'b1011111, 
        BRANCH = 7'b1100011, JALR     = 7'b1100111, RSVD1       = 7'b1101011, JAL       = 7'b1101111, 
        SYSTEM = 7'b1110011, RSVD2    = 7'b1110111, RV128_CUST3 = 7'b1111011, INST_VLIW = 7'b1111111
    } opcode_type;

    // Integer operation (ALU) subcodes
    // This 7-bit subcode format encompasses the entirety of the "standard" RV32G and RV64G integer
    // arithmetic operation set. This subcode format is, in general, of the format:
    //
    //     +-------------------------------+
    //     |   6   |   5   | 4  3  2  1  0 |
    //     | width | immed | function code |
    //     +-------------------------------+
    //
    // Here, the 'width' bit signifies a 64-bit operation (i.e. FUNCxW for RV64G). It is oriented as MSB to
    // enable RV32G functional units to simply ignore it and process only the lower six bits, as the RV32G 
    // master instruction decoder will issue a 'bad instruction' signal if the 64-bit version is encountered.
    //
    // As it implies, the 'immed' bit indicates to the functional unit that an immediate-encoding version of
    // the instruction is present. The subcodes below have been designed so that register/immediate pairings
    // of instructions (ADD/ADDI, SLL/SLLI, etc.) differ only in their bit 5 value. This allows this bit to
    // serve as a simple mux between the two sources. Note that some decision logic will be necessary here as
    // not all operations support immediate variants.
    //
    // Unlike the instruction set, this mapping does not maintain dual definitions for SLLI, SRLI, and SRAI. 
    // Instead, it relies on this module (the instruction decoder) to detect both and zero-extend the 
    // immediate appropriately. The barrel shifter unit can then mask down the immediate to get the shift
    // constant.
    enum logic [6:0] {
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
        IOP_SRAIW = 7'b1110001 
    } alu_op_type;

    enum logic [4:0] {

    } fpu_op_type;

    // Non-atomic load/store (memory) subcodes
    // These codes are passed to the load/store logic to effect data transfers to and from the processor 
    // registers. This subcode possesses the format:
    //
    //     +----------------------------------------------+
    //     |   5   |   4   |   3   |   2   |   1      0   |
    //     | width | float | rd/wr | upper | operand size |
    //     +----------------------------------------------+
    //
    // The fields are as follows:
    //     - width       : if set, indicates a RV64G-only instruction not present in RV32G
    //     - float       : if set, the operation encoded is a FP operation and should use the FP register set
    //     - rd/wr       : if set, the operation reads from memory (load), else if clear, is a write (store)
    //     - upper       : indicates the 'upper' variant of an instruction
    //     - operand size: indicates the operand set; encoded { B = 2'b00, H = 2'b01, W = 2'b10, D = 2'b11 }
    //
    // Similarly to the ALU subcodes, the 'width' term is presented MSB-first to allow for 32b implementations
    // to safely ignore it, as the instruction decoder is responsible for detecting the illegal instruction 
    // and flagging it.
    enum logic [5:0] {
        MEM_LB  = 6'b001000, MEM_LH  = 6'b001001, MEM_LW  = 6'b001010, MEM_LD  = 6'b101011,
        MEM_LBU = 6'b001100, MEM_LHU = 6'b001101, MEM_LWU = 6'b101110, MEM_FLW = 6'b011010,
        MEM_FLD = 6'b011011, MEM_SB  = 6'b000000, MEM_SH  = 6'b000001, MEM_SW  = 6'b000010, 
        MEM_SD  = 6'b100011, MEM_FSW = 6'b010010, MEM_FSD = 6'b010011
    } mem_op_type;

    // Sign extension helper function for 12-bit immediates.
    // Fills the upper 20 bits with '1' if the sign bit of the immediate is set. Otherwise, fills the upper
    // 20 bits with '0'.
    function logic [31:0] sgnext12 (input logic [11:0] imm); 
        sgnext12 = (imm[11]) ? {20'hfffff, imm} : {20'h00000, imm};
    endfunction

    opcode_type opcode;
    alu_op_type alu_code;
    fpu_op_type fpu_code;
    mem_op_type mem_code;
    logic [ 6:0] funct7;
    logic [ 2:0] funct3;
    logic [11:0] imm12;
    logic [ 4:0] destreg;

    wire bad_instruction;
    assign n_bad_inst = ~bad_instruction;

    always @(posedge clk or n_rst) begin
        if (n_rst == 1'b0) begin
            opcode = 5'b00000;
            funct3 = 3'b000;
            funct7 = 3'b0000000;
            bad_instruction = 1'b0;
        end 
        else begin

            opcode = instruction[ 6: 2];
            funct3 = instruction[14:12];
            funct7 = instruction[31:25];
            imm12  = instruction[31:20];

            case (opcode)
                // Integer LOAD instructions.
                // These instructions sign-extend imm[11:0] to 32-bit width and add it to the supplied source
                // register to obtain the load address.  
                LOAD: begin
                    mem_op = 1'b1;
                    immed  = sgnext12(imm12);
                    case (funct3)
                        3'b000: // LB
                        3'b001: // LH
                        3'b010: // LW
                        3'b011: // LD  (RV64I)
                        3'b100: // LBU
                        3'b101: // LHU 
                        3'b110: // LWU (RV64I)
                    endcase
                end
                default: bad_instruction = 1'b1;
            endcase
        end
    end

endmodule