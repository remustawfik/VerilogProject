

module OnePunchMan(CLOCK_50, KEY,VGA_CLK,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N,VGA_R,VGA_G,VGA_B);

input CLOCK_50;
input [3:0] KEY;

wire [8:0] xVGA;
wire [7:0] yVGA;
wire [8:0] xCtrl;
wire [7:0] yCtrl;
wire [2:0] colourVGA;
wire [13:0] address;
wire [2:0] addressColour;


//Flags
wire plotIt;
wire SoDone;
wire right;
wire reset;
wire delete;
wire dataDel;
wire startDraw;

assign reset = KEY[0];
assign plotIt = ~KEY[1];
assign right = ~KEY[2];
assign center = ~KEY[3];


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
		
		
control pupperz(CLOCK_50,reset,SoDone,plotIt,center,right,xCtrl,yCtrl,dataDel,startDraw);
datapath PUPPER(CLOCK_50,reset,plotIt,SoDone,xCtrl,yCtrl,xVGA,yVGA,address);	
			
endmodule 

//-------------------------------------------------------------------------------------
module control(clk,reset,DoneCtrl,PlotCtrl,centerflag,rightFlag,xout,yout,delpls,draw);

input clk,reset,DoneCtrl,PlotCtrl,centerflag,rightFlag;
//input [2:0] cin;
output reg [8:0] xout;
output reg [7:0] yout;
//output reg [2:0] cout;
output reg delpls,draw;


reg [5:0] current_state, next_state; 
    
    localparam  S_Reset         = 3'd0, 
					 S_StartAnimation= 3'd1, 
					 S_Right         = 3'd2,
					 S_Left          = 3'd3,
					 S_Center        = 3'd4,
					 S_Done          = 3'd5, 
					 S_Delete        = 3'd6;
					 
					 
	always@(*)
   
		 begin: state_table 
				 
			  case (current_state)
					  
				S_Reset: next_state =  PlotCtrl ? S_StartAnimation: S_Reset;
				
				S_StartAnimation: 
											if(centerflag)
											next_state = S_Center;
											else
											next_state = rightFlag ? S_Right : S_Left;
				
				S_Right : next_state = DoneCtrl ? S_Done : S_Right;
				
				S_Left : next_state = DoneCtrl ? S_Done : S_Left;
				
				S_Center: next_state = DoneCtrl ? S_Done : S_Center;
				
				S_Done: next_state = S_Reset;
				
//				S_Delete: next_state = S_Reset;
				
				
				default:
				next_state= S_Reset;
					
		 endcase
   end
 
 always @(*)
  
  begin: enable_signals
       
  
 case (current_state)
           

	S_Reset: begin
	
//	xout = 9'd0;
//	yout = 8'd0;
//	draw = 1'b0;
		
   end
	
	S_Right: begin
	
	xout = 9'd160;
	yout = 8'd70;
	//draw = 1'b1;
	
	end
	
	S_Left: begin
	
   xout = 9'd80;
	yout = 8'd70;
	//draw = 1'b1;
	
	end
	
	S_Center: begin
	
   xout = 9'd120;
	yout = 8'd70;
	//draw = 1'b1;
	
	end
	
//	S_Delete: begin
//	
//	
//  xout = 9'd80;
//	yout = 8'd70;
//	cout = 3'b000;
//	draw = 1'b1;
//	
//   end
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
 
 
 module datapath(clk,resetData, start,DoneData,Xin,Yin,Xout,Yout,counter);
 
 input clk,resetData,start;
 
 input [8:0] Xin;
 input [7:0] Yin;
 output reg [8:0] Xout;
 output reg [7:0] Yout;
 output reg DoneData;

 output reg [13:0]counter;
 wire [8:0] Xlimit;
 wire [7:0] Ylimit;
 
 //add 80
 assign Xlimit = Xin + 9'd80;
 //add 120
 assign Ylimit = Yin + 8'd120;
 
 always@(posedge clk)
   begin
	if(!resetData)
		begin
			Xout <= Xin;
			Yout <= Yin;
			DoneData <= 1'b0;
			counter <= 14'd0;
		end
	
	if(start)
	begin
	if(Xout == Xlimit && Yout < Ylimit)
		begin
		Xout <= Xin;
		Yout <= Yout + 1'b1;
		DoneData <= 1'b0;
		end
	if(Yout == Ylimit)
		begin
		DoneData <= 1'b1;
		end
	if(Xout < Xlimit && Yout < Ylimit)
		begin
			counter <= counter + 1'b1;
			Xout <= Xout + 1'b1;
			DoneData <= 1'b0;
		end
	end
	end
	
endmodule
 
