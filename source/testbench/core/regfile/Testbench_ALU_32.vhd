---------------------------------------------------------------------------------------------------
-- Title          : Testbench for 32-bit Dual-Port Tristate Register                             --
-- Project        : Nebula RV32 Core                                                             --
-- Filename       : Testbench_ALU_32.vhd	                                                 --
-- Description    : Configures a testbench to test the functionality of the Alu_32 module.       --
--                                                                                               --
-- Main Author    : Connor Clarke	                                                         --
-- Creation Date  : July 19, 2023 20:30                                                          --
-- Last Revision  : July 19, 2023 20:30                                                          --
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

entity Testbench_ALU_32 is
end entity Testbench_ALU_32;

architecture Behavioral of Testbench_ALU_32 is

	-- Signals for the test harness (ALU_32).
	-------------------------------------------------------------------------------------------
	signal input_a, input_b, dout_result           : STD_LOGIC_VECTOR(31 downto 0);
	signal ALUOp				       : STD_LOGIC_VECTOR(6 downto 0);
	signal clk, n_rst, din_regwr, alu_in           : STD_LOGIC;
	signal dout_regwr			       : STD_LOGIC;
	
	-- Alu_32 component
	-- Create a new declaration for the Alu_32 component which will
	-- be instantiated below.
	--------------------------------------------------------------------	
	component Alu_32 port(
        	input_a, input_b              : in  STD_LOGIC_VECTOR(31 downto 0);
          	clk, n_rst, din_regwr, alu_in : in  STD_LOGIC;
          	ALUOp                         : in  STD_LOGIC_VECTOR(6 downto 0);
          	dout_regwr                    : out STD_LOGIC;
          	dout_result                   : out STD_LOGIC_VECTOR(31 downto 0)
	);
	end component Alu_32;
	
begin

	-- Create a Alu_32 instance and map the testbench signals to it
	--------------------------------------------------------------------
	DUT: Alu_32 port map (
		input_a     => input_a,
		input_b     => input_b,
		ALUOp       => ALUOp,
		clk         => clk,
		n_rst       => n_rst,
		din_regwr   => din_regwr,
		alu_in      => alu_in,
		dout_regwr  => dout_regwr,
		dout_result => dout_result
	);

	-- 1. Do an Add Operation on an example with no overflow
	-- 2. Generate a clock signal using clock_generate() 
	-- 3. Test that correct outputs are changed on clock high when alu_in is high
	-- 4. Test that reg_wr signal is correctly set
	--------------------------------------------------------------------------
	TEST: process
	begin
		input_a      <= x"00000001";
                input_b      <= x"0000000A";
		ALUOp	     <= "0000000"; --addition opperation
		clk          <= '0';
		alu_in       <= '0';
		n_rst        <= '0';
		din_regwr    <= '1';
		wait for 50 ns;

		-- Test reg_wr signal is correctly set
		clk <= '1';
		din_regwr <= '0';
		wait for 50 ns;
		clk <= '0';
		din_regwr <= '0';
		wait for 50 ns;
		clk <= '1';
		din_regwr <= '1';

		-- Test addition operation is performed when alu_in is set high and clock is high
		clk <= '0';
		alu_in <= '1';
		wait for 50 ns;
		clk <= '1';
		wait for 50 ns;
		clk <= '0';
		alu_in <= '0';

		-- Test subtraction
		wait for 50 ns;
		ALUOp <= "0000001";
	        alu_in <= '1';
		clk <= '1';

		-- Test Multiplication
		-- Currently not working
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0000010";
	        alu_in <= '1';
		clk <= '1';

		-- Test MULH
		-- Currently not implemented
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0000011";
	        alu_in <= '1';
		clk <= '1';

		-- Test MULHU
		-- Currently not implemented
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0000100";
	        alu_in <= '1';
		clk <= '1';


		-- Test Division
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0000101";
		alu_in <= '1';
		clk <= '1';

		-- Test Division Unsigned
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0000110";
	        alu_in <= '1';
		clk <= '1';

		-- Test Remainder
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0000111";
		alu_in <= '1';
		clk <= '1';

		-- Test Remainder Unsigned
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0001000";
	        alu_in <= '1';
		clk <= '1';

		-- Test SLL
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0001001";
	        alu_in <= '1';
		clk <= '1';

		-- Test SLA
		-- Currently not implemented
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0001010";
	        alu_in <= '1';
		clk <= '1';

		-- Test SRL
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0001011";
	        alu_in <= '1';
		clk <= '1';

		-- Test SRA
		-- Currently not implemented
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0001100";
	        alu_in <= '1';
		clk <= '1';

		-- Test SLT
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0001101";
	        alu_in <= '1';
		clk <= '1';
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		input_a <= x"0000000A";
                input_b <= x"00000001";
		clk <= '1';

		-- Test SLTU
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0001110";
	        alu_in <= '1';
		clk <= '1';
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		input_a <= x"00000001";
                input_b <= x"0000000A";
		clk <= '1';

		-- Test And
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0001111";
	        alu_in <= '1';
		clk <= '1';

		-- Test Or
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0010000";
	        alu_in <= '1';
		clk <= '1';

		-- Test Xor
		wait for 50 ns;
		clk <= '0';
		wait for 50 ns;
		ALUOp <= "0010001";
	        alu_in <= '1';
		clk <= '1';

		wait for 50 ns;

		--


		wait;
	end process TEST;
	
end architecture Behavioral;
