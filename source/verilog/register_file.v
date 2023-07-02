// ---------------------------------------------------------------------------------------------- //
// Title          : Register File, 32-Way, Configurable-Width with Triple Outputs                 //
// Project        : Nebula RV32 Core                                                              //
// Filename       : register_file.v                                                               // 
// Description    : Implements a 32-way configurable-width register file. Contains signals to     //
//                  support dyadic, triadic, and tetradic operations (supporting the entirety of  //
//                  the RV32G/RV64G instruction set). The first register (%x0) is locked to zero. //
//                                                                                                //
// Main Author    : Elijah Creed Fedele                                                           //
// Creation Date  : July 2, 2023 02:07                                                            //
// Last Revision  : July 2, 2023 07:23                                                            //
// Version        : N/A                                                                           //
// License        : CERN-OHL-S-2.0 (CERN OHL, v2.0, Strongly Reciprocal)                          //
// Copyright      : (C) 2023 Elijah Creed Fedele & Connor Clarke                                  //
//                                                                                                //
// Library        : N/A                                                                           //
// Dependencies   : register, decoder32                                                           //
// Initialization : N/A                                                                           //
// Notes          : Synthesizable; can be simulated using standard Verilog simulators such as     //
//                  Questa, ModelSim, or Icarus Verilog.                                          //
// ---------------------------------------------------------------------------------------------- //

// ---------------------------------------------------------------------------------------------- //
// Module:      register_file                                                                     //
// Description: Implements a 32-way, single-input, triple-output data register file for the       //
//              Nebula RV32G core. Contains signals to support dyadic, triadic, and tetradic      //
//              operations. The first register (%x0) is hardwired to zero in accordance with the  //
//              RISC-V specification.                                                             //
//                                                                                                //
// Inputs:      din                 (WIDTH)     Main data input bus (WIDTH wide)                  //
//              clk                 (1)         Register clock signal input                       //
//              n_rst               (1)         Asynchronous reset signal (active LOW)            //
//              n_wr                (1)         Write-enable signal (active LOW). This signal is  //
//                                              ORed with the decoder signals to designate the    //
//                                              correct read-write phasing of the operation.      //
//              n_op3               (1)         Tetradic (3 source register) operation signal.    //
//                                              This signal makes the C output bus active by      //
//                                              enabling the respective register address decoder. //
//              sel_a, sel_b, sel_c (5)         Source register selection addresses. These are    //
//                                              decoded internally to select the registers to     //
//                                              output over the A, B, and C buses.                //
// Outputs:     out_a, out_b, out_c (WIDTH)     Output buses (WIDTH wide)                         //
// ---------------------------------------------------------------------------------------------- //
module register_file #(parameter WIDTH = 32) (
    input  wire [WIDTH-1:0] data_in,
    input  wire [4:0]       sel_a, sel_b, sel_c, sel_in,
    input  wire             clk, n_rst, n_wr, n_op3,
    output wire [WIDTH-1:0] out_a, out_b, out_c
);

    wire [31:0] dec_a, dec_b, dec_c, dec_in;
    decoder32 da ( .sel(sel_a),  .n_en(1'b0),  .act(1'b0), .dec(dec_a)  );
    decoder32 db ( .sel(sel_b),  .n_en(1'b0),  .act(1'b0), .dec(dec_b)  );
    decoder32 dc ( .sel(sel_c),  .n_en(n_op3), .act(1'b0), .dec(dec_c)  );
    decoder32 di ( .sel(sel_in), .n_en(1'b0),  .act(1'b0), .dec(dec_in) );

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin: GENERATE_REGISTERS
            // Handle the special case that the first register, %x0, must be hardwired to zero
            // (similarly to many other RISC processor designs). This is accomplished by hardwiring
            // the active-LOW reset to ground, forcing it to assume a value of zero at all times.
            if (i == 0) begin
                register #(WIDTH = WIDTH) r (
                    .din(data_in),
                    .clk(clk),
                    .n_rst(1'b0),
                    .n_wr(dec_in[i] |  n_wr),
                    .n_oea(dec_a[i] | ~n_wr),
                    .n_oeb(dec_b[i] | ~n_wr),
                    .n_oec(dec_c[i] | ~n_wr),
                    .out_a(out_a),
                    .out_b(out_b),
                    .out_c(out_c)
                );
            // For all other registers (%x1 through %x31), link the register line reset signals to
            // the register file master reset
            end else begin
                register #(WIDTH = WIDTH) r (
                    .din(data_in),
                    .clk(clk),
                    .n_rst(n_rst),
                    .n_wr(dec_in[i] |  n_wr),
                    .n_oea(dec_a[i] | ~n_wr),
                    .n_oeb(dec_b[i] | ~n_wr),
                    .n_oec(dec_c[i] | ~n_wr),
                    .out_a(out_a),
                    .out_b(out_b),
                    .out_c(out_c)
                );
            end
        end
    endgenerate

endmodule