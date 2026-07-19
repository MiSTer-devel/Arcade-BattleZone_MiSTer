# Arcade-BattleZone_MiSTer — Technical Assessment

**Date:** 2026-07-18
**Revised:** 2026-07-18
**Reviewed at commit:** `dc8afac` (master)
**Method:** Static reading of the RTL, plus comparison against the sibling cores
`Arcade-StarWars_MiSTer`, `Arcade-Asteroids_MiSTer` and (added on revision)
`Arcade-BlackWidow_MiSTer`.

> **Caveat:** This is a static source review. The core was not built, simulated, or run
> on hardware. Timing discrepancies below are "the numbers do not match the documented
> hardware," **not** "the game was observed running incorrectly." Anything marked
> *needs hardware verification* must be measured before it is changed.

> ### Revision note
>
> The original draft omitted **`Arcade-BlackWidow_MiSTer`**, which is the closest sibling
> — Atari 6502 + AVG hardware, the same family as BattleZone — and which received a major
> release in July 2026 (`e814f50`, `e560fd8`) implementing almost everything recommended
> below. Three conclusions here are wrong as a result and are corrected inline: §3.1
> (CPU clock), §4.1 (`hiscore.v`), §4.6 (pause). §2.5's "DDR-backed" is also incomplete —
> the renderer needs DDRAM **and** SDRAM. See `HANDOFF.md` for the full correction table.
>
> Star Wars is a **6809** machine and Asteroids is a **DVG**; neither is the right
> reference for BattleZone's CPU or vector generator.

---

## 1. Root cause

This core is a MiSTer wrapper around a CMU 18-545 student capstone project
(`README.md:11-13`, upstream `MXButterfly/F15_18545_BattleZone`). It is a
*reimplementation* of Battlezone, not a schematic-level or MAME-derived port.

Nearly every issue in this document traces back to that provenance: constants were
tuned by eye until the game looked right, rather than derived from hardware. The
fingerprints are visible in the source:

- `rtl/avg.sv:208` — `"DEMO: multiplied dx/dy by 2"`
- `rtl/avg.sv:85` — `"DEMO: changed to else if"`
- `rtl/avg_decode.sv:66-79` — four more `"DEMO:"` annotations (removed right shifts,
  added sign extension)
- `rtl/avg.sv:199-205` — `// ajs ajs ajs` fence around a hand patch
- `rtl/fb_controller.sv:195-196` — comment admitting the original buffer-swap FSM
  "created latches and never worked as intended"
- `rtl/avg.sv:50-51` — unresolved `//WARNING: don't know how many bits this should be`

By contrast, `Arcade-StarWars_MiSTer` has become a reference-quality core: a cycle-exact
AVG driven by the real state PROM loaded from the MRA, a `Research/` folder with
hand-transcribed schematics, a maintained CHANGELOG, and roughly 15 commits in the last
six weeks. **Most of what BattleZone needs already exists in the sibling repositories.**

Maintenance status of this core: last substantive work was 2024. Since then only a `sys`
update and a rotation-metadata flag.

---

## 2. Tier 1 — The visual gap

### 2.1 No phosphor emulation at all

`rtl/fb_controller.sv:70-71` infers two `logic [3:0] ... [307200]` arrays (640 × 480),
totalling **2,457,600 bits of on-chip RAM** — over half the M10K budget on a 5CSEBA6 —
and the back buffer is hard-cleared by a linear address counter every frame
(`rtl/fb_controller.sv:84`, terminal count at `:104`).

Consequences:

- **No persistence or decay.** Real vector monitors hold a stroke for tens of
  milliseconds. Here every pixel is binary on/off per frame.
- **No bloom, halo, or glow.** The characteristic vector-CRT look is entirely absent.
- **No intersection brightening.** Crossing vectors overwrite rather than accumulate.
  Battlezone's imagery is almost entirely long crossing lines, so this matters more here
  than in most vector games.
- **No dwell-based intensity.** `rtl/rasterizer.sv:68` latches the 4-bit `lineColor` once
  per line and writes it flat. There is no intensity-vs-length compensation, no gamma,
  no beam-start hotspot.

`rtl/fb_controller.sv:110-127` fans the stored 4-bit value straight to the R/G/B nibbles.

