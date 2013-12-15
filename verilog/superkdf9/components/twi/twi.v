`include "twi_define.v"
module twi(
    // system clock and reset
    input          CLK_I       ,
    input          RST_I       ,
    
    // wishbone interface signals
    input          TWI_CYC_I   ,//NC
    input          TWI_STB_I   ,
    input          TWI_WE_I    ,
    input          TWI_LOCK_I  ,//NC
    input  [2:0]   TWI_CTI_I   ,//NC
    input  [1:0]   TWI_BTE_I   ,//NC
    input  [5:0]   TWI_ADR_I   ,
    input  [31:0]  TWI_DAT_I   ,
    input  [3:0]   TWI_SEL_I   ,
    output reg     TWI_ACK_O   ,
    output         TWI_ERR_O   ,//const 0
    output         TWI_RTY_O   ,//const 0
    output [31:0]  TWI_DAT_O   ,

    output         TWI_SCL_O   ,
    input          TWI_SDA_I   ,
    output         TWI_SDA_OEN ,
    output         PWM         ,
    output         WATCH_DOG   , 

    output         SFT_SHCP    ,
    output         SFT_DS      ,
    output         SFT_STCP    ,
    output         SFT_MR_N    ,
    output         SFT_OE_N    ,

    input          FAN_IN0     ,
    input          FAN_IN1     
);

assign TWI_ERR_O = 1'b0 ;
assign TWI_RTY_O = 1'b0 ;

//-----------------------------------------------------
// WB bus ACK
//-----------------------------------------------------
always @ ( posedge CLK_I or posedge RST_I ) begin
        if( RST_I )
                TWI_ACK_O <= 1'b0 ;
        else if( TWI_STB_I && (~TWI_ACK_O) )
                TWI_ACK_O <= 1'b1 ;
        else 
                TWI_ACK_O <= 1'b0 ;
end

wire i2cr_wr_en  = TWI_STB_I & TWI_WE_I  & ( TWI_ADR_I == `I2CR) & ~TWI_ACK_O ;
wire i2wd_wr_en  = TWI_STB_I & TWI_WE_I  & ( TWI_ADR_I == `I2WD) & ~TWI_ACK_O ;
wire pwm_wr_en   = TWI_STB_I & TWI_WE_I  & ( TWI_ADR_I == `PWMC) & ~TWI_ACK_O ;
wire wdg_wr_en   = TWI_STB_I & TWI_WE_I  & ( TWI_ADR_I == `WDG ) & ~TWI_ACK_O ;
wire sft_wr_en   = TWI_STB_I & TWI_WE_I  & ( TWI_ADR_I == `SFT ) & ~TWI_ACK_O ;

wire i2cr_rd_en  = TWI_STB_I & ~TWI_WE_I  & ( TWI_ADR_I == `I2CR) & ~TWI_ACK_O ;
wire i2rd_rd_en  = TWI_STB_I & ~TWI_WE_I  & ( TWI_ADR_I == `I2RD) & ~TWI_ACK_O ;
wire wdg_rd_en   = TWI_STB_I & ~TWI_WE_I  & ( TWI_ADR_I == `WDG ) & ~TWI_ACK_O ;
wire sft_rd_en   = TWI_STB_I & ~TWI_WE_I  & ( TWI_ADR_I == `SFT ) & ~TWI_ACK_O ;
wire fan0_rd_en  = TWI_STB_I & ~TWI_WE_I  & ( TWI_ADR_I == `FAN0 ) & ~TWI_ACK_O ;
wire fan1_rd_en  = TWI_STB_I & ~TWI_WE_I  & ( TWI_ADR_I == `FAN1 ) & ~TWI_ACK_O ;

//-----------------------------------------------------
// PWM
//-----------------------------------------------------
reg [9:0] reg_pwm ;
reg [9:0] pwm_cnt ;
always @ ( posedge CLK_I or posedge RST_I ) begin
	if( RST_I )
		reg_pwm <= 10'h00 ;
	else if( pwm_wr_en )
		reg_pwm <= TWI_DAT_I[9:0] ;
end

always @ ( posedge CLK_I or posedge RST_I ) begin
	if( RST_I )
		pwm_cnt <= 10'b0 ;
	else
		pwm_cnt <= pwm_cnt + 10'b1 ;
end

assign PWM = pwm_cnt < reg_pwm ;

//-----------------------------------------------------
// WDG
//-----------------------------------------------------
reg wdg_en ;
reg [25:0] wdg_cnt ;

always @ ( posedge CLK_I or posedge RST_I ) begin
	if( RST_I )
		wdg_en <= 1'b0 ;
	else if( wdg_wr_en )
		wdg_en <= TWI_DAT_I[0] ;
end

always @ ( posedge CLK_I or posedge RST_I ) begin
	if( RST_I )
		wdg_cnt <= 26'b0 ;
	else if( wdg_wr_en && (wdg_en || TWI_DAT_I[0]) )
		wdg_cnt <= TWI_DAT_I[26:1] ;
	else if( |wdg_cnt )
		wdg_cnt <= wdg_cnt - 1 ;
end

assign WATCH_DOG = wdg_en && (wdg_cnt == 1 || wdg_cnt == 2) ;

