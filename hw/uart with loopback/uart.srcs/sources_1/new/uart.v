module uart #(
    parameter CLK_FREQ = 50000000,      // System clock frequency in Hz
    parameter BAUD_RATE = 115200,       // Desired baud rate
    parameter DATA_WIDTH = 8            // Number of data bits
)(
    input wire clk,                     // System clock
    input wire reset,                   // Active-high synchronous reset
    input wire rx,                      // UART receive input
    input wire [DATA_WIDTH-1:0] data_in, // Data to be transmitted
    input wire data_in_valid,           // Assert high when data_in is valid

    output reg [DATA_WIDTH-1:0] data_out,   // Received data output
    output reg data_out_valid,              // Asserted for one cycle when data_out is valid
    output reg tx,                          // UART transmit output
    output reg tx_ready,                    // High when transmitter is ready for new data
    output reg busy                         // HIGH if either transmitting or receiving
);

  localparam BIT_PERIOD = CLK_FREQ / BAUD_RATE;

  // Transmitter internal signals
  reg [15:0] tx_clk_counter;
  reg [3:0] tx_bit_index;
  reg [DATA_WIDTH-1:0] tx_shift_reg;
  reg tx_sending;

  // Receiver internal signals
  reg [15:0] rx_clk_counter;
  reg [3:0] rx_bit_index;
  reg [DATA_WIDTH-1:0] rx_shift_reg;
  reg rx_receiving;
  reg [1:0] rx_sync;

  // Synchronize RX input
  always @(posedge clk) begin
    rx_sync <= {rx_sync[0], rx};
  end

  always @(posedge clk) begin
    if (reset) begin
      // Transmitter reset
      tx <= 1'b1;
      tx_ready <= 1;
      tx_clk_counter <= 0;
      tx_bit_index <= 0;
      tx_sending <= 0;

      // Receiver reset
      data_out <= 0;
      data_out_valid <= 0;
      rx_clk_counter <= 0;
      rx_bit_index <= 0;
      rx_shift_reg <= 0;
      rx_receiving <= 0;

      // Unified busy signal reset
      busy <= 0;

    end else begin
      // Update unified busy signal
      busy <= tx_sending || rx_receiving;

      // ------------------ Transmitter Logic ------------------
      if (data_in_valid && tx_ready) begin
        tx_sending <= 1;
        tx_ready <= 0;
        tx_shift_reg <= data_in;
        tx_bit_index <= 0;
        tx_clk_counter <= 0;
        tx <= 0; // Start bit
      end else if (tx_sending) begin
        if (tx_clk_counter < BIT_PERIOD - 1) begin
          tx_clk_counter <= tx_clk_counter + 1;
        end else begin
          tx_clk_counter <= 0;
          if (tx_bit_index < DATA_WIDTH) begin
            tx <= tx_shift_reg[tx_bit_index];
            tx_bit_index <= tx_bit_index + 1;
          end else begin
            tx <= 1; // Stop bit
            tx_sending <= 0;
            tx_ready <= 1;
          end
        end
      end

      // ------------------ Receiver Logic ------------------
      data_out_valid <= 0;
      if (!rx_receiving && rx_sync[1] == 0) begin
        // Start bit detected
        rx_receiving <= 1;
        rx_clk_counter <= BIT_PERIOD + (BIT_PERIOD / 2); // Middle of first data bit
        rx_bit_index <= 0;
      end else if (rx_receiving) begin
        if (rx_clk_counter > 0) begin
          rx_clk_counter <= rx_clk_counter - 1;
        end else begin
          rx_clk_counter <= BIT_PERIOD - 1;
          if (rx_bit_index < DATA_WIDTH) begin
            rx_shift_reg[rx_bit_index] <= rx_sync[1];
            rx_bit_index <= rx_bit_index + 1;
          end else begin
            data_out <= rx_shift_reg;
            data_out_valid <= 1;
            rx_receiving <= 0;
          end
        end
      end
    end
  end

endmodule