### 2.2 Sub-pixel resolution is discarded

- `rtl/avg.sv:234-237` right-shifts the AVG's 14-bit coordinates to 13 bits
  (`startX = currX[13:1]`), throwing away half the positional resolution before
  rasterization.
- `rtl/rasterizer.sv:34-35` declares `truncStartX`/etc. with the comment
  `"EDIT: truncate if out of bounds"`, and then `:55-58` assigns them straight through —
  the clipping was never implemented.
- Line drawing is classic integer Bresenham (`rtl/rasterizer.sv:253-278`), one pixel per
  50 MHz clock, major/minor axis selected at `:78`. **No sub-pixel positioning, no
  anti-aliasing, no line thickness.**

In a game built from slow-rotating long lines, integer truncation is the worst possible
precision loss — it produces crawl and shimmer on exactly the content the game consists of.

### 2.3 Off-screen vectors are not clipped

Because clipping was never implemented (2.2), off-screen pixels are masked only at write
time via `goodPixel` (`rtl/rasterizer.sv:109-112`). The rasterizer still burns one clock
per off-screen pixel, so a long off-screen vector stalls the entire line queue.

### 2.4 The overlay is a hard split

`rtl/fb_controller.sv:111-122` forces `row <= 120` to red and everything below to green,
emulating the mylar overlay with a hard scanline boundary and no gradient or blend band.
Red Baron and Bradley Trainer render monochrome white.

### 2.5 Recommended fix

Port `rtl/videodr0me_fb/` from `Arcade-Asteroids_MiSTer` or `Arcade-StarWars_MiSTer`.
The two copies were diffed: **only 3 of 18 files differ**, so the library is already
proven portable between cores.

Integration surface is small — `vfb_top.sv:7-86` consumes only
`X_VECTOR`, `Y_VECTOR`, `Z_VECTOR`, `RGB`, `IS_DOT`, `BEAM_ON`, `FRAME_DONE`.

What it provides:

| Capability | Module |
|---|---|
| Phosphor decay (4-bit draw index + age LUTs) | `vfb_readout.sv:450-545` |
| 9-bit saturating intensity accumulation (intersection glow) | `vfb_tile_cache_manager.sv:503-506` |
| Local bloom (5×5 separable) | `vfb_blur.sv` |
| Wide halo (1/16-scale coarse image + 8-tap kernels) | `vfb_halo_wide.sv` |
| End-of-chain perceptual tone curves | `vfb_tonemap.sv` |
| Diagonal sub-pixel insertion with 1-step lookahead | `vfb_rasterizer.sv:296-345` |
| Line-delay parked in SDRAM via RLE instead of BRAM | `vfb_sdram_delay.sv` + `vfb_rle_encoder.sv` |
| Resolution presets / OSD profiles | `vfb_profile_resolver.sv` |

It is DDR-backed, which additionally **frees the 2.4 Mbit of BRAM** currently spent on the
framebuffer. Note that this core currently ties SDRAM to Z and DDRAM to 0
(`Arcade-BattleZone.sv:197-198`), so that plumbing has to be brought up.

> **Corrected on revision.** The current version needs **both** buses: DDRAM for the tile
> framebuffer and SDRAM for the compressed halo-alignment delay line (`vfb_top.sv:22-43`,
> `vfb_sdram_delay.sv`). Black Widow's changelog requires a 32 MB SDRAM module. Take the
> copy from `Arcade-BlackWidow_MiSTer/rtl/videodr0me_fb/` — it is the newest and the one
> matching the PROM-driven AVG.

---

## 3. Tier 2 — Timing is not derived from hardware

### 3.1 Clock rates

| Signal | This core | Documented hardware | Source |
|---|---|---|---|
| CPU clock | 3.125 MHz (50/16) | 1.512 MHz | `rtl/top.sv:137` |
| AVG clock | 6.25 MHz (50/8) | 1.5 MHz state / 12 MHz shift | `rtl/top.sv:138` |
| NMI rate | ~235 Hz | 250 Hz | `rtl/top.sv:297-310` |
| Video | 640×480 @ 60 Hz generic VGA | ~40 Hz vector monitor | `rtl/VGA_fsm.sv:30-37` |

