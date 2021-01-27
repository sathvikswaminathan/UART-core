//=======================
// UART Top level module
//=======================

module uart
#(
    parameter DBIT = 8,
              SB_TICK = 16,
              DVSR = 163,
              DVSR_BIT = 8,
              FIFO_W = 2    // 4 words (bytes) in FIFO
 )
// IO ports
(
    input wire clk, reset,
    input wire rd_uart, wr_uart, rx,
    input wire [DBIT-1:0] w_data,
    output wire tx_full, tx,
    output wire [DBIT-1:0] r_data  
);

// internal signal declaration
wire tick, rx_done_tick, tx_done_tick;
wire tx_empty, tx_fifo_not_empty;
wire [7:0] tx_fifo_out, rx_data_out;

//body
// baud rate generator
counter #(.N(DVSR_BIT), .M(DVSR)) baud_gen_unit
        (.clk(clk), .reset(reset), .tick(tick));

// UART receiver
uart_rx #(.D_BIT(DBIT), .SB_TICK(SB_TICK)) uart_rx_unit
        (.clk(clk), .reset(reset), .rx(rx), .s_tick(tick),
         .rx_done_tick(rx_done_tick), .dout(rx_data_out));

// UART receiver FIFO buffer
fifo #(.B(DBIT), .W(FIFO_W)) uart_rx_buffer_unit
     (.clk(clk), .reset(reset), .rd(rd_uart), .wr(rx_done_tick),
      .w_data(rx_data_out), .empty(rx_empty), .full(), .r_data(r_data));

// UART transmitter FIFO buffer
fifo #(.B(DBIT), .W(FIFO_W)) uart_tx_buffer_unit
     (.clk(clk), .reset(reset), .rd(tx_done_tick), .wr(wr_uart),
      .w_data(w_data), .empty(tx_empty), .full(tx_full), .r_data(tx_fifo_out));

// UART transmitter
uart_tx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_tx_unit
        (.clk(clk), .reset(reset), .tx_start(tx_fifo_not_empty), .s_tick(tick),
         .din(tx_fifo_out), .tx_done_tick(tx_done_tick), .tx(tx));

assign tx_fifo_not_empty = ~tx_empty;

endmodule
