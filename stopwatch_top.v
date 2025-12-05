`timescale 1ns / 1ps

module stopwatch (
    input        clk,
    input        rst,
    // input  mode,
    input        Btn_L,
    input        Btn_R,

    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour 
);

    wire [6:0] w_msec;
    wire [5:0] w_sec;
    wire [5:0] w_min;
    wire [4:0] w_hour;
    wire w_runstop;
    wire w_clear;
    wire w_btn_r;
    wire w_btn_l;   

    button_debounce U_BD_RUNSTOP(
        .clk(clk),
        .rst(rst),
        .i_btn(Btn_R),
        .o_btn(w_btn_r)
    );

    button_debounce i_btn_debounce(
        .clk(clk),
        .rst(rst),
        .i_btn(Btn_L),
        .o_btn(w_btn_l)
    );

    stopwatch_dp U_SW_DP(
        .clk(clk),
        .i_runstop(w_runstop),
        .i_clear(w_clear),
        .rst(rst),
        .msec(msec),
        .sec(sec),
        .min(min),
        .hour(hour)
    );

    stopwatch_cu U_SW_CU (
        .clk(clk),
        .rst(rst),
        .i_runstop(w_btn_r),
        .i_clear(w_btn_l),
        .o_runstop(w_runstop),
        .o_clear(w_clear)
    );

endmodule
////////////////////////////////////////////

