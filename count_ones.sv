// Additional operation applied to ALU for counting the number of ones in input values
module count_ones(
    input clk;
    input size;
    input [31:0] inp;
    output logic[5:0] result;
);

// NOTE: The variable inside always_comb can be modified only inside the always_comb block. So do not initialize them outside.

logic[31:0] temp_inp;
logic[5:0] count_1s;

always_comb begin
    temp_inp = size ? inp : (inp & 32'h0000ffff);
    count_1s = 0;
    while (temp_inp != 0) begin
        count_1s = count_1s + (temp_inp & 32'h1);
        temp_inp = temp_inp >> 1;
    end
    result = count_1s;
end

endmodule
