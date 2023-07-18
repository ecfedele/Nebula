---------------------------------------------------------------------------------------------------
-- Title          : Decoder, 5-to-32, Negative-Polarity                                          --
-- Project        : Nebula RV32 Core                                                             --
-- Filename       : Register_Decoder.vhd                                                         --
-- Description    : Implements a 5-to-32 negative-polarity decoder with inverted enable used for --
--                  the selection of a register within the register file.                        --
--                                                                                               --
-- Main Author    : Elijah Creed Fedele                                                          --
-- Creation Date  : July 18, 2023 02:24                                                          --
-- Last Revision  : July 18, 2023 02:24                                                          --
-- Version        : N/A                                                                          --
-- License        : CERN-OHL-S-2.0 (CERN OHL, v2.0, Strongly Reciprocal)                         --
-- Copyright      : (C) 2023 Elijah Creed Fedele & Connor Clarke                                 --
--                                                                                               --
-- Library        : N/A                                                                          --
-- Dependencies   : IEEE (STD_LOGIC_1164, NUMERIC_STD)                                           --
-- Initialization : N/A                                                                          --
-- Notes          : Should be able to be simulated on any standards-compliant VHDL               --
--                  simulator, although written specifically for GHDL/GTKWave.                   --
---------------------------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

---------------------------------------------------------------------------------------------------
-- Module:      Register_Decoder                                                                 --
-- Description: Implements a 5-to-32 negative-polarity decoder for selection of registers within --
--              the register file.                                                               --
--                                                                                               --
-- Inputs:      addr    ( 5)    The register address to decode                                   --
--              n_en    ( 1)    Enable, active LOW - when inactive, output defaults to FFFFFFFFh --
--                                                                                               --
-- Outputs:     reg_sel (32)    The one-cold decoder output                                      --
---------------------------------------------------------------------------------------------------
entity Register_Decoder is
    port(
        addr    : in  STD_LOGIC_VECTOR( 4 downto 0);
        n_en    : in  STD_LOGIC;
        reg_sel : out STD_LOGIC_VECTOR(31 downto 0)
    );
end entity Register_Decoder;

architecture RTL of Register_Decoder is
begin
    ADDR_DECODE: process(addr, n_en)
    begin
        if n_en = '1' then
            reg_sel <= (others => '1');
        else
            case addr is
                when "00000" => reg_sel <= ( 0 => '0', others => '1');
                when "00001" => reg_sel <= ( 1 => '0', others => '1');
                when "00010" => reg_sel <= ( 2 => '0', others => '1');
                when "00011" => reg_sel <= ( 3 => '0', others => '1');
                when "00100" => reg_sel <= ( 4 => '0', others => '1');
                when "00101" => reg_sel <= ( 5 => '0', others => '1');
                when "00110" => reg_sel <= ( 6 => '0', others => '1');
                when "00111" => reg_sel <= ( 7 => '0', others => '1');
                when "01000" => reg_sel <= ( 8 => '0', others => '1');
                when "01001" => reg_sel <= ( 9 => '0', others => '1');
                when "01010" => reg_sel <= (10 => '0', others => '1');
                when "01011" => reg_sel <= (11 => '0', others => '1');
                when "01100" => reg_sel <= (12 => '0', others => '1');
                when "01101" => reg_sel <= (13 => '0', others => '1');
                when "01110" => reg_sel <= (14 => '0', others => '1');
                when "01111" => reg_sel <= (15 => '0', others => '1');
                when "10000" => reg_sel <= (16 => '0', others => '1');
                when "10001" => reg_sel <= (17 => '0', others => '1');
                when "10010" => reg_sel <= (18 => '0', others => '1');
                when "10011" => reg_sel <= (19 => '0', others => '1');
                when "10100" => reg_sel <= (20 => '0', others => '1');
                when "10101" => reg_sel <= (21 => '0', others => '1');
                when "10110" => reg_sel <= (22 => '0', others => '1');
                when "10111" => reg_sel <= (23 => '0', others => '1');
                when "11000" => reg_sel <= (24 => '0', others => '1');
                when "11001" => reg_sel <= (25 => '0', others => '1');
                when "11010" => reg_sel <= (26 => '0', others => '1');
                when "11011" => reg_sel <= (27 => '0', others => '1');
                when "11100" => reg_sel <= (28 => '0', others => '1');
                when "11101" => reg_sel <= (29 => '0', others => '1');
                when "11110" => reg_sel <= (30 => '0', others => '1');
                when "11111" => reg_sel <= (31 => '0', others => '1');
                when others  => reg_sel <= (others => '1');
            end case;
        end if;
    end process ADDR_DECODE;
end architecture RTL;