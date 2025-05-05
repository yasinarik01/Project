`timescale 1ns / 1ps

module uart_wrapper_tb;

    // Parameters
    parameter CLK_FREQ = 50000000;
    parameter BAUD_RATE = 115200;
    parameter DATA_WIDTH = 8;
    localparam BIT_PERIOD = 1000000000 / BAUD_RATE; // ns

    // Signals
    reg clk = 0;
    reg reset;
    reg rx;
    wire tx;

    // Instantiate DUT
    uart_wrapper #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .tx(tx)
    );

    // Generate 50 MHz clock
    always #10 clk = ~clk; // 20 ns period

    // UART send task (start + 8 bits + stop)
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // Start bit
            rx <= 0;
            #(BIT_PERIOD);

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx <= data[i];
                #(BIT_PERIOD);
            end

            // Stop bit
            rx <= 1;
            #(BIT_PERIOD);

            // Extra wait
            #(BIT_PERIOD * 4);
        end
    endtask

    initial begin
        // Initialize
        rx = 1;
        reset = 1;
        #100;
        reset = 0;

        #1000;

        $display("[%0t ns] Sending RX byte: 0x10", $time);
        uart_send_byte(8'h10); // RX = 0x10, TX should be 0x13

        // Wait for UART to finish transmission
        #(BIT_PERIOD * 35);

// Test case 2
    $display("[%0t ns] Sending RX byte: 0xA5", $time);
    uart_send_byte(8'hA5); // New input
    #(BIT_PERIOD * 40);

    // Test case 3
    $display("[%0t ns] Sending RX byte: 0xFF", $time);
    uart_send_byte(8'hFF); // Another input
    #(BIT_PERIOD * 45);




        // Check result
        if (dut.tx_data === 8'h13) begin
            $display("[%0t ns] ✅ TEST PASSED: TX output is 0x13 as expected.", $time);
        end else begin
            $display("[%0t ns] ❌ TEST FAILED: TX output is 0x%02X, expected 0x13", $time, dut.tx_data);
        end

        $finish;
    end

endmodule