**Do not "fix" the CPU divider without measurement.** The CPU is Arlet Ottens' 6502
(`rtl/cpu.sv:1-11`), whose own header at `:13-19` documents that it is not cycle-accurate
and that "not all 6502 interface signals are supported (yet)." The 2× clock may be
compensating for that core's cycle behaviour. *Needs hardware verification.*

> **Corrected on revision.** This concern is real but avoidable rather than something to
> measure around. Black Widow runs **T65** from a **1.5 MHz clock enable off the original
> 12.096 MHz master** (`bwidow.vhd:130-135`, divider at `:299-317`) — no divided clock and
> no compensation factor. The same process yields a 3 kHz tick and a true 250 Hz interrupt
> **with acknowledge**, which BattleZone's magic `nmi_counter == 12` lacks. Adopting T65
> + clock enable removes the question rather than answering it. Black Widow's July 2026
> release also reworked T65's decimal-mode, reset, and interrupt behaviour, so take that
> copy rather than Asteroids'.

The NMI is a magic counter: `NMI <= (nmi_counter == 12)` wrapping at 13, clocked from a
~3051 Hz tick (`rtl/top.sv:139`). Real hardware divides the 3 kHz clock by 12 for 250 Hz.
There is no NMI acknowledge — the level is held for one tick.

`IRQ` is tied off entirely (`rtl/top.sv:312`). `RDY` is hardwired high
(`rtl/top.sv:313`), so there is no DMA, wait-state, or pause hook.

### 3.2 AVG instruction timing is length-independent

`rtl/avg_decode.sv` assigns a fixed `instLength` per opcode — VCTR=7, SVEC=5,
STORE(STAT)=6 / SCAL=2, CNTR=4, JSR/JMP=4, RTS=3, HALT=1 — counted down at
`rtl/avg.sv:66-71`.

On real hardware a VCTR takes time **proportional to the vector's length**, because the
integrators run for the vector's duration. The consequences:

- The display list completes far faster than on hardware, and in length-independent time.
- Frame cadence is decoupled from the NMI cadence.
- The natural mechanism that would produce dwell-based brightness is removed — which is
  why §2.1's flat intensity cannot simply be patched in isolation.

### 3.3 Scaling is an approximation

`rtl/avg.sv:221-222`:

```
nextX_scaled = currX + (((dX_buf*2*(256-linScale))/256) >> binScale)
```

- Linear scale is a `(256-linScale)/256` approximation.
- `binScale` is declared `logic signed [2:0]` (`:34`) but used as an unsigned shift
  amount; negative or large binary scales are not handled.
- Contains a hardcoded `*2` (the `"DEMO:"` comment at `:208`) plus dead `* 1) / 1` terms.
- The whole 22-bit multiply/divide is one flat `always_comb` evaluated every clock at
  50 MHz with no pipelining — almost certainly the core's critical path, and unconstrained
  (see §5.3).

### 3.4 Video timing

`rtl/VGA_fsm.sv:30-37` is hardcoded PC VGA 640×480@60: H_MAX 800, V_MAX 525,
**H_PULSE 95 (should be 96)**, H_FP 16, H_BP 48, V_PULSE 2, V_FP 10, V_BP 32.

This bears no relationship to Battlezone's monitor geometry. There is no `direct_video`,
no low-latency vsync, no adaptive framerate. Buffer swap is driven by VGGO
(`rtl/fb_controller.sv:100-101, 197-213`), not by vblank, so tearing/judder against the
~235 Hz NMI cadence is possible.

**The pixel clock is divided twice, independently:** `Arcade-BattleZone.sv:362-365`
toggles `ce_pix` from `clk_50`, while `rtl/VGA_fsm.sv:147-150` runs its own private
divider from the same clock. Nothing forces the two into the same phase after reset, so
framebuffer readout and `CE_PIXEL` can sit a half-pixel apart. Fragile by construction.

### 3.5 Recommended fix

Rewrite the AVG against the Star Wars implementation:

- `Arcade-StarWars_MiSTer/rtl/avg/avg.vhd` — cycle-exact AVG state machine driven by the
  **real 256×4 state PROM loaded from the MRA** (`avg.vhd:5`; MRA part in
  `releases/Star Wars (Rev 2).mra:48`). Models PROM address
  `{NOT_HALT, OP2..OP0, ST3..ST0}` (`:66`), STROBE 0-3, and the normalization substates
  that freeze the PROM via the SA mechanism while LS194 shift registers run at 12 MHz
  (`:128, :236-249`).
