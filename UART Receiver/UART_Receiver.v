

	 module UART_Receiver #(parameter word_size = 8, 								//word size parameter for shift and data registers
									half_word = word_size/2)								//half word size parameter for sample and bit registers
								  (output [word_size-1:0] RCV_datareg,					//UART receiver output
									output					  read_not_ready_out,		//output signal to indicate error with receiving data
																  Error1, Error2,				//error1 if read signal = 0, error2 if stop bit != 1
																  
									output [6:0] 			  RCV_datareg_least, 		//outputs for seven segment display ports for implementation
																  RCV_datareg_most,
																  RCV_shftreg_least, 
																  RCV_shftreg_most,
																  Sample_counter_display, 
																  Bit_counter_display,
																  
									output					  clr_Sample_counter, 		//outputs for control signal ports for implementation
																  inc_Sample_counter,
																  clr_Bit_counter, 
																  inc_Bit_counter,
																  shift,
																  load,
																  
									input						  Serial_in, 					//inputs
																  read_not_ready_in,
																  Sample_clk,
																  rst_b);
	
	//seven  segment display modules for output and internal registers
	
	//displays receiver output
	SevSeg_display D0 (RCV_datareg[half_word-1:0], RCV_datareg_least);
	SevSeg_display D1 (RCV_datareg[word_size-1:half_word], RCV_datareg_most);
	
	//statement to explicitly tell Quartus that the shift register is 8 bits for programming
	wire [word_size-1:0] RCV_shftreg;
	//displays the shifting register
	SevSeg_display D2 (RCV_shftreg[half_word-1:0], RCV_shftreg_least);
	SevSeg_display D3 (RCV_shftreg[word_size-1:half_word], RCV_shftreg_most);
	
	//statement to explicitly tell Quartus that the counters are 4 bits for programming
	wire [half_word-1:0] Sample_counter, Bit_counter;
	//displays the sample and bit counters
	SevSeg_display D4 (Sample_counter, Sample_counter_display);
	SevSeg_display D5 (Bit_counter, Bit_counter_display);
	
	 Control_Unit M0 (read_not_ready_out,		//signals that the receiver is checking for errors
						   Error1,						//states whether host is ready to receive data (from read signal)
						   Error2,						//states whether stop bit is there
						   clr_Sample_counter,		//output to datapath, clears sample counter
						   inc_Sample_counter,		//output to datapath, increments sample counter
						   clr_Bit_counter,			//output to datapath, clears bit counter
							inc_Bit_counter,			//output to datapath, increments bit counter
						   shift,						//output to datapath, shifts RCV_shftreg
						   load,							//output to datapath, loads RCV_shftreg to RCV_datareg
						   read_not_ready_in,		//ready to read input signal from user
						   Ser_in_0,					//input from datapath, flags whether input data = 0
						   SC_eq_3,						//input from datapath, checks if sample counter = 3
						   SC_lt_7,						//input from datapath, checks if sample counter < 7
						   BC_eq_8,						//input from datapath, checks if bit counter = 8
						   Sample_clk,					//sampling clock
						   rst_b);						//universal reset
						  
	DataPath_Unit M1 (RCV_datareg,				//output parallel data word
							RCV_shftreg,				//intermediate shift register (output for seven segment display)
							Sample_counter,			//sample counter (output for seven segment display)
							Bit_counter,				//bit counter (output for seven segment display)
							Ser_in_0,					//output flag to control unit
							SC_eq_3,						//output flag to control unit
							SC_lt_7,						//output flag to control unit
							BC_eq_8,						//output flag to control unit
							Serial_in,					//input serial bit from transmission
							clr_Sample_counter,		//input form control unit
							inc_Sample_counter,		//input form control unit
							clr_Bit_counter,			//input form control unit
							inc_Bit_counter,			//input form control unit
							shift,						//input form control unit
							load,							//input form control unit
							Sample_clk,					//sampling clock
							rst_b);						//universal reset
	endmodule
	
	
	
	module Control_Unit # (parameter word_size = 8,
								            half_word_size = word_size/2,
												Num_state_bits = 2,
												idle      = 2'b00,				//state parameters for state register
												starting  = 2'b01,
												receiving = 2'b10)
								 (output reg read_not_ready_out,
												 Error1, Error2,
												 clr_Sample_counter,
												 inc_Sample_counter,
												 clr_Bit_counter,
												 inc_Bit_counter,
												 shift,
												 load,
								  input		 read_not_ready_in,				
												 Ser_in_0,
												 SC_eq_3,
												 SC_lt_7,
												 BC_eq_8,
												 Sample_clk,
												 rst_b);
	
	reg [Num_state_bits-1:0] state, next_state;
	
	always @ (posedge Sample_clk)		//state register
		if (~rst_b) state <= idle;	
		else			state <= next_state;
		
	always @ (state, Ser_in_0, SC_eq_3, SC_lt_7, read_not_ready_in)
		begin		//default values
		read_not_ready_out = 0;
		Error1 				 = 0;
		Error2 				 = 0;
		clr_Sample_counter = 0;
		inc_Sample_counter = 0;
		clr_Bit_counter 	 = 0;
		inc_Bit_counter 	 = 0;
		shift 				 = 0;
		load 					 = 0;
		next_state 			 = idle;
								  
								  
		case (state)
		idle : if (Ser_in_0) next_state = starting;
				 else				next_state = idle;
		
		starting : if (Ser_in_0 == 1'b0)			//current idle bit is one, cannot start
					     begin
						  next_state = idle;
						  clr_Sample_counter = 1; end
					  else if (SC_eq_3 == 1'b1)	//enough samples confirming a zero start bit
						  begin
						  next_state = receiving;
						  clr_Sample_counter = 1; end
					  else
						  begin
						  inc_Sample_counter = 1;	//currently taking samples of zero to confirm start bit
						  next_state = starting; end
		
		receiving : if (SC_lt_7 == 1'b1)			//if # of samples for current is less than seven, keep sampling
							begin	
							inc_Sample_counter = 1;
							next_state = receiving; end
						else
							begin
							clr_Sample_counter = 1;	//if enough samples, check if bit counter = 8
								if (!BC_eq_8)			//if not, increments bit counter, and gives shift flag
									begin
									shift = 1;
									inc_Bit_counter = 1;
									next_state = receiving; end
								else
									begin							//if bit counter = 8, checks whether output has errors and restarts
									next_state = idle;
									read_not_ready_out = 1;
									clr_Bit_counter = 1;
									if (read_not_ready_in) Error1 = 1;	//if not ready to read, outputs error1
									else if (Ser_in_0) Error2 = 1;		//if there is no stop bit, outputs error2
									else load = 1; end end					//if no errors, copies shift register to data register output
		
		default: next_state = idle;
		endcase
		end
		endmodule
		
		
		
		module DataPath_Unit # (parameter word_size = 8,
													 half_word = word_size/2,
													 Num_counter_bits = 4)
									  (output reg [word_size-1:0] RCV_datareg, 
										output reg [word_size-1:0] RCV_shftreg,
										output reg [Num_counter_bits-1:0] Sample_counter,
										output reg [Num_counter_bits-1:0] Bit_counter,
										output							Ser_in_0,
																			SC_eq_3,
																			SC_lt_7,
																			BC_eq_8,
										input								Serial_in,
																			clr_Sample_counter,
																			inc_Sample_counter,
																			clr_Bit_counter,
																			inc_Bit_counter,
																			shift,
																			load,
																			Sample_clk,
																			rst_b);
		
		//feedback flags for control unit
		assign Ser_in_0 = (Serial_in == 1'b0);
		assign BC_eq_8 = (Bit_counter == word_size);
		assign SC_lt_7 = (Sample_counter < word_size-1);
		assign SC_eq_3 = (Sample_counter == half_word-1);
		
			always @ (posedge Sample_clk)
			if (!rst_b)		//universal active low reset
				begin
				Sample_counter <= 0;
				Bit_counter <= 0;
				RCV_datareg <= 0;
				RCV_shftreg <= 0; end
			else
				begin
					  if (clr_Sample_counter) 	//clears sample counter
					     Sample_counter <= 0; 
				else if (inc_Sample_counter) 	//increments sample counter
						  Sample_counter <= (Sample_counter + 1);
						  
					  if (clr_Bit_counter) 		//clears bit counter
						  Bit_counter <= 0;
				else if (inc_Bit_counter) 		//increments bit counter
						  Bit_counter <= (Bit_counter + 1);
						  
					  if (shift) 					//shifts the shft register with the serial input data
						  RCV_shftreg <= {Serial_in, RCV_shftreg [word_size-1:1]};
					  if (load) 					//loads shift register into data register
						  RCV_datareg <= RCV_shftreg;
				end
			
		endmodule
	
	
	
	module SevSeg_display (four_bits, hex_display); //module to translate 4 bits into hex on a seven segment display
	input [3:0] four_bits;
	output reg [6:0] hex_display;
	parameter BLANK = 7'b111_1111;
	parameter ONE = 7'b111_1001;
	parameter TWO = 7'b010_0100;
	parameter THREE = 7'b011_0000;
	parameter FOUR = 7'b001_1001;
	parameter FIVE = 7'b001_0010;
	parameter SIX = 7'b000_0010;
	parameter SEVEN = 7'b111_1000;
	parameter EIGHT = 7'b000_0000;
	parameter NINE = 7'b001_1000;
	parameter A = 7'b000_1000;
	parameter B = 7'b000_0011;
	parameter C = 7'b100_0110;
	parameter D = 7'b010_0001;
	parameter E = 7'b000_0110;
	parameter F = 7'b000_1110;
	parameter ZERO = 7'b100_0000;
	
	always @ (four_bits)
		case (four_bits)
			4'b0000 : hex_display = ZERO;
			4'b0001 : hex_display = ONE;
			4'b0010 : hex_display = TWO;
			4'b0011 : hex_display = THREE;
			4'b0100 : hex_display = FOUR;
			4'b0101 : hex_display = FIVE;
			4'b0110 : hex_display = SIX;
			4'b0111 : hex_display = SEVEN;
			4'b1000 : hex_display = EIGHT;
			4'b1001 : hex_display = NINE;
			4'b1010 : hex_display = A;
			4'b1011 : hex_display = B;
			4'b1100 : hex_display = C;
			4'b1101 : hex_display = D;
			4'b1110 : hex_display = E;
			4'b1111 : hex_display = F;
			default : hex_display = BLANK;
		endcase
	endmodule