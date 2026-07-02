module top_module (
    input wire clk,           
    input wire [3:0] btn,    
    output wire [3:0] led,    
    // AXI interfejs ka GPIO IP koru
    output wire [31:0] axi_user_num,
    output wire [31:0] axi_rolled_num,
    output wire [31:0] axi_result
);

    wire [2:0] btn_user_stable;
    wire btn_roll_stable;
    
    wire lfsr_aktivno;
    wire [7:0] lfsr_rand_out;

    debounce_filter db_btn0 (.clk(clk), .taster_sirovi(btn[0]), .taster_stabilan(btn_user_stable[0]));
    debounce_filter db_btn1 (.clk(clk), .taster_sirovi(btn[1]), .taster_stabilan(btn_user_stable[1]));
    debounce_filter db_btn2 (.clk(clk), .taster_sirovi(btn[2]), .taster_stabilan(btn_user_stable[2]));
    debounce_filter db_btn3 (.clk(clk), .taster_sirovi(btn[3]), .taster_stabilan(btn_roll_stable));

    lfsr_generator lfsr_inst (
        .clk(clk),
        .aktivno(lfsr_aktivno),
        .lfsr_reg(lfsr_rand_out)
    );

    pynq_game_logic game_inst (
        .clk(clk),
        .btn_user(btn_user_stable),
        .btn_roll(btn_roll_stable),
        .lfsr_rand(lfsr_rand_out),
        .led(led),
        .lfsr_aktivno(lfsr_aktivno),
        .axi_user_num(axi_user_num),
        .axi_rolled_num(axi_rolled_num),
        .axi_result(axi_result)
    );

endmodule