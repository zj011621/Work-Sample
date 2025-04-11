

	module Jerky_Counter_tb ();
	parameter counter_size = 5;	//parametrizable counter size
	reg reset, enable, clk;
	wire [counter_size-1:0] count;
	
	//probes for testing, keeps track of variables that affect the counter's output
	wire [counter_size-1:0] probe_k;
	wire [counter_size-1:0] probe_evens;
	
	Jerky_Counter UUT (reset, enable, clk, count);
	assign probe_k = UUT.k;
	assign probe_evens = UUT.evens;

	initial	//clock cycle
	begin
		clk = 1'b0;
		forever
			#5 clk = ~clk;
	end
	
	initial
	begin
	reset = 1'b1;
	enable = 1'b1;
	#50 reset = 1'b0;							//pulling reset low for testing
	#10 reset = 1'b1; enable = 1'b0;		//pulling enable low while reset is high for testing
	#10 enable = 1'b1;						//testing full counter cycle
	end
	
	initial
	#300 $finish;

	endmodule
	
		
		
	