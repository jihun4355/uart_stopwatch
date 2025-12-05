`timescale 1ns / 1ps

module watch_dp (
    input        clk,
    input        rst,
    input i_run_sec,
    input i_run_min,
    input i_run_hour,
    output [6:0] msec,
    output [5:0] sec,
    output [5:0] min,
    output [4:0] hour
);

    wire w_tick_100hz;
    wire w_sec_tick;
    wire w_min_tick;
    wire w_hour_tick;
    wire w_run_sec, w_run_min, w_run_hour;


    time_counter #(
        .BIT_WIDTH(7),
        .TIME_COUNT(100)
    ) U_MSEC_COUNTER (
        .clk(clk), 
        .rst(rst),
        .i_run_sec(1'b0),
        .i_run_min(1'b0),
        .i_run_hour(1'b0),
        .i_tick(w_tick_100hz),
        .o_time(msec),
        .o_tick(w_sec_tick)
    );

    time_counter #(
        .BIT_WIDTH(6),
        .TIME_COUNT(60)
    ) U_SEC_COUNTER (
        .clk(clk), 
        .rst(rst),
        .i_run_sec(i_run_sec),
        .i_run_min(1'b0),
        .i_run_hour(1'b0),
        .i_tick(w_sec_tick),
        .o_time(sec),
        .o_tick(w_min_tick)
    );
    
    time_counter #(
        .BIT_WIDTH(6),
        .TIME_COUNT(60)
    ) U_MIN_COUNTER (
        .clk(clk), 
        .rst(rst),
        .i_run_sec(1'b0),
        .i_run_min(i_run_min),
        .i_run_hour(1'b0),
        .i_tick(w_min_tick),
        .o_time(min),
        .o_tick(w_hour_tick)
    );
    
    time_counter #(
        .BIT_WIDTH(6),
        .TIME_COUNT(24),
        .INIT_VALUE(12)
    ) U_HOUR_COUNTER (
        .clk(clk), 
        .rst(rst),
        .i_run_sec(1'b0),
        .i_run_min(1'b0),
        .i_run_hour(i_run_hour),
        .i_tick(w_hour_tick),
        .o_time(hour),
        .o_tick()
    );
    
    tick_gen_100hz U_TICK_GEN_100HZ(
        .clk(clk),
        .rst(rst),
        .o_tick_100hz(w_tick_100hz)
    );

endmodule

//////////////////////////////

module tick_gen_100hz (
    input  clk,
    input  rst,

    output o_tick_100hz
);

    parameter FCOUNT = 100_000_000 / 100;
    reg [$clog2(FCOUNT)-1:0] r_counter;
    reg r_tick;

    assign o_tick_100hz = r_tick;

    always @(posedge clk or posedge rst) begin
    if (rst) begin
        r_counter <= 1'b0;
        r_tick    <= 1'b0;
    end else begin
        r_tick <= 1'b0;  
        if (r_counter == FCOUNT-1) begin
        r_counter <= 1'b0;
        r_tick    <= 1'b1;   
        end else begin
        r_counter <= r_counter + 1'b1;
        end
    end
    end
endmodule
//////////////////////////////
module time_counter #(
    parameter BIT_WIDTH = 7,
    TIME_COUNT = 100,
    INIT_VALUE = 0
) (
    input clk, 
    input rst,
    input i_tick,
    input i_run_sec,
    input i_run_min,
    input i_run_hour,
    output [BIT_WIDTH-1:0] o_time,
    output o_tick
);

    reg [$clog2(TIME_COUNT) -1:0] count_reg, count_next;
    reg tick_reg, tick_next;

    assign o_time = count_reg;
    assign o_tick = tick_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg <= INIT_VALUE;
            tick_reg <= 1'b0;
        end else begin
            count_reg <= count_next;
            tick_reg <= tick_next;
        end
    end

    always @(*) begin
    count_next = count_reg;
    tick_next  = 1'b0;

    if (i_tick || i_run_sec || i_run_min || i_run_hour) begin
        if (count_reg == TIME_COUNT - 1) begin
            count_next = 0;
            tick_next  = 1'b1;
        end else begin
            count_next = count_reg + 1;
        end
    end
    end

  
endmodule