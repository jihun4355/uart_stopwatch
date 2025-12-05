`timescale 1ns / 1ps

module watch_stopwatch(
    input clk, rst, rst_watch,
    input Btn_L,
    input Btn_R,
    input Btn_U,
    input Btn_D,
    input [1:0] mode,
    input [3:0] btn_ctl_uart,

    output [3:0] fnd_com,
    output [7:0] fnd_data
    );


    wire [23:0]w_time;
    wire [5:0] w_sec, stop_sec;
    wire [6:0] stop_msec, w_msec;
    wire [5:0] stop_min, w_min;
    wire [4:0] stop_hour, w_hour;




    stopwatch U_STOPWATCH(
        .clk(clk),
        .rst(rst),
        .msec(stop_msec),
        .sec(stop_sec),
        .min(stop_min),
        .hour(stop_hour),
        .Btn_R(Btn_R),
        .Btn_L(Btn_L)
    );

    watch U_WATCH(
        .clk(clk),
        .rst(rst_watch),
        //.rst(rst),
        .msec(w_msec),
        .sec(w_sec),
        .min(w_min),
        .hour(w_hour),
        // .Btn_R(Btn_R),
        .Btn_L(Btn_L),
        .Btn_U(Btn_U),
        .Btn_D(Btn_D)//,
        //.btn_ctl_uart(btn_ctl_uart)
    );

    watch_mode_2X1 U_MODE_2X1(
        .sel(mode),
        .stop_w({stop_hour, stop_min, stop_sec, stop_msec}),
        .watch({w_hour, w_min, w_sec, w_msec}),
        .watch_stop_mode(w_time)
    );

    fnd_controller U_FND_CNTL (
        .clk(clk),
        .rst(rst),
        .i_time(w_time),
        .fnd_com(fnd_com),
        .fnd_data(fnd_data),
        .mode(mode)
    );

endmodule




module watch_mode_2X1(
    input [1:0] sel,
    input [23:0] stop_w,
    input [23:0] watch,
    output [23:0] watch_stop_mode
);

    assign watch_stop_mode = (sel[1] == 1) ? watch : stop_w;

endmodule