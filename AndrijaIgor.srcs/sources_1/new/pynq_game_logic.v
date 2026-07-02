module pynq_game_logic (
    input wire clk,
    input wire [2:0] btn_user,       
    input wire btn_roll,             
    input wire [7:0] lfsr_rand,      
    output reg [3:0] led,
    output reg lfsr_aktivno,        
    output reg [31:0] axi_user_num,
    output reg [31:0] axi_rolled_num,
    output reg [31:0] axi_result
);


    reg [23:0] clk_div = 0;
    always @(posedge clk) clk_div <= clk_div + 1;


    reg [27:0] reset_timer = 0;

    reg [2:0] user_num = 3'b000;
    reg [2:0] rolled_num = 3'b000;
    reg last_btn_roll = 0;
    reg game_over = 0;
    reg win = 0;


    always @(posedge clk) begin
        if (!btn_roll && !game_over) begin
            if (btn_user[0]) user_num[0] <= ~user_num[0];
            if (btn_user[1]) user_num[1] <= ~user_num[1];
            if (btn_user[2]) user_num[2] <= ~user_num[2];
        end else if (game_over && (reset_timer >= 28'd250000000)) begin
            user_num <= 3'b000;
        end
    end

    always @(posedge clk) begin
        last_btn_roll <= btn_roll;

        if (btn_roll) begin
            lfsr_aktivno <= 1;
            game_over <= 0;
            reset_timer <= 0;
        end
        else if (last_btn_roll && !btn_roll) begin
            lfsr_aktivno <= 0; 
            rolled_num <= lfsr_rand[2:0]; 
            game_over <= 1;
        end
        
        if (game_over) begin
            if (reset_timer < 28'd250000000) begin
                reset_timer <= reset_timer + 1;
            end else begin
                game_over <= 0;
                reset_timer <= 0;
            end
        end
    end

    always @(*) begin
        if (game_over && (rolled_num == user_num)) win = 1;
        else win = 0;
    end

    always @(*) begin
        if (btn_roll) begin
            led = clk_div[22] ? 4'b1010 : 4'b0101;
        end else if (game_over) begin
            if (win) begin
                led = clk_div[21] ? 4'b1111 : 4'b0000;
            end else begin
                led = clk_div[22] ? 4'b1001 : 4'b0110;
            end
        end else begin
            led = {1'b0, user_num};
        end
    end

    always @(posedge clk) begin
        axi_user_num   <= {29'b0, user_num};
        axi_rolled_num <= {29'b0, rolled_num};
        if (!game_over) 
            axi_result <= 32'd0;
        else 
            axi_result <= win ? 32'd1 : 32'd2;
    end

endmodule