
module FinalProject(CLOCK_50,KEY,LEDR,SW,GPIO_0,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,VGA_CLK,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N,VGA_R,VGA_G,VGA_B);

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
output [6:0] HEX2;
output [6:0] HEX3;
output [6:0] HEX4;
output [6:0] HEX5;


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
wire [2:0] addressMissed;
wire [2:0] addressCenterShuffle;
wire [2:0] addressRightShuffle;
wire [2:0] addressLeftShuffle;
reg endSignal;

//variables to count to 60 
reg [31:0] Time;
wire clearTimer;
wire HexEnabler1;
wire HexEnabler2;
reg stopTimer;
reg [3:0]HexWrite1;
reg [3:0]HexWrite2;

//Flags
wire plot,reset,start;

//datapath output flags
wire Ddraw,Dwait,DWaitHit;
wire [3:0] SelectImage;

//control output flags
wire Swait,SwaitHit,SDraw,Sreset,SResEnd;

//Hit flags
wire hitCenter,hitRight;
reg [3:0]scorePlayer1;
reg [3:0]scorePlayer2;
reg [3:0]scoreEnemy1;
reg [3:0]scoreEnemy2;
wire correct;
wire missed;
//wire value;
//assign hitCenter = GPIO_0[1];
//assign hitRight = GPIO_0[3];
assign hitCenter = ~KEY[2];
assign hitRight = ~KEY[3];
assign LEDR[0] = hitCenter;
assign LEDR[1] = hitRight;
//assign value = hitCenter | hitRight;


