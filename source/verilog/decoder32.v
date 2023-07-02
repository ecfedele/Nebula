// ---------------------------------------------------------------------------------------------- //
// Title          : Decoder, 5-to-32, Configurable-Active with Enable                             //
// Project        : Nebula RV32 Core                                                              //
// Filename       : decoder32.v                                                                   // 
// Description    : Implements a 5-to-32 decoder with configurable active state drive and output  //
//                  enable. If the 'act' input is asserted HIGH, the decoder unit will generate   //
//                  a positive-sense output. If driven LOW, the output is negative-sense.         //
//                                                                                                //
// Main Author    : Elijah Creed Fedele                                                           //
// Creation Date  : July 2, 2023 01:24                                                            //
// Last Revision  : July 2, 2023 07:22                                                            //
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
// Module:      decoder32                                                                         //
// Description: Implements a 5-to-32 decoder with configurable active state drive and output      //
//              enable.                                                                           //
//                                                                                                //
// Inputs:      sel     (5)     Encoded select signal                                             //
//              n_en    (1)     Output-enable signal (active LOW)                                 //
//              act     (1)     Active drive signal (positive output if HIGH, else negative)      //
// Outputs:     dec     (32)    Decoded output (active HIGH if act = 1'b1, else active LOW)       //
// ---------------------------------------------------------------------------------------------- //
module decoder32 (input wire [4:0] sel, input wire n_en, input wire act, output reg [31:0] dec);
    always @(*) begin
        if (n_en == 1'b0) begin
            case (sel)
                5'h00:   dec <= (act == 1'b1) ? 32'h00000001 : 32'hFFFFFFFE;
                5'h01:   dec <= (act == 1'b1) ? 32'h00000002 : 32'hFFFFFFFD;
                5'h02:   dec <= (act == 1'b1) ? 32'h00000004 : 32'hFFFFFFFB;
                5'h03:   dec <= (act == 1'b1) ? 32'h00000008 : 32'hFFFFFFF7;
                5'h04:   dec <= (act == 1'b1) ? 32'h00000010 : 32'hFFFFFFEF;
                5'h05:   dec <= (act == 1'b1) ? 32'h00000020 : 32'hFFFFFFDF;
                5'h06:   dec <= (act == 1'b1) ? 32'h00000040 : 32'hFFFFFFBF;
                5'h07:   dec <= (act == 1'b1) ? 32'h00000080 : 32'hFFFFFF7F;
                5'h08:   dec <= (act == 1'b1) ? 32'h00000100 : 32'hFFFFFEFF;
                5'h09:   dec <= (act == 1'b1) ? 32'h00000200 : 32'hFFFFFDFF;
                5'h0A:   dec <= (act == 1'b1) ? 32'h00000400 : 32'hFFFFFBFF;
                5'h0B:   dec <= (act == 1'b1) ? 32'h00000800 : 32'hFFFFF7FF;
                5'h0C:   dec <= (act == 1'b1) ? 32'h00001000 : 32'hFFFFEFFF;
                5'h0D:   dec <= (act == 1'b1) ? 32'h00002000 : 32'hFFFFDFFF;
                5'h0E:   dec <= (act == 1'b1) ? 32'h00004000 : 32'hFFFFBFFF;
                5'h0F:   dec <= (act == 1'b1) ? 32'h00008000 : 32'hFFFF7FFF;
                5'h10:   dec <= (act == 1'b1) ? 32'h00010000 : 32'hFFFEFFFF;
                5'h11:   dec <= (act == 1'b1) ? 32'h00020000 : 32'hFFFDFFFF;
                5'h12:   dec <= (act == 1'b1) ? 32'h00040000 : 32'hFFFBFFFF;
                5'h13:   dec <= (act == 1'b1) ? 32'h00080000 : 32'hFFF7FFFF;
                5'h14:   dec <= (act == 1'b1) ? 32'h00100000 : 32'hFFEFFFFF;
                5'h15:   dec <= (act == 1'b1) ? 32'h00200000 : 32'hFFDFFFFF;
                5'h16:   dec <= (act == 1'b1) ? 32'h00400000 : 32'hFFBFFFFF;
                5'h17:   dec <= (act == 1'b1) ? 32'h00800000 : 32'hFF7FFFFF;
                5'h18:   dec <= (act == 1'b1) ? 32'h01000000 : 32'hFEFFFFFF;
                5'h19:   dec <= (act == 1'b1) ? 32'h02000000 : 32'hFDFFFFFF;
                5'h1A:   dec <= (act == 1'b1) ? 32'h04000000 : 32'hFBFFFFFF;
                5'h1B:   dec <= (act == 1'b1) ? 32'h08000000 : 32'hF7FFFFFF;
                5'h1C:   dec <= (act == 1'b1) ? 32'h10000000 : 32'hEFFFFFFF;
                5'h1D:   dec <= (act == 1'b1) ? 32'h20000000 : 32'hDFFFFFFF;
                5'h1E:   dec <= (act == 1'b1) ? 32'h40000000 : 32'hBFFFFFFF;
                5'h1F:   dec <= (act == 1'b1) ? 32'h80000000 : 32'h7FFFFFFF;
                default: dec <= (act == 1'b1) ? 32'h00000000 : 32'hFFFFFFFF;
            end
        end else begin
            dec <= (act == 1'b1) ? 32'h00000000 : 32'hFFFFFFFF;
        end
    end
endmodule 