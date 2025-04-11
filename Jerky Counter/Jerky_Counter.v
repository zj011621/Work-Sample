

	module Jerky_Counter (reset, enable, clk, count);
	parameter counter_size = 5;	//parametrizable counter size
	
	input reset, enable, clk;
	output reg [counter_size-1:0] count;
	
	//k keeps track of where we are in the counter's cycle
	//evens is the shifting '1' counter for when k = 2, 4, 6, 8... to keep track of where the '1' was
	reg [counter_size-1:0] k;
	reg [counter_size-1:0] evens;	
	
	//reset_right represents counter = ...0001
	//reset_left represents counter = 1000...
	parameter [counter_size-1:0] reset_right = 1;
	parameter [counter_size-1:0] reset_left = {reset_right[0], reset_right[counter_size-1:1]};
	
	always @ (posedge clk or negedge reset)
	begin
		//if reset goes low, then resets all counters=...0001 and k=1
		if (~reset)	
			begin
			count <= reset_right;
			evens <= reset_right;
			k <= 1;
			end
			
		//if enable = 1 and the count is in the first half, switches between a 1 shifting left and a 1 on the right
		else if (enable & k < 2*counter_size-1)
			begin
			k <= k+1;
			//if k is odd, the counter's output is reset_right and evens is shifted in preparation for the next k
			//if k is even, the counter's output follows the prepared evens counter
			if (k%2 == 1) begin count <= reset_right; evens <= {evens[counter_size-2:0], evens[counter_size-1]}; end 
			else count <= evens; 
			end
			
		//if enable = 1 and the count is in the second half, switches between a 1 shifting right and a 1 on the left
		else if (enable & k >= 2*counter_size-1)
			begin
			k <= k+1;
			//counter cycle is finished when evens = ...0001, resets count, evens, and k
			if (evens == 1) begin count <= reset_right; evens <= reset_right; k <= 1; end
			//if k is odd, count = reset_left and shifts evens to the right
			//if k is even, count = evens
			else if (k%2 == 1) begin count <= reset_left; evens <= {evens[0], evens[counter_size-1:1]}; end
			else count <= evens;
			end
			
			
		else		//if reset = 1 and enable = 0, resets the counters and k
			begin 
			count <= reset_right;
			evens <= reset_right;
			k <= 1;
			end
			
	end
	endmodule
