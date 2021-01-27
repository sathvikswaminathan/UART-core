//=================================================
// BAUD generator to generate sampling signal
// chosen baud rate = 19200. system clock: 50-Mhz
// sampling rate = 19200 * 16 = 307200-Hz
// mod (50-Mhz/307200-Hz) = mod-163 counter(8 bits)
//=================================================

module counter
#(
    parameter N = 8,
    parameter M = 163
 )
// IO ports
(
    input wire clk, reset,
    output wire tick
);

// internal signal declaration
reg [N-1:0] r_reg;
wire [N-1:0] r_next;

// body
// register
always @(posedge clk) 
begin
    if(reset)
        r_reg <= 0;
    else
        r_reg <= r_next;
end

// FSM next-state logic
assign r_next = (r_reg == (M-1)) ? 1'b0 : r_reg + 1;

//output logic
assign tick = (r_reg == (M-1));

endmodule
