module testbench;
reg reset = 0;
reg clk = 0;
wire halted;
processor PE(halted, reset, clk);
initial begin
//$dumpfile;
//$dumpvars(0, PE);
  #10 reset = 1;
  #10 clk = 1;
  #10 reset = 0;
  while (!halted) begin
    #10 clk = 0;
	$display("------- Clock--------");
    #10 clk = 1;
  end
  $finish;
end
endmodule