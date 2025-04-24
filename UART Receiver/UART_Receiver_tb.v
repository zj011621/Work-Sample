

	module UART_Receiver_tb();
	
	parameter word_size = 8, half_word = word_size/2;
	parameter Num_counter_bits = 4;
	parameter Num_state_bits = 2;
	
	wire [word_size-1:0] RCV_datareg;
	wire						read_not_ready_out;
	wire						Error1, Error2;
	
	wire [word_size-1:0] RCV_datareg_least, 		
								RCV_datareg_most,
								RCV_shftreg_least, 
								RCV_shftreg_most,
								Sample_counter_display, 
								Bit_counter_display;
	
	wire						clr_Sample_counter,
								inc_Sample_counter,
								clr_Bit_counter, 
								inc_Bit_counter,
								shift,
								load;
	
	reg 						Serial_in,
								read_not_ready_in,
								Sample_clk,
								rst_b;
	
	UART_Receiver UUT (RCV_datareg,
							 read_not_ready_out,
							 Error1, Error2,
							 
							 RCV_datareg_least, 		//outputs for seven segment display ports for implementation
							 RCV_datareg_most,
							 RCV_shftreg_least, 
							 RCV_shftreg_most,
							 Sample_counter_display, 
							 Bit_counter_display,
							 
							 clr_Sample_counter, 		//outputs for control signal ports for implementation
							 inc_Sample_counter,
							 clr_Bit_counter, 
							 inc_Bit_counter,
							 shift,
							 load,
							 
							 Serial_in,
							 read_not_ready_in,
							 Sample_clk,
							 rst_b);
							 
	//internal probes
	wire SC_eq_3;
	wire SC_lt_7;
	wire BC_eq_8;
	wire [Num_state_bits-1:0] state;
	wire [Num_counter_bits-1:0] Sample_counter;
	wire [Num_counter_bits:0] Bit_counter;
	wire [word_size-1:0] RCV_shftreg;
	
	assign SC_eq_3 = UUT.SC_eq_3;
	assign SC_lt_7 = UUT.SC_lt_7;
	assign BC_eq_8 = UUT.BC_eq_8;
	assign state = UUT.M0.state;
	assign Sample_counter = UUT.M1.Sample_counter;
	assign Bit_counter = UUT.M1.Bit_counter;
	assign RCV_shftreg = UUT.M1.RCV_shftreg;
	
	initial
	begin
	Sample_clk = 0;
	forever
	#5 Sample_clk = ~Sample_clk;
	end
	
	initial
	begin
		 rst_b = 0;
	#10 rst_b = 1;
	#40 rst_b = 0;
	#50 rst_b = 1;
	end
	
	initial
		begin		  Serial_in = 0;
				#10  Serial_in = 1;
				#140 Serial_in = 0;
				#80  Serial_in = 1;
				#80  Serial_in = 0;
				#80  Serial_in = 1;
				#80  Serial_in = 0;
				#80  Serial_in = 1;
				#80  Serial_in = 1;
				#80  Serial_in = 0;
				#80  Serial_in = 1;
				#80  Serial_in = 1;
				
				#80  Serial_in = 0;
				#80  Serial_in = 1;
				#80  Serial_in = 1;
				#80  Serial_in = 1;
				#80  Serial_in = 0;
				#80  Serial_in = 1;
				#80  Serial_in = 1;
				#80  Serial_in = 0;
				#80  Serial_in = 0;
				#80  Serial_in = 1;
				
				#80  Serial_in = 0;
				#80  Serial_in = 1;
				#80  Serial_in = 1;
				#80  Serial_in = 1;
				#80  Serial_in = 1;
				#80  Serial_in = 0;
				#80  Serial_in = 0;
				#80  Serial_in = 0;
				#80  Serial_in = 1;
				#80  Serial_in = 1;
				
				#80  Serial_in = 0;
				#720 Serial_in = 1;
				
				#80  Serial_in = 0;
				#80  Serial_in = 1;
				#320 Serial_in = 0;
				#400 Serial_in = 1;
		end
		
	initial
		begin
				read_not_ready_in = 0;
		#1500 read_not_ready_in = 1;
		#700  read_not_ready_in = 0;
		end
	
	initial
	#5000 $finish;
	endmodule
	