- `Arcade-StarWars_MiSTer/rtl/avg/vector_drawer.vhd:86-121` — 34-bit position
  accumulators (2 guard + 14 output + **18 sub-pixel bits**), with the LF13201
  multiplying-DAC transfer function modelled exactly.
- `Arcade-StarWars_MiSTer/Research/avg_schematic_reference.txt` — hand-transcribed
  schematics.

This work is **coupled to §2.5**: the new renderer's sub-pixel capability is wasted if it
is fed truncated coordinates.

---

## 4. Tier 3 — Missing hardware

### 4.1 No EAROM / no non-volatile storage

Grepping the entire repository for `earom` / `nvram` returns **zero hits** in RTL and in
all three MRAs. `rtl/coreInterface.sv:113-141` decodes only RAM, vector RAM/ROM, program
ROM, POKEY, and the mathbox — there is no EAROM range at all, so reads there return
undefined data and high scores never persist.

Reference implementation: Star Wars does 256-byte NVRAM save/load/clear over
`ioctl_index==4` with autosave-on-dirty (`Arcade-StarWars.sv:788-838`) plus
`<nvram index="4" size="256">` in the MRA. **Neither sibling core uses `hiscore.v`** —
follow the NVRAM pattern rather than looking for `hiscore.v`.

> **Corrected on revision.** Black Widow uses `hiscore.v` (`Arcade-BlackWidow.sv:569`)
> with `<nvram index="4">` in all three of its MRAs, coupled to pause via `hs_pause`.
> Its `rtl/earom.vhd` is a 42-line stub that returns `"11111111"` and never models the
> ER2055 — high scores come from snooping RAM instead. Both paths are therefore live
> options here: the accurate one (ER2055 device model + NVRAM transport) and the cheap
> one (`hiscore.v`).

### 4.2 No watchdog

Address 0x1000 (WDCLR) is undecoded. `rtl/coreInterface.sv:179` special-cases only 0x1400
to suppress an `unmappedAccess` flag — and that flag, along with `unmappedRead` and
`vramWrite` (`:146, :160-162, :186`), is computed and then never used or output. These are
simulation-era debug leftovers.

### 4.3 POKEY is partial

`rtl/POKEY.sv:159-178` implements only: read ALLPOT (0x8) and RANDOM (0xA); write
AUDF1-4 / AUDC1-4 (0x0-0x7), AUDCTL (0x8), POTGO (0xB), SKCTL (0xF).

Missing: individual POT0-POT7 reads, SERIN/SEROUT, IRQEN/IRQST, KBCODE, SKSTAT, STIMER,
timer interrupts, two-tone mode, high-pass linkage correctness. Audio output is 4-bit
(`:34`).

POT emulation is a hack — `rtl/POKEY.sv:176` snapshots the 8 P pins straight into ALLPOT
on a POTGO write. Battlezone's switches are wired to the pot lines so this happens to
work, but **Red Baron's analog stick is faked** by shoving the axis byte into those same
digital pins (`Arcade-BattleZone.sv:340`), with a 1-sample, no-RC-timing pot model.

### 4.4 Mathbox is behavioural

`rtl/mathbox.sv` (477 lines) is a hand-written FSM, not an emulation of the actual
mathbox microcode ROM / AM2901 bit-slice. Sub-states are named after microcode ROM
addresses (`S048A/B`, `S0BFA/B/C`), i.e. someone transcribed the microcode by hand.

- Status byte is a single busy flag: `8'hFF` default, `0` only in IDLE (`:85, :92`) —
  not the real status register.
- The divide loop is a variable-latency spin; timing bears no relation to hardware.
- Red Baron support is only a read-address remap (`:56-68`).

This is *functionally* adequate and is **not** a priority — but it should be understood
as an approximation, not an emulation.

### 4.5 Bradley Trainer is not emulated

`rtl/top.sv:46` takes `mod_bradley` as an input and **never references it in the module
body**. Bradley Trainer is therefore just Battlezone with different ROMs; none of its
analog gun / gunsight I/O exists.

### 4.6 No pause

