//============================================================================
//  Arcade: Battlezone
//
//  Port to MiSTer
//  Copyright (C) 2018 
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================
module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,
	output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign HDMI_FREEZE = 0;
assign VGA_DISABLE=0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

assign LED_USER  = ioctl_download | fifo_full_led;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

// SDRAM carries the compressed halo-alignment delay line; DDRAM carries the
// tile framebuffer. Both are driven by vfb_top -- see the instantiation below.
assign SDRAM_DQ   = sdram_dq_oe ? sdram_dq_out : 16'hzzzz;
assign SDRAM_DQML = sdram_dqm[0];
assign SDRAM_DQMH = sdram_dqm[1];
assign SDRAM_CLK  = ~clk_125;

assign BUTTONS = 0;

assign AUDIO_MIX = 0;

`include "build_id.v"
//
// status bit allocation
//   0        Reset
//   3        Self Test
//   15:14    Aspect ratio
//   20       Overlay on/off
//   25       120 Hz output
//   28:26    CRT profile
//   30:29    Dot scale      (only meaningful with the profile Off)
//   32:31    Phosphor decay (only meaningful with the profile Off)
//   33       Direct video scan rate
//   34       Debug overlay (bring-up diagnostics)
//
localparam CONF_STR = {
	"A.BATTLEZONE;;",
	"OEF,Aspect ratio,Optimized,Stretched,Pixel Perfect;",
	"h0OX,Direct Video Scan Rate,15 kHz (240p),31 kHz (480p);",
	"D3OP,120Hz Output (720p),Off,On;",
	"-;",
	"OQS,CRT Profile,80s Cruise Control,80s Overdrive,Neon Fever Dream,Custom 1,Custom 2,Off,A Touch of CRT;",
	"h7OTU,Dot Scale,Auto,Off,1,2;",
	"h7OVW,Phosphor Decay,Off,Short,Medium,Long;",
	"-;",
	"h8OK,Overlay,On,Off;",
	"-;",
	"OY,Debug Overlay,Off,On;",
	"-;",
	"DIP;",
	"-;",
	"O3,Self Test,Off,On;",
	"-;",
	"R0,Reset;",
	"J1,fire,Start 1P,Start 2P,Coin,Pause;",
	"jn,A,Start,Select,R,L;",
	"V,v",`BUILD_DATE
};

wire [15:0] status_menumask = {
	7'd0,
	mod_is_battlezone,           // h8 - overlay only exists on Battlezone
	crt_profile_off,             // h7
	3'd0,
	(STABLE_HEIGHT != 12'd720),  // D3 - 120 Hz is 720p only
	2'd0,
	direct_video                 // h0
};

////////////////////   CLOCKS   ///////////////////

wire clk_6, clk_12, clk_50, clk_125;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_50),
	.outclk_1(clk_12),
	.outclk_2(clk_6),
	.outclk_3(clk_125),
	.locked(pll_locked)
);

assign CLK_VIDEO = clk_125;

///////////////////////////////////////////////////


wire [127:0] status;
wire   [1:0] buttons;
wire         direct_video;
wire         forced_scandoubler;
wire  [21:0] gamma_bus;

wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_index;

wire [15:0] joy_0, joy_1;
wire [15:0] joy = joy_0 | joy_1;
wire [15:0] joya;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_12),
	.HPS_BUS(HPS_BUS),

	.buttons(buttons),
	.status(status),
	.status_menumask(status_menumask),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	.forced_scandoubler(forced_scandoubler),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_index(ioctl_index),

	.joystick_0(joy_0),
	.joystick_1(joy_1),
	.joystick_l_analog_0(joya)
);

localparam mod_battlezone = 0;
localparam mod_bradley    = 1;
localparam mod_redbaron   = 2;

reg [7:0] mod = 255;
always @(posedge clk_12) if (ioctl_wr & (ioctl_index==1)) mod <= ioctl_dout;

wire mod_is_battlezone = (mod == mod_battlezone);
wire mod_is_bradley    = (mod == mod_bradley);
wire mod_is_redbaron   = (mod == mod_redbaron);

reg [7:0] sw[8];
always @(posedge clk_12) if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) sw[ioctl_addr[2:0]] <= ioctl_dout;

wire [7:0] DSW0 = sw[0];
wire [7:0] DSW1 = sw[1];

wire reset = (RESET | status[0] | buttons[1] | ioctl_download);

////////////////////   INPUTS   ///////////////////

