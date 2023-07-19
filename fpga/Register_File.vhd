---------------------------------------------------------------------------------------------------
-- Title          : Register File, 32-way, 32-bit Integer for RV32G                              --
-- Project        : Nebula RV32 Core                                                             --
-- Filename       : Register_File.vhd                                                            --
-- Description    : Implements the main RV32G integer register file.                             --
--                                                                                               --
-- Main Author    : Elijah Creed Fedele                                                          --
-- Creation Date  : July 18, 2023 14:36                                                          --
-- Last Revision  : July 18, 2023 14:37                                                          --
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
-- Module:      Register_File                                                                    --
-- Description: Implements a 32-way, configurable-width register file tailored to the RISC-V     --
--              specification.                                                                   --
--                                                                                               --
-- Parameters:  REG_WIDTH          (INTEGER)   Configures the register's data width              --
-- Inputs:      data_in            (REG_WIDTH) Main data input (REG_WIDTH-bit wide)              --
--              clk                (1)         Clock signal input                                --
--              n_rst              (1)         Asynchronous reset signal (active LOW)            --
--              n_wr               (1)         Write-enable signal (active LOW)                  --
--              n_rd               (1)         Read-enable signal (active LOW)                   --
--              raddr_d            (5)         Destination register address                      --
--              raddr_s1, raddr_s2 (5)         Source register addresses                         --
--                                                                                               --
-- Outputs:     dout_s1, dout_s2   (REG_WIDTH) Output buses (REG_WIDTH-bit wide)                 --
---------------------------------------------------------------------------------------------------
entity Register_File is 
    generic(REG_WIDTH : INTEGER := 32);
    port(
        data_in                     : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        clk, n_rst, n_wr, n_rd      : in  STD_LOGIC;
        raddr_d, raddr_s1, raddr_s2 : in  STD_LOGIC_VECTOR(4 downto 0);
        dout_s1, dout_s2            : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end entity Register_File;

architecture RTL of Register_File is 

    --- Construct three internal buses for the decoder outputs
    signal dec_d, dec_s1, dec_s2 : STD_LOGIC_VECTOR(31 downto 0);

    -- Declare the Register_2P register object. The generic REG_WIDTH parameter will be configured
    -- within a generic map during instantiation.
    component Register_2P
        generic(REG_WIDTH : INTEGER);
        port(
            data_in          : in  STD_LOGIC_VECTOR(REG_WIDTH-1 downto 0);
            clk, n_rst, n_wr : in  STD_LOGIC;
            n_oea, n_oeb     : in  STD_LOGIC;
            dout_a, dout_b   : out STD_LOGIC_VECTOR(REG_WIDTH-1 downto 0)
        );
    end component Register_2P;

    -- Declare the Register_Decoder object.
    component Register_Decoder
        port(
            addr    : in  STD_LOGIC_VECTOR( 4 downto 0);
            n_en    : in  STD_LOGIC;
            reg_sel : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component Register_Decoder;

begin
    -- Map the three register address decoders. These connect to the register address input signals
    -- as well as the n_wr and n_rd control signals exposed on the top-level Register_File entity.
    -- They output to one of three 32-bit buses which provide the write-enable and output-enable 
    -- signals to the parallel register block.
    DEST_DECODER: Register_Decoder port map (
        addr    => raddr_d,
        n_en    => n_wr,
        reg_sel => dec_d
    );

    SRC1_DECODER: Register_Decoder port map (
        addr    => raddr_s1,
        n_en    => n_rd,
        reg_sel => dec_s1
    );

    SRC2_DECODER: Register_Decoder port map (
        addr    => raddr_s2,
        n_en    => n_rd,
        reg_sel => dec_s2
    );

    -- Use a generate loop to port map the registers. The first case (I = 0, register %x0) is a
    -- special case; it is hardwired to zero similarly to MIPS. This is accomplished by tying its
    -- reset line (n_rst) permanently low. For all others, the register line n_rst signal is 
    -- connected to the entity top-level reset signal.
    GENERATE_REGS: for I in 0 to 31 generate
        RZERO: if I = 0 generate
            ZERO_LINE: Register_2P generic map (REG_WIDTH => REG_WIDTH) port map (
                data_in => data_in,
                clk     => clk,
                n_rst   => '0',
                n_wr    => dec_d(I),
                r_oea   => dec_s1(I),
                n_oeb   => dec_s2(I),
                dout_a  => dout_s1,
                dout_b  => dout_s2
            );
        end generate RZERO;
        OTHER: if I /= 0 generate
            REG_LINE: Register_2P generic map (REG_WIDTH => REG_WIDTH) port map (
                data_in => data_in,
                clk     => clk,
                n_rst   => n_rst,
                n_wr    => dec_d(I),
                r_oea   => dec_s1(I),
                n_oeb   => dec_s2(I),
                dout_a  => dout_s1,
                dout_b  => dout_s2
            );
        end generate OTHER;
    end generate GENERATE_REGS;
end architecture RTL;