// 
//module OnePunchMan(CLOCK_50, KEY,VGA_CLK,VGA_HS,VGA_VS,VGA_BLANK_N,VGA_SYNC_N,VGA_R,VGA_G,VGA_B);
//
//input CLOCK_50;
//input [3:0] KEY;
//
//wire [8:0] xVGA;
//wire [7:0] yVGA;
//wire [2:0] colourVGA;
//wire [13:0] address;
//wire plotIt;
//wire SoDone;
//wire reset;
//
//assign reset = KEY[0];
//assign plotIt = ~KEY[1];
//
//
//output			VGA_CLK;   				//	VGA Clock
//output			VGA_HS;					//	VGA H_SYNC
//output			VGA_VS;					//	VGA V_SYNC
//output			VGA_BLANK_N;		   //	VGA BLANK
//output			VGA_SYNC_N;				//	VGA SYNC
//output	[9:0]	VGA_R;   				//	VGA Red[9:0]
//output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
//output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
//
//
//Boxer cat(address,CLOCK_50,3'b000,1'b0,colourVGA);
//
//vga_adapter VGA(
//			.resetn(reset),
//			.clock(CLOCK_50),
//			.colour(colourVGA),
//			.x(xVGA),
//			.y(yVGA),
//			.plot(plotIt),
//			.VGA_R(VGA_R),
//			.VGA_G(VGA_G),
//			.VGA_B(VGA_B),
//			.VGA_HS(VGA_HS),
//			.VGA_VS(VGA_VS),
//			.VGA_BLANK(VGA_BLANK_N),
//			.VGA_SYNC(VGA_SYNC_N),
//			.VGA_CLK(VGA_CLK));
//			
//		defparam VGA.RESOLUTION = "320x240";
//		defparam VGA.MONOCHROME = "FALSE";
//		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
//		defparam VGA.BACKGROUND_IMAGE = "bannertoo.mif";
//		
//		
//control pupperz(CLOCK_50,reset,SoDone,plotIt);
//datapath PUPPER(CLOCK_50,reset,plotIt,SoDone,xVGA,yVGA,address);	
//			
//endmodule 
//
////-------------------------------------------------------------------------------------
//module control(clk,reset,DoneCtrl,PlotCtrl);
//
//input clk,reset,DoneCtrl,PlotCtrl;
//
//reg [5:0] current_state, next_state; 
//    
//    localparam  S_Reset         = 3'd0, 
//					 S_StartAnimation= 3'd1,                
//					 S_Done          = 3'd2;
//					 
//					 
//	always@(*)
//   
//		 begin: state_table 
//				 
//			  case (current_state)
//					  
//				S_Reset: next_state =  PlotCtrl ? S_StartAnimation: S_Reset;
//				
//				S_StartAnimation: next_state = DoneCtrl ? S_Done : S_StartAnimation;
//				
//				S_Done: next_state = S_Reset;
//				
//				
//				default:
//					next_state= S_Reset;
//					
//		 endcase
//   end
//// 
//// always @(*)
////  
////  begin: enable_signals
////       
//// 
////  load_Done = 1'b0; 
////  
////  
//// case (current_state)
////           
////
////	S_Reset: begin
////	
////	
////		
////   end
////	
////	S_StartAnimation: begin
////	
////	end
////	
////	S_Done: begin
////	
////	
////   end
////endcase
////end
//
//// current_state registers
//  
//always@(posedge clk)
//  
//   begin: state_FFs
//     
//      if(!reset)       
//         current_state <= S_Reset; 
//      else            
//		   current_state <= next_state;
// 
//   end // state_FFS
//
// 
// endmodule
// 
// //----------------------------------------------------------------------------------------------
// 
// 
// module datapath(clk,resetData, PlotData, DoneData,Xout,Yout,counter);
// 
// input clk,resetData,PlotData;
// output reg [8:0] Xout;
// output reg [7:0] Yout;
// //output reg [2:0] Cout;
// output reg DoneData;
//
//// reg [8:0] Xorigin;
//// reg [7:0] Yorigin;
//// reg [2:0] regColor;
// output reg [13:0]counter;
// wire [8:0] Xlimit;
// wire [7:0] Ylimit;
// 
// assign Xlimit = 9'd160 +  9'd80;
// assign Ylimit = 8'd70 + 8'd120;
// 
// always@(posedge clk)
//   begin
//	if(!resetData)
//		begin
//			Xout <= 9'd160;
//			Yout <= 8'd70;
//			DoneData <= 1'b0;
//			counter <= 15'b0;
//			//Cout <= 3'b001 ;
//		end
//	
//	if(PlotData)
//	begin
//	if(Xout == Xlimit && Yout < Ylimit)
//		begin
//		Xout <= 9'd160;
//		Yout <= Yout + 1'b1;
//		DoneData <= 1'b0;
//		end
//	if(Yout == Ylimit)
//		begin
//		DoneData <= 1'b1;
//		end
//	if(Xout < Xlimit && Yout < Ylimit)
//		begin
//			counter <= counter + 1'b1;
//			Xout <= Xout + 1'b1;
//		end
//	end
//	end
//	
//endmodule
// 
// //120: 1111000
// //80: 1010000
// //60: 111100
// //160:10100000
// //70:01000110
// 					 
//					