`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/08/13 14:41:42
// Design Name: 
// Module Name: uart_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_top (
    input  clk,
    input  rst,
    input  rx,         // UART 입력
    output tx,         // UART 출력

    input  [2:0] sw,   // 보드 스위치
    input  Btn_L, Btn_R, Btn_U, Btn_D,


    output [3:0] fnd_com,
    output [7:0] fnd_data
);
    wire w_b_tick;
    wire rx_done;
    wire [7:0] w_rx_data, w_rx_fifo_popdata, w_tx_fifo_popdata;
    wire w_rx_empty, w_tx_fifo_full, w_tx_fifo_empty, w_tx_busy;

    assign rx_trigger = ~w_rx_empty;  
    assign rx_data = w_rx_fifo_popdata;


    wire       w_rx_done;
    wire [1:0] w_mode;
    wire [3:0] w_btn_ctl;
    wire       w_rst_watch;
    wire       w_start; 

    uart_cu U_UART_CU (
        .clk(clk),
        .rst(rst),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done),
        .sw(sw),
        .Btn_L(Btn_L),
        .Btn_R(Btn_R),
        .Btn_U(Btn_U),
        .Btn_D(Btn_D),
        .mode(w_mode),
        .btn_ctl(w_btn_ctl),
        .rst_watch(w_rst_watch)
    );





    watch_stopwatch U_W_S (
        .clk(clk),
        .rst_watch(w_rst_watch),
        .rst(rst), // 외부 Reset + UART Reset

        // uart_cu에서 나온 버튼 신호 연결
        .Btn_L(w_btn_ctl[0]),   // Clear
        .Btn_R(w_btn_ctl[1]), 
        .Btn_U(w_btn_ctl[2]),   // Minute Up
        .Btn_D(w_btn_ctl[3]),   // Hour Up

        // uart_cu에서 나온 모드
        .mode(w_mode),
        //.btn_ctl(btn_ctl_uart),

        // 최종 출력 (FND)
        .fnd_com(fnd_com),
        .fnd_data(fnd_data)
    );


    button_debounce U_BD_START(
        .clk(clk),
        .rst(rst),
        .i_btn(Btn_R),
        .o_btn(w_start)
    );

    uart_tx U_UART_TX(
        .clk(clk),
        .rst(rst),
        .start_trigger(w_rx_done),
        .tx_data(w_rx_data),
        .b_tick(w_b_tick),
        .tx(tx),
        .tx_busy()
    );




    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );


    baud_tick_gen U_BAUD_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );




    // TX FIFO
    fifo U_TX_FIFO (
        .clk(clk),
        .rst(rst),
        .push_data(w_rx_fifo_popdata),  
        .push(~w_rx_empty),
        .pop(~w_tx_busy),
        .pop_data(w_tx_fifo_popdata),
        .full(w_tx_fifo_full),
        .empty(w_tx_fifo_empty)
    );

    // RX FIFO
    fifo U_RX_FIFO (
        .clk(clk),
        .rst(rst),
        .push_data(w_rx_data),  
        .push(rx_done),        
        .pop(~w_tx_fifo_full),  
        .pop_data(w_rx_fifo_popdata),
        .full(),
        .empty(w_rx_empty)
    );




endmodule

module baud_tick_gen (
    input  clk,
    input  rst,
    output b_tick
);
    parameter BAUDRATE = 9600 * 16;
    localparam BAUD_COUNT = 100_000_000 / BAUDRATE;
    reg [$clog2(BAUD_COUNT)-1:0] counter_reg, counter_next;
    reg tick_reg, tick_next;
    // output
    assign b_tick = tick_reg;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_reg    <= 1'b0;
        end else begin
            counter_reg <= counter_next;
            tick_reg    <= tick_next;
        end
    end
    // next CL
    always @(*) begin
        counter_next = counter_reg;  //래치
        tick_next    = tick_reg;
        if (counter_reg == BAUD_COUNT - 1) begin
            counter_next = 0;
            tick_next    = 1'b1;
        end else begin
            counter_next = counter_reg + 1;
            tick_next = 1'b0;
        end
    end
endmodule