always@(posedge correct)
begin
	if(start)
		begin
		scorePlayer1 <= 4'b0000;
		scorePlayer2 <= 4'b0000;
		end
	else if(scorePlayer1<4'b1001)
		scorePlayer1 <= scorePlayer1 + 4'b0001;
	else if(scorePlayer1 == 4'b1001)
		begin
		scorePlayer1 <= 4'b0000;
		scorePlayer2 <= scorePlayer2 + 4'b0001;
		end
	else
		begin
		scorePlayer1 <= scorePlayer1;
		scorePlayer2 <= scorePlayer2;
		end
end 

always@(posedge missed)
begin
	if(start)
		begin
		scoreEnemy1 <= 4'b0000;
		scoreEnemy2 <= 4'b0000;
		end
	else if(scoreEnemy1<4'b1001)
		scoreEnemy1 <= scoreEnemy1 + 4'b0001;
	else if(scoreEnemy1 == 4'b1001)
		begin
		scoreEnemy1 <= 4'b0000;
		scoreEnemy2 <= scoreEnemy2 + 4'b0001;
		end
	else
		begin
		scoreEnemy1 <= scoreEnemy1;
		scoreEnemy2 <= scoreEnemy2;
		end
end 

//calling sprites
assign reset = KEY[0];
assign start = ~KEY[1];

Center cat(address,CLOCK_50,3'b000,1'b0,addressColourCenter);
BoxerRight kitty(address,CLOCK_50,3'b000,1'b0,addressColourRight);
BoxerLeft  kittycat(address,CLOCK_50,3'b000,1'b0,addressColourLeft);
Hit doggo(address,CLOCK_50,3'b000,1'b0,addressColourHit);
EndScreen dogger(address,CLOCK_50,3'b000,1'b0,addressEnding);
Missed puppier(address,CLOCK_50,3'b000,1'b0,addressMissed);
JiggleCenter puppier2(address,CLOCK_50,3'b000,1'b0,addressCenterShuffle);
RightShuffle puppier3(address,CLOCK_50,3'b000,1'b0,addressRightShuffle);
LeftShuffle puppier4(address,CLOCK_50,3'b000,1'b0,addressLeftShuffle);

//---------------------------------------------------------------------

always@(*)
begin
	case(SelectImage)
	
	4'b0000: colourVGA = addressEnding;
	4'b0001: colourVGA = addressColourCenter;
	4'b0010: colourVGA = addressColourRight;
	4'b0011: colourVGA = addressColourLeft;
	4'b0100: colourVGA = addressColourHit;
	4'b0110: colourVGA = addressMissed; 
	4'b0101: colourVGA = addressCenterShuffle;
	4'b0111: colourVGA = addressRightShuffle;
	4'b1000: colourVGA = addressLeftShuffle;
	
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
		else if(stopTimer)
		   HexWrite1 <= 4'b0000;
		else if(HexWrite1 == 4'b1010)
			HexWrite1 <= 4'b0000;	
		else if((HexEnabler1 == 1'b1))
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
			stopTimer <= 1'b0;
		end
		else if((HexEnabler2 == 1'b1) && HexWrite2<4'b0110)
			HexWrite2 <= HexWrite2 + 1'b1;
	   else if(HexWrite2 == 4'b0110)
		   begin
			endSignal <= 1'b1;
			stopTimer <= 1'b1;
			end
		else if(HexWrite2 > 4'b0110)
		   begin
			stopTimer <= 1'b1;
			HexWrite2 <= HexWrite2;
			end
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
		defparam VGA.BACKGROUND_IMAGE = "Background.mif";
		
control pupperz(CLOCK_50,reset,Ddraw,Dwait,DWaitHit,start,Sreset,SDraw,Swait,SwaitHit,SelectImage,endSignal,SResEnd,hitCenter,hitRight,correct,missed);
datapath PUPPER(CLOCK_50,Sreset,Ddraw,Dwait,DWaitHit,xVGA,yVGA,address,Swait,SwaitHit,SDraw,endSignal,SResEnd);

hex_decoder BOI(HexWrite1, HEX0);
hex_decoder BOII(HexWrite2, HEX1);
hex_decoder BOIII(scorePlayer1,HEX2);
hex_decoder BOIIII(scorePlayer2,HEX3);
hex_decoder BOIIIII(scoreEnemy1,HEX4);
hex_decoder BOIIIIII(scoreEnemy2,HEX5);
			
endmodule 

//-------------------------------------------------------------------------------------
module control(clk,reset,DoneDraw,DoneWait,DoneWaitHit,PlotCtrl,startReset,startDraw,startWait,startWaitHit,SelectImag,endS,startResEnd,HitCenter,HitRight,gotHit,gotMissed);

input clk,DoneDraw,PlotCtrl,DoneWait,DoneWaitHit,reset,endS,HitCenter,HitRight;
output reg startReset,startResEnd,startDraw,startWait,startWaitHit;
output reg [3:0] SelectImag;
output reg gotHit,gotMissed;

reg [1:0] counter;

reg [5:0] current_state, next_state; 
    
    localparam  S_GameStart      = 6'd0,
					 S_StartAnimation = 6'd1, 
					 //---------------------
					 S_CenterOne      = 6'd2,
					 S_ResetCOne      = 6'd3,
					 S_Wait_CenterOne = 6'd4,
					 //---------------------
					 S_Center_ShuOne  = 6'd5,
					 S_ResetShuOne    = 6'd6,
					 S_Wait_CShuOne   = 6'd7,
					 //---------------------
					 S_CenterTwo      = 6'd8,
					 S_ResetCTwo      = 6'd9,
					 S_Wait_CenterTwo = 6'd10,
					 //---------------------
					 S_Center_ShuT    = 6'd11,
					 S_ResetShuT      = 6'd12,
					 S_Wait_CShuT     = 6'd13,
					 //---------------------
					 S_RightOne       = 6'd14,
					 S_ResetROne      = 6'd15,
					 S_Wait_RightOne  = 6'd16,
					 //----------------------
					 S_Right_Shu      = 6'd17,
					 S_ResetRShu      = 6'd18,
					 S_Wait_RightShu  = 6'd19,
					 //----------------------
					 S_RightTwo       = 6'd20,
					 S_ResetRTwo      = 6'd21,
					 S_Wait_RightTwo  = 6'd22,
					 //----------------------
					 S_CenterThree    = 6'd23,
					 S_ResetCThree    = 6'd24,
					 S_Wait_CThree    = 6'd25,
					 //---------------------
					 S_Center_ShuTwo  = 6'd26,
					 S_ResetShuTwo    = 6'd27,
					 S_Wait_CShuTwo   = 6'd28,
					 //---------------------
					 S_CenterFour     = 6'd29,
					 S_ResetCFour     = 6'd30,
					 S_Wait_CFour     = 6'd31,
					 //---------------------
					 S_LeftOne        = 6'd32,
					 S_ResetLOne      = 6'd33,
					 S_Wait_LeftOne   = 6'd34,
					 //---------------------
					 S_LeftShu        = 6'd35,
					 S_ResetLShu      = 6'd36,
					 S_Wait_LeftShu   = 6'd37,
					 //----------------------
					 S_LeftTwo        = 6'd38,
					 S_ResetLTwo      = 6'd39,
					 S_Wait_LeftTwo   = 6'd40,
					 //----------------------
					 S_ResetHitOne    = 6'd41,
					 S_Hit            = 6'd42,
					 S_ResetHitTwo    = 6'd43,
					 S_WaitHit        = 6'd44,
					 //----------------------
					 S_ResetMissedOne = 6'd45,
					 S_Missed         = 6'd46,
					 S_ResetMissedTwo = 6'd47,
					 S_WaitMissed     = 6'd48,
					 //----------------------
					 S_ResetEnd       = 6'd49,
					 S_EndScreen      = 6'd50,
					 S_Done           = 6'd51;
					 
					 
	always@(*)
   
		 begin: state_table 
		 	 
			  case (current_state)
					  
				S_GameStart: next_state = PlotCtrl ? S_StartAnimation : S_GameStart;
			
				S_StartAnimation: next_state = endS ? S_ResetEnd : S_CenterOne;
				
				//The Center Cycle
				
				S_CenterOne : next_state = DoneDraw ? S_ResetCOne : S_CenterOne;
				
				S_ResetCOne: next_state =  S_Wait_CenterOne;           
				
				S_Wait_CenterOne: if(HitCenter)
										begin
										gotHit = 1'b1;
									   gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitRight)
										begin
										gotHit = 1'b0;
									   gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										next_state = S_Center_ShuOne;
									else if(endS)
										next_state = S_ResetEnd;
				               else
										next_state = S_Wait_CenterOne;
				
				//----------------------------------
				
				S_Center_ShuOne : next_state = DoneDraw ? S_ResetShuOne : S_Center_ShuOne;
				
				S_ResetShuOne: next_state =  S_Wait_CShuOne;           
				
				S_Wait_CShuOne: 
									if(HitCenter)
										begin
										gotHit = 1'b1;
									   gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitRight)
										begin
										gotHit = 1'b0;
									   gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										next_state = S_CenterTwo;
									else if(endS)
										next_state = S_ResetEnd;
				               else
										next_state = S_Wait_CShuOne;
				
				//-----------------------------------------		
				
				S_CenterTwo : next_state = DoneDraw ? S_ResetCTwo : S_CenterTwo;
				
				S_ResetCTwo: next_state =  S_Wait_CenterTwo;           
				
				S_Wait_CenterTwo: 
								  if(HitCenter)
										begin
										gotHit = 1'b1;
									   gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitRight)
										begin
										gotHit = 1'b0;
									   gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										next_state = S_Center_ShuT;
									else if(endS)
										next_state = S_ResetEnd;
				               else
										next_state = S_Wait_CenterTwo;
										
				//----------------------------------
				S_Center_ShuT: next_state = DoneDraw ? S_ResetShuT : S_Center_ShuT;
				
				S_ResetShuT: next_state =  S_Wait_CShuT;           
				
				S_Wait_CShuT: 
									if(HitCenter)
										begin
										gotHit = 1'b1;
									   gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitRight)
										begin
										gotHit = 1'b0;
									   gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										next_state = S_RightOne;
									else if(endS)
										next_state = S_ResetEnd;
				               else
										next_state = S_Wait_CShuT;
				//-----------------------------------------		
										
				//The Right Cycle
				
				S_RightOne: next_state = DoneDraw ? S_ResetROne : S_RightOne;
				
				S_ResetROne: next_state =  S_Wait_RightOne;
				
				S_Wait_RightOne:  if(HitRight)
										begin
										gotHit = 1'b1;
										gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitCenter)
										begin
									   gotHit = 1'b0;
										gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										begin
										next_state = S_Right_Shu;
										end
									else if(endS)
									   begin
										next_state = S_ResetEnd;
										end
									else
										begin
										next_state = S_Wait_RightOne;
										end
										
			   //--------------------------------------------------
				
				S_Right_Shu : next_state = DoneDraw ? S_ResetRShu : S_Right_Shu;
				
				S_ResetRShu: next_state =  S_Wait_RightShu;           
				
				S_Wait_RightShu: 
									if(HitCenter)
										begin
										gotHit = 1'b1;
									   gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitRight)
										begin
										gotHit = 1'b0;
									   gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										next_state = S_RightTwo;
									else if(endS)
										next_state = S_ResetEnd;
				               else
										next_state = S_Wait_RightShu;
				
				//-----------------------------------------------------		
				S_RightTwo: next_state = DoneDraw ? S_ResetRTwo : S_RightTwo;
				
				S_ResetRTwo: next_state =  S_Wait_RightTwo;
				
				S_Wait_RightTwo:  
									if(HitRight)
										begin
										gotHit = 1'b1;
										gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitCenter)
										begin
									   gotHit = 1'b0;
										gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										begin
										next_state = S_CenterThree;
										end
									else if(endS)
									   begin
										next_state = S_ResetEnd;
										end
									else
										begin
										next_state = S_Wait_RightTwo;
										end
			   //------------------------------------------------------
				//The Second Center Cycle
				
				S_CenterThree : next_state = DoneDraw ? S_ResetCThree : S_CenterThree;
				
				S_ResetCThree: next_state =  S_Wait_CThree;
				
				S_Wait_CThree:  if(HitCenter)
										begin
										gotHit = 1'b1;
										gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitRight)
									   begin
										gotHit = 1'b0;
										gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										begin
										next_state = S_Center_ShuTwo;
										end
									else if(endS)
									   begin
										next_state = S_ResetEnd;
										end
									else
										begin
										next_state = S_Wait_CThree;
										end 	
	
				
				//----------------------------------
				
				S_Center_ShuTwo : next_state = DoneDraw ? S_ResetShuTwo : S_Center_ShuTwo;
				
				S_ResetShuTwo: next_state =  S_Wait_CShuTwo;           
				
				S_Wait_CShuTwo: 
									if(HitCenter)
										begin
										gotHit = 1'b1;
									   gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitRight)
										begin
										gotHit = 1'b0;
									   gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										next_state = S_CenterFour;
									else if(endS)
										next_state = S_ResetEnd;
				               else
										next_state = S_Wait_CShuTwo;
				
				//-----------------------------------------		
				
				S_CenterFour : next_state = DoneDraw ? S_ResetCFour : S_CenterFour;
				
				S_ResetCFour: next_state =  S_Wait_CFour;           
				
				S_Wait_CFour: 
								  if(HitCenter)
										begin
										gotHit = 1'b1;
									   gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitRight)
										begin
										gotHit = 1'b0;
									   gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										next_state = S_LeftOne;
									else if(endS)
										next_state = S_ResetEnd;
				               else
										next_state = S_Wait_CFour;
										
				//----------------------------------------------
				
				S_LeftOne : next_state = DoneDraw ? S_ResetLOne : S_LeftOne;
				
				S_ResetLOne: next_state =  S_Wait_LeftOne;
				
				S_Wait_LeftOne:   if(HitRight)
										begin
										gotHit = 1'b1;
										gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitCenter)
									   begin
										gotHit = 1'b0;
										gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										begin
										next_state = S_LeftShu;
										end
									else if(endS)
									   begin
										next_state = S_ResetEnd;
										end
									else
										begin
										next_state = S_Wait_LeftOne;
										end  
				
				//-------------------------------------
				
				S_LeftShu : next_state = DoneDraw ? S_ResetLShu : S_LeftShu;
				
				S_ResetLShu: next_state =  S_Wait_LeftShu;
				
				S_Wait_LeftShu:  
									if(HitRight)
										begin
										gotHit = 1'b1;
										gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitCenter)
									   begin
										gotHit = 1'b0;
										gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
										end
									else if(DoneWait)
										begin
										next_state = S_LeftTwo;
										end
									else if(endS)
									   begin
										next_state = S_ResetEnd;
										end
									else
										begin
										next_state = S_Wait_LeftShu;
										end  
				
				//----------------------------------------------
				
				S_LeftTwo : next_state = DoneDraw ? S_ResetLTwo : S_LeftTwo;
				
				S_ResetLTwo: next_state =  S_Wait_LeftTwo;
				
				S_Wait_LeftTwo:   
									if(HitRight)
										begin
										gotHit = 1'b1;
										gotMissed = 1'b0;
										next_state = S_ResetHitOne;
										end
									else if(HitCenter)
									   begin
										gotHit = 1'b0;
										gotMissed = 1'b1;
										next_state = S_ResetMissedOne;
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
										next_state = S_Wait_LeftTwo;
										end  
				
				//-------------------------------------
				
				S_ResetHitOne: next_state = S_Hit;
				
				S_Hit: next_state = DoneDraw ? S_ResetHitTwo : S_Hit;
				
				S_ResetHitTwo: next_state = S_WaitHit;
				
				S_WaitHit: next_state = DoneWaitHit ? S_StartAnimation: S_WaitHit;
				
				//--------------------------------------
				
				S_ResetMissedOne: next_state = S_Missed;
				
				S_Missed: next_state = DoneDraw ? S_ResetMissedTwo : S_Missed;
				
				S_ResetMissedTwo: next_state = S_WaitMissed;
				
				S_WaitMissed: next_state = DoneWaitHit ? S_StartAnimation: S_WaitMissed;
					
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
	SelectImag = 4'b0001;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	end
	
	//----------------------------
	
	S_CenterOne: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0001;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetCOne: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_CenterOne: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
   //----------------------------
	
	S_Center_ShuOne: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0101;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetShuOne: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_CShuOne: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
   //----------------------------
	
	S_CenterTwo: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0001;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetCTwo: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_CenterTwo: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	//----------------------------
	
	S_Center_ShuT: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0101;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetShuT: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_CShuT: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
   //----------------------------
   S_RightOne: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	end
	
   S_ResetROne: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_RightOne: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	//---------------------------------	

   S_Right_Shu: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0111;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	end
	
   S_ResetRShu: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_RightShu: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	//---------------------------------	

   S_RightTwo: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	end
	
   S_ResetRTwo: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_RightTwo: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	//---------------------------------	
	S_CenterThree: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0001;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetCThree: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_CThree: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	//----------------------------
	
	S_Center_ShuTwo: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0101;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetShuTwo: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_CShuTwo: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
   //----------------------------
	
	S_CenterFour: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0001;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetCFour: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0010;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	end
	
	S_Wait_CFour: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	//---------------------------------	
	S_LeftOne: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetLOne: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_LeftOne: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	//---------------------------------
	S_LeftShu: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b1000;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetLShu: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Wait_LeftShu: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	//---------------------------------	
	S_LeftTwo: begin

	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetLTwo: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	end
	
	S_Wait_LeftTwo: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b1;
	SelectImag = 4'b0011;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	//---------------------------------
	S_ResetHitOne:begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0100;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Hit:begin
	
	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0100;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetHitTwo:begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0001;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_WaitHit:begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0001;
	startResEnd = 1'b0;
	startWaitHit = 1'b1;
	
	end
	
	//------------------------------
	
	S_ResetMissedOne:begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0110;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_Missed:begin
	
	startReset = 1'b0;
	startDraw = 1'b1;
	startWait = 1'b0;
	SelectImag = 4'b0110;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_ResetMissedTwo:begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0001;
	startResEnd = 1'b0;
	startWaitHit = 1'b0;
	
	end
	
	S_WaitMissed:begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0001;
	startResEnd = 1'b0;
	startWaitHit = 1'b1;
	
	end
	
	//------------------------------
	S_ResetEnd: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0000;
	startResEnd = 1'b1;
	startWaitHit = 1'b0;
	end
	
	S_EndScreen: begin
	
	startReset = 1'b0;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0000;
	startResEnd = 1'b0;

	end
	
	S_Done: begin
	
	startReset = 1'b1;
	startDraw = 1'b0;
	startWait = 1'b0;
	SelectImag = 4'b0001;
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
 
 
 module datapath(clk,resetData,DoneDrawing,DoneWaiting,DoneWaitHit,Xout,Yout,Drawcount,startWait,startWaitHit,startDraw,DrawEnd,ResEnd);
 
 input clk,resetData,startDraw,startWait,startWaitHit,DrawEnd,ResEnd;
 
 //output flags
 output reg DoneDrawing,DoneWaiting,DoneWaitHit;
 
 //accessing memory block and VGA
 output reg [15:0] Drawcount;
 output reg [8:0] Xout;
 output reg [7:0] Yout;
 
 reg [27:0] timer1;
 reg [27:0] timer2;
 
 wire clearDraw,clearHit;
 
 //counts to 2 seconds Center
 
	always@(posedge clk)
	begin
	if(clearHit | resetData)
			begin
			timer2 <= 28'd0;
			DoneWaitHit <= 1'b0;
			end
	if(startWaitHit)
			timer2 <= timer2 + 1'b1;
	if(timer2 == 28'd50000000)
			begin
	      DoneWaitHit <= 1'b1;
			end
	end

  assign clearHit = DoneWaitHit;
 //counts to 0.5 seconds Center
 
	always@(posedge clk)
	begin
	if(clearDraw | resetData)
			begin
			timer1 <= 28'd0;
			DoneWaiting <= 1'b0;
			end
	if(startWait)
			timer1 <= timer1 + 1'b1;
	if(timer1 == 28'd10000000)
			begin
	      DoneWaiting <= 1'b1;
			end
	end

	assign clearDraw = DoneWaiting;

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
