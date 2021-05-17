`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/29 15:24:06
// Design Name: 
// Module Name: spi_config
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
//----------------------------------------------------------------------------------------//
//****************************************************************************************//

module	spi_config(
           //system signals
        input						sys_clk        ,//clock signal, 50M
        input						sys_rst_n      ,//reset, active low 
           //user
		input	       				spi_done,
		input        	[7:0]  	    spi_rdata,    // spi写入的数据	
		output			[1:0]		spi_mode,		    
		output	reg       			spi_en,
		output  reg		[7:0]  	spi_sdata    // spi读出的数据
			
);
//========================================================================\
// =========== Define Parameter and Internal signals =========== 
//========================================================================/
parameter      	mode 		= 2'd3;
parameter      	spi_cnt 	= 2'd3;//spi帧数，每一帧8位；
localparam      spi_wait	= 19'd1000;   
reg		[18:0]  ic_wait_cnt; 
reg		[18:0]  spi_wait_cnt; 
reg		[2:0]	flow_cnt;	
reg		[18:0]  cmd_cnt	;
wire       		init_done;
//=============================================================================
//**************    Main Code   **************
//=============================================================================
//

//
assign  spi_mode =  mode;

//上电等待计数器
always	@(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	ic_wait_cnt<='d0;            
        end
        else if(ic_wait_cnt<=18'd99)begin
        	ic_wait_cnt<=ic_wait_cnt+1'b1;
        end
end

//命令计数器
//
assign  init_done = (cmd_cnt==spi_cnt-1'b1)&&(spi_done) ? 1'b1 : 1'b0;
always	@(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	cmd_cnt<='d0;            
        end
        else if(spi_done)begin//spi_done包含了init_done
        	cmd_cnt<=cmd_cnt+1'b1;
			if(init_done)begin
        		cmd_cnt<=1'b0;
        	end
        end
end


//帧循环计数器
always	@(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	spi_wait_cnt<='d0;            
        end
        else if(flow_cnt == 2'd2)begin
			if(spi_wait_cnt <= spi_wait-1'b1)
        		spi_wait_cnt<=spi_wait_cnt+1'b1;
			else begin
            	spi_wait_cnt<='d0; 
        	end
        end
		else begin
			spi_wait_cnt<='d0; 
		end
end

//注意是时钟下降沿
//这是为了spi总线使能以及数据的发送
always	@(negedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	spi_en<='d0; 
        	flow_cnt<='d0;           
        end
        else begin
        	case(flow_cnt)
        		0:begin
        			if(ic_wait_cnt == 19'd100)begin
        				spi_en <= 1'b1;//spi使能
        				flow_cnt <= flow_cnt+1'b1;
        			end
        			
        		end
        		1:begin
        			if(cmd_cnt==1'd0)begin
       					spi_sdata<=8'h88;        			
        			end
 					if(spi_done&&cmd_cnt==1'd0)begin
        				spi_sdata<=8'h55;
        			end
					if(spi_done&&cmd_cnt==2'd1)begin
						spi_sdata<=8'haa;
        			end    
        			if(spi_done&&cmd_cnt==2'd2)begin
 						spi_en <=1'b0;
 						flow_cnt <=flow_cnt+1'b1; 
        			end   				
        		end
        		2:begin
        			if(spi_wait_cnt==spi_wait-1'b1)
        				flow_cnt <=2'd0;  
        		end
        	endcase
        end
end

//



endmodule
