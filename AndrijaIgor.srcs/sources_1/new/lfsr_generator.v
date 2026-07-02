module lfsr_generator (
    input wire clk,
    input wire aktivno,
    output reg [7:0] lfsr_reg = 8'h01
);

    always @(posedge clk) begin
        if (aktivno) begin
            lfsr_reg <= { (lfsr_reg[0] ^~ lfsr_reg[2] ^~ lfsr_reg[3] ^~ lfsr_reg[4]), lfsr_reg[7:1] };
        end
    end
endmodule