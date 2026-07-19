# Arcade-BattleZone_MiSTer — Work Handoff

**Date:** 2026-07-18
**Revised:** 2026-07-18 (see "Revision note" below)
**Baseline commit:** `dc8afac` (master, clean tree)
**Companion document:** [`ASSESSMENT.md`](ASSESSMENT.md) — read that first for the *why*
behind everything here.

> **Status of this document:** Phase 1 is **implemented and running on hardware** on
> branch `vector-pipeline-port`. See "Phase 1 results" below. The original draft was a
> static source review with nothing built, simulated, or run on hardware.

---

## Phase 1 results (built and tested on hardware)

All three games render with the CRT pipeline on a 5CSEBA6. Verified by screenshot on a
real MiSTer at 720p: Battlezone (green vectors, red score band, phosphor glow, bloom),
Red Baron and Bradley Trainer (monochrome white, no overlay).

**Fit:** 87% ALMs, 36% block memory, 63% DSP, 3 PLLs.
**Timing:** −0.734 ns worst setup on the 125 MHz domain. The residual paths are in the
framework's `ascal` scaler and Videodr0me's bloom filter, not in this core's logic.
Everything else has positive slack (clk_12 has +62 ns). Worth another look before
release, but no core logic is on the failing paths.

### Bugs found during bring-up, and what caused them

| Symptom | Cause |
|---|---|
| Black screen, correct 980×720 timing | The 1.512 MHz clock enable was gated by reset. `avg_prom_core` works only inside `if clken='1'`, so it never sampled `vgrst`, `halt_flag` never got set, and it powers up at 0 meaning *running* — the AVG executed garbage from `pc=0`. **Black Widow's divider free-runs; ours must too.** |
| CPU never reached the VGGO write | Same gating: `coreReset_l` released on the first enable after reset, giving T65 ~zero *enabled* cycles with `Res_n` low. Now stretched to 256, as `bwidow_top.vhd:104-118` does. |
| (latent) CPU would read stale data | `addrDecoder`'s read mux was registered on the CPU enable, describing the *previous* cycle. That suits Arlet's 6502, which has a registered address bus and presents the address a cycle ahead. T65 needs `DI` in the same enabled cycle — Black Widow's `c_din` is combinational. |
| (latent) AVG would fetch early | `vecmem_bz` merged Black Widow's vector RAM and ROM into one instance and lost a pipeline stage. `ram_2k` sets `outdata_reg_a => "CLOCK0"` (2 cycles) and `vecrom_dout_q` matches it; the AVG's tag pipeline is 2 deep to suit. |
| Image 1.34× overscaled, clipping at the edges | Scale constants inherited from Black Widow encode *its* playfield extent. Retuned against the pre-rework 640×480 output. |
| Overlay band in the wrong place | Drawn against raw `h_cnt`/`v_cnt`, which lead the renderer's output by ~92 px and 50 lines. Both the overlay and the diagnostics now use display coordinates derived from the renderer's own blanking. |

**Technique worth reusing:** the eight sticky diagnostic latches drawn as on-screen
squares (OSD toggle: Debug Overlay). They localized the reset bug in one build; without
them the obvious-looking fix (the read mux) would have been shipped and the screen would
still have been black. Prefix them with a fixed marker pattern so the cell-to-bit mapping
is self-identifying — the first attempt was ambiguous and produced a reading that was
internally contradictory.

**Settled empirically:** the A0 swap in `avg_bz.vhd`. Black Widow and the old Battlezone
core disagreed about vector-memory byte order; Black Widow's little-endian convention is
correct, since the display list decodes into recognisable Battlezone.

---

## Revision note — read this first

The first draft of this document compared BattleZone against `Arcade-StarWars_MiSTer`
and `Arcade-Asteroids_MiSTer` only. **That was the wrong pair of siblings**, and several
conclusions below were wrong as a result. Corrected:

