
module OnePunchMan(CLOCK_50,KEY,LEDR,SW,GPIO_0,HEX0,HEX1,HEX5,HEX4,VGA_CLK,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N,VGA_R,VGA_G,VGA_B);

input CLOCK_50;
input [3:0] KEY;
input [6:0] SW;
input [35:0] GPIO_0;

//VGA variables
output VGA_CLK;   			//	VGA Clock
output VGA_HS;					//	VGA H_SYNC
output VGA_VS;					//	VGA V_SYNC
output VGA_BLANK_N;		   //	VGA BLANK
output VGA_SYNC_N;			//	VGA SYNC
output [9:0] VGA_R;   		//	VGA Red[9:0]
output [9:0] VGA_G;	 		//	VGA Green[9:0]
output [9:0] VGA_B;   		//	VGA Blue[9:0]
output [9:0] LEDR;
output [6:0] HEX0;
output [6:0] HEX1;
output [6:0] HEX5;
output [6:0] HEX4;

//Drawing the Boxer
wire [8:0] xVGA;
wire [7:0] yVGA;
reg [2:0] colourVGA;
wire [15:0] address;
wire [2:0] addressColourCenter;
wire [2:0] addressColourRight;
wire [2:0] addressColourLeft;
wire [2:0] addressColourHit;
wire [2:0] addressEnding;
reg endSignal;

//variables to count to 60 
reg [31:0] Time;
wire  clearTimer;
wire HexEnabler1;
wire HexEnabler2;
reg [3:0]HexWrite1;
reg [3:0]HexWrite2;

//Flags
wire plot,reset,start;

//datapath output flags
wire Ddraw,Dwait;
wire [2:0] SelectImage;

//control output flags
wire Swait,SDraw,Sreset,SResEnd;

//Hit flags
wire hit;
reg [4:0]score1;
reg [4:0]score2;
assign hit = GPIO_0[1];
assign LEDR[0] = hit;

