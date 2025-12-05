`timescale 1ns / 1ps

module button_debounce(
    input clk, rst,i_btn,
    output o_btn
    
    );
    
    reg edge_reg;
    reg [3:0] q_reg, q_next;
    wire debounce;
    reg clk_reg;
    reg [$clog2(100)-1 : 0] cnt_reg;



/////////////////////////clk_reg_gen////////////////////
    always @(posedge clk, posedge rst) begin
        if(rst)begin
            cnt_reg <= 0;
            clk_reg <= 0;
        end
        else begin
            if(cnt_reg ==  99)begin
                cnt_reg <= 0;
                clk_reg <= 1;
            end else begin
                cnt_reg <= cnt_reg + 1;
                clk_reg <= 0;
            end
        end
    end

////////////////shift -register///////////////////////
    always @(posedge clk_reg, posedge rst) begin
        if(rst)begin
            q_reg <= 0;
        end
        else begin
            q_reg <= q_next;
        end
    end

    always @(*) begin
        q_next = {i_btn, q_reg[3:1]};
    end
    assign debounce = &q_next;

//////////////edge////////////////////////////////
    always@(posedge clk, posedge rst)begin
        if(rst)begin
            edge_reg <= 0;
        end
            else begin
                edge_reg <= debounce;
            end
    end

    assign o_btn = ~edge_reg & debounce;

endmodule