| Original claim | Corrected |
|---|---|
| Port the AVG from Star Wars | **Port from `Arcade-BlackWidow_MiSTer`.** Star Wars is a **6809** machine (`rtl/cpu/mc6809i.v`); its CPU is unusable here and its AVG is a later revision. Asteroids is a **DVG** (digital), a different generator entirely. Black Widow is 6502 + AVG — the same family as BattleZone. |
| The BattleZone AVG state PROM may not exist in the MAME set and may need synthesizing (Open Q3) | **It already exists and is already in the MRA.** `036408-01.k7` (256 B, crc `5903af03`) is listed at `releases/Battle Zone rev 2.mra:35` and is byte-identical (same SHA1) to Red Baron's `036408-01.k7` and Black Widow's `136002-125.n4`. It lands at download offset **`0x5000`** and nothing currently decodes it. |
| Is the 3.125 MHz CPU clock compensating for Arlet's 6502? (Open Q1) | **Moot.** Black Widow's July 2026 release runs T65 from a 1.5 MHz clock enable off the original 12.096 MHz master. Adopt that and the question disappears. |
| `videodr0me_fb` is DDR-backed | It needs **both** DDRAM (tile framebuffer) *and* SDRAM (halo-alignment delay) — `vfb_top.sv:22-43`. Requires a 32 MB SDRAM module. BattleZone ties **both** off (`Arcade-BattleZone.sv:197-198`), so Phase 1a is double the plumbing. |
| Neither sibling has `hiscore.v` or a pause feature | Black Widow has **both** — `hiscore.v` with `<nvram index="4">`, and `pause.v` driving `Rdy` (`bwidow.vhd:135`), including a vector-buffer freeze during pause (`bwidow_dw.vhd:470-477`). |

**Also newly found:** `Red Baron.mra` and `Bradley Trainer.mra` do **not** ship the AVG
state PROM. Both place the unrelated 32-byte `036174-01` at `0x5000` instead. A
PROM-driven AVG will not run on either game until those MRAs are fixed. `redbaron.zip`
does contain `036408-01.k7`; `bradley.zip` is unverified.

---

## TL;DR

This core is a wrapper around a CMU student capstone reimplementation, not a
hardware-derived port. It works, but it is well below the standard of the sibling
vector cores. The good news: **`Arcade-BlackWidow_MiSTer` did exactly this port in
July 2026** (commits `e814f50`, `e560fd8`) on the same CPU and the same vector
generator, so this is tracking a proven change rather than inventing one.

The two highest-value work items are coupled and should be done together:

1. Replace the framebuffer/rasterizer with `videodr0me_fb`.
2. Replace the behavioural AVG with Black Widow's PROM-driven AVG.

Doing (1) without (2) wastes the new renderer's sub-pixel precision on truncated input.
Doing (2) without (1) gives accurate coordinates to a renderer that discards them.

---

## Ground rules before you start

1. **Measure before changing timing.** The CPU runs at 2× the documented hardware rate.
   This may be deliberate compensation for Arlet's non-cycle-accurate 6502. Capture
   reference footage/timing from MAME or hardware *first*. See "Open questions" below.
2. **Keep a known-good build.** `releases/Arcade-BattleZone_20240525.rbf` is the current
   shipping bitstream. Do not delete it until a replacement is validated.
3. **Work on a branch.** Master is clean at `dc8afac`.
4. **The sound section is the best original work in the repo.** Do not rewrite it; it has
   a documented FIXME list from its author and only needs calibration.

---

## Phase 1 — Renderer + AVG replacement

**Goal:** Real vector-CRT appearance and hardware-accurate vector generation.
**Impact:** Transforms how the core looks. This is ~80% of the total value available.
**Risk:** High — this is a large change touching the whole video path.

### 1a. Rebuild the PLL, then bring up DDRAM *and* SDRAM

The clocking has to change first — everything else hangs off it.

| | Current BattleZone | Required |
|---|---|---|
| PLL outputs | `clk_50`, `clk_25`, `clk_6` (`Arcade-BattleZone.sv:225-234`) | `clk_50`, `clk_12`, `clk_6`, `clk_125` |
| `CLK_VIDEO` | `clk_50` | `clk_125` |
| CPU / AVG | 3.125 / 6.25 MHz divided clocks | 12.096 MHz master + 1.5 MHz clock enable |
| `SDRAM_CLK` | tied off | `~clk_125` |

`Arcade-BattleZone.sv:197-198` ties SDRAM to `Z` and DDRAM to `0`; both buses must be
brought up. Reference: `Arcade-BlackWidow.sv:530-539` for the PLL and SDRAM clock, and
`:1162-1183` for the DDRAM/SDRAM port wiring into `vfb_top`.

Repointing `CLK_VIDEO` also dissolves the two unsynchronized pixel-clock dividers
described in ASSESSMENT §3.4 — do not fix those separately.

### 1b. Port `videodr0me_fb`

