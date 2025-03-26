

	module Man_to_NRZ_Mealy_reg (Man, NRZ_reg, clk);
	input Man, clk;
	output reg NRZ_reg;
	reg next_NRZ;
	reg [1:0] state, next_state;
	parameter s0 = 2'b00;//first half of Manchester signal doesn't matter
	parameter s1 = 2'b01;//second half of Manchester signal goes to a logic high
	parameter s2 = 2'b10;//second half of Manchester signal goes to a logic low
	
	always @ (Man, state)
		case (state)
		s0: if (~Man) begin next_state = s1; 		//if next_state = s1, the next NRZ = 0 for 2 clock cycles
								  next_NRZ = 1'b0; end  //if next_state = s2, the next NRZ = 1 for 2 clock cycles
			 else begin next_state = s2; 
							next_NRZ = 1'b1; end
		s1: begin next_state = s0; 
					 next_NRZ = 1'b0; end
		s2: begin next_state = s0; 
					 next_NRZ = 1'b1; end
		default: begin next_state = s0; 
					next_NRZ = 1'b0; end
		endcase
		
	always @ (negedge clk)	//state register and registered output
	begin
		state <= next_state;
		NRZ_reg <= next_NRZ;
	end
	
	endmodule