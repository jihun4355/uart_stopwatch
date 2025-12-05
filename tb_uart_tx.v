// UART 통신 테스트벤치
`timescale 1ns/1ps

module tb_uart_top;

  // DUT I/O
  reg  clk, rst, rx;
  wire tx;
  reg  [2:0] sw;
  reg  Btn_L, Btn_R, Btn_U, Btn_D;
  wire [3:0] fnd_com;
  wire [7:0] fnd_data;

  // 100MHz & 9600bps
  localparam CLK_PERIOD_NS = 10;                         // 100 MHz
  localparam UART_BAUD     = 9600;
  localparam BIT_NS        = 1_000_000_000 / UART_BAUD;  // ≈104_166 ns/bit

  // DUT
  uart_top dut (
    .clk(clk), .rst(rst),
    .rx(rx), .tx(tx),
    .sw(sw),
    .Btn_L(Btn_L), .Btn_R(Btn_R), .Btn_U(Btn_U), .Btn_D(Btn_D),
    .fnd_com(fnd_com), .fnd_data(fnd_data)
  );

  // 100MHz clock
  initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD_NS/2) clk = ~clk;
  end

  // ================= Main Scenario =================
  initial begin
    // 초기화
    rx    = 1'b1;  // UART idle high
    rst   = 1'b1;
    sw    = 3'b000; // sw[2]=0 → Board+UART 동시 OR 동작 확인
    Btn_L = 0; Btn_R = 0; Btn_U = 0; Btn_D = 0;

    repeat (20) @(posedge clk);
    rst = 1'b0;
    repeat (20) @(posedge clk);

    // --- 선행: Watch 모드 진입 + Reset ---
    uart_send_byte("2"); wait_rx_done_log("2");  // Watch 모드
    uart_send_byte("R"); wait_rx_done_log("R");  // 12:00 리셋
    #(BIT_NS*2);

    // 슬롯 A: Minute+ 동시 자극 (UART 'M' + Btn_U)
    fork
      begin uart_send_byte("M"); end
      begin press_button("Btn_U (Minute+)", Btn_U, 200_000); end // ~200us
    join
    wait_rx_done_log("M");
    #(BIT_NS*2);

    // 슬롯 B: Hour+ 동시 자극 (UART 'H' + Btn_D)
    fork
      begin uart_send_byte("H"); end
      begin press_button("Btn_D (Hour+)", Btn_D, 200_000); end
    join
    wait_rx_done_log("H");
    #(BIT_NS*2);

    // --- Stopwatch(sec/mc) 모드로 전환 ---
    uart_send_byte("0"); wait_rx_done_log("0");
    #(BIT_NS*2);

    // 슬롯 C: Start/Stop 동시 자극 (UART 'S' + Btn_R)
    fork
      begin uart_send_byte("S"); end
      begin press_button("Btn_R (Run/Stop)", Btn_R, 200_000); end
    join
    wait_rx_done_log("S");

    // 잠깐 돌리고…
    #(BIT_NS*8);

    // 슬롯 D: Clear 동시 자극 (UART 'C' + Btn_L)
    fork
      begin uart_send_byte("C"); end
      begin press_button("Btn_L (Clear)", Btn_L, 200_000); end
    join
    wait_rx_done_log("C");

    // 여유
    #(BIT_NS*10);
    $display("[%0t ns] ** ALL TESTS DONE **", $time);
    $finish;
  end

  // ============= Tasks =============

  // TB → DUT.rx : UART 1바이트 전송 (9600bps, 8N1)
  task uart_send_byte(input [7:0] data);
    integer i;
    begin
      $display("[%0t ns] SEND '%c' (0x%02h)", $time, data, data);
      // start bit
      rx = 1'b0; #(BIT_NS);
      // data bits (LSB first)
      for (i=0; i<8; i=i+1) begin
        rx = data[i]; #(BIT_NS);
      end
      // stop bit
      rx = 1'b1; #(BIT_NS);
      // idle 간격
      #(BIT_NS);
    end
  endtask

  // DUT 내부 수신 완료 대기 & 로깅
  task wait_rx_done_log(input [7:0] expect);
    begin
      @(posedge dut.w_rx_done);
      @(posedge clk); // 한 클럭 안정화
      $display("[%0t ns] RX_DONE: got 0x%02h ('%c'), expect '%c', btn_ctl=%b mode=%b",
               $time, dut.w_rx_data, dut.w_rx_data, expect, dut.w_btn_ctl, dut.w_mode);
    end
  endtask

  // 보드 버튼 펄스 (ns 단위)
  task press_button(input [127:0] name, output reg btn, input integer ns_on);
    begin
      $display("[%0t ns] PRESS %s", $time, name);
      btn = 1'b1; #(ns_on); btn = 1'b0;
    end
  endtask

  // (옵션) VCD 파형 — XSim은 wdb 자동 생성
  initial begin
    $dumpfile("tb_uart_top.vcd");
    $dumpvars(0, tb_uart_top);
  end

endmodule




































