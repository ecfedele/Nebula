----------------------------------------------------------------------------------------------------
-- Title          : Utilities, Types, and Functions for RISC-V Subset G Instruction Decoding      --
-- Project        : Nebula RV32 Core                                                              --
-- Filename       : Decoder_Utilites.vhd                                                          --
-- Description    : Implements various custom types and functions used in the design of the       --
--                  Nebula instruction decoder.                                                   --
--                                                                                                --
-- Main Author    : Elijah Creed Fedele                                                           --
-- Creation Date  : July 29, 2023 23:19                                                           --
-- Last Revision  : July 30, 2023 02:24                                                           --
-- Version        : N/A                                                                           --
-- License        : CERN-OHL-S-2.0 (CERN OHL, v2.0, Strongly Reciprocal)                          --
-- Copyright      : (C) 2023 Elijah Creed Fedele & Connor Clarke                                  --
--                                                                                                --
-- Library        : N/A                                                                           --
-- Dependencies   : IEEE (STD_LOGIC_1164, NUMERIC_STD)                                            --
-- Initialization : N/A                                                                           --
-- Notes          : Should be able to be simulated on any standards-compliant VHDL                --
--                  simulator, although written specifically for GHDL/GTKWave.                    --
----------------------------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

package Decoder_Utilities is

    ------------------------------------------------------------------------------------------------
    -- RISC-V opcode allocations                                                                  --
    -- Contains a complete list of all 32-bit RISC-V instruction opcodes. Note that Nebula still  --
    -- only supports the RV32G subset, and will emit a bad_instruction signal on any unsupported  --
    -- encoding.                                                                                  --
    ------------------------------------------------------------------------------------------------
    type RV_Opcode is (
        OPC_LOAD,   OPC_LOAD_FP,  OPC_CUST_0,    OPC_MISC_MEM, 
        OPC_OP_IMM, OPC_AUIPC,    OPC_OP_IMM_32, OPC_INST_48B0, 
        OPC_STORE,  OPC_STORE_FP, OPC_CUST_1,    OPC_AMO, 
        OPC_OP,     OPC_LUI,      OPC_OP_32,     OPC_INST_64B, 
        OPC_MADD,   OPC_MSUB,     OPC_NMSUB,     OPC_NMADD, 
        OPC_OP_FP,  OPC_RSVD_0,   OPC_CUST_2,    OPC_INST_48B1, 
        OPC_BRANCH, OPC_JALR,     OPC_RSVD_1,    OPC_JAL, 
        OPC_SYSTEM, OPC_RSVD_2,   OPC_CUST_3,    OPC_INST_VLIW,
        OPC_UNKNOWN
    );

    ------------------------------------------------------------------------------------------------
    -- Integer operation (ALU) subcodes                                                           --
    -- This 7-bit subcode format encompasses the entirety of the "standard" RV32G and RV64G       --
    -- integer arithmetic operation set. This subcode format is, in general, of the format:       --
    --                                                                                            --
    --     +-------------------------------+                                                      --
    --     |   6   |   5   | 4  3  2  1  0 |                                                      --
    --     | width | immed | function code |                                                      --
    --     +-------------------------------+                                                      --
    --                                                                                            --
    -- Here, the 'width' bit signifies a 64-bit operation (i.e. FUNCxW for RV64G). It is oriented --
    -- as MSB to enable RV32G functional units to simply ignore it and process only the lower six --
    -- bits, as the RV32G master instruction decoder will issue an 'illegal instruction' signal   --
    -- if a 64-bit version is encountered.                                                        --
    --                                                                                            --
    -- As the name implies, the 'immed' bit indicates to the functional unit that an immediate    --
    -- version of the instruction is present. The subcodes below have been selected so that       --
    -- instructions featuring both register and immediate variants (ADD/ADDI, SLL/SLLI, etc.)     --
    -- differ only in their bit 5 value. This allows this bit to serve as a simple mux between    --
    -- the two sources. Note that some other decision logic will be necessary here as not all     --
    -- operations support immediate variants.                                                     --
    --                                                                                            --
    -- One unique gotcha is the dual definition of SLLI, SRLI, and SRAI in the RV64G instruction  --
    -- set. The base RV32G set does not provide enough room for the required 6-bit shamt field,   --
    -- which requires a separate shift encoding be defined in RV64G. Nonetheless, the 5-bit       --
    -- encodings remain valid, which present an interesting conundrum that two mostly-identical   --
    -- encodings exist for the same instruction. The decoder is responsible for handling this,    --
    -- issuing the IOP_SLLI, IOP_SRLI, and IOP_SRAI subcodes in both situations. In both cases,   --
    -- the 5-bit or 6-bit shamt field is zero-extended to the immediate.                          --
    ------------------------------------------------------------------------------------------------
    type Integer_Operation is (
        IOP_ADD,    IOP_ADDI,   IOP_ADDW,   IOP_ADDIW,  
        IOP_SUB,    IOP_SUBW,   IOP_SLT,    IOP_SLTI,   
        IOP_SLTU,   IOP_SLTIU,  IOP_MUL,    IOP_MULW, 
        IOP_MULH,   IOP_MULHSU, IOP_MULHU,  IOP_DIV,    
        IOP_DIVW,   IOP_DIVU,   IOP_DIVUW,  IOP_REM,    
        IOP_REMW,   IOP_REMU,   IOP_REMUW,  IOP_AND, 
        IOP_ANDI,   IOP_OR,     IOP_ORI,    IOP_XOR,    
        IOP_XORI,   IOP_SLL,    IOP_SLLW,   IOP_SLLI,   
        IOP_SLLIW,  IOP_SRL,    IOP_SRLW,   IOP_SRLI, 
        IOP_SRLIW,  IOP_SRA,    IOP_SRAW,   IOP_SRAI,   
        IOP_SRAIW
    );

    ------------------------------------------------------------------------------------------------
    -- Non-atomic load/store (memory) subcodes                                                    --
    -- These codes are passed to the load/store logic to effect data transfers to and from the    --
    -- processor registers. This subcode possesses the format:                                    --
    --                                                                                            --
    --     +----------------------------------------------+                                       --
    --     |   5   |   4   |   3   |   2   |   1      0   |                                       --
    --     | width | float | rd/wr | upper | operand size |                                       --
    --     +----------------------------------------------+                                       --
    --                                                                                            --
    -- The fields are as follows:                                                                 --
    --     - width       : if set, indicates a RV64G-only instruction not present in RV32G        --
    --     - float       : if set, the operation encoded is a FP operation and uses FP registers  --
    --     - rd/wr       : if set, the operation reads from memory (load), otherwise a store      --
    --     - upper       : indicates the 'upper' variant of an instruction                        --
    --     - operand size: indicates the operand set; encoded as a two-bit selector:              --
    --                         { B = 2'b00, H = 2'b01, W = 2'b10, D = 2'b11 }                     --
    --                                                                                            --
    -- Similarly to the ALU subcodes, the 'width' term is presented MSB-first to allow for 32-bit --
    -- implementations to safely ignore it, as the instruction decoder is responsible for         --
    -- detecting the illegal instruction and flagging it.                                         --
    ------------------------------------------------------------------------------------------------
    type Memory_Operation is (
        MEM_LB,  MEM_LH,  MEM_LW,  MEM_LD,  
        MEM_LBU, MEM_LHU, MEM_LWU, MEM_FLW, 
        MEM_FLD, MEM_SB,  MEM_SH,  MEM_SW, 
        MEM_SD,  MEM_FSW, MEM_FSD
    );

    function To_Opcode (Instruction_Opcode : STD_LOGIC_VECTOR) return RV_Opcode;

    ------------------------------------------------------------------------------------------------
    -- Subcode generation functions                                                               --
    -- As VHDL does not support user-specified enumeration type values, we are unable to directly --
    -- produce the desired subcode from the enumeration types above. These functions listed below --
    -- serve to produce the intended subcode from a specified enumeration value.                  --
    ------------------------------------------------------------------------------------------------
    function Generate_Alu_Subcode (Alu_Subcode : Integer_Operation) return STD_LOGIC_VECTOR;
    function Generate_Fpu_Subcode (Fpu_Subcode : Float_Operation)   return STD_LOGIC_VECTOR;
    function Generate_Mem_Subcode (Mem_Subcode : Memory_Operation)  return STD_LOGIC_VECTOR;

