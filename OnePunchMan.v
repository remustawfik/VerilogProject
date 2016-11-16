module OnePunchMan(CLOCK_50, KEY,VGA_CLK,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N,VGA_R,VGA_G,VGA_B);

input CLOCK_50;
input [3:0] KEY;

wire [8:0] xVGA;
wire [7:0] yVGA;
wire [2:0] colourVGA;
wire [13:0] address;
wire plotIt;
wire SoDone;
wire reset;

assign reset = KEY[0];
assign plotIt = ~KEY[1];


output			VGA_CLK;   				//	VGA Clock
output			VGA_HS;					//	VGA H_SYNC
output			VGA_VS;					//	VGA V_SYNC
output			VGA_BLANK_N;		   //	VGA BLANK
output			VGA_SYNC_N;				//	VGA SYNC
output	[9:0]	VGA_R;   				//	VGA Red[9:0]
output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
output	[9:0]	VGA_B;   				//	VGA Blue[9:0]


Boxer cat(address,CLOCK_50,3'b000,1'b0,colourVGA);

vga_adapter VGA(
			.resetn(reset),
			.clock(CLOCK_50),
			.colour(colourVGA),
			.x(xVGA),
			.y(yVGA),
			.plot(plotIt),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
			
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "bannertoo.mif";
		
		
control pupperz(CLOCK_50,reset,SoDone,plotIt);
datapath PUPPER(CLOCK_50,reset,plotIt,SoDone,xVGA,yVGA,address);	
			
endmodule 

//-------------------------------------------------------------------------------------
module control(clk,reset,DoneCtrl,PlotCtrl);

input clk,reset,DoneCtrl,PlotCtrl;

reg [5:0] current_state, next_state; 
    
    localparam  S_Reset         = 3'd0, 
					 S_StartAnimation= 3'd1,                
					 S_Done          = 3'd2;
					 
					 
	always@(*)
   
		 begin: state_table 
				 
			  case (current_state)
					  
				S_Reset: next_state =  PlotCtrl ? S_StartAnimation: S_Reset;
				
				S_StartAnimation: next_state = DoneCtrl ? S_Done : S_StartAnimation;
				
				S_Done: next_state = S_Reset;
				
				
				default:
					next_state= S_Reset;
					
		 endcase
   end
// 
// always @(*)
//  
//  begin: enable_signals
//       
// 
//  load_Done = 1'b0; 
//  
//  
// case (current_state)
//           
//
//	S_Reset: begin
//	
//	
//		
//   end
//	
//	S_StartAnimation: begin
//	
//	end
//	
//	S_Done: begin
//	
//	
//   end
//endcase
//end

// current_state registers
  
always@(posedge clk)
  
   begin: state_FFs
     
      if(!reset)       
         current_state <= S_Reset; 
      else            
		   current_state <= next_state;
 
   end // state_FFS

 
 endmodule
 
 //----------------------------------------------------------------------------------------------
 
 
 module datapath(clk,resetData, PlotData, DoneData,Xout,Yout,counter);
 
 input clk,resetData,PlotData;
 output reg [8:0] Xout;
 output reg [7:0] Yout;
 //output reg [2:0] Cout;
 output reg DoneData;

// reg [8:0] Xorigin;
// reg [7:0] Yorigin;
// reg [2:0] regColor;
 output reg [13:0]counter;
 
 
 always@(posedge clk)
   begin
	if(!resetData)
		begin
			Xout <= 9'b001111000;
			Yout <= 8'b01000110;
			DoneData <= 1'b0;
			counter <= 15'b0;
			//Cout <= 3'b001 ;
		end
	
	if(PlotData)
	begin
	if(Xout == 9'b011001000 && Yout < 8'b10111110)
		begin
		Xout <= 9'b001111000;
		Yout <= Yout + 1'b1;
		DoneData <= 1'b0;
		end
	if(Yout == 8'b10111110)
		begin
		DoneData <= 1'b1;
		end
	if(Xout < 9'b011001000 && Yout < 8'b10111110)
		begin
			counter <= counter + 1'b1;
			Xout <= Xout + 1'b1;
		end
	end
	end
	
endmodule
 
 
					 
					