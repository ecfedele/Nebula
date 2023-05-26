---------------------------------------------------------------------------------------------------
-- Title          : Register, 32-bit, Two-Output with Tristates                                  --
-- Project        : Nebula RV32 Core                                                             --
-- Filename       : Register_32.vhd                                                              --
-- Description    : Implements a basic 32-bit, single-write, dual-read storage register.         --
--                                                                                               --
-- Main Author    : Elijah Creed Fedele                                                          --
-- Creation Date  : May 24, 2023 02:32                                                           --
-- Last Revision  : May 24, 2023 23:23                                                           --
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
use 	IEEE.STD_LOGIC_1164.ALL;
use 	IEEE.NUMERIC_STD.ALL;

---------------------------------------------------------------------------------------------------
-- Module:      Register_32                                                                      --
-- Description: Implements a single-input, dual-output 32-bit register with write-enable and     --
--              dual output control signals. Emits tri-state ('Z') signals for compatibility     --
--              with parallel bus implementations.                                               --
--                                                                                               --
-- Inputs:      D           (STD_LOGIC_VECTOR)  Main data input (32-bit wide)                    --
--              CLK         (STD_LOGIC)	        Clock signal input                               --
--              nRST        (STD_LOGIC)         Asynchronous reset signal (active low)           --
--              nWR         (STD_LOGIC)         Write-enable signal (active low)                 --
--              nOEA, nOEB  (STD_LOGIC)         Output-enable signals (active low, channels A/B) --
-- Outputs:     QA, QB      (STD_LOGIC_VECTOR)  Output buses (32-bit wide)                       --
---------------------------------------------------------------------------------------------------
entity Register_32 is port(
    D               : in  STD_LOGIC_VECTOR(31 downto 0);
    CLK, nSET, nRST : in  STD_LOGIC;
    nWR, nOEA, nOEB : in  STD_LOGIC;
    QA, QB          : out STD_LOGIC_VECTOR(31 downto 0)
);
end entity Register_32;

architecture Behavioral of Register_32 is
    signal reg : STD_LOGIC_VECTOR(31 downto 0);
begin
    -- Use a first process to keep the internal state up-to-date.
    --     1. An asynchronous reset (nRST active low) reverts the register state to zero.
    --     2. A write-enable (nWR active low) signal enables synchronous read of data into
    --        the register state.
    DATA_PROC: process(CLK, nSET, nRST, nWR)
    begin
        if (nRST = '0') then
            reg <= (others => '0');
            QA  <= (others => 'Z');
            QB  <= (others => 'Z');
        elsif (nSET = '0') then
            reg <= (others => '1');
        elsif rising_edge(CLK) and nWR = '0' then
            reg <= D;
        end if;
    end process DATA_PROC;
    
    -- Use a second output process to control the output bus condition.
    -- For either channel, if the respective output-enable signal (nOEx, active low) is 
    -- asserted, write the contents of the register onto the bus. Otherwise, maintain the
    -- buses in tri-state/high-Z configuration.
    OUTPUT_STATE: process(reg, nOEA, nOEB)
        variable output_enables : STD_LOGIC_VECTOR(1 downto 0);
    begin
        output_enables  := nOEA & nOEB;
        case (output_enables) is
            when "00" =>
                QA <= reg;
                QB <= reg;
            when "01" =>
                QA <= reg;
                QB <= (others => 'Z');
            when "10" =>
                QA <= (others => 'Z');
                QB <= reg;
            when "11" =>
                QA <= (others => 'Z');
                QB <= (others => 'Z');
            when others => null;
        end case;
    end process OUTPUT_STATE;
end architecture Behavioral;