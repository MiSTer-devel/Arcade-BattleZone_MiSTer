`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Battlezone / Red Baron / Bradley Trainer core.
//
// Reworked to run the CPU and vector generator from the original 12.096 MHz
// master clock with a 1.512 MHz clock enable, driving the PROM-driven AVG
// ported from Arcade-BlackWidow_MiSTer. The framebuffer and rasterizer are
// gone; this module now emits a beam position stream that videodr0me_fb
// consumes in the top level.
//
// Two clock domains:
//   clk_12  12.096 MHz  CPU, address decode, mathbox, AVG
//   clk_50  50 MHz      POKEY and the analog sound section, whose dividers are
//                       hardcoded for 50 MHz (POKEY.sv:359,374,389) and would
//                       detune if moved.
// The POKEY bus crossing is safe by construction: address, data and the write
// strobe are all held for a full 1.5 MHz CPU cycle (~660 ns, 33 clk_50 cycles)
// and POKEY latches on the rising edge of phi2.
//////////////////////////////////////////////////////////////////////////////////
`include "coreInterface.vh"

module top
  (
   input wire          clk_12,
   input wire          clk_50,
   input wire          btnCpuReset,
   input wire [7:0]    DSW0,
   input wire [7:0]    DSW1,
   input wire [7:0]    REDBARONBUTTONS,
   input wire [7:0]    JB,
   input wire [7:0]    buttons,
   input wire          self_test,
   input wire          pause_cpu,
   output logic        audiosel,

   // Vector beam stream to the renderer (clk_12 domain)
   output logic [13:0] avg_x,
   output logic [13:0] avg_y,
   output logic [7:0]  avg_z,
   output logic [2:0]  avg_rgb,
   output logic        avg_is_dot,
   output logic        avg_halted,

   output logic [15:0] audio,

   // Bring-up diagnostics, see the debug overlay in Arcade-BattleZone.sv
   output logic        dbg_vggo,
   output logic        dbg_vgrst,
   output logic [15:0] dbg_cpu_addr,

   input wire [24:0]   dl_addr,
   input wire [7:0]    dl_data,
   input wire          dl_wr,
   input wire          mod_bradley,
   input wire          mod_redbaron,
   input wire          mod_battlezone
   );

  logic        rst;
  logic        rst_l;
  logic        rst_unstable;
  logic        vggo, vgrst;

  assign rst = ~rst_l;

  always @(posedge clk_12) begin
    rst_unstable <= btnCpuReset;
    rst_l        <= rst_unstable;
  end

  logic [23:0]       cpu_addr;
  logic [15:0]       address;
  logic [7:0]        dataIn, dataOut;
  logic              cpu_rw_l;
  logic              WE, NMI;

  logic [4:0] [7:0]  dataToBram, dataFromBram;
  logic [4:0] [15:0] addrToBram;
  logic [4:0]        weEnBram;

  logic [15:0]       prog_rom_addr;
  assign prog_rom_addr = addrToBram[`BRAM_PROG_ROM] - 16'h4000;

  //--------------------------------------------------------------------------
  // Clock enables
  //
  // 12.096 MHz / 8 = 1.512 MHz CPU enable, matching hardware. The 3 kHz timer
  // the game polls at $0800 bit 7 comes off a 9-bit divide of that, and the
  // 250 Hz NMI is a further divide by 12 -- both as documented, rather than
  // the old magic "nmi_counter == 12" wrap at ~218 Hz.
  //--------------------------------------------------------------------------
  logic [2:0]  clkdiv;
  logic        ena_1_5M;
  logic [8:0]  cnt_3khz;
  logic        clk_3KHz;
  logic [3:0]  nmi_div;

  assign clk_3KHz = cnt_3khz[8];

  // The divider must FREE-RUN, exactly as Black Widow's does (bwidow.vhd:280).
  // avg_prom_core only acts inside "if clken='1'", so gating the enable with
  // reset means vgrst is never sampled and halt_flag never gets set -- it powers
  // up at 0, i.e. "running", and the AVG executes garbage from pc=0. It also
  // starves T65's reset, which needs several *enabled* cycles with Res_n low.
  always @(posedge clk_12) begin
    clkdiv   <= clkdiv + 3'd1;
    ena_1_5M <= (clkdiv == 3'd0);

    if (rst) begin
      cnt_3khz <= '0;
      nmi_div  <= '0;
      NMI      <= 1'b0;
    end else if (clkdiv == 3'd0) begin
      cnt_3khz <= cnt_3khz + 9'd1;
      if (cnt_3khz == 9'd0) begin
        // 1.512 MHz / 512 = 2953 Hz tick; /12 = 246 Hz NMI.
        if (nmi_div == 4'd11) begin
          nmi_div <= 4'd0;
          NMI     <= 1'b1;
        end else begin
          nmi_div <= nmi_div + 4'd1;
          NMI     <= 1'b0;
        end
      end
    end
  end

  // Hold the CPU in reset for 256 enabled cycles after rst releases, matching
  // the 256-cycle stretcher in bwidow_top.vhd:104-118.
  logic [7:0] rst_cnt;
  logic       coreReset_l;
  always_ff @(posedge clk_12) begin
    if (rst) begin
      rst_cnt     <= 8'd0;
      coreReset_l <= 1'b0;
    end else if (ena_1_5M) begin
      if (rst_cnt == 8'hFF) coreReset_l <= 1'b1;
      else                  rst_cnt     <= rst_cnt + 8'd1;
    end
  end

  //--------------------------------------------------------------------------
  // CPU -- T65, cycle-accurate, from Arcade-BlackWidow_MiSTer.
  //--------------------------------------------------------------------------
  T65 cpu (
     .Mode    (2'b00),
     .BCD_en  (1'b1),
     .Res_n   (coreReset_l),
     .Enable  (ena_1_5M),
     .Clk     (clk_12),
     .Rdy     (~pause_cpu),
     .Abort_n (1'b1),
     .IRQ_n   (1'b1),
     .NMI_n   (~NMI),
     .SO_n    (1'b1),
     .R_W_n   (cpu_rw_l),
     .Sync    (),
     .EF      (),
     .MF      (),
     .XF      (),
     .ML_n    (),
     .VP_n    (),
     .VDA     (),
     .VPA     (),
     .A       (cpu_addr),
     .DI      (dataIn),
     .DO      (dataOut),
     .Regs    (),
     .DEBUG   (),
     .NMI_ack ()
     );

  assign address = cpu_addr[15:0];
  assign WE      = ~cpu_rw_l;

  addrDecoder ad
    (
     .dataToCore     (dataIn),
     .addrToBram     (addrToBram),
     .dataToBram     (dataToBram),
     .weEnBram       (weEnBram),
     .vggo           (vggo),
     .vgrst          (vgrst),
     .dataFromCore   (dataOut),
     .addr           ({1'b0, address[14:0]}),
     .dataFromBram   (dataFromBram),
     .we             (WE),
     .halt           (avg_halted),
     .clk            (clk_12),
     .clk_3KHz       (clk_3KHz),
     .clk_en         (ena_1_5M),
     .self_test      (self_test),
     .DSW0           (DSW0),
     .DSW1           (DSW1),
     .REDBARONBUTTONS(REDBARONBUTTONS),
     .coin           (JB[7:7]),
     .mod_redbaron   (mod_redbaron)
     );

  //--------------------------------------------------------------------------
  // Program memory
  //--------------------------------------------------------------------------
  wire prog_rom_cs = dl_addr < 'h4000;

  dpram #(.addr_width_g(14),.data_width_g(8)) progRom (
	.clock_a(clk_12),
	.address_a(dl_addr[13:0]),
	.data_a(dl_data),
	.wren_a(dl_wr & prog_rom_cs),

	.clock_b(clk_12),
	.enable_b(1'b1),
	.address_b(prog_rom_addr[13:0]),
	.q_b(dataFromBram[`BRAM_PROG_ROM])
	);

  sp_ram #(.DATA(8), .ADDR(11)) progRam
    (
     .clk         (clk_12),
     .clk_en      (1'b1),
     .addr        (addrToBram[`BRAM_PROG_RAM][10:0]),
     .din         (dataToBram[`BRAM_PROG_RAM]),
     .dout        (dataFromBram[`BRAM_PROG_RAM]),
     .wr          (weEnBram[`BRAM_PROG_RAM])
     );

  //--------------------------------------------------------------------------
  // Vector generator
  //
  // Single 8K vector window now lives inside avg_bz; the old design held two
  // copies of it that were written in parallel and could drift apart.
  //--------------------------------------------------------------------------
  wire vec_cs_l = ~(address[14:13] == 2'b01);   // CPU $2000-$3FFF

  assign dbg_vggo     = vggo;
  assign dbg_vgrst    = vgrst;
  assign dbg_cpu_addr = address;

  avg_bz avg (
     .clk          (clk_12),
     .clken        (ena_1_5M),
     .cpu_data_in  (dataFromBram[`BRAM_VECTOR]),
     .cpu_data_out (dataToBram[`BRAM_VECTOR]),
     .cpu_addr     (addrToBram[`BRAM_VECTOR][12:0]),
     .cpu_cs_l     (vec_cs_l),
     .cpu_rw_l     (cpu_rw_l),
     .vgrst        (rst | vgrst),
     .vggo         (vggo),
     .halted       (avg_halted),
     .xout14       (avg_x),
     .yout14       (avg_y),
     .zout         (avg_z),
     .rgbout       (avg_rgb),
     .is_dot_out   (avg_is_dot),
     .dn_addr      (dl_addr[15:0]),
     .dn_data      (dl_data),
     .dn_wr        (dl_wr)
     );

  mathBox mb
    (
     .addr           (addrToBram[`BRAM_MATH][7:0]),
     .DI             (dataToBram[`BRAM_MATH]),
     .we             (weEnBram[`BRAM_MATH]),
     .clk            (clk_12),
     .clk_en         (ena_1_5M),
     .rst            (rst),
     .mod_redbaron   (mod_redbaron),
     .dataOut        (dataFromBram[`BRAM_MATH])
     );

  //--------------------------------------------------------------------------
  // Sound -- stays in the 50 MHz domain, see header.
  //
  // The enable rates below are reproduced exactly as they were before the
  // rework (50/16 = 3.125 MHz, /4096 = 12.207 kHz, /1024 = 48.828 kHz) so the
  // hand-calibrated analog section behaves identically. These are sample-rate
  // enables for the mixer and IIR chain, not a CPU clock.
  //--------------------------------------------------------------------------
  logic        rst_50, rst_50_meta;
  logic [3:0]  counter3MHz;
  logic [11:0] counter12KHz;
  logic [9:0]  counter48KHz;
  logic        clk_3MHz_en, clk_12KHz_en, clk_48KHz_en;

  always @(posedge clk_50) begin
    rst_50_meta <= rst;
    rst_50      <= rst_50_meta;
  end

  always @(posedge clk_50) begin
    if (rst_50) begin
      counter3MHz  <= 4'd8;
      counter12KHz <= 12'd2048;
      counter48KHz <= 10'd512;
    end else begin
      counter3MHz  <= counter3MHz  + 4'd1;
      counter12KHz <= counter12KHz + 12'd1;
      counter48KHz <= counter48KHz + 10'd1;
    end
  end

  assign clk_3MHz_en  = (counter3MHz  == 4'd7);
  assign clk_12KHz_en = (counter12KHz == 12'd2047);
  assign clk_48KHz_en = (counter48KHz == 10'd511);

  //--------------------------------------------------------------------------
  // POKEY bus crossing, clk_12 -> clk_50.
  //
  // Address and data are registered on the CPU enable so they are glitch-free
  // and stable for a full 660 ns cycle. The access level is synchronized with
  // two flops and used directly as phi2, so POKEY's internal rising-edge
  // detector fires exactly once per CPU access, with address and data already
  // settled. A 6502 cannot issue two consecutive bus cycles to the same
  // device, so the level always returns low between accesses.
  //--------------------------------------------------------------------------
  logic [15:0] pokey_addr_q;
  logic [7:0]  pokey_data_q;
  logic        pokey_we_q;

  always @(posedge clk_12) begin
    if (ena_1_5M) begin
      pokey_addr_q <= addrToBram[`BRAM_POKEY];
      pokey_data_q <= dataToBram[`BRAM_POKEY];
      pokey_we_q   <= weEnBram[`BRAM_POKEY];
    end
  end

  logic pokey_we_s1, pokey_we_s2;
  always @(posedge clk_50) begin
    pokey_we_s1 <= pokey_we_q;
    pokey_we_s2 <= pokey_we_s1;
  end

  sound sound
    (
     .rst(rst_50),
     .clk(clk_50),
     .clk_3MHz(pokey_we_s2),
     .clk_3MHz_en(clk_3MHz_en),
     .clk_12KHz_en(clk_12KHz_en),
     .clk_48KHz_en(clk_48KHz_en),
     .dl_addr(dl_addr),
     .dl_data(dl_data),
     .mod_redbaron(mod_redbaron),
     .should_read(pokey_we_s2),
     .buttons(buttons),
     .addr_to_bram(pokey_addr_q),
     .data_to_bram(pokey_data_q),
     .audiosel(audiosel),
     .data_from_bram(dataFromBram[`BRAM_POKEY]),
     .audio(audio)
     );

endmodule
`default_nettype wire
