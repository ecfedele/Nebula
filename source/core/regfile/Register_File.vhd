----------------------------------------------------------------------------------------------------
-- Title          : Register File, 32-way with Program Counter                                    --
-- Project        : Nebula RV32 Core                                                              --
-- Filename       : Register_File.vhd                                                             --
-- Description    : Implements a 32-register MIPS/RISC-V file with separate program counter.      --
--                                                                                                --
-- Main Author    : Elijah Creed Fedele                                                           --
-- Creation Date  : May 24, 2023 02:32                                                            --
-- Last Revision  : May 24, 2023 23:23                                                            --
-- Version        : N/A                                                                           --
-- License        : CERN-OHL-S-2.0 (CERN OHL, v2.0, Strongly Reciprocal)                          --
--                                                                                                --
-- Library        : N/A                                                                           --
-- Dependencies   : IEEE (STD_LOGIC_1164, STD_LOGIC_UNSIGNED, STD_LOGIC_ARITH, NUMERIC_STD)       --
-- Initialization : N/A                                                                           --
-- Notes          : Should be able to be simulated on any standards-compliant VHDL                --
--                  simulator, although written specifically for GHDL/GTKWave.                    --
----------------------------------------------------------------------------------------------------

library IEEE;
use 	IEEE.STD_LOGIC_1164.ALL;
use     IEEE.STD_LOGIC_UNSIGNED.ALL;
use     IEEE.STD_LOGIC_ARITH.ALL;
use 	IEEE.NUMERIC_STD.ALL;

----------------------------------------------------------------------------------------------------
-- Module:      Register_File                                                                     --
-- Description: Implements a 32-way register file with multiple buses to support the operation    --
--              and execution of triadic instructions.                                            --
--                                                                                                --
-- Inputs:      DIN         (STD_LOGIC_VECTOR)  The register writeback data (32-bit)              --
--              OPRD        (STD_LOGIC_VECTOR)  The selector for the destination register (5-bit) --
--              OPRS1       (STD_LOGIC_VECTOR)  The selector for source register 1 (5-bit)        --
--              OPRS2       (STD_LOGIC_VECTOR)  The selector for source register 2 (5-bit)        --
--              RDWR        (STD_LOGIC)         Read/write signal (1 = RF read, 0 = RF write)     --
--              RDPC        (STD_LOGIC)         Read program counter signal                       --
-- Outputs:     DOUT1       (STD_LOGIC_VECTOR)  The output from selected register rs1             --
--              DOUT2       (STD_LOGIC_VECTOR)  The output from selected register rs2             --
----------------------------------------------------------------------------------------------------
entity Register_File is port(
    DIN                : in  STD_LOGIC_VECTOR(31 downto 0);
    OPRD, OPRS1, OPRS2 : in  STD_LOGIC_VECTOR( 4 downto 0);
    RDWR, RDPC         : in  STD_LOGIC;
    DOUT1, DOUT2       : out STD_LOGIC_VECTOR(31 downto 0)
);
end entity Register_File;