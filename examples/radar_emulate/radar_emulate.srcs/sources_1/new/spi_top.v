`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/29 15:25:12
// Design Name: 
// Module Name: spi_top
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


module  spi_top(
        	//system signals
        input						sys_clk,//clock signal, 25M
//        input                       sys_rst_n,//reset, active low 
        //user
        output                     ad9910_ref_clk_p,
        output                     ad9910_ref_clk_n,

		output						spi_csn,
		output						spi_clk,
		output						spi_mosi,
		input						spi_miso,
		
		//ctrl
        output                      o_io_update,
        output                      o_io_reset,
        output                      o_master_reset,
        output   [2:0]              o_profile_ctrl
);

//========================================================================\
// =========== Define Parameter and Internal signals =========== 
//========================================================================/

wire			spi_en;
wire			spi_done;
wire	[1:0]	spi_mode;
wire	[7:0]	spi_sdata;
wire	[7:0]	spi_rdata;
wire           sys_rst_n;
//=============================================================================
//**************    Main Code   **************
//=============================================================================
//spi_config	spi_config_inst(

//.sys_clk     	(sys_clk), 
//.sys_rst_n  	(sys_rst_n),  

//.spi_done		(spi_done),    
//.spi_rdata		(spi_rdata),  
//.spi_en			(spi_en),      
//.spi_sdata		(spi_sdata), 
//.spi_mode		(spi_mode)
//);
assign ad9910_ref_clk_p = sys_clk;
assign ad9910_ref_clk_n = ~sys_clk;

drive_ad9910	drive_ad9910_inst(

.sys_clk     	(sys_clk), 
.sys_rst_n  	(sys_rst_n),  

.spi_done		(spi_done),    
.spi_rdata		(spi_rdata),  
.spi_en			(spi_en),      
.spi_sdata		(spi_sdata), 
.spi_mode		(spi_mode),

.o_io_update    (o_io_update),
.o_io_reset     (o_io_reset),
.o_master_reset (o_master_reset),
.o_profile_ctrl (o_profile_ctrl)    //¿ØÖÆÄÚ²¿PROFILE¼Ä´æÆ÷
);


spi_master	spi_master_inst(
.sys_clk		(sys_clk),
.sys_rst_n		(sys_rst_n),    

.spi_en			(spi_en),   
.spi_mode		(spi_mode), 
.spi_sdata		(spi_sdata),
.spi_rdata		(spi_rdata),
.spi_done		(spi_done),

.spi_csn		(spi_csn),	
.spi_clk		(spi_clk),
.spi_mosi		(spi_mosi), 
.spi_miso		(spi_miso)

);

vio_0 your_instance_name (
  .clk(sys_clk),                // input wire clk
  .probe_out0(sys_rst_n)  // output wire [0 : 0] probe_out0
);

// OBUFDS: Differential Output Buffer
//         7 Series
// Xilinx HDL Libraries Guide, version 2016.3

//OBUFDS #(
//   .IOSTANDARD("DEFAULT"), // Specify the output I/O standard
//   .SLEW("SLOW")           // Specify the output slew rate
//) OBUFDS_inst (
//   .O(ad9910_ref_clk_p),     // Diff_p output (connect directly to top-level port)
//   .OB(ad9910_ref_clk_n),   // Diff_n output (connect directly to top-level port)
//   .I(sys_clk)      // Buffer input 
//);
  
// End of OBUFDS_inst instantiation

endmodule
