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
		input        	[7:0]  	    spi_rdata,    // spiд�������	
		output			[1:0]		spi_mode,		    
		output	reg       			spi_en,
		output  reg		[7:0]  	spi_sdata    // spi����������
			
);
//========================================================================\
// =========== Define Parameter and Internal signals =========== 
//========================================================================/
parameter      	mode 		= 2'd3;
parameter      	spi_cnt 	= 2'd3;//spi֡����ÿһ֡8λ��
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

//�ϵ�ȴ�������
always	@(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	ic_wait_cnt<='d0;            
        end
        else if(ic_wait_cnt<=18'd99)begin
        	ic_wait_cnt<=ic_wait_cnt+1'b1;
        end
end

//���������
//
assign  init_done = (cmd_cnt==spi_cnt-1'b1)&&(spi_done) ? 1'b1 : 1'b0;
always	@(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	cmd_cnt<='d0;            
        end
        else if(spi_done)begin//spi_done������init_done
        	cmd_cnt<=cmd_cnt+1'b1;
			if(init_done)begin
        		cmd_cnt<=1'b0;
        	end
        end
end


//֡ѭ��������
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

//ע����ʱ���½���
//����Ϊ��spi����ʹ���Լ����ݵķ���
always	@(negedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	spi_en<='d0; 
        	flow_cnt<='d0;           
        end
        else begin
        	case(flow_cnt)
        		0:begin
        			if(ic_wait_cnt == 19'd100)begin
        				spi_en <= 1'b1;//spiʹ��
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