// Battlezone's twin sticks synthesized from a single d-pad (from Ultratank).
reg JoyW_Fw, JoyW_Bk, JoyX_Fw, JoyX_Bk;
always @(posedge clk_12) begin
	case ({joy[3],joy[2],joy[1],joy[0]}) // Up,Down,Left,Right
		4'b1010: begin JoyW_Fw<=0; JoyW_Bk<=0; JoyX_Fw<=1; JoyX_Bk<=0; end //Up_Left
		4'b1000: begin JoyW_Fw<=1; JoyW_Bk<=0; JoyX_Fw<=1; JoyX_Bk<=0; end //Up
		4'b1001: begin JoyW_Fw<=1; JoyW_Bk<=0; JoyX_Fw<=0; JoyX_Bk<=0; end //Up_Right
		4'b0001: begin JoyW_Fw<=1; JoyW_Bk<=0; JoyX_Fw<=0; JoyX_Bk<=1; end //Right
		4'b0101: begin JoyW_Fw<=0; JoyW_Bk<=1; JoyX_Fw<=0; JoyX_Bk<=0; end //Down_Right
		4'b0100: begin JoyW_Fw<=0; JoyW_Bk<=1; JoyX_Fw<=0; JoyX_Bk<=1; end //Down
		4'b0110: begin JoyW_Fw<=0; JoyW_Bk<=0; JoyX_Fw<=0; JoyX_Bk<=1; end //Down_Left
		4'b0010: begin JoyW_Fw<=0; JoyW_Bk<=1; JoyX_Fw<=1; JoyX_Bk<=0; end //Left
		default: begin JoyW_Fw<=0; JoyW_Bk<=0; JoyX_Fw<=0; JoyX_Bk<=0; end
	endcase
end

//
// Red Baron analog fallback.
//
// Red Baron has a single self-centering flight stick read through POKEY's pot
// lines. Previously the raw analog axis was written straight into ALLPOT, so
// with no analog stick connected the value sat at centre and the d-pad did
// nothing at all. Synthesize a stick position from the d-pad when no analog
// input is present: ramp toward the extreme while held, spring back to centre
// when released, which is what the real stick does.
//
// MAME constrains Red Baron's stick to 0x40..0xbf, i.e. centre 128 +/- 63, so
// match that range rather than driving the full 0..255.
localparam signed [7:0] RB_LIMIT = 8'sd63;
localparam RB_RATE = 12'd3000;   // ~0.25 s from centre to full deflection

wire signed [7:0] joya_x = $signed(joya[15:8]) >>> 1;
wire signed [7:0] joya_y = $signed(joya[7:0])  >>> 1;
wire analog_active = (joya[15:8] != 8'd0) || (joya[7:0] != 8'd0);

reg [11:0] rb_tick = 0;
reg signed [7:0] rb_x = 0;
reg signed [7:0] rb_y = 0;
wire rb_step = (rb_tick == RB_RATE);

always @(posedge clk_12) begin
	rb_tick <= rb_step ? 12'd0 : rb_tick + 12'd1;
	if (rb_step) begin
		// X: joy[0] right, joy[1] left
		if (joy[0] && !joy[1])       rb_x <= (rb_x <  RB_LIMIT) ? rb_x + 8'sd1 : rb_x;
		else if (joy[1] && !joy[0])  rb_x <= (rb_x > -RB_LIMIT) ? rb_x - 8'sd1 : rb_x;
		else if (rb_x > 0)           rb_x <= rb_x - 8'sd1;
		else if (rb_x < 0)           rb_x <= rb_x + 8'sd1;

		// Y: joy[3] up, joy[2] down
		if (joy[3] && !joy[2])       rb_y <= (rb_y <  RB_LIMIT) ? rb_y + 8'sd1 : rb_y;
		else if (joy[2] && !joy[3])  rb_y <= (rb_y > -RB_LIMIT) ? rb_y - 8'sd1 : rb_y;
		else if (rb_y > 0)           rb_y <= rb_y - 8'sd1;
		else if (rb_y < 0)           rb_y <= rb_y + 8'sd1;
	end
end

wire signed [7:0] rb_axis_x = analog_active ? joya_x : rb_x;
wire signed [7:0] rb_axis_y = analog_active ? joya_y : rb_y;

// POKEY pot lines are unsigned, centred at 128. POTGO snapshots these into
// ALLPOT (POKEY.sv:176) and the game reads them back at $8 -- the same model
// MAME uses, where Red Baron overrides allpot_r() to return the stick value.
wire [7:0] rb_pot_x = 8'd128 + rb_axis_x;
wire [7:0] rb_pot_y = 8'd128 + rb_axis_y;

wire [7:0] JB;
wire [7:0] arcadebuttons;
wire       audiosel;
wire [7:0] REDBARONBUTTONS;

assign JB = mod_is_redbaron
	? { ~joy[7], joy[5], joy[6], joy[4], joy[2], joy[3], joy[0], joy[1] }
	: {  joy[7], joy[5], joy[6], joy[4], JoyW_Fw, JoyW_Bk, JoyX_Fw, JoyX_Bk };