`OSD_STATUS` is an input at `Arcade-BattleZone.sv:175` and is never used. `RDY` is tied
high at `rtl/top.sv:313` even though Arlet's core supports it — the hook exists and is
unused.

> **Corrected on revision.** Black Widow has pause, driven through exactly this hook:
> `Rdy => not pause_h` (`bwidow.vhd:135`) fed by a standard `pause.v`
> (`Arcade-BlackWidow.sv:414`). It also freezes the vector buffer swap while paused
> (`bwidow_dw.vhd:470-477`) — a detail worth copying, since without it a paused vector
> display flashes.

### 4.7 Input handling

- `Arcade-BattleZone.sv:252` — `joy = joy_0 | joy_1`. P1 and P2 are OR'd rather than
  routed to separate ports.
- Battlezone's dual-stick tank controls are synthesized from a single d-pad by a lookup
  table (`:284-296`). No true twin-stick mapping.
- `ps2_key` is not connected — no keyboard support.
- Input port 0x800 is a hardcoded literal (`rtl/coreInterface.sv:173`) with tied-high bits
  for slam switch / coin-2 / aux coin. One coin input only (`JB[7]`), no coin counters, no
  slam, no separate service switch (self-test is an OSD toggle at
  `Arcade-BattleZone.sv:216, 398`).

---

## 5. Tier 4 — Defects and hygiene

### 5.1 Genuine defects

| Issue | Location |
|---|---|
| `assign USER_OUT = '1;` written **twice** — duplicate driver on the same net | `Arcade-BattleZone.sv:187` and `:193` |
| Vector RAM instantiated **twice** (CPU-side `dpram` + separate AVG-side inferred array), both written from the same sources. 64 kbit wasted, two sources of truth that can silently diverge | `rtl/top.sv:258-270` and `:285-295`, written at `:278-283` |
| `dl_addr` / `dl_data` / `dl_wr` cross `clk_25` → `clk_50` **unsynchronized**. Works only because ROM loading is slow; formally unsound and liable to break on a re-fit | `Arcade-BattleZone.sv:260` vs `:390` |
| Copy-paste bug: assigns `counter12KHz` twice, never resets `counter48KHz` (in the unused `CLK_DIV=="FALSE"` branch) | `rtl/top.sv:160-161` |
| `forced_scandoubler` and `fx` **hardcoded to 0** despite `forced_scandoubler` being wired out of `hps_io` at `:265` — OSD scanline options do nothing | `Arcade-BattleZone.sv:379-380` |
| ~~`AUDIO_S = 0` (unsigned) while the mixer sums signed IIR output~~ — **not a defect**, see below | `Arcade-BattleZone.sv:387` |
| H_PULSE is 95, should be 96 | `rtl/VGA_fsm.sv:30-37` |
| Blocking assignments inside a clocked `always @(posedge clk_50)` block | `Arcade-BattleZone.sv:284-296` |
| `retValid` computed but never used — stack underflow/overflow silently wraps | `rtl/avg.sv:292` |

> **`AUDIO_S` corrected on revision.** Reading the mixer rather than inferring from
> the IIR's signed accumulator: `rtl/audio_output.sv:70` computes
> `out_unfiltered <= pokey_filtered + analog_audio`. `pokey_filtered` is POKEY's
> 4-bit output zero-padded into bits 13:10 (`:47`), and `analog_audio` is the sum
> of unsigned generator outputs (`rtl/analog_sound.sv:84-88`). Both are
> non-negative, so the mix never goes below zero and **unsigned is correct**. The
> `signed` accumulator inside `rtl/iir.sv` is internal to the leaky integrator and
> does not make the output bipolar. No change needed.

### 5.2 Dead code and debris

- `rtl/squeal_samples.sv` — a **1.4 MB, 48,000-line** inline `initial` block filling
  `reg [15:0] squeal_samples[48000]`, i.e. **768 kbit of BRAM for one Red Baron sound
  effect** (`rtl/squeal_player.sv:22-25`). Non-looping, non-retriggerable mid-play,
  hard-clamped at 48000 samples (`:14`). Should be a sample ROM loaded from the MRA.
- `rtl/coreInterface.sv:4-72` — an entire 128-deep `memStoreQueue` module, never
  instantiated.
