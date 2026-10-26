# WayVes Shell GPU Benchmarks

Measured Oct 24, 2026.

At the everyday clock cap (300–1500 MHz), the full shell idles at 12.4 W with the dock up, or 11.7 W in power save, against 9.1 W for a bare desktop. The heaviest state measured, a live 4K60 wallpaper behind the picker playing a video preview, draws 29.8 W at an 1800 MHz cap, or 22.0 W in power save. Hidden WayVes instances cost nothing. Laptop RTX 5060 Max-Q on NVIDIA 615.78.08, eDP-1 2560×1600 at 240 Hz, Hyprland.

## Cost by state

Each row is a 60 s average of 1 s samples; ranges are min–max. Static wallpaper and paused media players unless noted. **Full look** = translucent notches (`panelOpacity: 0.65`) and blurred shell layers with `xray` off. **Power save** = opaque notches and no blur on the shell's layers; window blur stays on. The dock, sidebar and media widget rows include the dock; the picker hides it. Util, clock and P-state read power save / full look.

| State | Clock cap (MHz) | Power save (W) | Full look (W) | Power save saves (W) | Util | Clock (MHz) | P-state |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Bare desktop, WayVes running but all hidden | 1500 | 9.1 (9.0–9.6) | — | — | 3.4% | 594 | P5 |
| Dock up, idle | 1500 | 11.7 (11.6–11.8) | 12.4 (12.3–12.6) | 0.7 | 13.1% / 17.8% | 840 / 899 | P4 / P4 |
| Sidebar open (Usage visualisers, 60 fps) | 1500 | 14.8 (14.3–15.1) | 18.8 (18.7–18.9) | 4.0 | 31.7% / 44.6% | 1220 / 1273 | P4 / P0 |
| Wallpaper picker, static card | 1500 | 14.5 (14.4–14.6) | 21.3 (21.2–21.5) | 6.8 | 30.1% / 51.2% | 1089 / 1255 | P4 / P0 |
| Media widget open (paused) | 1500 | 18.5 (18.4–18.6) | 21.8 (21.7–22.0) | 3.3 | 42.7% / 58.9% | 1201 / 1323 | P0 / P0 |
| Wallpaper picker, video preview playing | 1500 | — | 24.3 (24.1–24.4) | — | 70.6% | 1485 (pinned at cap) | P0 |
| Live 4K60 video wallpaper, picker with video preview playing | 1800 | 22.0 (21.8–22.2) | 29.8 (29.7–30.1) | 7.8 | 44.9% / 74.2% | 1728 / 1760 | P0 / P0 |

The bare desktop was measured with Hyprland blur off everywhere, a static stand-in for the dock and no sidebar.

## Fixes and what they saved

The three biggest wins were all about surfaces redrawing when they didn't need to, not about WayVes rendering. Each saving was measured when the fix landed, so only the difference is shown. Sorted by watts saved.

| Change | State measured in | Saved (W) |
| --- | --- | --- |
| `BottomWaves` (waves\_caps) given a `visibilityChangeCommand`, so it stops rendering when hidden | Everything hidden, stock clocks | 7.0 |
| Dock surface shrunk from fullscreen to 2560×700 | Dock up, blur on, 1500 cap | 4.4 |
| Top-bar layerrule `xray = 1` | Media widget open, 1500 cap | 4.0 |
| Clock cap `-lgc 300,1500` | Everything hidden, idle | 3.8 |
| ncs\_wallpaper shader removed from WayVes | Picker with video preview, 1800 cap | 2.8 |
| Sidebar QML read rate 60 → 2 fps | Sidebar open | 1.6 |
| Sidebar WayVes Usage instances 60 → 2 fps | Sidebar open, QML at 2 fps | 1.0 |
| Content shadow → shape shadow (`applyToShape: true`) | Sidebar at 60 fps / media widget | 0.2–0.5 |
| Hyprland `misc:vfr` on | Sidebar open | none |
| Dock `visible1` also requires `opacity > 0` | Picker with video preview, 1800 cap | none measurable |

The opposite direction was tested once: reading the dock's DMA-BUF surfaces at 240 fps instead of 25/30 added 10.8 W, with WayVes output unchanged.

## What drives the cost

The cost tracks how many pixels get recomposited each frame, not how much WayVes draws.

- **WayVes itself is cheap.** Hidden instances cost 0 W: nine hidden instances measure the same as WayVes quit. The dock's WayVes rendering plus DMA-BUF import measured 2.6 W; five sidebar Usage instances at 60 fps, about 1 W.
- **Qt redraws the whole window every frame.** The same 100×50 marquee costs +0.5 W in a 400×80 window and +5.3 W in a fullscreen one. A fullscreen dock redrawing at 25 fps cost 4.5 W in Qt alone. So surface size and redraw rate are the levers, not what's drawn.
- **Blur multiplies it.** Any damage over a blurred layer with `xray` off makes Hyprland re-blur under it every frame, and pushes VRAM from P4 (9001 MHz) to P0 (12001 MHz). Power save removes that: it saves 0.7 W at dock idle, where nothing blurred animates, and 6.8–7.8 W in the picker, the largest blurred surface. In full look, Hyprland is the top process in pmon (about 50% SM in the picker over a live wallpaper).
- **The picker with a video is the heaviest shell state.** A fullscreen animated Qt window over blurred layers combines all three effects: 24.3 W with a video preview, pinned at the 1500 MHz cap, and 29.8 W over a live 4K60 wallpaper at 1800.

## Caveats

- **Noise is about ±1.5 W between sessions.** Each row is a single 60 s run. Within a run the spread stayed under 1 W, but the same state measured in another session can move by about 1.5 W, so smaller differences aren't conclusive.
- **Two rows use other settings.** The bare desktop had Hyprland blur off everywhere. The live-wallpaper row ran at an 1800 MHz cap, so its gap to the 1500 rows isn't the wallpaper alone.
- **pmon attribution is rough.** It reports whole percent per process, and its shares swung widely at identical power. Treat watts as the measurement, pmon as a hint.
- **Laptop GPU, open driver, 240 Hz panel.** A 60 Hz panel was never tested and may idle at a lower memory clock.