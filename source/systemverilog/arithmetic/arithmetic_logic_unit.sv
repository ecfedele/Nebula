module arithmetic_logic_unit #(parameter BITS = 32) (
    input  wire [BITS-1:0] reg_a, reg_b, immed,
    input  wire [6:0]      alu_code,
    input  wire [3:0]      inst_type,
    input  wire            clk, n_rst, 
    output wire [BITS-1:0] output
);

    import instruction_utilities::*;
    logic [(2*BITS)-1:0] result;

    always @ (posedge clk or n_rst)
    begin

    end

endmodule