- `rtl/rasterizer.sv:320-397` — a full simulation testbench (`sanityBench`) left inside
  the synthesizable file under `` `ifdef NOTDEFINED ``, carrying its own note
  "NOTE: Outdated, need to change 10:0 to 12:0".
- `rtl/rasterizer.sv:19-24, 138` — **Xilinx `(* mark_debug = "true" *)` attributes in a
  Quartus/Altera project** (Vivado leftovers from the capstone).
- `rtl/fb_controller.sv:224-227` — a `//DEPRECATED` block assigning `ready = 1'b0`
  unconditionally; `ready` is wired to `readyFrame` at `rtl/top.sv:407` and never used.
- `rtl/top.sv:108-179` — an entire `CLK_DIV == "FALSE"` generate branch that is never used
  (and contains the bug in §5.1).
- `rtl/avg.sv:328-400` — the 32-deep `lineRegQueue` is 32 discrete registers with one-hot
  write enable; a small BRAM FIFO would do.
- `clk_6` is generated by the PLL (`rtl/pll.v:91`) and never meaningfully used.
- Non-RTL dev debris checked in: `rtl/data.pickle`, `rtl/convert_to_wav.py`,
  `rtl/generate_control_coltages_to_frequency.py` (note the typo), and four `*_tb.sv`
  testbenches. Correctly excluded from `files.qip` at least.
- Two prebuilt `.rbf` binaries committed in `releases/` (2023, 2024).
- `rtl/coreInterface.sv:113-141` duplicates the whole memory map for Red Baron vs
  Battlezone instead of parameterizing it.

### 5.3 Build configuration

- **No core-specific `.sdc`** — only `sys/sys_top.sdc`. Nothing constrains the AVG's long
  flat combinational multiply (§3.3) or the two hand-rolled clock dividers (§3.4).
- `Arcade-BattleZone.qsf:52` sets `SEED 1` with aggressive physical-synthesis options
  turned on across the board — reads as "enable everything until it fits," which is a
  symptom of the missing constraints.
