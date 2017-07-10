


// This is not a top module 
module full_adder(
	input_a,
	input_b,
	input_cin,
	
	output_sum_o,
	output_cout_o
);

input input_a;
input input_b;
input input_cin;

output output_sum_o;
output output_cout_o;

reg output_sum;
reg output_cout;

assign output_sum_o = output_sum;
assign output_cout_o = output_cout;
//assign {output_cout, output_sum} = input_cin + input_a + input_b;

always @* begin
   {output_cout, output_sum} <= input_cin + input_a + input_b;
end

endmodule



