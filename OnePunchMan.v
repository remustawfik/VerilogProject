

module OnePunchMan(CLOCK_50, KEY,LEDR,VGA_CLK,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N,VGA_R,VGA_G,VGA_B);

input CLOCK_50;
input [3:0] KEY;

output			VGA_CLK;   				//	VGA Clock
output			VGA_HS;					//	VGA H_SYNC
output			VGA_VS;					//	VGA V_SYNC
output			VGA_BLANK_N;		   //	VGA BLANK
output			VGA_SYNC_N;				//	VGA SYNC
output	[9:0]	VGA_R;   				//	VGA Red[9:0]
output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
output [9:0] LEDR;

wire [8:0] xVGA;
wire [7:0] yVGA;
wire [2:0] colourVGA;
wire [13:0] address;
wire [2:0] addressColour;


//Flags
wire plot,reset,start;

//datapath output flags
wire Ddraw,Dwait,Ddel;

//control output flags
wire Swait,Sdel,SresetDel,Cycle;


assign reset = KEY[0];
assign start = ~KEY[1];
assign LEDR[0] = Ddraw; 

centerpose cat(address,CLOCK_50,3'b000,1'b0,addressColour);

assign colourVGA = Sdel ? 3'b000 : addressColour;
assign plot = 1'b1;

vga_adapter VGA(
			.resetn(reset),
			.clock(CLOCK_50),
			.colour(colourVGA),
			.x(xVGA),
			.y(yVGA),
			.plot(plot),
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
		
control pupperz(CLOCK_50,reset,Ddraw,Ddel,Dwait,start,Sdel,Swait,SresetDel,Cycle);
datapath PUPPER(CLOCK_50,reset,start,Ddraw,Ddel,Dwait,xVGA,yVGA,address,Sdel,Swait,SresetDel,Cycle);
			
endmodule 

//-------------------------------------------------------------------------------------
module control(clk,reset,DoneDraw,DoneDel,DoneWait,PlotCtrl,startDel,startWait,startresetDel,cycle);

input clk,reset,DoneDraw,PlotCtrl,DoneDel,DoneWait;
output reg startDel,startWait,startresetDel,cycle;



reg [5:0] current_state, next_state; 
    
    localparam  S_Reset          = 3'd0, 
					 S_StartAnimation = 3'd1, 
					 S_Center         = 3'd2,
					 S_Wait           = 3'd3,
					 S_Delete         = 3'd4,
					 S_Done           = 3'd5;
					 
					 
	always@(*)
   
		 begin: state_table 
				 
			  case (current_state)
					  
				S_Reset: if((PlotCtrl == 1'b1) | (cycle==1'b1))
					       next_state = S_StartAnimation;
							 else
							 next_state = S_Reset;
				
				S_StartAnimation: next_state = S_Center;
				
				S_Center : next_state = DoneDraw ? S_Wait : S_Center;
				
				S_Wait: next_state = DoneWait ? S_Delete : S_Wait;
				
				S_Delete : next_state = DoneDel ? S_Done : S_Delete;
				
				S_Done: next_state = S_Reset;
				
				default:
				next_state= S_Reset;
					
		 endcase
   end
 
 always @(*)
  
  begin: enable_signals
       
  
 case (current_state)
           
	
	S_Center: begin

	startDel = 1'b0;
	startWait = 1'b0;
	startresetDel = 1'b0;
	cycle = 1'b0;
	
	end
	
	S_Wait: begin
	
	startWait = 1'b1;
	startDel = 1'b0;
	startresetDel = 1'b1;
	cycle = 1'b0;
	
	end
	
	S_Delete: begin
	
	startDel = 1'b1;
	startWait = 1'b0;
	startresetDel = 1'b0;
	cycle = 1'b0;

	end
	
	S_Done: begin
	
	startDel = 1'b0;
	startWait = 1'b0;
   startresetDel = 1'b0;
   cycle = 1'b1;	
	
	end
	
endcase
end

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
 
 
 module datapath(clk,resetData,Plot,DoneDrawing,DoneDeleting,DoneWaiting,Xout,Yout,Drawcount,startDelete,startWait,startresDel,cyc);
 
 input clk,resetData,Plot,startDelete,startWait,startresDel,cyc;
 
 //output flags
 output reg DoneDrawing,DoneDeleting;
 output DoneWaiting;
 
 //accessing memory block and VGA
 output reg [13:0] Drawcount;
 output reg [8:0] Xout;
 output reg [7:0] Yout;
 

 reg [27:0] timer;
 
 wire clear1;
 

 //counts to 4 seconds
 
	always@(posedge clk)
	begin
	if(clear1 | !resetData)
			timer <= 28'd0;	
	if(startWait)
			timer <= timer + 1'b1;
	end

	assign clear1 = DoneWaiting;
	assign DoneWaiting = (timer == 28'd100000000) ? 1'b1 : 1'b0;

//---------------------------------------------------------
 always@(posedge clk)
   begin
				if(!resetData | cyc)
					begin
						Xout <= 9'd90;
						Yout <= 8'd70;
						DoneDrawing <= 1'b0;
						Drawcount <= 14'd0;
					end
				
				if(startresDel)
				begin
						Xout <= 9'd0;
						Yout <= 8'd70;
						Drawcount <= 14'b0;
						DoneDeleting <= 1'b0;
				end
	
				if((Plot == 1'b1) | (cyc == 1'b1))
					begin
						if(Xout == 9'd220 && Yout < 8'd190)
							begin
							Xout <= 9'd90;
							Yout <= Yout + 1'b1;
							DoneDrawing <= 1'b0;
							end
						if(Yout == 8'd190)
							begin
							DoneDrawing <= 1'b1;
							end
						if(Xout < 9'd220 && Yout < 8'd190)
							begin
								Drawcount <= Drawcount + 1'b1;
								Xout <= Xout + 1'b1;
								DoneDrawing <= 1'b0;
							end
					end
				 if(startDelete & !startresDel)
						begin
						if(Xout == 9'd320 && Yout < 8'd190)
							begin
							Xout <= 9'd0;
							Yout <= Yout + 1'b1;
							DoneDeleting <= 1'b0;
							
							end
						if(Yout == 8'd190)
							begin
							DoneDeleting <= 1'b1;
							end
						if(Xout < 9'd320 && Yout < 8'd190)
							begin
								Xout <= Xout + 1'b1;
								DoneDeleting <= 1'b0;
							end
	               end

	end
	
endmodule 