- `files.qip` omits `rtl/frequencies.sv` and `rtl/squeal_samples.sv` because they are
  `` `include ``-d into other `.sv` files. Unusual and brittle.
- No CI, no build script, no `.mister` metadata.

### 5.4 Sound (the best part of the repo)

The analog sound section is a genuine effort and the strongest original work here:
`analog_sound.sv`, `engine_sound.sv`, `noise_source_shell_explo.sv`, `bang_sound.sv`,
`lfo.sv`, `iir.sv`, driven from the real output latch bits
(`rtl/audio_output.sv:22-40`), with a SPICE-derived `frequencies.sv` LUT.

Open FIXMEs, self-documented by the author:

- `rtl/engine_sound.sv:1-2` — LFO is a triangle; hardware is between triangle and sine.
  IIR not derived from the schematic.
- `rtl/audio_output.sv:43` — filter depth never calculated.
- `rtl/noise_source_shell_explo.sv:27, 38` — cutoff and amp decay unverified.
- `rtl/lfo.sv:10` — LFO shared between engine sound and elsewhere.

Mixing is fixed shifts with no calibration (`rtl/analog_sound.sv:84-88`). Mono only
(`Arcade-BattleZone.sv:386`).

---

## 6. OSD and packaging

Current CONF_STR (`Arcade-BattleZone.sv:209-221`) is four functional lines: aspect ratio,
`DIP;`, Self Test, Reset.

Missing relative to a polished core: scandoubler/scanline FX (hardwired off, §5.1),
overlay on/off, vector persistence/glow controls, service mode, Red Baron analog
sensitivity, autofire, 2P controls.

The MRAs (`releases/*.mra`) *do* carry proper `<switches>` DIP definitions and
`<display type="vector"/>`, and DIPs are correctly wired through
(`Arcade-BattleZone.sv:307-308, 350-351`). That part is fine. Gaps: no `<nvram>`, and
Red Baron's DIP `bits="0,7" name="Coinage" ids="Normal"` is a placeholder.

`README.md` is 13 lines with no documentation of controls, known issues, or fidelity
caveats.

---

## 7. Ranked fidelity gaps

1. **No phosphor persistence, decay, or glow** — vectors are hard on/off. The defining
   look of the game is missing.
2. **AVG instruction timing is a fixed cycle count** instead of length-proportional, so
   vector-draw timing is decoupled from everything else — and this blocks a proper fix
   for #1.
3. **Sub-pixel coordinates truncated to integers** before rasterization, in a game made
   entirely of long rotating lines.
4. **CPU at 3.125 MHz on a non-cycle-accurate 6502, NMI at ~235 Hz instead of 250 Hz** —
   game speed is empirical. *Needs hardware verification.*
5. **Generic 640×480@60 VGA output** unrelated to the original monitor, with two
   unsynchronized pixel-clock dividers.
6. **No EAROM** — high scores never persist.
7. **POKEY missing pots/timers/IRQ**; Red Baron's analog control faked through ALLPOT.
8. **Resource use roughly 2× what is needed** — 2.4 Mbit framebuffer + 768 kbit inline WAV
   + duplicated vector RAM.

---

## 8. What to copy from the sibling cores

> **Corrected on revision.** The first three rows below pointed at the wrong cores.
> Prefer `Arcade-BlackWidow_MiSTer` throughout: it is 6502 + AVG like BattleZone, and its
> July 2026 release already did this port. Revised priority rows:
>
> | Need | Source |
> |---|---|
> | Whole vector renderer (newest) | `Arcade-BlackWidow_MiSTer/rtl/videodr0me_fb/*` |
> | PROM-driven AVG (generic core) | `Arcade-BlackWidow_MiSTer/rtl/avg/avg_prom_core.vhd` |
> | Vector drawer | `Arcade-BlackWidow_MiSTer/rtl/avg/vector_drawer.vhd` |
> | Cycle-accurate 6502 + 1.5 MHz clock enable | `Arcade-BlackWidow_MiSTer/rtl/t65/` + `bwidow.vhd:299-317` |
> | Core `.sdc` (async PLL clock groups) | `Arcade-BlackWidow.sdc` |
> | Pause via `RDY` | `rtl/pause.v` + `bwidow.vhd:135` |
> | High scores | `rtl/hiscore.v` + `<nvram index="4">` |
>
> The original table follows for reference; rows below the first three remain useful.

| Need | Source |
|---|---|
| Whole vector renderer | `Arcade-Asteroids_MiSTer/rtl/videodr0me_fb/*` (interface at `vfb_top.sv:7-86`) |
| Cycle-exact AVG | `Arcade-StarWars_MiSTer/rtl/avg/avg.vhd` |
| Sub-pixel accumulators + DAC-accurate scale | `Arcade-StarWars_MiSTer/rtl/avg/vector_drawer.vhd:86-121` |
| Anti-aliasing-ish diagonal fill | `vfb_rasterizer.sv:296-345` |
| Intersection glow | `vfb_tile_cache_manager.sv:503-506` |
| Phosphor persistence | `vfb_readout.sv:450-545` |
| Cheap wide glow | `vfb_halo_wide.sv` |
| Line-delay without BRAM | `vfb_sdram_delay.sv` + `vfb_rle_encoder.sv` |
| Resolution auto-adapt from `STABLE_HEIGHT` | `Arcade-StarWars_MiSTer/rtl/starwars.sv:1082-1216` |
| Beam walker (for pixel-rate vs vector-rate mismatch) | `Arcade-Asteroids_MiSTer/rtl/asteroids_video.sv:434-473` |
| Empirical visible-window measurement technique | `Arcade-Asteroids_MiSTer/rtl/asteroids_video.sv:392-405` |
| NVRAM save/load/clear | `Arcade-StarWars.sv:788-838` + MRA `<nvram index="4">` |
| Profile/OSD UX pattern | `vfb_profile_resolver.sv` + `Arcade-StarWars.sv:275-403` |
| Analog control fallback FSM (nearest reference for twin-stick) | `Arcade-StarWars.sv:580-668` |

**Not available from the siblings** — must be built for BattleZone:

- The periscope overlay / backdrop (with a proper gradient, replacing §2.4).
- True dual-stick tank controls.
- EAROM device model (the NVRAM *transport* is copyable; the device is not).
- Bradley Trainer analog I/O.

Note also that **neither sibling core has `hiscore.v` or a pause feature** — do not look
there for those.
