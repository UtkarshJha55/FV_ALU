// ALU Design code in SystemVerilog, acting as the design to be verified
module alu_design (
	input clk,
	input reset,
	input valid,
	input [2:0] command,
	input size,
	input [31:0] in_a,
	input [31:0] in_b,
	
    output logic [31:0] result,
	output logic [1:0] signal
);

//Size: 0 - 16-bit, 1 - 32-bit. Block is not required to clear high bits.
//Command:
//  0 - AND (result all 1's sets signal[1], result all 0's set signal[0])
//  1 - OR (result all 1's set signal[1], result all 0's sets signal[0])
//  2 - ADD (inputs are 2's complement, overflow sets signal[1], zero result
//  sets signal[0])
//  3 - SUBTRACT (A-B, inputs are 2's complement, overflow sets signal[1], zero
//  result sets signal[0])
//  4 - SATURATING ADD (inputs are unsigned, saturation sets signal[1] and
//  result is all 1's to proper width, zero result sets signal[0])
//  5 - SATURATING SUBTRACT (A-B, inputs are unsigned, saturation sets
//  signal[1] and result is all 0's, unsaturated zero result sets signal[0])
//  6 - A*B, 16x16 into 32 bit only, zero result sets signal[0]

logic [1:0] temp_signal;
logic [31:0] temp_result;
logic [32:0] sat_add_result;
logic [23:0] mult_result_lo, mult_result_hi;
logic [5:0] num_ones;
logic [31:0] shifted_A;

multiplier mult_lo (
	.clk(clk),
	.multiplicand(in_a[15:0]),
	.multiplier(in_b[7:0]),
	.product(mult_result_lo[23:0])
);
multiplier mult_hi (
	.clk(clk),
	.multiplicand(in_a[15:0]),
	.multiplier(in_b[15:8]),
	.product(mult_result_hi[23:0])
);

count_ones count_B1s (
	.clk(clk),
	.size(size),
	.inp(in_b),
	.result(num_ones)
);