Copy `Arcade-BlackWidow_MiSTer/rtl/videodr0me_fb/` (18 files) — that is the newest copy
and the one matching the PROM-driven AVG below. Treat it as a shared library.

Integration surface is small on the vector side — `vfb_top.sv` consumes
`X_VECTOR`, `Y_VECTOR`, `Z_VECTOR`, `RGB`, `IS_DOT`, `BEAM_ON`, `FRAME_DONE` — but the
module also needs `clk_125`, `clk_12`, the raw `h_cnt`/`v_cnt`/`ce_pix`/sync/blank
counters, `RENDER_WIDTH`/`RENDER_HEIGHT`, the OSD profile signals, and **both** the
DDRAM and SDRAM buses. See the instantiation at `Arcade-BlackWidow.sv:1131`.

**Delete on success:** `rtl/fb_controller.sv`, `rtl/rasterizer.sv`, `rtl/VGA_fsm.sv`.
This reclaims ~2.4 Mbit of BRAM.

**Carry forward:** the mylar overlay logic currently at `rtl/fb_controller.sv:111-122`
(red above scanline 120, green below). Reimplement it in the new pipeline with a proper
gradient/blend band rather than a hard split — and add an OSD toggle.

### 1c. Replace the AVG

Port from `Arcade-BlackWidow_MiSTer/rtl/avg/`. The three files split cleanly:

| File | Lines | Action |
|---|---|---|
| `avg_prom_core.vhd` | 481 | **Copy as-is.** Game-agnostic PROM-driven state machine with a clean external memory interface (`avg_addr_out` / `avg_data_in` / `avg_data_valid`). |
| `vector_drawer.vhd` | 145 | **Copy as-is.** 14-bit drawer. |
| `avg.vhd` | 170 | **Rewrite.** Thin per-game wrapper owning vector memory and CPU-vs-AVG arbitration. |

**PROM loading.** The PROM is already in the ROM download and currently discarded.
Change Black Widow's decode (`avg.vhd:80`) from `x"A0"` to `x"50"`:

```vhdl
avg_prom_wr <= dn_wr when dn_addr(15 downto 8)=x"50" else '0';
```

All three BattleZone MRAs place their trailing PROM at exactly `0x5000` (16 KB program
ROM ends at `0x4000` per `rtl/top.sv:225`, 4 KB vector ROM ends at `0x5000` per `:256`),
so **one constant covers all three games** — once the Red Baron and Bradley MRAs are
fixed to actually carry `036408-01` (see Revision note).

The PROM decodes correctly under the core's address formation
`running & op & prom_state`: the lower 128 bytes are all zero (`running=0` → halted),
the upper nibble is always zero (matching `dn_data(3 downto 0)` at
`avg_prom_core.vhd:151`), and the eight opcode rows are coherent microcode matching the
VCTR/HALT/SVEC/STAT/CENTER/JSRL/RTSL/JMPL ordering documented in that file's header.

**Delete on success:** `rtl/avg.sv`, `rtl/avg_decode.sv`.

This also removes the unpipelined 22-bit combinational multiply at `rtl/avg.sv:221-222`,
which is very likely the current critical path.

### 1d. Useful technique from Asteroids

If the vector rate and pixel rate mismatch causes dotted lines at high resolutions, see
the **beam walker** at `Arcade-Asteroids_MiSTer/rtl/asteroids_video.sv:434-473` — it runs
at 12 MHz with 8 slots per vector step and moves one pixel at a time, treating jumps
greater than 8 px as repositions rather than dragging a line.

Also worth borrowing: the **empirical visible-window measurement** approach at
`asteroids_video.sv:392-405`. Asteroids determined that the DVG spans 1024×1024 but the
game only ever draws Y 120..904, yielding a 1024×784 window and near-square pixels on 4:3.
The equivalent measurement should be done for BattleZone rather than assuming a window.

### 1e. Acceptance criteria

- Vectors visibly persist and decay between frames.
- Crossing vectors are brighter at intersections.
- Parked dots (bullets, radar sweep, explosion particles) bloom brighter than strokes.
- Long slow-rotating lines do not crawl or shimmer.
- Resolution adapts to the reported HDMI mode.
- Fits with timing closure (see Phase 4 — add the `.sdc` *before* judging fit).

---

## Phase 2 — EAROM and NVRAM

**Goal:** High scores persist.
**Impact:** Real missing hardware, user-visible.
**Risk:** Low. Self-contained.

