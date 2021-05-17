`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/29 15:50:49
// Design Name: 
// Module Name: tb_spi_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_spi_top();
// constants                                           
// general purpose registers
// test vector input registers
reg					sys_clk;
reg					sys_rst_n;
	
reg					spi_en;		
reg		[7:0]		spi_sdata;
wire	[7:0]		spi_rdata;
wire				spi_done;	
wire				spi_csn	;
wire				spi_clk;	
wire				spi_mosi;	
reg					spi_miso;	

reg       			data_flag;
reg					datain;
wire      			negedge_flag;
reg     [7:0]  	shift_buf[3:0];
// assign statements (if any)                          
spi_top 	spi_top_inst (
// port map - connection between master ports and signals/registers   
//system signals    
	//sys_interface
.sys_clk		(sys_clk),//ϵͳʱ��50Mhz
.sys_rst_n		(sys_rst_n),
.spi_csn		(spi_csn),
.spi_clk		(spi_clk),
.spi_mosi		(spi_mosi),
.spi_miso       (spi_miso)
  
);
//F1û����1�ĳ�ʼ��
initial   begin   
sys_clk= 1;
sys_rst_n <= 1;       
#15000                
sys_rst_n <= 0;
spi_miso<=0;
#15000	 
sys_rst_n <= 1;
#2000  
#500
tx_byte();            
//$display("Running testbench");                       
end 


always   #20 sys_clk = ~sys_clk;

initial $readmemb ("D:/vivado_pros/radar_emulate/flash_TX_data.txt",shift_buf);



task tx_bit(input [7:0] shift_buf);
     integer i ;
	  for(i=0;i<8;i=i+1)begin
				case(i)//ģ�⴮�ڷ���
						0: spi_miso <= shift_buf[7];
						//��Ҫ�ӳ�104_160ns������ͬ��
						1: spi_miso <= shift_buf[6];
						2: spi_miso <= shift_buf[5]; 
						3: spi_miso <= shift_buf[4];     
						4: spi_miso <= shift_buf[3];
						5: spi_miso <= shift_buf[2];
						6: spi_miso <= shift_buf[1];
						7: spi_miso <= shift_buf[0];
				endcase
				#1000;//���ӳ���i���ӳ٣���0123456789֮����ӳ٣�������ÿһλ���ݲ��εĳ���ʱ��	
	  end
endtask
task tx_byte();
integer i ;
for(i=0;i<3;i=i+1)begin
  tx_bit(shift_buf[i]);
  end
endtask                                              
endmodule
