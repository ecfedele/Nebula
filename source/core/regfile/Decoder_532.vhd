---------------------------------------------------------------------------------------------------
-- Title          : Decoder, 5-to-32, Configurable-Output                                        --
-- Project        : Nebula RV32 Core                                                             --
-- Filename       : Decoder_532.vhd                                                              --
-- Description    : Implements a 5-to-32 decoder (packed 5-bit to 32-way one-hot/one-cold) for   --
--                  use in instruction and logic decoding and switching.                         --
--                                                                                               --
-- Main Author    : Elijah Creed Fedele                                                          --
-- Creation Date  : May 24, 2023 02:42                                                           --
-- Last Revision  : May 24, 2023 23:23                                                           --
-- Version        : N/A                                                                          --
-- License        : CERN-OHL-S-2.0 (CERN OHL, v2.0, Strongly Reciprocal)                         --
--                                                                                               --
-- Library        : N/A                                                                          --
-- Dependencies   : IEEE (STD_LOGIC_1164, STD_LOGIC_UNSIGNED, STD_LOGIC_ARITH, NUMERIC_STD)      --
-- Initialization : N/A                                                                          --
-- Notes          : Should be able to be simulated on any standards-compliant VHDL               --
--                  simulator, although written specifically for GHDL/GTKWave.                   --
---------------------------------------------------------------------------------------------------

library IEEE;
use 	IEEE.STD_LOGIC_1164.ALL;
use     IEEE.STD_LOGIC_UNSIGNED.ALL;
use     IEEE.STD_LOGIC_ARITH.ALL;
use 	IEEE.NUMERIC_STD.ALL;

---------------------------------------------------------------------------------------------------
-- Module:      Decoder_532                                                                      --
-- Description: A basic 5-to-32 decoder module. Accepts a single 5-bit input and transforms this --
--              into a 32-way one-hot encoding for use in switch circuits. This version produces --
--              either one-hot or one-cold encodings depending on the status of the POL line.    --
--                                                                                               --
-- Inputs:      A           (STD_LOGIC_VECTOR)  Input (5-bit)                                    --
--              POL         (STD_LOGIC)         Output polarity - 1 for one-hot, 0 for one-cold  --
--              EN          (STD_LOGIC)         Positive-sense enable line                       --
-- Outputs:     Y           (STD_LOGIC_VECTOR)  One-cold output (32-bit)                         --
---------------------------------------------------------------------------------------------------
entity Decoder_532 is port(
    A       : in  STD_LOGIC_VECTOR(4 downto 0);
    POL, EN : in  STD_LOGIC;
    Y       : out STD_LOGIC_VECTOR(31 downto 0)
); 
end entity Decoder_532;

architecture Behavioral of Decoder_532 is
begin 
    COMB_LOGIC: process(all)
        signal controls : STD_LOGIC_VECTOR(1 downto 0) := EN & POL;
        variable dec    : INTEGER := to_integer(UNSIGNED(A));
    begin
        case (controls) is
            when "00" => Y <= (others => '1');
            when "01" => Y <= (others => '0');
            when "10" => Y <= (dec => '0', others => '1');
            when "11" => Y <= (dec => '1', others => '0');
        end case;
    end process COMB_LOGIC;
end architecture Behavioral;