

`timescale 1ns / 1ps

module uart_cu #(
    parameter integer HOLD_CLKS = 2_000_000,   // 버튼 펄스 유지 클럭 수
    parameter integer W = $clog2(HOLD_CLKS)    // 카운터 비트 폭
)(
    input        clk,
    input        rst,

    // UART 입력
    input  [7:0] rx_data,
    input        rx_done,

    // 보드 스위치/버튼 입력
    input  [2:0] sw,       // sw[1:0]=mode, sw[2]=priority
    input        Btn_L,    // Clear
    input        Btn_R,    // Start/Stop
    input        Btn_U,    // Minute Up
    input        Btn_D,    // Hour Up

    // 최종 출력
    output reg [1:0] mode,     // 최종 모드
    output reg [3:0] btn_ctl,  // 버튼 제어
    output reg       rst_watch // Watch reset (12:00으로 초기화)

);

    //--------------------------------------
    // 내부 신호
    //--------------------------------------
    reg [1:0] uart_mode;        // UART로 입력된 모드
    reg [3:0] btn_ctl_uart;     // UART 버튼 제어
    reg [W-1:0] cnt;            // 펄스 유지 카운터

    wire [1:0] board_mode = sw[1:0]; // 보드 모드
    wire       priority   = sw[2];   // 1=UART only, 0=보드+UART


    //--------------------------------------
    // UART 입력 처리
    //--------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            uart_mode    <= 2'b00;
            btn_ctl_uart <= 4'b0000;
            cnt          <= 0;
            rst_watch    <= 1'b0;
        end else begin
            rst_watch <= 1'b0; // 기본값

            if (rx_done) begin
                case (rx_data)
                    // ---------------- 모드 전환 ----------------
                    "0": uart_mode <= 2'b00; // Stopwatch sec/mc
                    "1": uart_mode <= 2'b01; // Stopwatch min/hour
                    "2": uart_mode <= 2'b10; // Watch

                    // ---------------- Stopwatch ----------------
                    "C": begin
                        if (uart_mode == 2'b00) begin       // Stopwatch sec/mc
                            btn_ctl_uart <= 4'b0001;        // Clear
                            cnt <= HOLD_CLKS;
                        end
                        if (uart_mode == 2'b01) begin       // Stopwatch min/hour
                            btn_ctl_uart <= 4'b0001;        // Clear
                            cnt <= HOLD_CLKS;
                        end
                        if (uart_mode == 2'b10) begin       // Watch 모드일 때는 무시
                            // 아무것도 안됨
                        end
                    end

                    "S": begin 
                        if (uart_mode == 2'b00) begin       // Stopwatch sec/mc
                            btn_ctl_uart <= 4'b0010;        // Start/Stop
                            cnt <= HOLD_CLKS;
                        end
                        if (uart_mode == 2'b01) begin       // Stopwatch min/hour
                            btn_ctl_uart <= 4'b0010;        // Start/Stop
                            cnt <= HOLD_CLKS;
                        end
                        if (uart_mode == 2'b10) begin       // Watch 모드일 때는 무시
                            // 아무것도 안됨
                        end
                    end


                    // ---------------- Watch ----------------
                    "R": begin
                        if (uart_mode == 2'b10) begin
                            rst_watch <= 1'b1;      // Watch 모드에서만 Reset → 12:00
                        end
                        // Stopwatch 모드에서는 Reset 없음
                    end

                    "M": begin
                            if (uart_mode == 2'b10) begin
                                btn_ctl_uart <= 4'b0100; // Minute up
                                cnt <= HOLD_CLKS;
                            end
                        end

                    "H": begin
                            if (uart_mode == 2'b10) begin
                                btn_ctl_uart <= 4'b1000; // Hour up
                                cnt <= HOLD_CLKS;
                            end
                        end


                
                endcase
            end



            else if (cnt != 0) begin
                cnt <= cnt - 1;
            end 
            else begin
                btn_ctl_uart <= 4'b0000;
            end
        end
    end



    //--------------------------------------
    // 최종 모드/버튼 결정
    //--------------------------------------
    always @(*) begin
        if (priority) begin
            // UART only
            mode    = uart_mode;
            btn_ctl = btn_ctl_uart;
        end else begin
            // 보드 + UART (debounce 적용 버튼 사용)
            mode    = (board_mode != 2'b00) ? board_mode : uart_mode;
            btn_ctl = btn_ctl_uart | {Btn_D, Btn_U, Btn_R, Btn_L};
        end
    end


endmodule



