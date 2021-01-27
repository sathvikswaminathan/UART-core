//========================================
// UART Receiver
// Oversampling frequency = 16 * baud_rate
//========================================

module uart_rx 
#(
    parameter D_BIT = 8,        // number of data bits
              SB_TICK = 16     // number of ticks for stop bits (SB_TICK / 16)
 )
// IO ports
(
    input wire clk, reset,
    input wire rx, s_tick,
    output reg rx_done_tick,
    output wire [D_BIT-1:0] dout
); 

// symbolic state representation
localparam  [1:0]
            IDLE  = 2'b00,
            START = 2'b01,
            DATA  = 2'b10,
            STOP  = 2'b11;

// internal signal declaration
reg [1:0] state_reg, state_next;
reg [3:0] s_reg, s_next;            // log base 2 (16)
reg [2:0] n_reg, n_next;            // log base 2 (D_BIT)
reg [7:0] b_reg, b_next;            // D_BIT

// body
// FSMD state and data registers
always @(posedge clk, posedge reset) 
begin
    if(reset)
        begin
            state_reg <= IDLE;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
        end 
    else
        begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
        end
end

// FSMD next-state logic
always @*
begin
    // default values
    state_next = state_reg;
    s_next = s_reg;
    n_next = n_reg;
    b_next = b_reg;

    case (state_reg)

        IDLE:
            if(rx == 0)
                begin
                    s_next = 0;
                    state_next = START; 
                end
        
        START:
            if(s_tick)
                begin
                    if(s_reg == 7)
                        begin
                            s_next = 0;
                            n_next = 0;
                            state_next = DATA;
                        end
                    else
                        s_next = s_reg + 1;
                end

        DATA:
            if(s_tick)
                begin
                    if(s_reg == 15)
                        begin
                            s_next = 0;
                            b_next = {rx, b_reg[7:1]};
                            if(n_reg == (D_BIT -1))
                                state_next = STOP;
                            else
                                n_next = n_reg + 1;
                        end
                    else
                        s_next = s_reg + 1;
                end
        
        STOP:
            if(s_tick)
                begin
                    if(s_tick == (SB_TICK-1))
                        begin
                           rx_done_tick = 1'b1;
                           state_next = IDLE; 
                        end
                    else
                        s_next = s_reg + 1;
                end
        
        default: state_next = IDLE;

    endcase
end

// output logic
assign dout = b_reg;

endmodule