1. **Add EAROM address decoding** to `rtl/coreInterface.sv:113-141`. Currently there is
   *no* EAROM range decoded at all — reads there return undefined data.
2. **Implement the ER2055 device model** (write/erase/read cycle behaviour). This is the
   only part with no reference implementation available; it must be written from the
   datasheet.
3. **Add the save/load transport.** Copy the Star Wars pattern:
   `Arcade-StarWars.sv:788-838` — save/load/clear over `ioctl_index==4` with
   autosave-on-dirty, manual save, and clear-and-force-save.
4. **Add `<nvram index="4" size="...">`** to `releases/*.mra`.

> **Note (corrected):** Black Widow **does** use `hiscore.v` (`Arcade-BlackWidow.sv:569`)
> with `<nvram index="4">` in all three of its MRAs, coupled to pause via `hs_pause`.
> Notably its `rtl/earom.vhd` is a 42-line **stub** (`data_out <= "11111111"`) — it never
> models the ER2055 at all and gets high scores by snooping RAM instead. That is a much
> cheaper path than writing the device model from the datasheet, at some cost in accuracy.
> Decide which you want before starting; the Star Wars NVRAM-transport pattern remains the
> alternative.

While in `coreInterface.sv`, also **add the watchdog** — address 0x1000 (WDCLR) is
currently undecoded.

---

## Phase 3 — Correctness fixes

**Goal:** Fix real defects. **Risk:** Low. These are independent and can be done any time,
including before Phase 1 as warm-up.

| Fix | Location |
|---|---|
| Remove the duplicate `assign USER_OUT = '1;` (written twice) | `Arcade-BattleZone.sv:187` and `:193` |
| Collapse the duplicated vector RAM into one instance | `rtl/top.sv:258-270` and `:285-295` |
| Add a synchronizer for `dl_addr`/`dl_data`/`dl_wr` crossing `clk_25`→`clk_50` | `Arcade-BattleZone.sv:260` vs `:390` |
| Wire `forced_scandoubler` (already available at `:265`) and `fx` instead of hardcoding 0 | `Arcade-BattleZone.sv:379-380` |
| Verify `AUDIO_S` polarity — set to 0 (unsigned) while the mixer sums signed IIR output | `Arcade-BattleZone.sv:387` |
| Convert blocking assignments in a clocked block to non-blocking | `Arcade-BattleZone.sv:284-296` |
| Fix `H_PULSE` 95 → 96 (moot if Phase 1 deletes `VGA_fsm.sv`) | `rtl/VGA_fsm.sv:30-37` |

Several of these become moot after Phase 1 — check before doing redundant work.

---

## Phase 4 — Build hygiene

**Goal:** Make the build trustworthy. **Do this before judging Phase 1's fit results.**

1. **Write a core-specific `.sdc`.** There is currently none (only `sys/sys_top.sdc`), so
   nothing constrains the long combinational paths or the hand-rolled clock dividers.
   Without this, timing "closure" is meaningless. Copy the shape of
   `Arcade-BlackWidow.sdc` — it declares the four PLL outputs as asynchronous clock
   groups to match the renderer's CDC structure, which the system SDC does not do
   because they share a PLL. **This moves into Phase 1a**, since the new renderer
   depends on it.
2. **Reconsider `Arcade-BattleZone.qsf:52`** — `SEED 1` plus every physical-synthesis
   option enabled is a symptom of missing constraints, not a solution. Revisit once the
   `.sdc` exists.
3. **Move the Red Baron squeal to a sample ROM.** `rtl/squeal_samples.sv` is a 1.4 MB /
   48,000-line inline `initial` block consuming **768 kbit of BRAM** for one sound effect
   (`rtl/squeal_player.sv:22-25`). Load it from the MRA instead. Also fix: non-looping,
   non-retriggerable mid-play, hard-clamped at 48000 samples (`:14`).
4. **Delete dead code:**
   - `rtl/coreInterface.sv:4-72` — `memStoreQueue`, never instantiated
   - `rtl/coreInterface.sv:146, 160-162, 186` — unused debug signals
     (`unmappedAccess`, `unmappedRead`, `vramWrite`)
   - `rtl/rasterizer.sv:320-397` — `sanityBench` testbench inside synthesizable RTL
   - `rtl/rasterizer.sv:19-24, 138` — **Xilinx `mark_debug` attributes in a Quartus
     project**
   - `rtl/fb_controller.sv:224-227` — `//DEPRECATED` block
   - `rtl/top.sv:108-179` — unused `CLK_DIV=="FALSE"` branch (also contains a
     copy-paste bug at `:160-161`)
   - `rtl/data.pickle` — binary dev debris