end Decoder_Utilities;

package body Decoder_Utilities is

    function To_Opcode (Instruction_Opcode : STD_LOGIC_VECTOR) return RV_Opcode is
        variable RVOPC  : STD_LOGIC_VECTOR(4 downto 0) := Instruction_Opcode(6 downto 2);
    begin
        if Instruction_Decode(1 downto 0) /= "11" then
            return OPC_UNKNOWN;
        else
            case RVOPC is
                when "00000" => return OPC_LOAD;      when "00001" => return OPC_LOAD_FP;
                when "00010" => return OPC_CUST_0;    when "00011" => return OPC_MISC_MEM;
                when "00100" => return OPC_OP_IMM;    when "00101" => return OPC_AUIPC;
                when "00110" => return OPC_OP_IMM_32; when "00111" => return OPC_INST_48B0;
                when "01000" => return OPC_STORE;     when "01001" => return OPC_STORE_FP;
                when "01010" => return OPC_CUST_1;    when "01011" => return OPC_AMO;
                when "01100" => return OPC_OP;        when "01101" => return OPC_LUI;
                when "01110" => return OPC_OP_32;     when "01111" => return OPC_INST_64B;
                when "10000" => return OPC_MADD;      when "10001" => return OPC_MSUB;
                when "10010" => return OPC_NMSUB;     when "10011" => return OPC_NMADD;
                when "10100" => return OPC_OP_FP;     when "10101" => return OPC_RSVD_0;
                when "10110" => return OPC_CUST_2;    when "10111" => return OPC_INST_48B1;
                when "11000" => return OPC_BRANCH;    when "11001" => return OPC_JALR;
                when "11010" => return OPC_RSVD_1;    when "11011" => return OPC_JAL;
                when "11100" => return OPC_SYSTEM;    when "11101" => return OPC_RSVD_2;
                when "11110" => return OPC_CUST_3;    when "11111" => return OPC_INST_VLIW;
                when others  => return OPC_UNKNOWN;
            end case;
        end if;
    end To_Opcode;

end Decoder_Utilities;