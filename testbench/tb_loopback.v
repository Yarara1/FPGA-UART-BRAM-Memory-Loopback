`timescale 1ns / 1ns

module tb_loopback();

    parameter MEMORY_DEPTH = 100;
    // parameter MEMORY_DEPTH = 16384;

    reg clk_100MHz;
    reg rst_pin;
    reg rx_switch;
    reg tx_switch;
    reg rx_switch_tester;
    reg tx_switch_tester;

    wire clk_50MHz;
    wire uart_rx;
    wire uart_tx;
    wire led;

    initial clk_100MHz = 1'b0;
    always #5 clk_100MHz = ~clk_100MHz;

    ClockDivider #(
        .divide_rate(2)
    ) UClockDivider (
        .clk_in(clk_100MHz),
        .rst(rst_pin),
        .clk_out(clk_50MHz)
    );

    tester_loopback #(
        .BAUD_RATE(115_200),
        .CLOCK_RATE(50_000_000),
        .MEMORY_DEPTH(MEMORY_DEPTH)
    ) tester (
        .clk(clk_50MHz),
        .rst(rst_pin),
        .rx_switch(rx_switch_tester),
        .tx_switch(tx_switch_tester),
        .uart_rx(uart_tx),
        .uart_tx(uart_rx)
    );

    loopback_top #(
        .BAUD_RATE(115_200),
        .CLOCK_RATE(50_000_000),
        .MEMORY_DEPTH(MEMORY_DEPTH)
    ) loopback (
        .clk(clk_100MHz),
        .rst(rst_pin),
        .uart_rx(uart_rx),
        .rx_switch(rx_switch),
        .tx_switch(tx_switch),
        .uart_tx(uart_tx),
        .led(led)
    );

    initial begin
        rst_pin          = 1'b0;
        rx_switch        = 1'b0;
        tx_switch        = 1'b0;
        rx_switch_tester = 1'b0;
        tx_switch_tester = 1'b0;

        #3;
        rst_pin = 1'b1;
        #100;
        rst_pin = 1'b0;

        // Start DUT receive mode
        #20;
        rx_switch = 1'b1;

        // Start tester transmit mode
        #20;
        tx_switch_tester = 1'b1;

        // Wait until DUT indicates receive is done
        wait (led == 1'b1);
        $display("LED turned on at time %0t", $time);

        // Stop RX phase
        #50;
        rx_switch = 1'b0;
        tx_switch_tester = 1'b0;

        // Start tester receive mode
        #50;
        rx_switch_tester = 1'b1;

        // Start DUT transmit mode
        #50;
        tx_switch = 1'b1;

        #10000000;
        $finish;
    end

endmodule
