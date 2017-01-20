module SensorTest(LEDR,GPIO_1,GPIO_0,CLOCK_50);
input [35:0]GPIO_1;
input CLOCK_50;
input [35:0]GPIO_0;
output [9:0] LEDR;

wire receiver;
reg led;
assign LEDR[0] = led;
assign receiver = GPIO_1[1];

always@(*)
begin
led<= 1'b0;
if(receiver == 1'b1)
led <= 1'b1;
else
led<= 1'b0;
end

endmodule 
