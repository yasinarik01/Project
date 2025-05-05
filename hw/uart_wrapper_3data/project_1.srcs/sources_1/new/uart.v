module uart #(
    parameter CLK_FREQ   = 100000000,
    parameter BAUD_RATE  = 115200,
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire reset,
    input  wire rx,
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire data_in_valid,

    output reg  [DATA_WIDTH-1:0] data_out,
    output reg  data_out_valid,
    output reg  tx,
    output reg  tx_ready,
    output wire busy
);

    localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;

    
    reg [15:0] tx_clk_counter;
    reg [3:0]  tx_bit_index;
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg tx_sending;
    reg tx_stop_bit;

    
    reg [15:0] rx_clk_counter;
    reg [3:0]  rx_bit_index;
    reg [DATA_WIDTH-1:0] rx_shift_reg;
    reg rx_receiving;
    reg [1:0] rx_sync;

    assign busy = tx_sending || rx_receiving;

    
    always @(posedge clk)
        rx_sync <= {rx_sync[0], rx};

    always @(posedge clk) begin
        if (reset) begin
            // TX sıfırlama
            tx <= 1;
            tx_ready <= 1;
            tx_sending <= 0;
            tx_stop_bit <= 0;
            tx_clk_counter <= 0;
            tx_bit_index <= 0;
            tx_shift_reg <= 0;

            
            data_out <= 0;
            data_out_valid <= 0;
            rx_clk_counter <= 0;
            rx_bit_index <= 0;
            rx_shift_reg <= 0;
            rx_receiving <= 0;
        end else begin
            //--------------------------------------
            
            //--------------------------------------
            if (data_in_valid && tx_ready) begin
                tx_shift_reg <= data_in;
                tx_sending <= 1;
                tx_ready <= 0;
                tx_bit_index <= 0;
                tx_clk_counter <= 0;
                tx_stop_bit <= 0;
                tx <= 0; // Start bit
            end else if (tx_sending) begin
                if (tx_clk_counter < BIT_PERIOD - 1) begin
                    tx_clk_counter <= tx_clk_counter + 1;
                end else begin
                    tx_clk_counter <= 0;

                    if (tx_bit_index < DATA_WIDTH-1) begin
                        tx <= tx_shift_reg[tx_bit_index]; // LSB-first
                        tx_bit_index <= tx_bit_index + 1;
                    end else if (!tx_stop_bit) begin
                        tx <= 1; // Stop bit
                        tx_stop_bit <= 1;
                    end else begin
                        tx_sending <= 0;
                        tx_ready <= 1;
                        tx_bit_index <= 0;   // ← Burada sıfırlanıyor
                        tx_stop_bit <= 0;
                    end
                end
            end

            //--------------------------------------
            // RX Logic
            //--------------------------------------
            data_out_valid <= 0;

            if (!rx_receiving && rx_sync == 2'b10) begin
                rx_receiving <= 1;
                rx_clk_counter <= BIT_PERIOD + (BIT_PERIOD / 2);
                rx_bit_index <= 0;
            end else if (rx_receiving) begin
                if (rx_clk_counter > 0) begin
                    rx_clk_counter <= rx_clk_counter - 1;
                end else begin
                    rx_clk_counter <= BIT_PERIOD - 1;

                    rx_shift_reg[rx_bit_index] <= rx_sync[1];

                    if (rx_bit_index == DATA_WIDTH - 1) begin
                        data_out <= {rx_sync[1], rx_shift_reg[DATA_WIDTH-2:0]};
                        data_out_valid <= 1;
                        rx_receiving <= 0;
                    end else begin
                        rx_bit_index <= rx_bit_index + 1;
                    end
                end
            end
        end
    end
endmodule