//-----------------------------------------------------
// SHIFT
//-----------------------------------------------------
/*
00: Set master reset
01: Shift register
10: Storage register
11: Output Enable
*/
wire sft_done ;
reg sft_done_r ;
wire [31:0] reg_sft = {28'b0,sft_done_r,SFT_OE_N,2'b0} ;
always @ ( posedge CLK_I or posedge RST_I ) begin
	if( RST_I )
		sft_done_r <= 1'b0 ;
	else if( sft_wr_en )
		sft_done_r <= 1'b0 ;
	else if( sft_done )
		sft_done_r <= 1'b1 ;
end

shift u_shift(
/*input       */ .clk      (CLK_I          ) ,
/*input       */ .rst      (RST_I          ) ,
/*input       */ .vld      (sft_wr_en      ) ,
/*input  [1:0]*/ .cmd      (TWI_DAT_I[1:0] ) ,
/*input       */ .cmd_oen  (TWI_DAT_I[2]   ) ,
/*input  [7:0]*/ .din      (TWI_DAT_I[15:8]) ,
/*output      */ .done     (sft_done       ) ,

/*output      */ .sft_shcp (SFT_SHCP       ) ,
/*output      */ .sft_ds   (SFT_DS         ) ,
/*output      */ .sft_stcp (SFT_STCP       ) ,
/*output      */ .sft_mr_n (SFT_MR_N       ) ,
/*output      */ .sft_oe_n (SFT_OE_N       ) 
);

//-----------------------------------------------------
// fan speed
//-----------------------------------------------------
reg [25:0] sec_cnt ;//1m
reg [25:0] fan_cnt0 ;
reg [25:0] fan_cnt1 ;
reg [25:0] reg_fan0 ;
reg [25:0] reg_fan1 ;
reg [4:0] clk_div ;
wire fan_clk = clk_div[4] ;

always @ ( posedge CLK_I or posedge RST_I ) begin
	clk_div <= clk_div + 1 ;
end

always @ ( posedge fan_clk or posedge RST_I ) begin
	if( RST_I )
		sec_cnt <= 26'b0 ;
	else if( sec_cnt == 26'h17d784 )
		sec_cnt <= 26'b0 ;
	else
		sec_cnt <= 26'b1 + sec_cnt ;
end

always @ ( posedge fan_clk or posedge RST_I ) begin
	if( RST_I )
		fan_cnt0 <= 26'b0 ;
	//else if( sec_cnt == 26'h2faf080 ) begin
	else if( sec_cnt == 26'h17d784 ) begin
		fan_cnt0 <= 26'b0 ;
		reg_fan0 <= fan_cnt0 ;
	end else if( ~FAN_IN0 )
		fan_cnt0 <= fan_cnt0 + 26'b1 ;
end

always @ ( posedge fan_clk or posedge RST_I ) begin
	if( RST_I )
		fan_cnt1 <= 26'b0 ;
	else if( sec_cnt == 26'h17d784 ) begin
		fan_cnt1 <= 26'b0 ;
		reg_fan1 <= fan_cnt1 ;
	end else if( ~FAN_IN1 )
		fan_cnt1 <= fan_cnt1 + 26'b1 ;
end

//-----------------------------------------------------
// read
//-----------------------------------------------------
reg i2cr_rd_en_r ;
reg wdg_rd_en_r ;
reg sft_rd_en_r ;
reg fan0_rd_en_r ;
reg fan1_rd_en_r ;

wire [7:0] reg_i2cr ;
wire [7:0] reg_i2rd ;
always @ ( posedge CLK_I ) begin
	i2cr_rd_en_r <= i2cr_rd_en ;
	wdg_rd_en_r <= wdg_rd_en ;
	sft_rd_en_r <= sft_rd_en ;
	fan0_rd_en_r <= fan0_rd_en ;
	fan1_rd_en_r <= fan1_rd_en ;
end

assign TWI_DAT_O = i2cr_rd_en_r ? {24'b0,reg_i2cr}     : 
		   wdg_rd_en_r  ? {5'b0,wdg_cnt,wdg_en}:
		   sft_rd_en_r  ? reg_sft              : 
		   fan0_rd_en_r ? {6'b0,reg_fan0}      :
		   fan1_rd_en_r ? {6'b0,reg_fan1}      :
                   {24'b0,reg_i2rd} ;

twi_core twi_core (
/*input       */ .clk          (CLK_I                ) , 
/*input       */ .rst          (RST_I                ) ,
/*input       */ .wr           (i2cr_wr_en|i2wd_wr_en) , //we
/*input  [7:0]*/ .data_in      (TWI_DAT_I[7:0]       ) ,//dat1
/*input  [7:0]*/ .wr_addr      ({2'b0,TWI_ADR_I}     ) ,//adr1 
/*output [7:0]*/ .i2cr         (reg_i2cr             ) ,
/*output [7:0]*/ .i2rd         (reg_i2rd             ) ,
/*output      */ .twi_scl_o    (TWI_SCL_O            ) ,
/*input       */ .twi_sda_i    (TWI_SDA_I            ) ,
/*output      */ .twi_sda_oen  (TWI_SDA_OEN          )
);

endmodule

