// Multiplier design having a bug to remove
module multiplier (
	input clk,
	input [15:0] multiplicand, 
	input [7:0] multiplier,  
	output logic [23:0] product
);

//logic[23:0] easy_partial[7:0];
logic[7:0] [23:0] easy_partial;
logic[23:0] easy_sum;
generate 
	for(genvar i = 0; i < 8; i++) begin
		always_comb begin
			easy_partial[i] = multiplier[i] ? multiplicand << i : 24'b0;
		end
	end
endgenerate

always_comb begin
	easy_sum = 
		easy_partial[0] +
// bug injected here
//		{easy_partial[0][23:1], ~easy_partial[0][0]} +
		easy_partial[1] +
		easy_partial[2] +
		easy_partial[3] +
		easy_partial[4] +
		easy_partial[5] +
		easy_partial[6] +
		easy_partial[7];
	 product = easy_sum;
end
endmodule
