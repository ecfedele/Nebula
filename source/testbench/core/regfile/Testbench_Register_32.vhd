---------------------------------------------------------------------------------------------------
-- Title          : Testbench for 32-bit Dual-Port Tristate Register                             --
-- Project        : Nebula RV32 Core                                                             --
-- Filename       : Testbench_Register_32.vhd                                                    --
-- Description    : Configures a testbench to test the functionality of the Register_32 module.  --
--                                                                                               --
-- Main Author    : Elijah Creed Fedele                                                          --
-- Creation Date  : May 24, 2023 13:23                                                           --
-- Last Revision  : May 25, 2023 17:04                                                           --
-- Version        : N/A                                                                          --
-- License        : CERN-OHL-S-2.0 (CERN OHL, v2.0, Strongly Reciprocal)                         --
-- Copyright      : (C) 2023 Elijah Creed Fedele & Connor Clarke                                 --
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
use 	IEEE.NUMERIC_STD.ALL;

-- FOR SIMULATION USE ONLY! --
use     IEEE.MATH_REAL.ALL;
------------------------------

entity Testbench_Register_32 is
end entity Testbench_Register_32;

architecture Behavioral of Testbench_Register_32 is

	-- Signals for the test harness (Register_32). Note that they are given proper names,
	-- rather than the terse, datasheet-like constructions found in the Register_32 port names.
	-------------------------------------------------------------------------------------------
	signal data_in, data_out_a, data_out_b         : STD_LOGIC_VECTOR(31 downto 0);
	signal clock, n_set, n_reset, loop_ready       : STD_LOGIC; 
	signal n_write_sel, n_read_sel_a, n_read_sel_b : STD_LOGIC;
	
	-- Register_32 component
	-- Create a new declaration for the Register_32 component which will
	-- be instantiated below.
	--------------------------------------------------------------------
	component Register_32 port(
		D               : in  STD_LOGIC_VECTOR(31 downto 0);
		CLK, nSET, nRST : in  STD_LOGIC;
		nWR, nOEA, nOEB : in  STD_LOGIC;
		QA, QB          : out STD_LOGIC_VECTOR(31 downto 0)
	);
	end component Register_32;
	
begin

	-- Create a Register_32 instance and map the testbench signals to it
	--------------------------------------------------------------------
	DUT: Register_32 port map (
		D    => data_in,
		CLK  => clock,
		nSET => n_set,
		nRST => n_reset,
		nWR  => n_write_sel,
		nOEA => n_read_sel_a,
		nOEB => n_read_sel_b,
		QA   => data_out_a,
		QB   => data_out_b
	);

	-- 1. Put a random 32-bit quantity on the data_in bus
	-- 2. Generate a clock signal using clock_generate() 
	-- 3. Configure all lines in the appropriate initial states
	--------------------------------------------------------------------------
	TEST: process
	begin
		data_in      <= x"DEADBEEF";
		clock        <= '0';
		n_set        <= '1';
		n_reset      <= '1';
		n_write_sel  <= '1';
		n_read_sel_a <= '1';
		n_read_sel_b <= '1';
		loop_ready   <= '1';
		wait for 50 ns;

		clock <= '1';
		n_reset <= '0';
		wait for 50 ns;
		clock <= '0';
		wait for 50 ns;
		n_reset <= '1';

		clock <= '1';
		n_write_sel <= '0';
		wait for 50 ns;
		clock <= '0';
		wait for 50 ns;
		n_write_sel <= '1';

		clock <= '1';
		n_read_sel_a <= '0';
		wait for 50 ns;
		clock <= '0';
		wait for 50 ns;

		clock <= '1';
		n_read_sel_b <= '0';
		wait for 50 ns;
		clock <= '0';
		wait for 50 ns;

		clock <= '1';
		n_set <= '0';
		wait for 50 ns;
		clock <= '0';
		wait for 50 ns;
		n_set <= '0';

		clock <= '1';
		n_write_sel <= '0';
		wait for 50 ns;
		clock <= '0';
		wait for 50 ns;
		n_write_sel <= '1';

		clock <= '1';
		wait for 50 ns;
		clock <= '0';
		wait for 50 ns;
		
		wait;
	end process TEST;
	
end architecture Behavioral;
