module ram_dual(i_clk,i_rst,
           i_wr_addr,i_rd_addr, // write adn read adress
           i_wr_en,i_rd_en,		//wr and rd enable
           i_wr_data,    		// and write data
           i_cs,i_valid,        //chip select and valid signal
            o_data_wr,o_data_rd,
            o_ready); 
  //parameterized RAM depth address and width
  
  parameter WIDTH = 16;
  parameter DEPTH = 32;
  parameter ADDRESS= 5;       //log base 2( DEPTH)
  
  //port decleration
  
  input                 i_clk,i_rst;
  input                 i_rd_en,i_wr_en;
  input [ADDRESS-1:0]   i_wr_addr;
  input [ADDRESS-1:0]   i_rd_addr;
  input [WIDTH-1:0]     i_wr_data;
  input                 i_cs,i_valid;
  output reg [WIDTH-1:0]o_data_wr;
  output reg [WIDTH-1:0]o_data_rd; 
  output                o_ready;
  
  assign o_ready =1'b1;
   
 //memory modelling 
  
  reg[WIDTH-1:0]mem[0:DEPTH-1];
  
  
  //write memory logic
  
   always@(posedge i_clk)
    begin
      if(i_rst)
        begin
      o_data_wr <={WIDTH{1'b0}};
  end 
      else if (i_cs && i_wr_en && i_valid && o_ready)
      begin
        mem[i_wr_addr] <= i_wr_data;
        o_data_wr <= mem[i_wr_addr];
      end   
  end
      
      //read memory logic
      
    always @(posedge i_clk)
      begin
        if(i_rst)
          begin
          o_data_rd <={WIDTH{1'b0}};
        end 
        else if(i_rd_en)
          begin
        o_data_rd <= mem[i_rd_addr];
      end
  end
endmodule
      
       
  
  
