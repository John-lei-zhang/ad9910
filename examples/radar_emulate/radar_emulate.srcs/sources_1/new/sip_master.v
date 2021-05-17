`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/04/29 15:22:05
// Design Name: 
// Module Name: sip_master
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
// Note:1计数器一定要并行的写，不能写在状态机执行的always里面
//		2mode3:SPI下降沿发送数据，上升沿接收数据
//		3mode1:SPI上升沿发送数据，下降沿接收数据
//		4IDLE状态进入其他状态是通过分频时钟
//		5stop状态通过系统时钟，这样在en信号高电平时，stop只维持一个时钟，马上进入了下一个读写状态
//		6由于stop状态只维持一个时钟，所以帧完成也是一个时钟
//		7spi_done即是spi一帧数据的完成信号，也是spi读数据的标志信号
//----------------------------------------------------------------------------------------//
//****************************************************************************************//

module	spi_master(
	//sys_interface
	input	wire			sys_clk,//系统时钟50Mhz 
	input	wire			sys_rst_n,
	//user_interface
	input	wire			spi_en,
	input	wire	[1:0]	spi_mode,
	input			[7:0]	spi_sdata,//SPI串行发送sdata
	output	reg		[7:0]	spi_rdata,//接收串行数据输出并行rdata
	output	reg				spi_done,//一帧SPI传输结束
	//SPI_interface
	output	reg				spi_csn,	
	output	reg				spi_clk,//1M
	output	reg				spi_mosi,
	input	wire			spi_miso//读输入管脚不进行编程
);
//========================================================================\
// =========== Define Parameter and Internal signals =========== 
//========================================================================/

localparam  IDLE 	= 4'b0001;
localparam	SPI_W_R	= 4'b0010;
localparam	STOP 	= 4'b0100;



reg		[4:0]	state;//状态机的寄存器变量，编码方式采用独热码
reg		[4:0]	div_cnt;
reg				clk_p=1'b0;
wire			clk_n;
reg				spi_negedge;
reg				spi_posedge;
reg		[4:0]	shift_cnt;
reg		[7:0]	shift_buf;
reg				idle_done;
reg				spi_w_r_done;
//=============================================================================
//**************    Main Code   **************
//=============================================================================

//准备1:分频时钟
//*****************分频计数器********************************
//周期50下，T=50*20=1000ns=1us=1M
parameter	H_DIV_CYC	=	5'd25;//分频计数器值
always 	@(posedge sys_clk or negedge sys_rst_n)
		if(sys_rst_n == 1'b0)
			div_cnt <= 5'd0;
		else if( div_cnt == H_DIV_CYC-1'b1 )
			div_cnt <= 'd0;
		else 
			div_cnt <= div_cnt + 1'b1;
//分频时钟不允许做寄存器的触发时钟，也就是不能写在always块的触发列表中
always 	@(posedge sys_clk or negedge sys_rst_n)
		if(sys_rst_n == 1'b0)
			clk_p <= 1'b0;
		else if(div_cnt == H_DIV_CYC-1'b1)
			clk_p <= ~clk_p;
//SPI时钟下降沿信号,在下降沿将数据发送出去
//在时钟低电平的末尾判定，在高电平的开头生成
assign	clk_n = ~clk_p;
always 	@(posedge sys_clk or negedge sys_rst_n)
		if(sys_rst_n == 1'b0)
			spi_negedge <= 1'b0;
		else if(clk_n == 1'b1 && div_cnt == H_DIV_CYC-1'b1)
			spi_negedge <= 1'b1;
		else	
			spi_negedge <= 1'b0;
//SPI时钟上升沿信号,用于读取数据			
always 	@(posedge sys_clk or negedge sys_rst_n)
		if(sys_rst_n == 1'b0)
			spi_posedge <= 1'b0;
		else if(clk_n == 1'b0 && div_cnt == H_DIV_CYC-1'b1)
			spi_posedge <= 1'b1;
		else	
			spi_posedge <= 1'b0;					
//**********************************************************
		


//*****************************各状态完成信号*******************************************

//状态机从空闲进入工作一定要在分频时钟的驱动下
//初始化状态完成
always  @(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	idle_done<='d0;	            
        end
		else if(spi_mode==2'd1)begin
			if(spi_negedge)begin//模式1的时候用下降沿采样en信号
				if((spi_en == 1'b1)&&(state==IDLE))//IDLE状态如果en是高电平就拉高
					idle_done<=1'b1;
				else begin//是低电平就拉低
				    idle_done<=1'b0;
				end
			end			
		end
		else if(spi_mode==2'd3)begin
			if(spi_posedge)begin
				if((spi_en == 1'b1)&&(state==IDLE))
					idle_done<=1'b1;
				else begin
		   			idle_done<=1'b0;  
				end
			end
		end

end

//写状态机完成
//整个写状态完成
always  @(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        	spi_w_r_done<='d0;    
        end
		else if(spi_mode==2'd1)begin
			if((shift_cnt == 5'd8)&&(spi_negedge == 1'b1))
				spi_w_r_done<=1'b1;
			else 
		     	spi_w_r_done<=1'b0;
		end        
		else if(spi_mode==2'd3)begin
			if((shift_cnt == 5'd8)&&(spi_posedge == 1'b1))
				spi_w_r_done<=1'b1;
			else 
		     	spi_w_r_done<=1'b0;
		end
end
//**************************************************************************************		
//状态机状态转换			
always 	@(posedge sys_clk or negedge sys_rst_n)begin
		if(!sys_rst_n)
			state <= IDLE;
		else case (state)
			IDLE :begin			
				if(idle_done)
					state <= SPI_W_R;
			end
			SPI_W_R:begin
				if(spi_w_r_done)begin
					state <= STOP;
				end
			end
			STOP:begin
				if(spi_mode==2'd1)begin
					if(!spi_en)
						state <= IDLE;
					else begin
					    state <= SPI_W_R;
					end
				end				
				if(spi_mode==2'd3)begin
					if(!spi_en)
						state <= IDLE;
					else begin
					    state <= SPI_W_R;
					end
				end
			end
			default:state <= IDLE;		
		endcase		
end	
						
//状态机状态执行
//每个状态该执行什么操作
always  @(posedge sys_clk or negedge sys_rst_n)begin
        if(!sys_rst_n)begin
        		spi_csn <= 1'b1; 
			    spi_clk <= 'd0;   
			    shift_buf <= 'd0;  
			    spi_mosi <= 'd0; 
        end
		else begin
			case(state)
			    IDLE:begin
			    	spi_csn <= 1; 
			    	if(spi_mode==2'd1)begin
			    		spi_clk <= 0;
			    	end
			    	if(spi_mode==2'd3)begin
			    		spi_clk <= 1;
			    	end			    
			    	shift_buf <= spi_sdata;
			    end
				SPI_W_R:begin
					spi_csn <= 0;
					spi_clk <= clk_n;//???
					if(spi_mode==2'd1)begin
						if(spi_posedge)begin
							spi_mosi  <= shift_buf[7];	
						end
						if(spi_negedge)begin
							//将后14位数据向左移位,采集的数据放入最低位
							shift_buf <= {shift_buf[6:0],spi_miso};
						end
					end
					if(spi_mode==2'd3)begin
						if(spi_negedge)begin
							spi_mosi  <= shift_buf[7];	
						end
						if(spi_posedge)begin
							//将后8位数据向左移位,采集的数据放入最低位
							shift_buf <= {shift_buf[6:0],spi_miso};
						end
					end
				end	
				STOP:begin		    				    	
			    	if(spi_en)begin
			    		shift_buf[7:0] <=spi_sdata[7:0];			    	
			    	end
				end
		    endcase
		end	
end


//buff移位计数器
always 	@(posedge sys_clk or negedge sys_rst_n)
		if(!sys_rst_n)
			shift_cnt <= 'd0;
		else if(state == SPI_W_R)
			if(spi_negedge == 1'b1)
				shift_cnt <= shift_cnt + 1'b1;
			else begin
			    shift_cnt <=shift_cnt;
			end	
		else 
			shift_cnt <= 4'd0;

//数据输出,附带数据标记信号
always  @(posedge sys_clk or negedge sys_rst_n)begin
        if (!sys_rst_n)begin
        	spi_done<=1'b0; 
        	spi_rdata<='d0;   
        end
		else if(spi_w_r_done)begin
			//spi_done即是spi一帧数据的完成信号，也是spi读数据的标志信号
			spi_done<=1'b1;
			//在读状态机末，进行判定输出，则数据将在stop状态机输出
			spi_rdata <= shift_buf[7:0];
		end
		else begin
		    spi_done<=1'b0;   
		    spi_rdata<='d0;
		end
end
endmodule
