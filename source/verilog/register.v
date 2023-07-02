// ---------------------------------------------------------------------------------------------- //
// Title          : Register, Configurable-Width, Three-Output with Tristates                     //
// Project        : Nebula RV32 Core                                                              //
// Filename       : register.v                                                                    //
// Description    : Implements a basic configurable-width, single-write, triple-read storage      //
//                  register with three tri-stating ('Z') outputs to support parallel bus         //
//                  implementations. The width is parameterized and nominally 32-bit.             //
//                                                                                                //
// Main Author    : Elijah Creed Fedele                                                           //
// Creation Date  : July 2, 2023 01:24                                                            //
// Last Revision  : July 2, 2023 07:21                                                           //
// Version        : N/A                                                                           //
// License        : CERN-OHL-S-2.0 (CERN OHL, v2.0, Strongly Reciprocal)                          //
// Copyright      : (C) 2023 Elijah Creed Fedele & Connor Clarke                                  //
//                                                                                                //
// Library        : N/A                                                                           //
// Dependencies   : N/A                                                                           //
// Initialization : N/A                                                                           //
// Notes          : Synthesizable; can be simulated using standard Verilog simulators such as     //
//                  Questa, ModelSim, or Icarus Verilog.                                          //
// ---------------------------------------------------------------------------------------------- //

// ---------------------------------------------------------------------------------------------- //
// Module:      register                                                                          //
// Description: Implements a single-input, triple-output data register with write-enable and      //
//              fully-independent output-control signals. When not selected, emits tri-state (Z)  //
//              signals for compatibility with parallel bus implementations.                      //
//                                                                                                //
// Inputs:      din                 (WIDTH)     Main data input bus (WIDTH wide)                  //
//              clk                 (1)         Register clock signal input                       //
//              n_rst               (1)         Asynchronous reset signal (active LOW)            //
//              n_wr                (1)         Write-enable signal (active LOW)                  //
//              n_oea, n_oeb, n_oec (1)         Output-enable signal (active LOW, channels A/B/C) //
// Outputs:     out_a, out_b, out_c (WIDTH)     Output buses (WIDTH wide)                         //
// ---------------------------------------------------------------------------------------------- //
module register #(parameter WIDTH = 32) (
    input wire [WIDTH-1:0] din,
    input wire             clk, n_rst, n_wr, n_oea, n_oeb, n_oec,
    output reg [WIDTH-1:0] out_a, out_b, out_c
);

    reg [WIDTH-1:0] data;

    // Asynchronous reset. If asserted active LOW, reset the internal register state
    // to zero.
    always @(n_rst) begin
        if (n_rst == 1'b0)
            data <= {WIDTH{1'b0}};
    end

    // Clocked register load. If a positive clock edge occurs and the 'n_wr' signal is asserted
    // active LOW, load the register with the data presented on 'din'.
    always @(posedge clk) begin
        if (n_wr == 1'b0)
            data <= din;
    end

    // Output state control. If the respective output-enable signal (n_oeX) is asserted active LOW,
    // drive the contents of the data register onto the output bus. Otherwise, maintain the buses 
    // in a tri-state/high-Z condition.
    always @(data, n_oea, n_oeb, n_oec) begin
       out_a <= (n_oea == 1'b0) ? data : {WIDTH{1'bZ}}; 
       out_b <= (n_oeb == 1'b0) ? data : {WIDTH{1'bZ}}; 
       out_c <= (n_oec == 1'b0) ? data : {WIDTH{1'bZ}}; 
    end

endmodule