`timescale 1ns / 1ps
module stopwatch_cu (
    input  clk,
    input  rst,
    input  i_runstop,   // 1-clk pulse
    input  i_clear,     // 1-clk pulse
    output o_runstop,   // 1이면 동작(run), 0이면 정지(stop)
    output o_clear      // 1클럭 clear 펄스
);
    // state define
    localparam STOP=2'b00, RUN=2'b01, CLEAR=2'b10;

    reg [1:0] c_state, n_state;
    reg runstop_reg, runstop_next;
    reg clear_reg,   clear_next;

    assign o_runstop = runstop_reg;
    assign o_clear   = clear_reg;

    // state/output registers
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state     <= STOP;
            runstop_reg <= 1'b0;
            clear_reg   <= 1'b0;
        end else begin
            c_state     <= n_state;
            runstop_reg <= runstop_next;
            clear_reg   <= clear_next;
        end
    end

    // next-state / Moore outputs
    always @* begin
        n_state      = c_state;

        // 기본값(안전)
        runstop_next = 1'b0;
        clear_next   = 1'b0;

        case (c_state)
            STOP: begin
                // STOP에서는 run=0, clear=0
                if (i_clear) begin
                    n_state = CLEAR;
                end else if (i_runstop) begin
                    n_state = RUN;
                end
            end

            RUN: begin
                runstop_next = 1'b1; // RUN상태에서는 run=1
                if (i_clear) begin
                    n_state = CLEAR;  // 런 중 클리어 허용 (권장)
                end else if (i_runstop) begin
                    n_state = STOP;
                end
            end

            CLEAR: begin
                // 1클럭 clear 펄스
                clear_next = 1'b1;
                // 클리어 후 즉시 STOP 복귀
                n_state = STOP;
            end

            default: begin
                n_state = STOP;
            end
        endcase
    end
endmodule
