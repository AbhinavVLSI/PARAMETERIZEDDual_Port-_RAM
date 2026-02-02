`timescale 1ns/ 1ps
module tb_dual;
  parameter WIDTH = 16;
  parameter DEPTH = 32;
  parameter ADDRESS = 5;
  reg i_clk,i_rst;
  reg i_rd_en,i_wr_en;
  reg [ADDRESS-1:0]i_wr_addr,i_rd_addr;
  reg [WIDTH-1:0]i_wr_data;
  reg i_cs,i_valid;
  wire [WIDTH-1:0]o_data_wr;
  wire  [WIDTH-1:0]o_data_rd;
  wire o_ready;
  
  ram_dual dut(
    .i_rst(i_rst),
    .i_clk(i_clk),
    .i_rd_en(i_rd_en),
    .i_wr_en(i_wr_en),
    .i_wr_addr(i_wr_addr),
    .i_rd_addr(i_rd_addr),
    .i_wr_data(i_wr_data),
    .i_cs(i_cs),
    .i_valid(i_valid),
    .o_data_wr(o_data_wr),
    .o_data_rd(o_data_rd),
    .o_ready(o_ready)
             );
  
  always begin
    #5 i_clk = ~i_clk;
  end
  task initial_test;
    begin
      i_cs     =0;
      i_rst    =1;
      i_clk    =0;
      i_wr_data=0;
      i_rd_addr=0;
      i_wr_addr=0;
      i_rd_en  =0;
      i_wr_en  =0;
      i_valid=0; 
      
      repeat(2)@(negedge i_clk);
      i_rst=0;
      @(negedge i_clk);
      $display("initial reset aplied and released  at %0t",$time);
    end
  endtask
  
  //task for one complete write cycle
  task write_mem(input [ADDRESS-1:0] addr, input [WIDTH-1:0] data);
  begin
    @(negedge i_clk);
    i_cs      <= 1;
    i_valid   <= 1;
    i_wr_en   <= 1;
    i_wr_addr <= addr;
    i_wr_data <= data;
    @(negedge i_clk);
    // deassert after one cycle
    i_wr_en   <= 0;
    i_cs      <= 0;
    i_valid   <= 0;
  end
  endtask
  
  task read_mem(input [ADDRESS-1:0] addr, input [WIDTH-1:0] exp);
  begin
    @(negedge i_clk);
    i_cs      <= 1;
    i_rd_en   <= 1;
    i_rd_addr <= addr;
    @(negedge i_clk)
    if (o_data_rd !== exp)
      $display("ERROR @%0t: addr=%0d exp=%02h got=%02h", $time, addr, exp, o_data_rd);
    else
      $display("PASS  @%0t: addr=%0d data=%02h", $time, addr, o_data_rd);
    // deassert
    i_rd_en <= 0;
    i_cs    <= 0;
  end
  endtask

  
  task sanity_test(input integer start_addr, input integer count);
    integer j;
  begin
    // write pattern
    for (j = start_addr; j < start_addr + count; j = j + 1)
      write_mem(j, 8'hA0 + j);
    
    // small gap
    repeat (2) @(negedge i_clk);
    
    // read & verify
    
    for (j = start_addr; j < start_addr + count; j = j + 1)
      read_mem(j, 8'hA0 + j);
    $display("Sanity Test: %0d locations @%0t complete", count, $time);
  end
  endtask
  
  // full depth 
  task boundary_full_burst();
  integer j;
  begin
    $display("--- Starting full-depth burst write at %0t ---", $time);
    for (j = 0; j < DEPTH; j = j + 1) begin
      write_mem(j, j[WIDTH-1:0]);  // write incremental data
    end
    $display("--- Completed full-depth burst write at %0t ---", $time);
  end
endtask
  
  // now overflow 
  
  task overflow();
    reg [WIDTH-1:0] prev_data;
begin
  // --- 1) Sample existing data at addr 0
  @(negedge i_clk);
  i_cs      <= 1;
  i_valid   <= 1;
  i_rd_en   <= 1;
  i_rd_addr <= 0;
  @(negedge i_clk);
  prev_data = o_data_rd;
  i_rd_en <= 0;
  i_cs    <= 0;

  $display("Starting overflow test at %0t: before=%0h", $time, prev_data);

  // --- 2) Issue the extra write
  @(negedge i_clk);
  i_cs      <= 1;
  i_valid   <= 1;
  i_wr_en   <= 1;
  i_wr_addr <= 0;
  i_wr_data <= -1;  // e.g. 0xFF
  @(negedge i_clk);
  i_wr_en <= 0;
  i_cs    <= 0;

  // --- 3) Read it back again
  @(negedge i_clk);
  i_cs      <= 1;
  i_valid   <= 1;
  i_rd_en   <= 1;
  i_rd_addr <= 0;
  @(negedge i_clk);

  // --- 4) Compare and report
  if (o_data_rd === prev_data)
    $display("OK: overflow write was ignored (still %0h)", o_data_rd);
  else
    $display("FAIL: overflow write stuck (got %0h, expected %0h)",
             o_data_rd, prev_data);

  // teardown
  i_rd_en <= 0;
  i_cs    <= 0;
end
endtask
     
  initial 
    begin
      $display("reset done %ot",$time);
      
      initial_test;
      boundary_full_burst;
      overflow;
      write_mem(3,8'h42);
      
      @(negedge i_clk);
      read_mem(3,8'h42);
      @(negedge i_clk);
      sanity_test(0,4);
      @(negedge i_clk);
     
      $display("all test complete");
      $finish;
    end
  initial
    begin
      $dumpfile("hii.vcd");
      $dumpvars();
    end
endmodule


      
    
  