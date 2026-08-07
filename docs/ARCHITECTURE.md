# Architecture

## Signal path

```text
App (e.g. browser)
    │
    ▼
Speakers (Crossover)   ← PipeWire filter-chain sink (default)
    │
    ├─ Convolver (Dolby-Music-Balanced.wav L/R)
    ├─ Bankstown (psychoacoustic bass weight for tiny woofers)
    ├─ LSP multiband compressor (sub / punch / mid / presence)
    ├─ Light air shelf (high)
    ├─ Calf Exciter (bypassed — was a grit source)
    ├─ Crisp peak (pre-crossover, currently mild)
    │
    └─ LSP stereo crossover @ ~1350 Hz (LR4)
           │
           ├─ Low → woofers (FL/FR)
           │     HPF ~160 Hz
           │     kick body shelf + ~180 Hz peak
           │     mud cut ~380 Hz
           │     woofer compressor (busy/kick stacks)
           │     limiter_f (~−4.5 dBFS)
           │
           └─ High → keyboard tweeters (RL/RR)
                 HPF ~1700 Hz (keeps low keys off bass)
                 mid cloud / ~3.3 kHz vocal-static EQ
                 kb multiband dyn (mud | rasp | snare | stick)
                 broadband pad
                 snare/crack EQ; sparkle ~9.8 kHz; air ~11.5 kHz
                 cymbal wash ~5.8–7.2 kHz (cut-through / static zone)
                 limiter_r (~−6.5 dBFS)
                 LPF ~12 kHz
    │
    ▼
ALSA HiFi Speaker playback
    │
    └─ slim7x-speaker-gains
          Digital 81 (−3 dB codec max)
          Speakers PA: Woofer 6 / Tweeter 5 / Woofer 6 / Tweeter 5
          Woofer BOOST on · Tweeter BOOST off
          Softclip on · COMP off
```

## Why the split BOOST policy

- **Woofer BOOST on** — needed for Windows-like average SPL / kick weight.
- **Tweeter BOOST off** — with BOOST on, mid/high energy softclipped into a constant “radio static” hash around the snare band (~5–7 kHz), even when DSP peaking looked modest.
- **Tweeter PA 5 (−1.5 dB)** — extra hardware headroom on the keyboard drivers while woofers stay at 0 dB pad.

## PipeWire / systemd pieces

| Piece | Role |
|-------|------|
| `slim7x-crossover-module.conf` | Full filter-chain definition |
| `pipewire.conf.d/60-slim7x-crossover.conf` | Same graph auto-loaded with PipeWire |
| `slim7x-load-crossover` | Ensures module is loaded; sets default sink |
| `pipewire.service.d/allow-lv2.conf` | Relaxes sandbox so LV2 plugins can map executable pages |
| `slim7x-speaker-gains.service` | Applies ALSA targets after login (twice, delayed) |
| `slim7x-speaker-guard.service` | Re-applies if BOOST/PA/digital/softclip drift |

## Channel map warning

Do not assume FL/FR are “front speakers.” On this chassis:

- **FL/FR = woofers**
- **RL/RR = tweeters**

The ALSA `Speakers` element order is **WooferL, TweeterL, WooferR, TweeterR** (verified separately from PCM order).
