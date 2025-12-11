## 🔍 Project Overview – UART/FIFO 기반 통합 시계 시스템

본 프로젝트는 FPGA(Basys3)를 기반으로  
**시계(Watch) + 스톱워치(Stopwatch) + UART 제어 + RX/TX FIFO 구조**를 하나의 통합된 디지털 시스템으로 설계한 것이다.  
버튼, 스위치, UART 명령을 통해 Watch/Stopwatch의 동작을 제어하며, FIFO는 안정적인 UART 데이터 통신을 위해 사용된다.

(출처: PDF 1~6p  :contentReference[oaicite:2]{index=2})

---

## 🧩 1. 전체 동작 개요 (p.3~6)

### ✔ 모드 선택
- mode[1:0] = 00 / 01 → Stopwatch (세부 모드: sec/msec, hour/min)
- mode[1:0] = 10 → Watch

### ✔ 버튼 제어
- Btn_R → Start/Stop  
- Btn_L → Clear  
- Btn_U → Minute +1  
- Btn_D → Hour +1  
- rst_watch → 12:00 초기화

### ✔ UART 제어 명령
| 문자 | 기능 |
|------|------|
| `"0"` `"1"` `"2"` | 모드 전환 |
| `"S"` | Start/Stop |
| `"C"` | Clear |
| `"M"` | Minute +1 |
| `"H"` | Hour +1 |
| `"R"` | Watch Reset |

### ✔ 우선순위 제어(sw[2])
- sw[2] = 1 → UART만 동작  
- sw[2] = 0 → UART + 보드 버튼 OR 병합

---

## 🛰 2. UART Receiver / Transmitter (p.7–12)

### ✔ UART RX FSM
- IDLE → START → DATA (8bit) → STOP  
- 23 b_tick 도달 시 데이터 샘플링  
- STOP 단계에서 rx_done=1 pulse 발생 → 상위 로직에 수신 완료 알림

### ✔ UART TX FSM
- IDLE → START → DATA(bit0~7) → STOP  
- count를 이용해 bit 전송  
- tx_busy_reg를 통해 전송 중 상태 유지

### ✔ UART TX 시뮬레이션
- bit_cnt 0→7 정상 증가  
- start_trigger와 tx_busy 타이밍 일치 → 정상 전송 검증됨

(출처: PDF 7~12p  :contentReference[oaicite:3]{index=3})

---

## 📦 3. FIFO 설계 (p.13–16)

### ✔ RX_FIFO
- UART 수신 데이터를 임시 저장하는 버퍼  
- push 시점마다 rx_data 저장  
- pop으로 상위 로직이 필요한 시점에 데이터 꺼냄

### ✔ TX_FIFO
- 상위 로직이 보낸 데이터를 저장  
- UART TX 준비 완료 시 pop되어 전송됨

### ✔ FIFO FSM (p.13)
- RESET → IDLE → (PUSH / POP / PUSH&POP)

### ✔ FIFO 시뮬레이션 결과
- push=1 → full=0 상태에서 순차 저장  
- pop=1 → empty=1로 비워짐  
- push & pop 동시에 발생 시 FIFO 내부 데이터 유지  

---

## ⏱ 4. Stopwatch / Watch Mode Logic (p.17–24)

### ✔ Stopwatch Mode (00)
- Btn_R → run/stop  
- Btn_L → clear  
- 내부 tick(100Hz)에 따라 msec/sec/min/hour 카운트

### ✔ Watch Mode (10)
- Btn_U → min+1  
- Btn_D → hour+1  
- rst_watch → 12:00 초기화  
- 초/밀리초는 내부 tick으로 지속 증가

### ✔ Block Diagram (p.17–18)
Stopwatch와 Watch는 독립적인 데이터패스를 가지고,  
Mode block에서 선택한 출력만 FND Controller로 전달됨.

### ✔ Schematic (p.19–24)
- stopwatch_top: FSM + Counter datapath  
- watch_top: debounce + CU + DP  
- watch_top의 dp는 hour/min/sec 3단 카운터로 구성

---

## 🔗 5. UART CU – 핵심 제어 유닛 (p.25–31)

### ✔ 기능
- UART로 들어오는 문자에 따라 mode, watch_reset, min_up, hour_up 등 제어 신호 생성  
- case 기반 모드 전환  
- “M”, “H”, “S”, “C” 등은 펄스로 만들어 debounce 충돌 방지  
- board 버튼과 UART 제어를 OR 하되, sw[2]가 1이면 UART만 사용

### ✔ 시뮬레이션 결과
- UART 명령 도착 → uart_mode 정상 변경  
- btn_ctl_uart 펄스가 Min/Hour 증가 동작과 완전히 일치  
- mode=2 순간부터 Watch 값이 FND에 출력

---

## 📊 6. FND Controller (p.32–34)

- fnd_com: 자리 선택  
- fnd_data: BCD to 7-Segment 디코딩 값  
- stopwatch와 watch 값이 UART 명령에 따라 실시간으로 변화  
- fnd_data가 정상적으로 자리 순환하는지 waveform으로 확인

---

## ⚠ 7. Troubleshooting (p.35–37)

### ✔ 문제: Min Up 신호가 너무 짧아 watch_top 카운터가 놓침  
- debounce 처리 타이밍과 충돌  
- UART CU에서 발생한 펄스가 watch 카운터까지 도달하기 전에 종료됨

### ✔ 해결
- 버튼/모드 분기 난잡한 AND/MUX 구조 개선  
- 신호 길이 보정 및 게이트 단순화  
- 안정적인 UART+Button 통합 동작 확보

---

## ✔ 최종 결과

- UART + FIFO + Stopwatch + Watch가 완전하게 통합됨  
- 모드 전환 / 시간 증가 / clear / reset 모두 UART로 제어 가능  
- Basys3 보드에서 실시간 FND 표시  
- 시뮬레이션(All waveforms)에서 정상 동작 검증 완료


## 📄 UART / FIFO Integrated Digital Time System (PDF Report)

전체 프로젝트 문서는 아래 PDF에서 확인할 수 있습니다.

👉 [📘 **UART/FIFO 프로젝트 PDF 열기**](./uart_fifo.pdf)


:contentReference[oaicite:1]{index=1}

---

### 📌 PDF 미리보기 썸네일 (옵션)

[![PDF Preview](./uart_fifo_page1.png)](./uart_fifo.pdf)