5. **Parameterize the memory map.** `rtl/coreInterface.sv:113-141` duplicates the entire
   map for Red Baron vs Battlezone.
6. Consider whether the two committed `.rbf` files in `releases/` should stay.

---

## Phase 5 — Timing accuracy

**Resolved in principle — this is now part of Phase 1, not a separate investigation.**

| Signal | Current | Documented HW | Location |
|---|---|---|---|
| CPU clock | 3.125 MHz | 1.512 MHz | `rtl/top.sv:137` |
| AVG clock | 6.25 MHz | 1.5 / 12 MHz | `rtl/top.sv:138` |
| NMI | ~235 Hz | 250 Hz | `rtl/top.sv:297-310` |

The original worry was that BattleZone's 2× CPU clock might be deliberate compensation
for Arlet Ottens' non-cycle-accurate 6502 (`rtl/cpu.sv:13-19`), so correcting the divider
alone could halve game speed.

Black Widow answers this by demonstration: swap Arlet's core for **T65** and drive it
from a **1.5 MHz clock enable off the 12.096 MHz master** rather than a divided clock —
`bwidow.vhd:130-135` for the instantiation, `:299-317` for the divider. That same process
generates a 3 kHz tick and a true **250 Hz interrupt with acknowledge** (`intack_l`
resets `irqctr`), replacing BattleZone's magic `nmi_counter == 12` wrap with no ack.

Note Black Widow's July 2026 release also **reworked T65 itself** — corrected decimal
mode, reset, and interrupt behaviour. Take that copy (`rtl/t65/`), not Asteroids'.

`RDY` is tied high (`rtl/top.sv:313`) — that is the pause hook, and Black Widow drives it
from `pause.v` as `Rdy => not pause_h`.

---

## Phase 6 — Features and polish

- **Pause.** `OSD_STATUS` is an unused input at `Arcade-BattleZone.sv:175`; `RDY` is tied
  high at `rtl/top.sv:313`. Both hooks exist.
- **True dual-stick tank controls.** Currently `joy = joy_0 | joy_1`
  (`Arcade-BattleZone.sv:252`) with the two sticks synthesized from one d-pad by a lookup
  table (`:284-296`). Nearest reference for an analog/digital fallback FSM is
  `Arcade-StarWars.sv:580-668`.
- **Red Baron analog.** Currently faked by writing the axis byte into POKEY's ALLPOT
  (`Arcade-BattleZone.sv:340`, `rtl/POKEY.sv:176`) with no RC timing. Needs a real pot
  model, which means extending POKEY (below).
- **POKEY completion** (`rtl/POKEY.sv:159-178`): missing individual POT0-POT7 reads,
  SERIN/SEROUT, IRQEN/IRQST, KBCODE, SKSTAT, STIMER, timer interrupts, two-tone mode.
- **Bradley Trainer.** `mod_bradley` is an input to `top` that is never referenced in the
  module body (`rtl/top.sv:46`). Currently just BattleZone with different ROMs.
- **OSD expansion.** Current CONF_STR (`Arcade-BattleZone.sv:209-221`) is four functional
  lines. Add: video FX, overlay on/off, vector persistence/glow profiles, service mode,
  Red Baron analog sensitivity. Copy the profile + menumask UX from
  `vfb_profile_resolver.sv` and `Arcade-StarWars.sv:275-403`.
- **Keyboard support** — `ps2_key` is not connected.
- **Coin/service inputs** — port 0x800 is a hardcoded literal
  (`rtl/coreInterface.sv:173`); no coin counters, no slam switch, one coin input only.
- **Sound calibration.** Author's own FIXME list: `rtl/engine_sound.sv:1-2`,
  `rtl/audio_output.sv:43`, `rtl/noise_source_shell_explo.sv:27,38`, `rtl/lfo.sv:10`.
  Mixing is uncalibrated fixed shifts (`rtl/analog_sound.sv:84-88`).
- **README.** Currently 13 lines. Document controls, known issues, fidelity caveats.
- **Red Baron MRA DIP** `bits="0,7" name="Coinage" ids="Normal"` is a placeholder.

---

## Open questions

1. ~~**Is the 3.125 MHz CPU clock compensating for Arlet's 6502?**~~ **Resolved** — moot
   once T65 + 1.5 MHz clock enable off 12.096 MHz is adopted, as Black Widow does.