function logic[5:0] count_ones(input logic[31:0] num_ones);
	count_ones = 0;
	for ( ; num != 32'h0; ) begin
		count_ones = count_ones + (num & 32'h1);
		num = num >> 1;
	end
	return count_ones;
endfunction

always_comb begin
	casex ({command, size})
	// ? is a wildcard char, it can be 0 or 1
		// AND
		4'b000?: begin
			temp_result = size ? (in_a & in_b) : {15'b0, (in_a[15:0] & in_b[15:0])};
			temp_signal[1] = size ? (temp_result == 32'hffff_ffff) : (temp_result[15:0] == 16'hffff);
			temp_signal[0] = size ? (temp_result == 32'h0) : (temp_result[15:0] == 16'h0);
		end

		//OR
		4'b001? : begin
            //bug injected here
			//temp_result = ~size ? (in_a | (in_b >> 1)) : {15'b0, (in_a[15:0] | in_b[15:0])};
			temp_result = size ? (in_a | in_b) : {15'b0, (in_a[15:0] | in_b[15:0])};
			temp_signal[1] = size ? (temp_result == 32'hffff_ffff) : (temp_result[15:0] == 16'hffff);
			temp_signal[0] = size ? (temp_result == 32'h0) : (temp_result[15:0] == 16'h0);
		end

		// ADD
		4'b010? : begin
			temp_result = size ? (in_a + in_b) : {15'b0, (in_a[15:0] + in_b[15:0]) & 16'hffff};
			temp_signal[1] = size ? ((in_a[31] == in_b[31]) && (in_a[31] != temp_result[31])) : ((in_a[15] == in_b[15]) && (in_a[15] != temp_result[15]));
			temp_signal[0] = size ? (temp_result == 32'h0) : (temp_result[15:0] == 16'h0);
		end

		// SUB
		4'b011? : begin
			temp_result = size ? (in_a - in_b) : {15'b0, (in_a[15:0] - in_b[15:0]) & 16'hffff};
			temp_signal[1] = size ? ((in_a[31] != in_b[31]) && (in_a[31] != temp_result[31])) : ((in_a[15] != in_b[15]) && (in_a[15] != temp_result[15]));
			temp_signal[0] = size ? (temp_result == 32'h0) : (temp_result[15:0] == 16'h0);
		end

		// SATADD
		4'b100? : begin
			sat_add_result = size ? (in_a + in_b + 33'b0) : (in_a[15:0] + in_b[15:0] + 17'b0);
			temp_signal[1] = size ? sat_add_result[32] : sat_add_result[16];
			temp_result = size ? (temp_signal[1] ? 32'hffff_ffff : sat_add_result[31:0]) : (temp_signal[1] ? 16'hffff : sat_add_result[15:0]);
			temp_signal[0] = size ? (temp_result == 32'h0) : (temp_result[15:0] == 16'h0);
		end

		// SATSUB
		4'b101? : begin
			sat_add_result = size ? (in_a - in_b + 33'b0) : (in_a[15:0] - in_b[15:0] + 17'b0);
			temp_signal[1] = size ? sat_add_result[32] : sat_add_result[16];
			temp_result = size ? (temp_signal[1] ? 32'h0000_0000 : sat_add_result[31:0]) : (temp_signal[1] ? 16'h0000 : sat_add_result[15:0]);
			temp_signal[0] = size ? (temp_result == 32'h0 && ~temp_signal[1]) : (temp_result[15:0] == 16'h0 && ~temp_signal[1]);
		end

		// MUL - 16-bit, there is no 32-bit * 32-bit multiplication.
		4'b1100 : begin
			temp_result = mult_result_lo + {mult_result_hi, 8'b0};
			temp_signal[1] = 0;
			temp_signal[0] = (temp_result == 0);
		end

		// XOR
		/* 4'b111?: begin
			// temp_result = size ? ~(in_a ^ in_b) : {15'b0, ~(in_a[15:0] ^ in_b[15:0])};		// XNOR
			temp_result = size ? (in_a ^ in_b) : {15'b0, (in_a[15:0] ^ in_b[15:0])};
			temp_signal[1] = size ? (temp_result == 32'hffff_ffff) : (temp_result[15:0] == 16'hffff);
			temp_signal[0] = size ? (temp_result == 32'h0) : (temp_result[15:0] == 16'h0);
		end */

		// COMPLEX
		4'b111?: begin
			shifted_A = size ? (in_a[26:0] << 5) : (in[15:0] << 4);
			temp_result = size ? {shifted_A[31:5], num_ones[4:0]} : {12'h0, shifted_A[19:4], num_ones[3:0]};
			temp_signal[1] = size ? (temp_result == 32'hffff_ffff) : (temp_result[15:0] == 16'hffff);
			temp_signal[0] = size ? (temp_result == 0);
		end

		/*4'b111?: begin
			num_ones = size ? count_ones(in_b) : count_ones({16h'0, in_b[15:0]});
			shifted_A = size ? (in_a[26:0] << 5) : (in[15:0] << 4);
			temp_result = size ? {shifted_A[31:5], num_ones[4:0]} : {12'h0, shifted_A[19:4], num_ones[3:0]};
			temp_signal[1] = size ? (temp_result == 32'hffff_ffff) : (temp_result[15:0] == 16'hffff);
			temp_signal[0] = size ? (temp_result == 0);
		end*/

		default : begin
			// Bug in Default case. There is no X in cpp spec file. Hence we need to make it as 0.
			// temp_result = 'bx;
			// temp_signal = 'bx;
			temp_result = 'b0;
			temp_signal = 'b0;
		end

	endcase
end

always @(posedge clk) begin
	if(reset) begin
		result <= 'b0;
		signal <= 'b0;
	end
	else if (valid) begin
		result <= temp_result;
		signal <= temp_signal;
	end
	else begin
		result <= result;
		signal <= signal;
	end
end

endmodule
