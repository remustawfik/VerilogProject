

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


Boxer cat(address,CLOCK_50,3'b000,1'b0,addressColour);

assign colourVGA = dataDel ? 3'b000 : addressColour;

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
		
control pupperz(CLOCK_50,reset,SoDone,plotIt,center,right,xCtrl,yCtrl,dataDel);
datapath PUPPER(CLOCK_50,reset,plotIt,SoDone,xCtrl,yCtrl,xVGA,yVGA,address,dataDel);	
			
endmodule 

//-------------------------------------------------------------------------------------
module control(clk,reset,DoneCtrl,PlotCtrl,centerflag,deleteFlag,xout,yout,delpls);

input clk,reset,DoneCtrl,PlotCtrl,centerflag,deleteFlag;
//input [2:0] Cin;
output reg [8:0] xout;
output reg [7:0] yout;
//output reg [2:0] Cout;
output reg delpls;



reg [5:0] current_state, next_state; 
    
    localparam  S_Reset         = 3'd0, 
					 S_StartAnimation= 3'd1, 
					 S_Center         = 3'd2,
					 S_Delete          = 3'd3,
					 S_Done          = 3'd4;
					 
					 
	always@(*)
   
		 begin: state_table 
				 
			  case (current_state)
					  
				S_Reset: next_state =  PlotCtrl ? S_StartAnimation: S_Reset;
				
				S_StartAnimation: next_state = deleteFlag ? S_Center : S_Delete;
				
				S_Center : next_state = DoneCtrl ? S_Done : S_Center;
				
				S_Delete : next_state = DoneCtrl ? S_Done : S_Delete;
				
				S_Done: next_state = S_Reset;
				
//				S_Delete: next_state = S_Reset;
				
				
				default:
				next_state= S_Reset;
					
		 endcase
   end
 
 always @(*)
  
  begin: enable_signals
       
  
 case (current_state)
           
	
	S_Center: begin
	
	xout = 9'd120;
	yout = 8'd70;
	delpls = 1'b0;
	//Cout = Cin;
	
	end
	
	S_Delete: begin
	
   xout = 9'd0;
	yout = 8'd70;
	delpls = 1'b1;
	//Cout = 3'b000;
	
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
 
 
 module datapath(clk,resetData, start,DoneData,Xin,Yin,Xout,Yout,counter,delete);
 
 input clk,resetData,start,delete;
 
 input [8:0] Xin;
 input [7:0] Yin;
 output reg [8:0] Xout;
 output reg [7:0] Yout;
 output reg DoneData;
 output reg [13:0]counter;
 wire [8:0] Xlimit;
 wire [7:0] Ylimit;
 
 
 
 assign Xlimit = delete ? (Xin + 9'd320) : (Xin + 9'd80);
 assign Ylimit = Yin + 8'd120;

 //--------------------------------------------------------
//	always@(posedge CLOCK_50)
//	begin
//		if((clear1 == 1'b1)|(reset == 1'b1))
//			count1 <= 28'd0;
//		else
//			count1 <= count1 + 1'b1;
//	end
//
//	assign clear1 = Enable;
//	assign Enable = (count1 == maxCount) ? 1'b1 : 1'b0;
//
//	always@(posedge CLOCK_50)
//	begin
//		if(reset == 1'b1)
//			count2 <= 4'b0000;
//		else if(Enable == 1'b1)
//			count2 <= count2 + 1'b1;
//		else
//			count2 <= count2;
//	end
//---------------------------------------------------------
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
	  if(!delete)
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
	 else
		begin
		if(Xout == 9'd320 && Yout < 9'd190)
			begin
			Xout <= 9'd0;
			Yout <= Yout + 1'b1;
			DoneData <= 1'b0;
			counter <= 1'b0;
			end
		if(Yout == 9'd190)
			begin
			counter <= 1'b0;
			DoneData <= 1'b1;
			end
		if(Xout < 9'd320 && Yout < 9'd190)
			begin
				counter <= 1'b0;
				Xout <= Xout + 1'b1;
				DoneData <= 1'b0;
			end
		
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