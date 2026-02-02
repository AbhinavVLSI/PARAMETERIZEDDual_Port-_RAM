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
      i_cs     <=0;
      i_rst    <=1;
      i_clk    <=0;
      i_wr_data<=0;
      i_rd_addr<=0;
      i_wr_addr<=0;
      i_rd_en  <=0;
      i_wr_en  <=0;
      i_valid  <=0; 
      
      repeat(2)@(negedge i_clk);
      i_rst <=0;
//       i_cs <=0;
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
  
 // for reading
  
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

  //sanity test
  
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
  
 // task for simultaneous read write 
  
  task simultaneous_read_write;
    begin
      $display ("---simultaneous READ and WRITE Test");
      
      write_mem(5,8'h99);
      @(negedge i_clk);
      
      i_cs      <= 1;
      i_valid   <= 1;
      i_wr_en   <= 1;
      i_rd_en   <= 1; 
      i_wr_addr <= 1;
      i_rd_addr <= 1;
      i_wr_addr <= 5;
      i_rd_addr <= 5;
      i_wr_data <= 8'h55;
      
      @(negedge i_clk);
      $display("Read and write at same address(5):  got=%0h",o_data_rd);
      
      i_cs   <=0;
      i_valid<=0;
      i_wr_en<=0;
      i_rd_en<=0;
      //reading again to check the final value 
      @(negedge i_clk);
      read_mem(5,8'h55);
    end
  endtask
      //write different value at same address
      task overwrite ;
        begin
          
          $display("=== Overwrite Test ===");
           write_mem(7, 16'hAAAA);
  		  write_mem(7, 16'hBBBB);
  		  read_mem(7, 16'hBBBB);
	end
  endtask

    task corner_middle_value ;
      begin
        $display("---bounday and middle value test---");
        write_mem(0, 8'hAA);
        read_mem(0, 8'hAA);
        write_mem(1, 8'hBB);
        read_mem(1, 8'hBB);
        
        write_mem(DEPTH/2, 8'hEE);
        read_mem(DEPTH/2, 8'hEE);
        
        write_mem(DEPTH-2, 8'hCC); read_mem(DEPTH-2, 8'hCC);
        write_mem(DEPTH-1, 8'HDD); read_mem(DEPTH-1, 8'hDD);
      end
    endtask
  
  task continous_read_write;
    integer i;
    begin
      $display("--Back to Back Read & Write---");
      for (i=0; i<=4; i= i+1) begin
      write_mem(i,16'h1000 + i);
      read_mem (i,16'h1000 + i);
    end
    end
  endtask
  task random;
    integer i;
    reg[ADDRESS-1:0]addr;
    reg[WIDTH-1:0]data;
    begin
      $display("--random data tetsing--");
      for(i=0; i<=10; i=i+1)begin
      addr = $urandom % DEPTH;
      data = $urandom % ADDRESS;
      write_mem(addr, data);
      @(negedge i_clk);
        read_mem(addr,data);
    end
    end
  endtask
 
  task reset_between_two_read();
    begin
      write_mem(4'd12,32'h12121212);
      read_mem(4'd12, 32'h12121212);
        @(negedge i_clk); i_rst=0;				
      @(negedge i_clk); i_rst=1;
      read_mem(4'd12, 32'h12121212);
    end
  endtask
  
  task automatic address_walking;
    integer bit_pos, i;
    reg [ADDRESS-1:0] walk_addr;
    begin
      $display("-- starting Address‑Walking‑1 Test --");

      // 1) CLEAR ALL LOCATIONS 
      for (i = 0; i < (1 << ADDRESS); i = i + 1)
        write_mem(i, {WIDTH{1'b0}});

      // 2) FOR EACH ADDRESS BIT…
      for (bit_pos = 0; bit_pos < ADDRESS; bit_pos = bit_pos + 1) begin
        
        
        walk_addr = {ADDRESS{1'b0}};
        walk_addr[bit_pos] = 1'b1;
        $display(" Testing address bit %0d (addr = %0h)", bit_pos, walk_addr);

        // WRITE a '1' at walk_addr
        write_mem(walk_addr, {{(WIDTH-1){1'b0}}, 1'b1});

        // VERIFY: only walk_addr should read back '1'
        for (i = 0; i < (1 << ADDRESS); i = i + 1) begin
          if (i == walk_addr)
            read_mem(i, {{(WIDTH-1){1'b0}}, 1'b1});
          else
            read_mem(i, {WIDTH{1'b0}});
        end

        // CLEAR that cell for the next 
        write_mem(walk_addr, {WIDTH{1'b0}});
      end

      $display("--- Address‑Walking Test PASSED ---\n");
    end
  endtask

  
  initial 
    begin
      $display("reset done %ot",$time);
      
      initial_test;
      if($test$plusargs("write_mem"))begin
       write_mem(3,8'h42);      
      end
      if($test$plusargs("read_mem"))begin
      read_mem(3,8'h42);
      end
      if($test$plusargs("sanity_test"))begin
      sanity_test(0,6);
      end
      if($test$plusargs("simultaneouss_read_write"))begin
        simultaneous_read_write();
    end
      if($test$plusargs("overwrite"))begin
        overwrite();
      end
      if($test$plusargs("corner_middle_value"))begin
        corner_middle_value();
      end
      if($test$plusargs("continous_read_write"))begin
      continous_read_write;
      end
      if($test$plusargs("random"))
      random;
      if($test$plusargs("reset_between_two_reads"))begin
        reset_between_two_read();
      end
      if($test$plusargs("address_walking"))begin
      address_walking;
      end
      
      $display("all test complete");
      $finish;
    end
  initial
    begin
      $dumpfile("hii.vcd");
      $dumpvars();
    end
endmodule


      
    
  