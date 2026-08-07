# Slim 7x Audio (Lenovo Yoga Slim 7 14Q8X9)

PipeWire speaker DSP for the **Lenovo Yoga Slim 7x** (Snapdragon X Elite, model `83ED` / `Yoga Slim 7 14Q8X9`).

This is **not** a generic laptop EQ. It is tuned for this machine’s four-speaker layout and ALSA/WSA amp controls, targeting something closer to Windows Dolby loudness/clarity without the mid/high softclip “radio static” that shows up when the tweeters are overdriven.

Upstream starting point / IR credit: [taprobane99/Lenovo-Yoga-Slim-7x-Dolby-Linux-Audio](https://github.com/taprobane99/Lenovo-Yoga-Slim-7x-Dolby-Linux-Audio). The live graph here is a heavily evolved custom crossover chain (see [docs/TUNING.md](docs/TUNING.md)).

## Hardware assumptions

| Role | PCM (PipeWire) | ALSA Speakers mixer order |
|------|----------------|---------------------------|
| Woofers (under deck) | FL / FR | channels 1 & 3 |
| Keyboard tweeters | RL / RR | channels 2 & 4 |

Verified by ear on this chassis. Other Slim 7 / Yoga models may differ.

## What this installs

1. **UCM patch** — safer PA / COMP / digital defaults; `alsa-ucm-conf` held
2. **Dolby impulse responses** → `/usr/share/dolby-audio/`
3. **PipeWire filter-chain** — convolver + Bankstown + LSP multiband + 2-way crossover + per-path EQ/dynamics/limiters
4. **ALSA gain script** — woofer BOOST on, tweeter BOOST off, tweeter PA one step down, softclip on
5. **systemd user units** — load DSP at login, apply gains, re-apply if ALSA drifts

## Quick install

```bash
git clone https://github.com/Dhxqhu/slim7x-audio.git
cd slim7x-audio
./install.sh
```

Then log out/in (or reboot) and select **Speakers (Crossover)** if it is not already the default sink.

Also pulled automatically by [slim7x-hyde](https://github.com/Dhxqhu/slim7x-hyde) (`install.sh` audio step).

## Dependencies (Ubuntu 26.04 arm64)

```bash
sudo apt install pipewire pipewire-pulse wireplumber libpipewire-0.3-modules \
  lsp-plugins lsp-plugins-lv2 bankstown-lv2 calf-plugins \
  alsa-utils alsa-ucm-conf
```

`install.sh` installs these if missing.

## Layout

```text
slim7x-audio/
├── install.sh
├── slim7x-audio-patch.sh          # UCM PA/COMP/digital patch + apt hold
├── config/pipewire/               # live DSP graph + quantum
├── config/systemd/user/           # crossover / gains / guard + LV2 sandbox relax
├── bin/                           # load-crossover, speaker-gains, helpers
├── irs/                           # Dolby-*.wav impulse responses
├── upstream/                      # original Dolby confs + credit README
└── docs/
    ├── ARCHITECTURE.md            # signal path
    └── TUNING.md                  # what we changed and why
```

## Manual checks

```bash
wpctl status | grep -A2 Filters
slim7x-speaker-gains
amixer -c 0 sget Speakers
amixer -c 0 sget 'WooferLeft BOOST'
amixer -c 0 sget 'TweeterLeft BOOST'
```

Expected: Speakers `6,5,6,5`, woofer BOOST **on**, tweeter BOOST **off**, default sink `Speakers (Crossover)`.

## License / credit

Impulse responses and original Dolby PipeWire approach: upstream project above. Custom crossover graph, gain staging, and tuning notes in this repo are documented for this specific Slim 7x.
