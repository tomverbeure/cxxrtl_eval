
`timescale 1ns/100ps

`default_nettype none

module tb;

    reg osc_clk;
    reg osc_reset_;

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars;

        osc_clk = 0;
        osc_reset_ = 1;

        repeat(20)
            @(posedge osc_clk);

        osc_reset_ = 0;

        repeat(40000)
            @(posedge osc_clk);

        $finish;
    end

    always
        #20 osc_clk = !osc_clk;

    wire uart_txd, uart_rxd;

    ExampleTop u_dut(
        .osc_clk_in(osc_clk),

        .button(1'b1),

        .uart_txd(uart_txd),
        .uart_rxd(uart_rxd)
    );

endmodule
