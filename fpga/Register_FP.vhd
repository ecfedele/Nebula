library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

---------------------------------------------------------------------------------------------------
-- Module:      Register_FP                                                                      --
-- Description: Implements a single-input, triple-output state register with write-enable and    --
--              independent output control signals intended for the storage of both single- and  --
--              double-precision floating-point values (encoded per IEEE 754). The register      --
--              stores 65 bits, the lower 64 of which comprise the data value storage with the   --
--              uppermost bit signaling single (0) or double (1) precision.                      --
--                                                                                               --
--              The output data buses are widened to 65-bit; the uppermost bit corresponds to    --
--              the S/D bit described above. The type-match detection logic is thus moved out of --
--              the individual register units and into the master FPU register file entity. This --
--              avoids undue complications with parallelization of the buses.                    --
--                                                                                               --
-- Inputs:      data_in                (STD_LOGIC_VECTOR) Main data input (64-bit wide)          --
--              clk                    (STD_LOGIC)        Clock signal input                     --
--              n_rst                  (STD_LOGIC)        Asynchronous reset signal (active LOW) --
--              n_wr                   (STD_LOGIC)        Write-enable signal (active LOW)       --
--              fpu_sd                 (STD_LOGIC)        Single vs. double mode switch          --
--              n_oea, n_oeb, n_oec    (STD_LOGIC)        Output-enable signals (active LOW)     --
-- Outputs:     dout_a, dout_b, dout_c (STD_LOGIC_VECTOR) Output buses (65-bit wide)             --
---------------------------------------------------------------------------------------------------
entity Register_FP is
    port(
        data_in                  : in  STD_LOGIC_VECTOR(63 downto 0);
        clk, n_rst, n_wr, fpu_sd : in  STD_LOGIC;
        n_oea, n_oeb, n_oec      : in  STD_LOGIC;
        dout_a, dout_b, dout_c   : out STD_LOGIC_VECTOR(64 downto 0)
    );
end entity Register_FP;

architecture RTL of Register_FP is
    signal FP_State : STD_LOGIC_VECTOR(64 downto 0);
begin
    -- Use a first process to keep the internal state up-to-date.
    --     1. An asynchronous reset (n_rst active LOW) reverts the register state to zero.
    --     2. A write-enable (n_wr active LOW) signal enables synchronous read of data into
    --        the register state. 
    --            - If the FPU single/double-precision mode switch (fpu_sd) is deasserted, the 
    --              value presented over data_in is assumed to be 32-bit; the upper 32 bits of the 
    --              register are zeroed and the 64th bit is set equal to fpu_sd
    --            - If the fpu_sd switch is '1' (i.e. double/64-bit), the entire data_in value is
    --              copied to the register, with a '1' in the S/D (64) bit 
    STATE_PROC: process(clk, n_rst)
    begin
        if n_rst = '0' then
            FP_State      <= (others => '0');
        elsif rising_edge(clk) and n_wr = '0' then
            if fpu_sd = '0' then
                FP_State <= "000000000000000000000000000000000" & data_in;
            else
                FP_State <= "1" & data_in;
            end if;
        end if;
    end process STATE_PROC;

    -- Use a second output process to control the output bus condition.
    -- For each of the three output ports, if the respective output-enable signal (n_oeX, 
    -- active LOW) is asserted, write the contents of the register onto the bus. Otherwise, 
    -- maintain the buses in tri-state/high-Z configuration.
    OUTPUT_PROC: process(FP_State, fpu_sd, n_oea, n_oeb, n_oec)
    begin
        dout_a <= FP_State when n_oea = '0' else (others => 'Z');
        dout_b <= FP_State when n_oeb = '0' else (others => 'Z');
        dout_c <= FP_State when n_oec = '0' else (others => 'Z');
    end process OUTPUT_PROC;
end architecture RTL;