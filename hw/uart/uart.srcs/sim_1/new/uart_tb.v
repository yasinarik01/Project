

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.04.2025 14:27:57
// Design Name: 
// Module Name: uarttest
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////





module uart_tb;

    // Parameters
    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 115200;
    parameter DATA_WIDTH = 8;
    parameter BIT_PERIOD_NS = 1000000000 / BAUD_RATE;

    // Testbench signals
    reg clk = 0;
    reg reset;
    reg rx;
    reg [DATA_WIDTH-1:0] data_in;
    reg data_in_valid;

    wire [DATA_WIDTH-1:0] data_out;
    wire data_out_valid;
    wire tx;
    wire tx_ready;
    wire busy;

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

    // Task to emulate UART reception (LSB first)
    task uart_rx_byte(input [7:0] byte);
        integer i;
        begin
            rx <= 0; // Start bit
            #(BIT_PERIOD_NS);

            for (i = 0; i < 8; i = i + 1) begin
                rx <= byte[i];
                #(BIT_PERIOD_NS);
            end

            rx <= 1; // Stop bit
            #(BIT_PERIOD_NS);
        end
    endtask

    initial begin
        // Initial state
        rx = 1;
        data_in = 8'h00;
        data_in_valid = 0;
        reset = 1;

        // Wait for a few cycles and release reset
        #100;
        reset = 0;

        // Transmit a byte
        @(posedge clk);
        if (tx_ready) begin
            data_in = 8'h5A;         // Send 0x5A
            data_in_valid = 1;
        end
        @(posedge clk);
        data_in_valid = 0;

        // Wait for TX to finish
        wait (tx_ready == 1);

        // Receive a byte: emulate rx line
        #100000;                    // wait for spacing
        uart_rx_byte(8'hA5);       // Receive 0xA5 from outside

        // Wait until reception is completed
        wait (data_out_valid == 1);
        $display("Received byte: %02X", data_out);

        #10000;
        $finish;
    end

endmodule