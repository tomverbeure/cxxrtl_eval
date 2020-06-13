
module blink(input clk, output led);

    reg [63:0] counter = 0;

    always @(posedge clk) 
        counter <= counter + 1'b1;

    assign led = counter[7];


endmodule

module top(input clk, output led);

    reg [3:0] mem[1023:0];

    blink u_blink(
        .clk(clk),
        .led(led)
    );

endmodule