always@(posedge hit)
begin
	if(start)
		begin
		score1 <= 4'b0000;
		score2 <= 4'b0000;
		end
	else if(hit && score1<4'b1001)
		score1 <= score1 + 4'b0001;
	else if((score1 == 4'b1001)  && hit)
		begin
		score1 <= 4'b0000;
		score2 <= score2 + 4'b0001;
		end
	else
		begin
		score1 <= score1;
		score2 <= score2;
		end
end 

//calling sprites
assign reset = KEY[0];
assign start = ~KEY[1];

BoxerCenter cat(address,CLOCK_50,3'b000,1'b0,addressColourCenter);
BoxerRight kitty(address,CLOCK_50,3'b000,1'b0,addressColourRight);
BoxerLeft  kittycat(address,CLOCK_50,3'b000,1'b0,addressColourLeft);
Hit        doggo(address,CLOCK_50,3'b000,1'b0,addressColourHit);
EndScreenNe  dogger(address,CLOCK_50,3'b000,1'b0,addressEnding);

//---------------------------------------------------------------------

always@(*)
begin
	case(SelectImage)
	
	3'b000: colourVGA = addressEnding;
	3'b001: colourVGA = addressColourCenter;
	3'b010: colourVGA = addressColourRight;
	3'b011: colourVGA = addressColourLeft;
	3'b100: colourVGA = addressColourHit;
	
	endcase

end

assign plot = 1'b1;

// counts to 60 seconds
	always@(posedge CLOCK_50)
	begin
	if(clearTimer | start)
			Time <= 32'd0;	
	else 
			Time <= Time + 1'b1;
	end

	assign clearTimer = HexEnabler1;
	assign HexEnabler1 = (Time == 32'd50000000) ? 1'b1 : 1'b0;
	
	always@(posedge CLOCK_50)
	begin
		if(start)
			HexWrite1 <= 4'b0000;
		else if(HexWrite1 == 4'b1010)
			HexWrite1 <= 4'b0000;	
		else if(HexEnabler1 == 1'b1 && HexWrite1 < 4'b1010)
			HexWrite1 <= HexWrite1 + 1'b1;
		else
			HexWrite1 <= HexWrite1;
	end
	
	assign HexEnabler2 = (HexWrite1 == 4'b1010) ? 1'b1 : 1'b0;
	
	always@(posedge CLOCK_50)
	begin
		if(start)
		begin
			HexWrite2 <= 4'b0000;
			endSignal <= 1'b0;
		end
		else if(HexEnabler2 == 1'b1)
			HexWrite2 <= HexWrite2 + 1'b1;
	   else if(HexWrite2 == 4'b0110)
		   endSignal <= 1'b1;
		else
			HexWrite2 <= HexWrite2;
	end

//calls modules
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
		defparam VGA.BACKGROUND_IMAGE = "bannerfinaltoo.mif";
		
control pupperz(CLOCK_50,reset,Ddraw,Dwait,start,Sreset,SDraw,Swait,SelectImage,endSignal,SResEnd,hit);
datapath PUPPER(CLOCK_50,Sreset,Ddraw,Dwait,xVGA,yVGA,address,Swait,SDraw,endSignal,SResEnd);

hex_decoder BOI(HexWrite1, HEX0);
hex_decoder BOII(HexWrite2, HEX1);
hex_decoder BOIII(score1, HEX4);
hex_decoder BOIIII(score2, HEX5);
			
endmodule 

//-------------------------------------------------------------------------------------
module control(clk,reset,DoneDraw,DoneWait,PlotCtrl,startReset,startDraw,startWait,SelectImag,endS,startResEnd,HitS);

input clk,DoneDraw,PlotCtrl,DoneWait,reset,endS,HitS;
output reg startReset,startResEnd,startDraw,startWait;
output reg [2:0] SelectImag;



reg [5:0] current_state, next_state; 
    
    localparam  S_GameStart      = 5'd0,
					 S_StartAnimation = 5'd1, 
					 //---------------------
					 S_Center         = 5'd2,
					 S_ResetC         = 5'd3,
					 S_Wait_Center    = 5'd4,
					 //---------------------
					 S_Right          = 5'd5,
					 S_ResetR         = 5'd6,
					 S_Wait_Right     = 5'd7,
					 //---------------------
					 S_Centertoo      = 5'd8,
					 S_ResetCtoo      = 5'd9,
					 S_Wait_Ctoo      = 5'd10,
					 //---------------------
					 S_Left           = 5'd11,
					 S_ResetL         = 5'd12,
					 S_Wait_Left      = 5'd13,
					 //----------------------
					 S_ResetHitOne    = 5'd14,
					 S_Hit            = 5'd15,
					 S_ResetHitTwo    = 5'd16,
					 S_WaitHit        = 5'd17,
					 //----------------------
					 S_ResetEnd       = 5'd18,
					 S_EndScreen      = 5'd19,
					 S_Done           = 5'd20;
					 
					 
	always@(*)
   
		 begin: state_table 
				 
			  case (current_state)
					  
				S_GameStart: next_state = PlotCtrl ? S_StartAnimation : S_GameStart;
							
				S_StartAnimation: next_state = endS ? S_ResetEnd : S_Center;
				
				//---------------------------------
				
				S_Center : next_state = DoneDraw ? S_ResetC : S_Center;
				
				S_ResetC: next_state =  S_Wait_Center;
				
				S_Wait_Center: if(HitS)
										begin
										next_state = S_ResetHitOne;
										end
									else if(DoneWait)
									   begin
										next_state = S_Right;
										end
									else if(endS)
									   begin
										next_state = S_ResetEnd;
										end
				               else
									   begin
										next_state = S_Wait_Center;
										end
				
				//HitS ? S_ResetHitOne : (DoneWait ? S_Right : S_Wait_Center);
				
				//----------------------------------
				
				S_Right: next_state = DoneDraw ? S_ResetR : S_Right;
				
				S_ResetR: next_state =  S_Wait_Right;
				
				S_Wait_Right:  if(HitS)
										begin
										next_state = S_ResetHitOne;
										end
									else if(DoneWait)
										begin
										next_state = S_Centertoo;
										end
									else if(endS)
									   begin
										next_state = S_ResetEnd;
										end
									else
										begin
										next_state = S_Wait_Right;
										end
				
				//HitS ? S_ResetHitOne : (DoneWait ? S_Centertoo : S_Wait_Right);
			
				//-----------------------------------
				
				S_Centertoo : next_state = DoneDraw ? S_ResetCtoo : S_Centertoo;
				
				S_ResetCtoo: next_state =  S_Wait_Ctoo;
				
				S_Wait_Ctoo:  if(HitS)
										begin
										next_state = S_ResetHitOne;
										end
									else if(DoneWait)
										begin
										next_state = S_Left;
										end
									else if(endS)
									   begin
										next_state = S_ResetEnd;
										end
									else
										begin
										next_state = S_Wait_Ctoo;
										end 	
				
				//HitS ? S_ResetHitOne : (DoneWait ? S_Left : S_Wait_Ctoo);
				
				//------------------------------------
				
				S_Left : next_state = DoneDraw ? S_ResetL : S_Left;
				
				S_ResetL: next_state =  S_Wait_Left;
				
				S_Wait_Left: if(HitS)
										begin
										next_state = S_ResetHitOne;
										end
									else if(DoneWait)
										begin
										next_state = S_Done;
										end
									else if(endS)
									   begin
										next_state = S_ResetEnd;
										end
									else
										begin
										next_state = S_Wait_Left;
										end  
				
				//HitS ? S_ResetHitOne : (DoneWait ? S_Done : S_Wait_Left);
				
				//-------------------------------------
				
				S_ResetHitOne: next_state = S_Hit;
				
				S_Hit: next_state = DoneDraw ? S_ResetHitTwo : S_Hit;
				
				S_ResetHitTwo: next_state = S_WaitHit;
				
				S_WaitHit: next_state = DoneWait ? S_StartAnimation: S_WaitHit;
				
				//--------------------------------------
				S_ResetEnd: next_state = S_EndScreen;
				
				S_EndScreen: next_state = S_EndScreen;
				
				S_Done: next_state= S_StartAnimation;
				
				default:
				next_state= S_StartAnimation;
					
		 endcase
   end
 
 always @(*)
  
  begin: enable_signals
       
  
 case (current_state)
           
	
	S_GameStart:begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 3'b001;
	startResEnd = 1'b0;
	
	end
	
	//----------------------------
	
	S_Center: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 3'b001;
	startResEnd = 1'b0;
	
	end
	
	S_ResetC: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 3'b010;
	startResEnd = 1'b0;
	
	end
	
	S_Wait_Center: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 3'b010;
	startResEnd = 1'b0;
	
	end
	
   //----------------------------
   S_Right: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 3'b010;
	startResEnd = 1'b0;
	end
	
   S_ResetR: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 3'b011;
	startResEnd = 1'b0;
	
	end
	
	S_Wait_Right: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 3'b011;
	startResEnd = 1'b0;
	
	end
	//---------------------------------
	
	S_Centertoo: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 3'b001;
	startResEnd = 1'b0;
	
	end
	
	S_ResetCtoo: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 3'b011;
	startResEnd = 1'b0;
	
	end
	
	S_Wait_Ctoo: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 3'b011;
	startResEnd = 1'b0;
	
	end
	
	//---------------------------------
	
	S_Left: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 3'b011;
	startResEnd = 1'b0;
	
	end
	
	S_ResetL: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 3'b011;
	startResEnd = 1'b0;
	
	end
	
	S_Wait_Left: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 3'b011;
	startResEnd = 1'b0;
	
	end
	
	//---------------------------------
	
	S_ResetHitOne:begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 3'b100;
	startResEnd = 1'b0;
	
	end
	
	S_Hit:begin
	
	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 3'b100;
	startResEnd = 1'b0;
	
	end
	
	S_ResetHitTwo:begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 3'b001;
	startResEnd = 1'b0;
	
	end
	
	S_WaitHit:begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 3'b001;
	startResEnd = 1'b0;
	
	end
	
	//------------------------------
	S_ResetEnd: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 3'b000;
	startResEnd = 1'b1;
	end
	
	S_EndScreen: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 3'b000;
	startResEnd = 1'b0;

	end
	
	S_Done: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 3'b001;
	startResEnd = 1'b0;
	
	end
	
endcase
end

// current_state registers
  
always@(posedge clk)
  
   begin: state_FFs
     
      if(!reset)       
         current_state <= S_GameStart; 
      else            
		   current_state <= next_state;
 
   end // state_FFS

 
 endmodule
 
 //----------------------------------------------------------------------------------------------
 
 
 module datapath(clk,resetData,DoneDrawing,DoneWaiting,Xout,Yout,Drawcount,startWait,startDraw,DrawEnd,ResEnd);
 
 input clk,resetData,startDraw,startWait,DrawEnd,ResEnd;
 
 //output flags
 output reg DoneDrawing;
 output reg DoneWaiting;
 
 //accessing memory block and VGA
 output reg [15:0] Drawcount;
 output reg [8:0] Xout;
 output reg [7:0] Yout;
 
 reg [27:0] timer1;
 
 wire clear1;

 //counts to 4 seconds Center
 
	always@(posedge clk)
	begin
	if(clear1 | resetData)
			begin
			timer1 <= 28'd0;
			DoneWaiting <= 1'b0;
			end
	if(startWait)
			timer1 <= timer1 + 1'b1;
	if(timer1 == 28'd50000000)
			begin
	      DoneWaiting <= 1'b1;
			end
	end

	assign clear1 = DoneWaiting;

//---------------------------------------------------------
 always@(posedge clk)
   begin
				if(resetData)
					begin
						Xout <= 9'd0;
						Yout <= 8'd75;
						DoneDrawing <= 1'b0;
						Drawcount <= 16'd0;
					end
				
	         //Draw Boxer
				if(startDraw)
					begin
						if(Xout == 9'd320 && Yout < 8'd240)
							begin
								Xout <= 9'd0;
								Yout <= Yout + 1'b1;
								DoneDrawing <= 1'b0;
							end
						if(Yout == 8'd240)
							begin
								DoneDrawing <= 1'b1;
							end
						if(Xout < 9'd320 && Yout < 8'd240)
							begin
								Drawcount <= Drawcount + 1'b1;
								Xout <= Xout + 1'b1;
							   DoneDrawing <= 1'b0;
							end
					end
					
				if(ResEnd)
					begin
						Xout <= 9'd0;
						Yout <= 8'd0;
						Drawcount <= 16'd0;
					end
						
				if(DrawEnd)
					begin
						if(Xout == 9'd320 && Yout < 8'd240)
							begin
								Xout <= 9'd0;
								Yout <= Yout + 1'b1;
							end
						if(Yout == 8'd240)
							begin
	                   
							end
						if(Xout < 9'd320 && Yout < 8'd240)
							begin
								Drawcount <= Drawcount + 1'b1;
								Xout <= Xout + 1'b1;
							end
					end							
	   end
	
endmodule 


module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule
