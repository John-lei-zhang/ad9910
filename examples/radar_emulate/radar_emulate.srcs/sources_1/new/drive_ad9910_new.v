`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/05 22:23:01
// Design Name: 
// Module Name: drive_ad9910_new
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


module drive_ad9910_new(
        input                    i_sys_clk,
        input                    i_sys_rst_n,
        
        input          [7:0]     i_spi_rxdata,
        input                    i_spi_done,
        
        output   reg  [2:0]      o_profile_ctl,
        output   reg             o_io_update,
        output   reg             o_master_reset,
        output   reg             o_io_reset,
        
        output   reg   [7:0]     o_spi_txdata,       
        output                   o_spi_mode,
        output   reg             o_spi_en    
    );
    
parameter spi_mode = 3'd3;//第三种spi总线时序模式


//----------------------------------------三段式FSM---------------------------------------//
parameter IDLE             = 8'b00000001,
          RESET             = 8'b00000010,
          TRANS_CR1         = 8'b00000100,
          TRANS_CR2         = 8'b00001000,
          TRANS_CR3         = 8'b00010000,
          TRANS_PROFILE_0   = 8'b00100000,
          ENABLE_IO_UPDATE  = 8'b01000000,
          DISEN_IO_UPDATE   = 8'b10000000;
          
reg [3:0] current_state;
reg [3:0] next_state;


reg [7:0] r_reset_cnt;
reg       r_reset_finish_flag;
reg [39:0] ad9910_cr1 = {8'h00,32'h0000_0002};//将spi配置成三线
reg [39:0] ad9910_cr2 = {8'h01,32'h0140_0820};
reg [39:0] ad9910_cr3 = {8'h02,32'h1D3F_4150};
reg [71:0] ad9910_profile_0 = {8'h0e,64'h08B5_0000_000C_CCCD};
//状态转移
always @ (posedge i_sys_clk or negedge i_sys_rst_n)
    begin
        if(!i_sys_rst_n)begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
 always @ (*)
    begin
         case(current_state)
           IDLE:begin 
                    next_state = RESET; 
                end
           RESET:begin
                    if(r_reset_finish_flag == 1'b1)begin
                        next_state = TRANS_CR1;
                    end else begin
                        next_state = RESET;
                    end
                 end
           TRANS_CR1:begin end
           TRANS_CR2:begin end
           TRANS_CR3:begin end
           TRANS_PROFILE_0:begin end
           ENABLE_IO_UPDATE:begin end
           DISEN_IO_UPDATE:begin end
         endcase
    end   
 
 
 always @ (posedge i_sys_clk or negedge i_sys_rst_n)   
    begin
        if(!i_sys_rst_n)begin
            r_reset_cnt <= 1'b0;
            r_reset_finish_flag <= 1'b0;
        
            o_profile_ctl <= 3'b000;
            o_io_update <= 1'b0;//上升沿有效
            o_io_reset <= 1'b0;//上升沿有效,其高电平保持时间不低于一个sync_clk时钟
            o_spi_txdata <= 8'bz;
            o_spi_en <= 1'b0;
            o_master_reset <= 1'b0;//高电平有效
            
        end else begin
            case(current_state)
                IDLE:begin
                    o_profile_ctl <= 3'b000;
                    o_io_update <= 1'b0;
                    o_io_reset <= 1'b0;
                    o_spi_txdata <= 8'bz;
                    o_spi_en <= 1'b0;
                    o_master_reset <= 1'b0;//高电平有效
                end
                RESET:begin 
                    if(r_reset_cnt <= 'd100)begin
                        r_reset_cnt <= 1'b0;
                        r_reset_finish_flag <= 1'b1;//复位结束
                        
                        o_spi_en <= 1'b1;
                        o_io_reset <= 1'b1;
                        o_master_reset <= 1'b1;
                    end else begin
                        o_io_reset <= 1'b1;
                        o_master_reset <= 1'b1;
                        
                        r_reset_cnt <= r_reset_cnt + 1'b1;
                    end
                end
                TRANS_CR1:begin 
                    o_spi_en <= 1'b1;//使能spi
                    
                end
                TRANS_CR2:begin end
                TRANS_CR3:begin end
                TRANS_PROFILE_0:begin end
                ENABLE_IO_UPDATE:begin end
                DISEN_IO_UPDATE:begin end
            endcase
        end
    end

endmodule
