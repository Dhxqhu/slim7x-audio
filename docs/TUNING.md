# Tuning notes (Yoga Slim 7x)

Living log of what changed relative to the stock upstream Dolby filter-chain, and why. Tuned by ear against Windows Dolby on the same machine (Peg, dense EDM, spoken/sung mids). Phone SPL readings were used as a rough loudness check (~79–82 dB peak target at the same listening position).

## Goals

1. Closer to Windows **loudness** and **kick** without woofer softclip grit on sustained bass
2. **Clear mids** without hollow “scooped” choruses
3. **Snare snap / brightness** without constant mid/high **radio static**
4. Keep instrument separation (already good once mud/rasp were controlled)

## Hardware ceiling (important)

You cannot “just turn it up” past the amp:

- Speakers PA max = **6** (0 dB)
- WSA digital max useful = **81** (−3 dB on this codec)
- Extra SPL came from **BOOST** + denser average level in DSP
- Distortion under load was almost always **softclip** (especially tweeters), not “needs more EQ boost”

## Evolution (high level)

### Loudness / kick

- Raised average level via mid/high makeups and woofer path punch rather than only peak slam
- **BOOST on** for SPL; woofer peaks grabbed harder so BOOST raises average, not rasp
- Kick body: shelf + ~175 Hz peak on woofer path; slower punch-band attack so the beater lands before compression
- Sustained bass guitar: less Bankstown saturation, harder/faster grab after the transient, narrower kick peak so held notes don’t cook

### Mud / rasp

- Mid cloud cuts (~520 Hz woofer, ~1.5 kHz keyboard) + dyn duck when the stack pushes
- Narrow ~3.3 kHz rasp notch (avoided wide 3 kHz cuts that sounded hollow)
- Learned: **permanent negative makeups** on kb multiband were quietly lowering overall volume every pass — switched to “hard when loud, closer to unity when quiet”

### Snare static (the big one)

Symptom: constant radio-static / hash around the snare band.

Causes that mattered:

1. **Tweeter BOOST** + softclip hashing mid/high continuously
2. Stacked peaking EQ in ~4.5–7.5 kHz into that softclip
3. Harmonic **exciter** adding grit (now **bypassed**)
4. Presence makeup restoring HF into an already hot tweeter path

Fixes that stuck:

- Tweeter **BOOST off**, tweeter **PA 5**, colder tweeter limiter (~−2 dBFS)
- Deep/wide grit notch ~**6.2 kHz**
- Crack peak moved **down** (~4.3 kHz); air moved **up** (~8.5–9.5 kHz) — around the grit band, not through it
- Exciter bypassed

Trade-off: aggressive static kill sounded hollow/dull briefly; restored body with eased mid scoops + careful crisp, without re-stacking 5–7 kHz boosts.

## Current target character

| Band | Intent |
|------|--------|
| Sub / punch | Kick hits; sustained notes sit down |
| Low-mid | Not muddy; not hollow |
| Rasp (~3 kHz) | Dyn + narrow notch when it pushes |
| Snare crack (~4.3 kHz) | Present |
| Grit (~6.2 kHz) | Cut hard (static zone) |
| Air (~8.5–9.5 kHz) | Brightness without hash |

## Files to touch when tuning

| File | What |
|------|------|
| `config/pipewire/slim7x-crossover-module.conf` | DSP graph (keep `60-slim7x-crossover.conf` identical) |
| `bin/slim7x-speaker-gains` | ALSA BOOST / PA / digital / softclip |
| `config/systemd/user/slim7x-speaker-guard.service` | Must match desired gains (6,5,6,5 / BOOST policy) |

Reload after DSP edits:

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
sleep 2
systemctl --user restart slim7x-crossover.service slim7x-speaker-guard.service
slim7x-load-crossover
slim7x-speaker-gains
```

## 2026-08-07 dial-in (current)

Locked a crisp/loud balance after long A/B. Notable vs earlier tree:

- Broadband convolver **+3 dB**; loudness from mid/high makeups, bass path kept softclip-safe
- Keyboard HPF **~1700 Hz** so low keys don’t muddy bass
- Vocal static: wide-ish **~3.3 kHz** sit + rasp dyn that doesn’t chase vibrato (slow attack, longer release on sustains)
- Sparkle at **~9–11 kHz**, grit still cut around **5.5–6.2 kHz**
- Busy sections: mid/woofer dyn + colder limiters; avoid raising all thresholds at once (that muddied sparse parts)

## Still imperfect

- Rare kick/vocal crack peaks under very dense material
- Windows can still win slightly on absolute clarity/loudness
- Graph is specific to this Slim 7x channel map and amp controls — porting needs re-verification of FL/FR vs RL/RR and mixer order
