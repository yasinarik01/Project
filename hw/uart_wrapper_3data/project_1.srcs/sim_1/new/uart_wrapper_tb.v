`timescale 1ns / 1ps

module uart_wrapper_tb;

    
    parameter CLK_FREQ   = 100_000_000;
    parameter BAUD_RATE  = 115200;
    parameter DATA_WIDTH = 8;
    
    
    localparam BIT_PERIOD = 1000000000 / BAUD_RATE;

   
    reg clk = 0;
    reg reset;
    reg rx;
    wire tx;

    // DUT (Design Under Test)
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

    
    always #5 clk = ~clk; // 10 ns tam periyot

    
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            rx <= 0; // Start bit
            #(BIT_PERIOD);

            for (i = 0; i < 8; i = i + 1) begin
                rx <= data[i]; // LSB-first
                #(BIT_PERIOD);
            end

            rx <= 1; // Stop bit
            #(BIT_PERIOD);

            #(BIT_PERIOD * 4); // boşluk
        end
    endtask

    initial begin
        
        rx = 1; // idle
        reset = 1;
        #100;
        reset = 0;

        #1000;

        
        $display("[%0t ns] Sending RX byte: 0x10", $time);
        uart_send_byte(8'h10); // TX = 0x13 beklenir
        #(BIT_PERIOD * 40);

        
        $display("[%0t ns] Sending RX byte: 0xA5", $time);
        uart_send_byte(8'hA5); // TX = 0xA8 beklenir
        #(BIT_PERIOD * 40);

        
        $display("[%0t ns] Sending RX byte: 0xFF", $time);
        uart_send_byte(8'h21); // TX = 0x02 beklenir (FF+3 = 0x102 % 256)
        #(BIT_PERIOD * 50);

        $finish;
    end

endmodule