2. **What is BattleZone's actual visible vector window?** Still open. Needed to size
   `RENDER_WIDTH`/`RENDER_HEIGHT`. Measure empirically rather than assuming.
3. ~~**Does the BattleZone AVG state PROM dump exist?**~~ **Resolved** — `036408-01.k7`,
   256 B, crc `5903af03`, already in `Battle Zone rev 2.mra` and already downloaded to
   offset `0x5000`. Byte-identical to Red Baron's and Black Widow's copies.
4. **Will `videodr0me_fb` + the existing sound section fit** on a 5CSEBA6 with timing
   closure? Still open — needs a build. Note Phase 1 frees ~2.4 Mbit of BRAM by deleting
   the old framebuffer, and Black Widow fits the same renderer on the same device.
5. **Is `AUDIO_S = 0` actually wrong?** Still open. Needs a listening test.
6. **Does `bradley.zip` contain `036408-01`?** New. If not, Bradley's MRA must reference
   bzone's copy or inline the 256 bytes the way Black Widow inlines its index-3 part.
7. **Are the Red Baron controls correct?** Partly resolved, **fix untested**.
   - The ALLPOT approach is *not* a hack: MAME overrides Red Baron's `allpot_r()` to
     return the stick value selected by the output latch, which is exactly what this
     core does (`rtl/POKEY.sv:176` snapshots the P pins on a POTGO write).
   - The real defect: the axis came straight from `joystick_l_analog_0`, so with no
     analog stick connected it sat at centre and **the d-pad did nothing at all**.
     A spring-return digital fallback is now in place, clamped to `0x40..0xbf` to match
     MAME's `PORT_MINMAX` for that stick.
   - **Not verified on hardware.** The mrext remote API only exposes MiSTer system keys
     (`up`/`down`/`left`/`right`/`osd`/`user`/`reset`/`menu`), not game buttons, so a
     coin cannot be inserted remotely and Red Baron cannot be driven out of attract mode.
     Needs a human with a controller. Check: d-pad should turn the aircraft smoothly and
     recentre when released; verify the X/Y axes are not swapped and that neither is
     inverted, since the `audiosel` axis select is inherited and unconfirmed.

---

## Suggested sequencing

Revised. Phase 5 folds into Phase 1, and several Phase 3 defects dissolve rather than
needing separate fixes.

```
Phase 1a (PLL + DDRAM/SDRAM + .sdc)
        │
        ├──> Phase 1c (PROM AVG + T65)  ──┐
        │                                  ├──> build ──> hardware test ──> Phase 6
        └──> Phase 1b (videodr0me_fb)  ────┘
                                            └──> Phase 2 (hiscore/EAROM)
Phase 5 — absorbed into 1a/1c
```

**Defects that fix themselves** — check before doing them separately:

| Defect | Dissolved by |
|---|---|
| Duplicate vector RAM (`top.sv:258-270` / `:285-295`) | new AVG wrapper owns vector memory |
| Two unsynchronized pixel-clock dividers (§3.4) | `CLK_VIDEO` repointed to `clk_125` |
| `H_PULSE` 95→96 (`VGA_fsm.sv`) | `VGA_fsm.sv` deleted |
| `forced_scandoubler`/`fx` hardcoded 0 | new video path |
| Unpipelined 22-bit multiply (`avg.sv:221-222`) | `avg.sv` deleted |

Still worth doing independently: the duplicate `USER_OUT` driver, the `dl_*` CDC
synchronizer, `AUDIO_S` polarity, and the blocking-assignment cleanup.

---

## Files most likely to be deleted

If Phase 1 completes as planned:

- `rtl/fb_controller.sv` — replaced by `videodr0me_fb`
- `rtl/rasterizer.sv` — replaced by `vfb_rasterizer.sv`
- `rtl/VGA_fsm.sv` — replaced by `videodr0me_fb` timing
- `rtl/avg.sv`, `rtl/avg_decode.sv` — replaced by Black Widow's PROM-driven AVG
- `rtl/cpu.sv`, `rtl/ALU.sv` — replaced by T65 (Black Widow's reworked copy)
- `rtl/squeal_samples.sv` — becomes an MRA-loaded sample ROM
- `rtl/data.pickle` — debris

Retained essentially unchanged: the entire analog sound section, `rtl/mathbox.sv`,
`rtl/POKEY.sv` (pending Phase 6).
