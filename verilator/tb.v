
`timescale 1ns/100ps

`default_nettype none

module tb(input osc_clk);

    reg osc_reset_ = 1'b0;

    always @(posedge osc_clk) begin
        osc_reset_  <= 1'b1;
    end

    wire led_red, led_green, led_blue;
    wire uart_txd, uart_rxd;

    ExampleTop u_dut(
        .osc_clk_in(osc_clk),

        .led_red(led_red),
        .led_green(led_green),
        .led_blue(led_blue),

        .button(1'b1),

        .uart_txd(uart_txd),
        .uart_rxd(uart_rxd)
    );

    reg prev_led_red, prev_led_green, prev_led_blue;

    always @(posedge osc_clk) begin

        if (led_red != prev_led_red) begin
            $display("led_red: %d\n", led_red);
        end
        if (led_green != prev_led_green) begin
            $display("led_green: %d\n", led_green);
        end
        if (led_blue != prev_led_blue) begin
            $display("led_blue: %d\n", led_blue);
        end

        prev_led_red <= led_red;
        prev_led_green <= led_green;
        prev_led_blue <= led_blue;
    end


endmodule