// POKEY P port: NC, NC, Start, Fire, L-For, L-Rev, R-For, R-Rev
assign arcadebuttons = mod_is_redbaron
	? (audiosel ? rb_pot_y : rb_pot_x)
	: { 2'b00, joy[5], |{joy[6],joy[4]}, JoyW_Fw, JoyW_Bk, JoyX_Fw, JoyX_Bk };

assign REDBARONBUTTONS = mod_is_redbaron ? {joy[4], joy[5], 6'b0} : 8'b0;

////////////////////   PAUSE   ////////////////////

// J1 lists fire, Start 1P, Start 2P, Coin, Pause -> joy[4] .. joy[8].
wire m_pause = joy[8];
wire pause_cpu;
wire [11:0] pause_rgb_unused;

pause #(4,4,4,12) pause_mod (
	.clk_sys(clk_12),
	.reset(reset),
	.user_button(m_pause),
	.pause_request(1'b0),
	.options({1'b0, 1'b0}),
	.OSD_STATUS(OSD_STATUS),
	.r(4'd0), .g(4'd0), .b(4'd0),
	.pause_cpu(pause_cpu),
	.rgb_out(pause_rgb_unused)
);

////////////////////   CORE   /////////////////////

wire [13:0] avg_x;
wire [13:0] avg_y;
wire  [7:0] avg_z_raw;
wire  [2:0] avg_rgb;
wire        avg_is_dot;
wire        avg_halted;
wire        dbg_vggo, dbg_vgrst;
wire [15:0] dbg_cpu_addr;

assign AUDIO_R = AUDIO_L;
// Unsigned is correct despite ASSESSMENT.md 5.1 flagging it: audio_output.sv:70
// sums pokey_filtered (4-bit POKEY zero-padded into bits 13:10) with
// analog_audio, both non-negative, so the result never goes below zero. The
// signed accumulator inside iir.sv is an implementation detail of the filter.
assign AUDIO_S = 0;

top bzonetop(
  .clk_12(clk_12),
  .clk_50(clk_50),
  .btnCpuReset(~reset),
  .DSW0(DSW0),
  .DSW1(DSW1),
  .JB(JB),
  .buttons(arcadebuttons),
  .REDBARONBUTTONS(REDBARONBUTTONS),
  .audiosel(audiosel),
  .self_test(~status[3]),
  .pause_cpu(pause_cpu),
  .avg_x(avg_x),
  .avg_y(avg_y),
  .avg_z(avg_z_raw),
  .avg_rgb(avg_rgb),
  .avg_is_dot(avg_is_dot),
  .avg_halted(avg_halted),
  .dbg_vggo(dbg_vggo),
  .dbg_vgrst(dbg_vgrst),
  .dbg_cpu_addr(dbg_cpu_addr),
  .audio(AUDIO_L),
  .dl_addr(ioctl_addr),
  .dl_data(ioctl_dout),
  .dl_wr(ioctl_wr & !ioctl_index),
  .mod_bradley(mod_is_bradley),
  .mod_redbaron(mod_is_redbaron),
  .mod_battlezone(mod_is_battlezone)
);

/////////////////   VIDEO MODE   //////////////////

reg [11:0] h_s1 = 0, h_s2 = 0;
reg [11:0] hdmi_height_candidate = 0;
reg [11:0] stable_height_reg = 0;
reg [24:0] hdmi_height_timer = 0;
reg direct_video_s1 = 0, direct_video_s2 = 0;
reg direct_video_31khz_s1 = 0, direct_video_31khz_s2 = 0;

always @(posedge clk_50) begin
	direct_video_s1 <= direct_video;
	direct_video_s2 <= direct_video_s1;
	direct_video_31khz_s1 <= status[33];
	direct_video_31khz_s2 <= direct_video_31khz_s1;

	if (direct_video_s2)
		h_s1 <= direct_video_31khz_s2 ? 12'd480 : 12'd240;
	else
		h_s1 <= HDMI_HEIGHT;
	h_s2 <= h_s1;

	if (h_s1 == h_s2) begin
		if (h_s2 > 12'd200 && h_s2 == hdmi_height_candidate) begin
			if (hdmi_height_timer < 25'd25_000_000) begin
				hdmi_height_timer <= hdmi_height_timer + 1'd1;
			end else begin
				stable_height_reg <= hdmi_height_candidate;
			end
		end else begin
			hdmi_height_candidate <= h_s2;
			hdmi_height_timer <= 0;
			stable_height_reg <= 0;
		end
	end
end

reg hz_s1 = 0, hz_s2 = 0;
reg osd_120hz_latched = 0;
reg [24:0] hz_timer = 0;

always @(posedge clk_50) begin
	hz_s1 <= status[25];
	hz_s2 <= hz_s1;

	if (hz_s1 == hz_s2) begin
		if (hz_s2 != osd_120hz_latched) begin
			if (hz_timer < 25'd25_000_000) hz_timer <= hz_timer + 1'd1;
			else begin osd_120hz_latched <= hz_s2; hz_timer <= 0; end
		end else hz_timer <= 0;
	end
end

wire is_120hz_changing = (hz_s2 != osd_120hz_latched) || (hz_timer > 0);
wire [11:0] STABLE_HEIGHT = is_120hz_changing ? 12'd0 : stable_height_reg;
wire STABLE_120HZ = osd_120hz_latched & (STABLE_HEIGHT == 12'd720);

// Profile encoding matches vfb_profile_resolver: 0=Off .. 7=Custom2.
// The OSD lists the useful ones first, so rotate onto that encoding.
wire [2:0] crt_profile_sel = status[28:26];
wire [2:0] crt_profile =
	(crt_profile_sel == 3'd0) ? 3'd2 :   // 80s Cruise Control
	(crt_profile_sel == 3'd1) ? 3'd3 :   // 80s Overdrive
	(crt_profile_sel == 3'd2) ? 3'd4 :   // Neon Fever Dream
	(crt_profile_sel == 3'd3) ? 3'd6 :   // Custom 1
	(crt_profile_sel == 3'd4) ? 3'd7 :   // Custom 2
	(crt_profile_sel == 3'd5) ? 3'd0 :   // Off
	                            3'd1;    // A Touch of CRT

wire crt_profile_off = (crt_profile == 3'd0);

wire [2:0] effective_dot_mode;
wire [1:0] effective_tonemapping;
wire [2:0] effective_bloom_width;
wire [2:0] effective_bloom_curve;
wire [2:0] effective_halo_filter;
wire [1:0] effective_halo_spread;
wire [1:0] effective_phosphor_mode;
wire       effective_color_space;
wire [2:0] effective_color_channels;
wire       effective_slot_mask;
wire       effective_full_bypass;

reg [11:0] fb_width  = 12'd640;
reg [11:0] fb_height = 12'd480;
reg [11:0] x_center  = 12'd320;
reg [11:0] y_center  = 12'd237;
reg [12:0] auto_arx  = 13'h1000 | 13'd640;
reg [12:0] auto_ary  = 13'h1000 | 13'd480;

vfb_profile_resolver crt_profiles (
	.profile(crt_profile),
	.fb_height(fb_height),
	.off_dot_mode({1'b0, status[30:29]}),
	.off_tonemapping(2'd0),
	.off_phosphor_mode(status[32:31]),
	.custom1_settings(23'd0),
	.custom2_settings(23'd0),
	.dot_mode(effective_dot_mode),
	.tonemapping(effective_tonemapping),
	.bloom_width(effective_bloom_width),
	.bloom_curve(effective_bloom_curve),
	.halo_filter(effective_halo_filter),
	.halo_spread(effective_halo_spread),
	.phosphor_mode(effective_phosphor_mode),
	.color_space(effective_color_space),
	.color_channels(effective_color_channels),
	.slot_mask(effective_slot_mask),
	.full_bypass(effective_full_bypass)
);

reg [11:0] h_total_reg  = 12'd992;
reg [11:0] v_total_reg  = 12'd524;
reg [11:0] hs_start_reg = 12'd720;
reg [11:0] hs_end_reg   = 12'd816;
reg [11:0] vs_start_reg = 12'd490;
reg [11:0] vs_end_reg   = 12'd492;

reg is_1080p = 1'b0;
reg is_480p  = 1'b1;
reg is_240p  = 1'b0;

reg signed [11:0] x_scaled;
reg signed [11:0] y_scaled;
wire signed [21:0] avg_x_ext = $signed(avg_x);
wire signed [21:0] avg_y_ext = $signed(avg_y);

reg [11:0] stable_height_meta = 12'd480;
reg osd_120hz_meta;
reg osd_120hz_vid = 0;
reg fb_reset_vid = 1'b0;

reg [11:0] fb_width_next, fb_height_next, x_center_next, y_center_next;
reg [12:0] auto_arx_next, auto_ary_next;
reg [11:0] h_total_next, v_total_next, hs_start_next, hs_end_next, vs_start_next, vs_end_next;
reg is_1080p_next, is_480p_next, is_240p_next;
reg [12:0] band_recip_next;
reg [12:0] band_recip = 13'd2185;

always @(*) begin
	is_1080p_next = (stable_height_meta >= 12'd1080 && stable_height_meta < 12'd1400);
	is_480p_next  = (stable_height_meta >= 12'd480  && stable_height_meta < 12'd720);
	is_240p_next  = (stable_height_meta != 12'd0    && stable_height_meta < 12'd480);

	if (is_1080p_next) begin
		fb_width_next = 12'd1472; fb_height_next = 12'd1080;
		x_center_next = 12'd736;  y_center_next  = 12'd525;
		auto_arx_next = 13'h1000 | 13'd1472;
		auto_ary_next = 13'h1000 | 13'd1080;
		h_total_next  = 12'd1851; v_total_next  = 12'd1124;
		hs_start_next = 12'd1600; hs_end_next   = 12'd1688;
		vs_start_next = 12'd1088; vs_end_next   = 12'd1093;
		band_recip_next = 13'd978;   // 65536/(1080/16)
	end else if (is_240p_next) begin
		fb_width_next = 12'd640;  fb_height_next = 12'd240;
		x_center_next = 12'd320;  y_center_next  = 12'd119;
		auto_arx_next = 13'h1000 | 13'd640;
		auto_ary_next = 13'h1000 | 13'd240;
		h_total_next  = 12'd993;  v_total_next  = 12'd261;
		hs_start_next = 12'd720;  hs_end_next   = 12'd816;
		vs_start_next = 12'd245;  vs_end_next   = 12'd248;
		band_recip_next = 13'd4369;  // 65536/(240/16)
	end else if (is_480p_next) begin
		fb_width_next = 12'd640;  fb_height_next = 12'd480;
		x_center_next = 12'd320;  y_center_next  = 12'd237;
		auto_arx_next = 13'h1000 | 13'd640;
		auto_ary_next = 13'h1000 | 13'd480;
		h_total_next  = 12'd992;  v_total_next  = 12'd524;
		hs_start_next = 12'd720;  hs_end_next   = 12'd816;
		vs_start_next = 12'd490;  vs_end_next   = 12'd492;
		band_recip_next = 13'd2185;  // 65536/(480/16)
	end else begin
		fb_width_next = 12'd980;  fb_height_next = 12'd720;
		x_center_next = 12'd490;  y_center_next  = 12'd350;
		auto_arx_next = (stable_height_meta >= 12'd1440) ? (13'h1000 | 13'd1960) : (13'h1000 | 13'd980);
		auto_ary_next = (stable_height_meta >= 12'd1440) ? (13'h1000 | 13'd1440) : (13'h1000 | 13'd720);
		h_total_next  = 12'd1388; v_total_next  = 12'd749;
		hs_start_next = 12'd1108; hs_end_next   = 12'd1196;
		vs_start_next = 12'd728;  vs_end_next   = 12'd733;
		band_recip_next = 13'd1456;  // 65536/(720/16)
	end
end

always @(posedge clk_125) begin
	stable_height_meta <= STABLE_HEIGHT;
	osd_120hz_meta     <= STABLE_120HZ;
	osd_120hz_vid      <= osd_120hz_meta;

	if (stable_height_meta == 12'd0) begin
		fb_reset_vid <= 1'b1;
	end else begin
		fb_reset_vid <= 1'b0;
		fb_width  <= fb_width_next;  fb_height <= fb_height_next;
		x_center  <= x_center_next;  y_center  <= y_center_next;
		auto_arx  <= auto_arx_next;  auto_ary  <= auto_ary_next;
		h_total_reg  <= h_total_next;  v_total_reg  <= v_total_next;
		hs_start_reg <= hs_start_next; hs_end_reg   <= hs_end_next;
		vs_start_reg <= vs_start_next; vs_end_reg   <= vs_end_next;
		is_1080p <= is_1080p_next; is_480p <= is_480p_next; is_240p <= is_240p_next;
		band_recip <= band_recip_next;
	end
end

wire [1:0] ar = status[15:14];
assign VIDEO_ARX = (ar == 2'd0) ? auto_arx : (ar == 2'd1) ? 13'd0 : (13'h1000 | fb_width);
assign VIDEO_ARY = (ar == 2'd0) ? auto_ary : (ar == 2'd1) ? 13'd0 : (13'h1000 | fb_height);

//
// AVG coordinate scaling.
//
// Measured against the pre-rework 640x480 output, which is the reference for
// Battlezone's proportions. The constants inherited from Black Widow rendered
// the image uniformly 1.34x too large about the centre -- the horizon sat
// correctly at mid-screen but the mountains clipped at both edges. Comparing
// the isolated "(c) ATARI 1980" line gave a width ratio of 1.342 and a height
// ratio of 1.278 (the latter coarse, 12 px vs 23 px), i.e. one uniform
// overscale rather than an aspect error, so every constant is divided by 1.34
// and normalised onto a >>>10 shift.
//
always @(*) begin
	if (is_1080p) begin
		x_scaled = (avg_x_ext * 22'sd73) >>> 10;
		y_scaled = (avg_y_ext * 22'sd58) >>> 10;
	end else if (is_240p) begin
		x_scaled = (avg_x_ext * 22'sd32) >>> 10;
		y_scaled = (avg_y_ext * 22'sd13) >>> 10;
	end else if (is_480p) begin
		x_scaled = (avg_x_ext * 22'sd32) >>> 10;
		y_scaled = (avg_y_ext * 22'sd26) >>> 10;
	end else begin
		x_scaled = (avg_x_ext * 22'sd48) >>> 10;
		y_scaled = (avg_y_ext * 22'sd39) >>> 10;
	end
end

wire signed [11:0] new_x = $signed(x_center) + x_scaled;
wire signed [11:0] new_y = $signed(y_center) - 12'sd1 - y_scaled;
wire [10:0] final_x = new_x[10:0];
wire [10:0] final_y = new_y[10:0];
wire beam_in_bounds = (new_x[11:0] < (is_1080p ? 12'd1470 : fb_width)) &&
                      (new_y[11:0] < fb_height);

//
// Battlezone, Red Baron and Bradley are all monochrome -- the colour came from
// a mylar overlay, not the vector generator. The STAT colour bits are not
// meaningful here, so drive the renderer white and apply the overlay after it.
//
wire [2:0] beam_rgb = 3'b111;
wire raw_beam_on = |avg_z_raw;

wire [7:0] final_z = avg_z_raw;

// Dot scale: pick from the framebuffer size unless the profile overrides it.
wire [2:0] auto_dot_mode = (fb_height >= 12'd1000) ? 3'd2 :
                           (fb_height >= 12'd700)  ? 3'd1 : 3'd0;
wire [2:0] actual_dot_mode = (effective_dot_mode == 3'd0) ? auto_dot_mode
                                                          : (effective_dot_mode - 3'd1);

reg [10:0] vfb_x_q, vfb_y_q;
reg  [7:0] vfb_z_q;
reg  [2:0] vfb_rgb_q;
reg        vfb_is_dot_q, vfb_beam_on_q, vfb_frame_done_q;
reg  [2:0] vfb_dot_mode_q;

always @(posedge clk_12) begin
	vfb_x_q          <= final_x;
	vfb_y_q          <= final_y;
	vfb_z_q          <= final_z;
	vfb_rgb_q        <= beam_rgb;
	vfb_is_dot_q     <= avg_is_dot;
	vfb_beam_on_q    <= raw_beam_on && beam_in_bounds;
	vfb_frame_done_q <= avg_halted;
	vfb_dot_mode_q   <= actual_dot_mode;
end

/////////////////   VIDEO OUTPUT   ////////////////

wire rst_vid = reset | fb_reset_vid;

wire [11:0] pre_vblank_line = fb_height + 12'd2;
reg  [2:0]  clk_div_cnt;
reg         ce_pix;
reg  [10:0] h_cnt, v_cnt;

always @(posedge clk_125) begin
	if (rst_vid)            ce_pix <= 1'b0;
	else if (is_1080p)      ce_pix <= 1'b1;
	else if (osd_120hz_vid) ce_pix <= 1'b1;
	else if (is_240p)       ce_pix <= (clk_div_cnt[2:0] == 0);
	else if (is_480p)       ce_pix <= (clk_div_cnt[1:0] == 0);
	else                    ce_pix <= clk_div_cnt[0];
end

wire h_end = (h_cnt >= h_total_reg[10:0]);
wire v_end = (v_cnt >= v_total_reg[10:0]);

always @(posedge clk_125) begin
	if (rst_vid) begin
		clk_div_cnt <= 0;
		h_cnt <= h_total_reg[10:0];
		v_cnt <= pre_vblank_line[10:0];
	end else begin
		clk_div_cnt <= clk_div_cnt + 1'd1;
		if (ce_pix) begin
			if (h_end) begin
				h_cnt <= 0;
				v_cnt <= v_end ? 11'd0 : v_cnt + 1'd1;
			end else h_cnt <= h_cnt + 1'd1;
		end
	end
end

wire raw_hsync  = ~(h_cnt >= hs_start_reg[10:0] && h_cnt < hs_end_reg[10:0]);
wire raw_vsync  = ~(v_cnt >= vs_start_reg[10:0] && v_cnt < vs_end_reg[10:0]);
wire raw_hblank = (h_cnt >= fb_width[10:0]);
wire raw_vblank = (v_cnt >= fb_height[10:0]);

wire hblank, vblank, hs, vs;
wire [7:0] vfb_r, vfb_g, vfb_b;
wire fifo_full_led;
wire arbiter_reset_busy;

wire [15:0] sdram_dq_out;
wire        sdram_dq_oe;
wire  [1:0] sdram_dqm;

vfb_top rasterizer (
	.reset(rst_vid),
	.video_timing_reset(rst_vid),
	.clk_sys(clk_125),
	.clk_12(clk_12),

	.osd_bloom_width(effective_bloom_width),
	.osd_bloom_curve(effective_bloom_curve),
	.osd_halo_filter(effective_halo_filter),
	.osd_phosphor_mode(effective_phosphor_mode),
	.osd_halo_spread(effective_halo_spread),
	.osd_color_space(effective_color_space),
	.osd_color_channels(effective_color_channels),
	.osd_slot_mask(effective_slot_mask),
	.osd_full_bypass(effective_full_bypass),
	.arbiter_reset_busy(arbiter_reset_busy),

	.X_VECTOR(vfb_x_q),
	.Y_VECTOR(vfb_y_q),
	.Z_VECTOR(vfb_z_q),
	.RGB(vfb_rgb_q),
	.IS_DOT(vfb_is_dot_q),
	.BEAM_ON(vfb_beam_on_q),

	.FRAME_DONE(vfb_frame_done_q),
	.BUFFER_MODE(2'd0),
	.DOT_MODE(vfb_dot_mode_q),
	.FIFO_FULL_LED(fifo_full_led),
	.FLASH_PARAM(8'd0),
	.OSD_120HZ(STABLE_120HZ),

	.DDRAM_CLK(DDRAM_CLK),
	.DDRAM_BUSY(DDRAM_BUSY),
	.DDRAM_BURSTCNT(DDRAM_BURSTCNT),
	.DDRAM_ADDR(DDRAM_ADDR),
	.DDRAM_DOUT(DDRAM_DOUT),
	.DDRAM_DOUT_READY(DDRAM_DOUT_READY),
	.DDRAM_RD(DDRAM_RD),
	.DDRAM_DIN(DDRAM_DIN),
	.DDRAM_BE(DDRAM_BE),
	.DDRAM_WE(DDRAM_WE),

	.SDRAM_DQ_IN(SDRAM_DQ),
	.SDRAM_DQ_OUT(sdram_dq_out),
	.SDRAM_DQ_OE(sdram_dq_oe),
	.SDRAM_CKE(SDRAM_CKE),
	.SDRAM_nCS(SDRAM_nCS),
	.SDRAM_nRAS(SDRAM_nRAS),
	.SDRAM_nCAS(SDRAM_nCAS),
	.SDRAM_nWE(SDRAM_nWE),
	.SDRAM_DQM(sdram_dqm),
	.SDRAM_A(SDRAM_A),
	.SDRAM_BA(SDRAM_BA),

	.RENDER_WIDTH(fb_width),
	.RENDER_HEIGHT(fb_height),

	.VGA_R(vfb_r),
	.VGA_G(vfb_g),
	.VGA_B(vfb_b),
	.VGA_HS(hs),
	.VGA_VS(vs),
	.VGA_HBLANK(hblank),
	.VGA_VBLANK(vblank),

	.h_cnt(h_cnt),
	.v_cnt(v_cnt),
	.ce_pix(ce_pix),
	.hsync(raw_hsync),
	.vsync(raw_vsync),
	.hblank(raw_hblank),
	.vblank(raw_vblank)
);

//
// Mylar overlay.
//
// The cabinet had a red band across the top of the screen fading into green
// below. The old framebuffer did this as a hard switch at scanline 120 of 480
// with no blend; do it proportionally against the current framebuffer height
// with a gradient band so it does not cut a visible line across the image.
//
// band_recip is a per-mode constant so the blend is a multiply and a shift --
// a real divider here would sit on the pixel path at 125 MHz.
//   band spans fb_height/8 .. fb_height/4, so band_len = fb_height/8
//   band_recip = 65536 / band_len, and blend = (row-top)*recip >> 8
//
//
// Display-space pixel coordinates.
//
// vfb_top's readout is pipelined, so its VGA output lags the raw h_cnt/v_cnt
// by a substantial and mode-dependent amount (measured at roughly 92 pixels
// and 50 lines at 720p). Anything drawn against the raw counters lands in the
// wrong place, so derive real display coordinates from the renderer's own
// blanking edges and use those for the overlay and the diagnostics.
//
reg [10:0] disp_x, disp_y;
reg        hblank_prev, vblank_prev;

always @(posedge clk_125) begin
	if (rst_vid) begin
		disp_x <= 0; disp_y <= 0;
		hblank_prev <= 1'b1; vblank_prev <= 1'b1;
	end else if (ce_pix) begin
		hblank_prev <= hblank;
		vblank_prev <= vblank;

		if (hblank) disp_x <= 0;
		else        disp_x <= disp_x + 1'd1;

		if (vblank)                     disp_y <= 0;
		else if (hblank & ~hblank_prev) disp_y <= disp_y + 1'd1;
	end
end

// The blend depends only on the scanline, so it is pipelined freely -- two
// cycles of latency on a per-line value is invisible. Doing this
// combinationally put a subtract and two chained multiplies between the row
// counter and the output pins, which cost ~7.5 ns of setup slack at 125 MHz.
// The red section covers the score area down to a quarter of the screen, as
// the pre-rework hard cut at scanline 120 of 480 did; the blend then runs over
// the next sixteenth so the transition is not a razor edge. Placing the band
// higher (h/8 to h/4) left the SCORE text mid-gradient and rendered it yellow.
wire [11:0] band_top = fb_height >> 2;
wire        overlay_on = mod_is_battlezone & ~status[20];

reg [11:0] row_r;
reg [19:0] blend_full_r;
reg [7:0]  blend_r;
reg        above_r, in_band_r;

always @(posedge clk_125) begin
	row_r        <= {1'b0, disp_y};
	above_r      <= (row_r < band_top);
	in_band_r    <= (row_r >= band_top) && (row_r < (band_top + (fb_height >> 4)));
	blend_full_r <= (row_r - band_top) * band_recip;
	blend_r      <= above_r ? 8'd0 : (in_band_r ? blend_full_r[15:8] : 8'd255);
end

//
// Bring-up diagnostics.
//
// Eight sticky latches rendered as squares along the top of the screen, so a
// single build tells us how far the pipeline actually gets rather than costing
// a 25-minute rebuild per hypothesis. Left to right:
//   0 AVG state PROM was written during ROM download
//   1 vector ROM was written during ROM download
//   2 CPU address bus has changed since reset (T65 is fetching)
//   3 CPU reached program ROM ($4000+), i.e. it took the reset vector
//   4 VGGO seen (the game asked the AVG to run)
//   5 AVG left the halted state
//   6 AVG produced a non-zero Z (a visible vector)
//   7 BEAM_ON reached the renderer in bounds
//
reg dbg_prom_wr, dbg_vecrom_wr, dbg_cpu_move, dbg_cpu_rom;
reg dbg_saw_vggo, dbg_avg_ran, dbg_z_nz, dbg_beam;
reg [15:0] dbg_addr_prev;

always @(posedge clk_12) begin
	if (reset) begin
		dbg_cpu_move <= 0; dbg_cpu_rom <= 0; dbg_saw_vggo <= 0;
		dbg_avg_ran  <= 0; dbg_z_nz    <= 0; dbg_beam     <= 0;
	end else begin
		dbg_addr_prev <= dbg_cpu_addr;
		if (dbg_addr_prev != dbg_cpu_addr)       dbg_cpu_move <= 1'b1;
		if (dbg_cpu_addr >= 16'h4000 &&
		    dbg_cpu_addr <  16'h8000)            dbg_cpu_rom  <= 1'b1;
		if (dbg_vggo)                            dbg_saw_vggo <= 1'b1;
		if (!avg_halted)                         dbg_avg_ran  <= 1'b1;
		if (avg_z_raw != 8'd0)                   dbg_z_nz     <= 1'b1;
		if (vfb_beam_on_q)                       dbg_beam     <= 1'b1;
	end
	// ROM-download latches must survive the reset that download asserts.
	if (ioctl_wr && !ioctl_index) begin
		if (ioctl_addr[15:8]  == 8'h50) dbg_prom_wr   <= 1'b1;
		if (ioctl_addr[15:12] == 4'h4)  dbg_vecrom_wr <= 1'b1;
	end
end

// Cells 0..3 are a fixed 1,0,1,0 marker so the readout is self-identifying --
// the first attempt drew against the raw counters, which are offset from the
// displayed pixel by the renderer's pipeline depth, and the mapping from cell
// position to bit was ambiguous as a result.
wire [15:0] dbg_bits = {
	4'b0000,
	dbg_beam, dbg_z_nz, dbg_avg_ran, dbg_saw_vggo,
	dbg_cpu_rom, dbg_cpu_move, dbg_vecrom_wr, dbg_prom_wr,
	4'b1010
};

wire        dbg_on    = status[34];
wire        dbg_row   = dbg_on && (disp_y >= 11'd100) && (disp_y < 11'd140);
wire [10:0] dbg_col   = disp_x - 11'd40;
wire        dbg_in    = dbg_row && (disp_x >= 11'd40) && (dbg_col < 11'd512);
wire  [3:0] dbg_idx   = dbg_col[8:5];
wire        dbg_cell  = dbg_col[4:0] < 5'd24;
wire        dbg_lit   = dbg_in && dbg_cell && dbg_bits[dbg_idx];
wire        dbg_frame = dbg_in && dbg_cell && !dbg_bits[dbg_idx];

wire [15:0] lum_r = vfb_r * (8'd255 - blend_r);
wire [15:0] lum_g = vfb_g * blend_r;

// One registered stage on the whole output bundle, CE_PIXEL included, so the
// stream stays aligned rather than shifting RGB against the pixel enable.
reg  [7:0] r_d, g_d, b_d;
reg        hs_d, vs_d, de_d, ce_pix_d;

always @(posedge clk_125) begin
	r_d      <= dbg_lit ? 8'd0   : dbg_frame ? 8'd48 : overlay_on ? lum_r[15:8] : vfb_r;
	g_d      <= dbg_lit ? 8'd255 : dbg_frame ? 8'd48 : overlay_on ? lum_g[15:8] : vfb_g;
	b_d      <= dbg_lit ? 8'd0   : dbg_frame ? 8'd48 : overlay_on ? 8'd0        : vfb_b;
	hs_d     <= hs;
	vs_d     <= vs;
	de_d     <= ~(hblank | vblank);
	ce_pix_d <= ce_pix;
end

assign VGA_R    = r_d;
assign VGA_G    = g_d;
assign VGA_B    = b_d;
assign VGA_HS   = hs_d;
assign VGA_VS   = vs_d;
assign VGA_DE   = de_d;
assign VGA_SL   = 0;
assign CE_PIXEL = ce_pix_d;

endmodule
