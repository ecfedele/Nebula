---------------------------------------------------------------------------------------------------
-- Title          : Register, Configurable-Width, Three-Output with Tristates                    --
-- Project        : Nebula RV32 Core                                                             --
-- Filename       : Register_3P.vhd                                                              --
-- Description    : Implements a parameterized, configurable-width state register with three     --
--                  independently-controlled tristate output ports.                              --
--                                                                                               --
-- Main Author    : Elijah Creed Fedele                                                          --
-- Creation Date  : July 17, 2023 22:22                                                          --
-- Last Revision  : July 17, 2023 22:22                                                          --
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
-- Module:      Register_3P                                                                      --
-- Description: Implements a single-input, triple-output state register with write-enable and    --
--              independent output control signals. Employs tri-state ('Z') signaling on the     --
--              output ports for compatibility with parallel bus implementations.                --
--                                                                                               --
-- Parameters:  REG_WIDTH              (INTEGER)          Configures the register's data width   --
-- Inputs:      data_in                (STD_LOGIC_VECTOR) Main data input (REG_WIDTH-bit wide)   --
--              clk                    (STD_LOGIC)        Clock signal input                     --
--              n_rst                  (STD_LOGIC)        Asynchronous reset signal (active LOW) --
--              n_wr                   (STD_LOGIC)        Write-enable signal (active LOW)       --
--              n_oea, n_oeb, n_oec    (STD_LOGIC)        Output-enable signals (active LOW)     --
-- Outputs:     dout_a, dout_b, dout_c (STD_LOGIC_VECTOR) Output buses (REG_WIDTH-bit wide)      --
---------------------------------------------------------------------------------------------------
entity Register_3P is
    generic(REG_WIDTH : INTEGER := 32);
    port(
        data_in                : in  STD_LOGIC_VECTOR(REG_WIDTH-1 downto 0);
        clk, n_rst, n_we       : in  STD_LOGIC;
        n_oea, n_oeb, n_oec    : in  STD_LOGIC;
        dout_a, dout_b, dout_c : out STD_LOGIC_VECTOR(REG_WIDTH-1 downto 0)
    );
end entity Register_3P;

architecture RTL of Register_3P is
    signal State : STD_LOGIC_VECTOR(REG_WIDTH-1 downto 0);
begin
    -- Use a first process to keep the internal state up-to-date.
    --     1. An asynchronous reset (n_rst active LOW) reverts the register state to zero.
    --     2. A write-enable (n_we active LOW) signal enables synchronous read of data into
    --        the register state.
    CLOCK_PROC: process(clk, n_rst)
    begin
        if n_rst = '0' then
            State <= (others => '0');
        elsif rising_edge(clk) and n_we = '0' then
            State <= data_in;
        end if;
    end process CLOCK_PROC;
    
    -- Use a second output process to control the output bus condition.
    -- For each of the three output ports, if the respective output-enable signal (n_oeX, 
    -- active LOW) is asserted, write the contents of the register onto the bus. Otherwise, 
    -- maintain the buses in tri-state/high-Z configuration.
    OUTPUTS: process(State, n_oea, n_oeb, n_oec)
    begin
        -- See OUTPUTS process in Register_2P for more information.
        -- This may be found beginning with commit e60bcdf.
        if n_oea = '0' then
            dout_a <= State;
        else 
            dout_a <= (others => 'Z');
        end if;

        if n_oeb = '0' then
            dout_b <= State;
        else 
            dout_b <= (others => 'Z');
        end if;

        if n_oec = '0' then
            dout_c <= State;
        else 
            dout_c <= (others => 'Z');
        end if;
    end process OUTPUTS;
end architecture RTL;