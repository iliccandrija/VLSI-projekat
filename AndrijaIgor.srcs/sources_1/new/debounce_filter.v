module debounce_filter (
    input wire clk,
    input wire taster_sirovi,
    output reg taster_stabilan = 0
);

    reg [21:0] brojac = 0;
    reg taster_prethodni = 0;

    always @(posedge clk) begin
        taster_prethodni <= taster_sirovi;

        if (taster_sirovi != taster_prethodni) begin
            brojac <= 0;
        end 
        else if (brojac < 22'd2500000) begin
            brojac <= brojac + 1;
        end 
        else begin
            taster_stabilan <= taster_prethodni;
        end
    end
endmodule