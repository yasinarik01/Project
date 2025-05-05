module uart_wrapper #(
    parameter CLK_FREQ = 100000000,
    parameter BAUD_RATE = 115200,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire reset,
    input wire rx,
    output wire tx
);

    wire [DATA_WIDTH-1:0] rx_data;
    wire rx_data_valid;
    reg  [DATA_WIDTH-1:0] tx_data;
    reg  tx_data_valid;
    wire tx_ready;
    wire busy;

    uart #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATA_WIDTH(DATA_WIDTH)
    ) uart_inst (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_in(tx_data),
        .data_in_valid(tx_data_valid),
        .data_out(rx_data),
        .data_out_valid(rx_data_valid),
        .tx(tx),
        .tx_ready(tx_ready),
        .busy(busy)
    );

    reg [1:0] state;
    localparam IDLE = 2'd0, LOAD = 2'd1;

    always @(posedge clk) begin
        if (reset) begin
            tx_data <= 0;
            tx_data_valid <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    
                    if (rx_data_valid && tx_ready) begin
                        tx_data <= rx_data + 8'd3;
                        tx_data_valid <= 1;
                        state <= LOAD;
                    end
                end
                LOAD: begin
                    tx_data_valid <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
