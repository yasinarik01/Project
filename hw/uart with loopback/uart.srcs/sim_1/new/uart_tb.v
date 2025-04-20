`timescale 1ns / 1ps

module uart_tb;

    // Parameters
    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 115200;
    parameter DATA_WIDTH = 8;
    parameter BIT_PERIOD_NS = 1000000000 / BAUD_RATE;

    // Testbench signals
    reg clk = 0;
    reg reset;
    reg [DATA_WIDTH-1:0] data_in;
    reg data_in_valid;

    wire [DATA_WIDTH-1:0] data_out;
    wire data_out_valid;
    wire tx;
    wire tx_ready;
    wire busy;

    // Loopback: Connect TX to RX
    wire rx;
    assign rx = tx;

    // Instantiate UART module
    uart #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_in(data_in),
        .data_in_valid(data_in_valid),
        .data_out(data_out),
        .data_out_valid(data_out_valid),
        .tx(tx),
        .tx_ready(tx_ready),
        .busy(busy)
    );

    // Generate 50 MHz clock
    always #10 clk = ~clk;

    initial begin
        // Initial state
        data_in = 8'h00;
        data_in_valid = 0;
        reset = 1;

        // Wait for a few cycles and release reset
        #100;
        reset = 0;

        // Wait for module to become ready
        @(posedge clk);
        wait (tx_ready);

        // Send byte
        data_in = 8'h3C;          // Send 0x3C (00111100)
        data_in_valid = 1;
        @(posedge clk);
        data_in_valid = 0;

        // Wait until data is received back
        wait (data_out_valid);
        $display("Loopback received byte: %02X", data_out);

        #10000;
        $finish;
    end

endmodule

