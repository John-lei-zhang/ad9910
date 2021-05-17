`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/02 16:14:08
// Design Name: 
// Module Name: drive_ad9910
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
module	drive_ad9910(
           //system signals
        input						 sys_clk        ,//clock signal, 50M
        input						 sys_rst_n      ,//reset, active low 
           //user
		input	       				 spi_done,
		input        	[7:0]  	     spi_rdata,    // spiд�������	
		output			[1:0]		 spi_mode,		    
		output	        			 spi_en,
		output  reg	    [7:0]  	 spi_sdata,    // spi����������
		output  reg                 o_io_update,	
		output  reg                 o_io_reset,
		output  reg                 o_master_reset,
		output  wire    [2:0]       o_profile_ctrl    //�����ڲ�PROFILE�Ĵ���
);
//========================================================================\
// =========== Define Parameter and Internal signals =========== 
//========================================================================/
parameter      	mode 		= 2'd3;
parameter spi_cnt = 5'd5;//spi֡����ÿһ֡8λ��
parameter spi_cnt_1 = 5'd9;//����profile�Ĵ���ֵ���ܹ�9���ֽڣ�


localparam      spi_wait	= 19'd1000; 
  
reg		[18:0]  ic_wait_cnt; 
reg		[18:0]  spi_wait_cnt; 
reg		[2:0]	flow_cnt;	
reg		[18:0]  cmd_cnt	;
wire       		init_done;

assign o_profile_ctrl = 3'b000;//ѡ��profile0��ΪDDS���������Ĵ���

//=============================================================================
//**************    Main Code   **************
//=============================================================================
///////////////////////////////////////////////////////////////////////////////////////////////////////
reg      [2:0] r_trans_data_cnt;
//=============================================================================
//**************    Main Code   **************
//=============================================================================
//
wire [39:0] ad9910_cr1_3 [2:0];
assign ad9910_cr1_3[0] = {8'h00,32'h0000_0002};//��spi���ó�����
assign ad9910_cr1_3[1] = {8'h01,32'h0140_0820};
//assign ad9910_cr1_3[2] = {8'h02,32'h1D3F_4150};
assign ad9910_cr1_3[2] = {8'h02,32'h1D3F_4150};

wire [71:0] ad9910_profile_0;
//assign ad9910_profile_0 = {8'h0e,64'h08B5_0000_0CCC_CCCD};//50MHz
//assign ad9910_profile_0 = {8'h0e,64'h08B5_0000_7FFF_FFFF};//���Ƶ��Լ����ϵͳƵ�ʵ�һ��
assign ad9910_profile_0 = {8'h0e,64'h08B5_0000_1cFF_FFFF};//113MHz

reg r_spi_en_flag;

assign spi_en = r_spi_en_flag ? r_spi_en_avaible : 0;
///////////////////////////////////////////////////////////////////////////////////////////////////////
assign  spi_mode =  mode;

//�ϵ�ȴ�������
//ic_wait_cnt������100ʱֹͣ
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
assign  init_done = ad9910_cr1_3_finish ? ((cmd_cnt==spi_cnt_1-1'b1)&&(spi_done) ? 1'b1 : 1'b0):((cmd_cnt==spi_cnt-1'b1)&&(spi_done) ? 1'b1 : 1'b0);
always	@(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	cmd_cnt<='d0;            
        end
        else if(spi_done)begin//spi_done������init_done��˵����ʱ��д��8���ֽ�
        	cmd_cnt<=cmd_cnt+1'b1;
			if(init_done)begin           
        		cmd_cnt<=1'b0;
        	end
        end
end


//֡ѭ��������
//������ÿ��д������֮����и���
always	@(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	spi_wait_cnt<='d0;  
        	o_io_update <= 'd0;          
        end
        else if(flow_cnt == 2'd2)begin
			if(spi_wait_cnt <= spi_wait-1'b1)
        		spi_wait_cnt<=spi_wait_cnt+1'b1;
			else begin
            	spi_wait_cnt<='d0; 
        	end
        	if(spi_wait_cnt <= spi_wait/2 - 1'b1)begin
        	    o_io_update <= 1'b1;
        	end
        	else begin
        	    o_io_update <= 'd0;
            end
        end
		else begin
			spi_wait_cnt<='d0; 
			o_io_update <= 'b0;
		end
end


reg r_spi_en_avaible;
//ע����ʱ���½���
//����Ϊ��spi����ʹ���Լ����ݵķ���
always	@(negedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
            r_spi_en_avaible <= 'd0;
        	flow_cnt<='d0; 
        	
        	o_io_reset <= 1'b0;
        	o_master_reset <= 1'b0;   
        	
        end
        else begin
        	case(flow_cnt)
        		0:begin
        			if(ic_wait_cnt == 19'd100 && r_trans_data_cnt < 'd4)begin
                         r_spi_en_avaible <= 1'b1;//spiʹ��
                         if(ad9910_cr1_3_finish == 1'b1)begin
                            flow_cnt <= flow_cnt+3'd3;
                         end else begin
                            flow_cnt <= flow_cnt+1'b1;
                         end
                        
                         o_io_reset <= 1'b0;
        	             o_master_reset <= 1'b0;  
        			end
        			else begin
        			     o_io_reset <= 1'b1;//���ж˿ڸ�λ
        	             o_master_reset <= 1'b1;//����ϵͳ��λ�����мĴ�����ΪĬ��ֵ 
        			end
        		end
        		1:begin
        		          if(cmd_cnt==1'd0)begin
       					        spi_sdata<=ad9910_cr1_3[r_trans_data_cnt][39:32];        			
        			      end
 					      if(spi_done&&cmd_cnt==1'd0)begin
        				        spi_sdata<=ad9910_cr1_3[r_trans_data_cnt][31:24];
        			      end
					      if(spi_done&&cmd_cnt==2'd1)begin
						        spi_sdata<=ad9910_cr1_3[r_trans_data_cnt][23:16];
        			      end
        			      if(spi_done&&cmd_cnt==2'd2)begin
						        spi_sdata<=ad9910_cr1_3[r_trans_data_cnt][15:8];
        			      end
        			      if(spi_done&&cmd_cnt==2'd3)begin
						        spi_sdata<=ad9910_cr1_3[r_trans_data_cnt][7:0];
        			      end      
        			      if(spi_done&&cmd_cnt==3'd4)begin
                                r_spi_en_avaible <= 1'b0;
                                flow_cnt <=flow_cnt+1'b1;        
        			      end
        			   				
        		end
        		2:begin
        			if(spi_wait_cnt==spi_wait-1'b1)
        				flow_cnt <=2'd0;  
        		end
        		
        		3:begin
        		          if(cmd_cnt==1'd0)begin
       					        spi_sdata<=ad9910_profile_0[71:64];        			
        			      end
 					      if(spi_done&&cmd_cnt==5'd0)begin
        				        spi_sdata<=ad9910_profile_0[63:56];
        			      end
					      if(spi_done&&cmd_cnt==5'd1)begin
						        spi_sdata<=ad9910_profile_0[55:48];
        			      end
        			      if(spi_done&&cmd_cnt==5'd2)begin
						        spi_sdata<=ad9910_profile_0[47:40];
        			      end   
        			      if(spi_done&&cmd_cnt==5'd3)begin
       					        spi_sdata<=ad9910_profile_0[39:32];        			
        			      end
 					      if(spi_done&&cmd_cnt==5'd4)begin
        				        spi_sdata<=ad9910_profile_0[31:24];
        			      end
					      if(spi_done&&cmd_cnt==5'd5)begin
						        spi_sdata<=ad9910_profile_0[23:16];
        			      end
        			      if(spi_done&&cmd_cnt==5'd6)begin
						        spi_sdata<=ad9910_profile_0[15:8];
        			      end
        			      if(spi_done&&cmd_cnt==5'd7)begin
						        spi_sdata<=ad9910_profile_0[7:0];
        			      end    
        			      if(spi_done&&cmd_cnt==5'd8)begin
                                r_spi_en_avaible <= 1'b0;
                                flow_cnt <=flow_cnt - 1'b1;       
        			      end
        		  end       		
        	endcase
        end
end


reg ad9910_cr1_3_finish;//��������cr�Ĵ���д����ϣ���ʼ����profile0�Ĵ���

always @ (posedge sys_clk or negedge sys_rst_n)begin
    if(!sys_rst_n)begin
        r_trans_data_cnt <= 1'b0;
        r_spi_en_flag <= 'b1;
        
        ad9910_cr1_3_finish <= 1'b0;   
    end else begin
        if(spi_done == 1'b1&&cmd_cnt==3'd4)begin
            if(r_trans_data_cnt == 3'd2)begin
                r_trans_data_cnt <= 1'd0;
//                r_spi_en_flag = 'b0;
                
                ad9910_cr1_3_finish <= 1'b1;
            end
            else
                r_trans_data_cnt <= r_trans_data_cnt + 1'b1;
        end
        else begin
            if(spi_done == 1'b1 && cmd_cnt == 5'd8)begin
                r_spi_en_flag = 'b0;
            end  
        end
    end
end

endmodule
