//==================
// UART Transmitter
//==================

module uart_tx
#(
    parameter DBIT = 8,
              SB_TICK = 16
 )
// IO ports
(
    input wire clk, reset,
    input wire tx_start, s_tick,
    input wire [7:0] din,
    output reg tx_done_tick,
    output wire tx
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
reg tx_reg, tx_next; 

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
            tx_reg <= 1'b1;
        end 
    else
        begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
            tx_reg <= tx_next;
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
    tx_done_tick = 1'b0;
    tx_next = tx_reg;

    case (state_reg)

        IDLE:
            begin
               tx_next = 1'b1;         // IDLE signal to receiver
                if(tx_start)
                    begin
                        b_next = din;
                        s_next = 0;
                        state_next = START; 
                    end 
            end
        
        START:
            begin
               tx_next = 1'b0;         // START bit to receiver
                if(s_tick)
                    begin
                        if(s_reg == 15)
                            begin
                                s_next = 0;
                                n_next = 0;
                                state_next = DATA;
                            end
                        else
                            s_next = s_reg + 1;
                    end 
            end

        DATA:
            begin
                if(s_tick)
                    begin
                        if(s_reg == 15)
                            begin
                                tx_next = b_reg[0];     // DATA bits to receiver
                                s_next = 0;
                                b_next = b_reg >> 1;
                                if(n_reg == (D_BIT -1))
                                    state_next = STOP;
                                else
                                    n_next = n_reg + 1;
                            end
                        else
                            s_next = s_reg + 1;
                    end
            end
        
        STOP:
            begin
                tx_next = 1'b1;     // single STOP bit to receiver
                if(s_tick)
                    begin
                        if(s_tick == (SB_TICK-1))
                            begin
                            tx_done_tick = 1'b1;
                            state_next = IDLE; 
                            end
                        else
                            s_next = s_reg + 1;
                    end
            end
        
        default: state_next = IDLE;

    endcase
end

// output logic
assign tx = tx_reg;

endmodule
