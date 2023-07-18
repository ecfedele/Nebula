---------------------------------------------------------------------------------------------------
-- Title          : Arithmetic Logic unit, 32-bit Integer for RV32G                              --
-- Project        : Nebula RV32 Core                                                             --
-- Filename       : Alu_32.vhd                                                                      --
-- Description    : Implements the main ALU.                                                     --
--                                                                                               --
-- Main Author    : Connor Clarke                                                                --
-- Creation Date  : July 18, 2023 16:47                                                          --
-- Last Revision  : July 18, 2023 16:47                                                          --
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
-- Module:      Alu_32                                                                              --
-- Description: Implements an ALU tailored to the RISC-V specification.                          --
--                                                                                               --
--                                                                                               --
-- Parameters:  REG_WIDTH          (INTEGER)   Configures the register's data width              --
-- Inputs:      input_a, input_b   (REG_WIDTH) Inputs to perform operation on.		         --
--              clk                (1)         Clock signal input                                --
--              n_rst              (1)         Asynchronous reset signal (active LOW)            --
--              alu_in             (1)	       Indicates an integer arithmetic (ALU) instruction --    
--              ALUOp              (7)         Opp code of the operation to be performed         --
--                                                                                               --
-- Outputs:     dout_regwr	   (1)	       Write results to register (active LOW) 		 --							 --
-- 		dout_result        (REG_WIDTH) Result of Arithmetic instruction              	 --
---------------------------------------------------------------------------------------------------
entity Alu_32 is 
    generic(REG_WIDTH : INTEGER := 32);
    port(
        input_a, input_b            : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        clk, n_rst, din_regwr	    : in  STD_LOGIC;
        ALUOp			    : in  STD_LOGIC_VECTOR(6 downto 0);
        dout_regwr		    : out STD_LOGIC;
        dout_result            	    : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end entity Alu_32;

architecture ALU of ALU_32 is

	signal ALU_TMP_Result : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);

begin
    process(input_a,input_b,ALUOp)
	begin
		case(ALUOp) is
			when "0000000" => --Addition
     				ALU_TMP_RESULT(DATA_WIDTH-1 downto 0) <= signed(input_a) + signed(input_b);
     			when "0100000" => -- Sub
				ALU_TMP_RESULT <= signed(input_a) - signed(input_b);
			when others => null;
		end case;
	end process;
	dout_result <= ALU_TMP_RESULT;
	dout_regwr <= din_regwr;
end architecture ALU;
