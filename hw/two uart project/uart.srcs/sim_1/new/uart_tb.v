`timescale 1ns / 1ps

module uart_dual_tb;

    // Parameters
    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 115200;
    parameter DATA_WIDTH = 8;
    parameter BIT_PERIOD_NS = 1000000000 / BAUD_RATE;

    // Clock and reset
    reg clk = 0;
    reg reset;

    // UART A interface
    reg [DATA_WIDTH-1:0] data_in_a;
    reg data_in_valid_a;
    wire [DATA_WIDTH-1:0] data_out_a;
    wire data_out_valid_a;
    wire tx_a;
    wire tx_ready_a;
    wire busy_a;

    // UART B interface
    wire [DATA_WIDTH-1:0] data_out_b;
    wire data_out_valid_b;
    wire tx_b;
    wire tx_ready_b;
    wire busy_b;

    // Cross-connected RX lines
    wire rx_a = tx_b;
    wire rx_b = tx_a;

    // Instantiate UART A
    uart #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH)
    ) uart_a (
        .clk(clk),
        .reset(reset),
        .rx(rx_a),
        .data_in(data_in_a),
        .data_in_valid(data_in_valid_a),
        .data_out(data_out_a),
        .data_out_valid(data_out_valid_a),
        .tx(tx_a),
        .tx_ready(tx_ready_a),
        .busy(busy_a)
    );

    // Instantiate UART B
    uart #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH)
    ) uart_b (
        .clk(clk),
        .reset(reset),
        .rx(rx_b),
        .data_in(8'b0),               // No input to UART B
        .data_in_valid(1'b0),
        .data_out(data_out_b),
        .data_out_valid(data_out_valid_b),
        .tx(tx_b),
        .tx_ready(tx_ready_b),
        .busy(busy_b)
    );

    // Generate 50 MHz clock
    always #10 clk = ~clk;

    // Simulation
    initial begin
        data_in_a = 8'h00;
        data_in_valid_a = 0;
        reset = 1;

        #100;
        reset = 0;

        // Wait for UART A to be ready
        wait (tx_ready_a);

        // Send a byte from UART A
        data_in_a = $urandom_range(0, 255);
        $display("[%0t ns] UART A Sending: %02X", $time, data_in_a);
        data_in_valid_a = 1;
        @(posedge clk);
        data_in_valid_a = 0;

        // Wait for UART B to receive it
        wait (data_out_valid_b);
        $display("[%0t ns] UART B Received: %02X", $time, data_out_b);

        if (data_out_b === data_in_a)
            $display("SUCCESS: Data transferred correctly.");
        else
            $display("ERROR: Mismatch between sent and received data.");

        #10000;
        $finish;
    end

endmodule


