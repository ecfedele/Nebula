---------------------------------------------------------------------------------------------------
-- Title          : Arithmetic Logic unit, 32-bit Integer for RV32G                              --
-- Project        : Nebula RV32 Core                                                             --
-- Filename       : Alu_32.vhd                                                                   --
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
-- Module:      Alu_32                                                                           --
-- Description: Implements an ALU tailored to the RISC-V specification.                          --
--                                                                                               --
--                                                                                               --
-- Parameters:  REG_WIDTH          (INTEGER)   Configures the register's data width              --
-- Inputs:      input_a, input_b   (REG_WIDTH) Inputs to perform operation on.                   --
--              clk                (1)         Clock signal input                                --
--              n_rst              (1)         Asynchronous reset signal (active LOW)            --
--              din_regwr          (1)         Register write signal                             --
--              alu_in             (1)         Indicates an integer arithmetic (ALU) instruction --    
--              ALUOp              (7)         Opp code of the operation to be performed         --
--                                                                                               --
-- Outputs:     dout_regwr         (1)         Write results to register (active LOW)            --                             --
--              dout_result        (REG_WIDTH) Result of Arithmetic instruction                  --
---------------------------------------------------------------------------------------------------
entity Alu_32 is 
    generic(DATA_WIDTH : INTEGER := 32);
    port(
        input_a, input_b              : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        clk, n_rst, din_regwr, alu_in : in  STD_LOGIC;
        ALUOp                         : in  STD_LOGIC_VECTOR(6 downto 0);
        dout_regwr                    : out STD_LOGIC;
        dout_result                   : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end entity Alu_32;

architecture ALU of ALU_32 is

    signal ALU_TMP_Result : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
    signal MUL_Result : STD_LOGIC_VECTOR(63 downto 0);

begin
    process(clk, alu_in)
    begin
        if alu_in = '1' and rising_edge(clk) then 
            case(ALUOp) is
                when "0000000" => --ADD
                    ALU_TMP_Result <= STD_LOGIC_VECTOR(SIGNED(input_a) + SIGNED(input_b));
                when "0000001" => -- SUB
                    ALU_TMP_RESULT <= STD_LOGIC_VECTOR(SIGNED(input_a) - SIGNED(input_b));
		--when "0000010" => -- MUL
		--    MUL_Result <= STD_LOGIC_VECTOR(SIGNED(input_a) * SIGNED(input_b));
		--    ALU_TMP_RESULT <= MUL_Result(DATA_WIDTH-1 downto 0);
		--when "0000011" => -- MULH
		--when "0000100" => -- MULHU
		when "0000101" => -- DIV
		    ALU_TMP_RESULT <= STD_LOGIC_VECTOR(SIGNED(input_a) / SIGNED(input_b));
		when "0000110" => -- DIVU
		    ALU_TMP_RESULT <= STD_LOGIC_VECTOR(UNSIGNED(input_a) / UNSIGNED(input_b));
		when "0000111" => -- REM
		    ALU_TMP_RESULT <= STD_LOGIC_VECTOR(SIGNED(input_a) rem SIGNED(input_b));
		when "0001000" => -- REMU
		    ALU_TMP_RESULT <= STD_LOGIC_VECTOR(UNSIGNED(input_a) rem UNSIGNED(input_b));   
		when "0001001" => -- SLL
		    ALU_TMP_RESULT <= STD_LOGIC_VECTOR(UNSIGNED(input_a) sll to_integer(UNSIGNED(input_b)));
	        --when "0001010" => -- SLA
		    ---ALU_TMP_RESULT <= STD_LOGIC_VECTOR(UNSIGNED(input_a) sla UNSIGNED(input_b));
	        when "0001011" => -- SRL
		    ALU_TMP_RESULT <= STD_LOGIC_VECTOR(UNSIGNED(input_a) srl to_integer(UNSIGNED(input_b)));
		--when "0001100" => -- SRA
		    --ALU_TMP_RESULT <= STD_LOGIC_VECTOR(UNSIGNED(input_a) sla UNSIGNED(input_b));
	        when "0001101" => -- SLT
		    if input_a < input_b then 
		        ALU_TMP_RESULT <= (0 => '1', others => '0');
                    else
	                ALU_TMP_RESULT <= (others => '0'); 
		    end if;
		when "0001110" => -- SLTU
		    if input_a < input_b then 
		        ALU_TMP_RESULT <= (0 => '1', others => '0');
                    else
	                ALU_TMP_RESULT <= (others => '0'); 
		    end if;
		when "0001111" => -- AND
		    ALU_TMP_RESULT <= input_a and input_b;
		when "0010000" => -- OR
		    ALU_TMP_RESULT <= input_a or input_b;
		when "0010001" => -- XOR
		    ALU_TMP_RESULT <= input_a xor input_b;
                when others => null;
            end case;
        end if;
    end process;
    dout_result <= ALU_TMP_RESULT;
    dout_regwr  <= din_regwr;
end architecture ALU;
