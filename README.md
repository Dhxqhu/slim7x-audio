# Slim 7x Audio (Lenovo Yoga Slim 7 14Q8X9)

So you installed linux on your brand new lenovo Yoga Slim 7x only to realize the sound quality and level are absolute garbage? yeah me too.

PipeWire speaker DSP for the **Lenovo Yoga Slim 7x** (Snapdragon X Elite, model `83ED` / `Yoga Slim 7 14Q8X9`).

This is **not** a generic laptop EQ. It is tuned for this machine’s four-speaker layout and ALSA/WSA amp controls, targeting something closer to Windows Dolby loudness/clarity without the mid/high softclip “radio static” that shows up when the tweeters are overdriven. I've
been trying to target the Dolby Atmos sound quality on my laptop by tuning it by comparison by ear. As you may know, sound output is one 
of the most challenging problems to solve when installing linux on any machine. This current configuration tackles a lot of the issues that the stock configuration lacked. 
For one the sound level was insanely low compared to the windows boot but increasing gain only created distortion so I found work-arounds to really dial in the volume level, Currently on my machine it can achieve very similar overall levels to windows only slightly lacking as I'm still dealing with some distortion when trying to increase it more.. 
I added a crossover to split the signals after manual mapping all the speaker locations correctly as they were out of order with the stock configuration so if you plan to try this on something other than the listed laptop this may not be correct for your machine. But the crossover really splits the instruments nicely for a real dynamic feel.
I added a mulitband compressor to brighten up the track. I'm still dealing with some static around the mid-range but any time i target the area of the static it causes the sound quality to fall flat. I think the issue is around the snare frequency because i added a lot of dynamics to try and get the snare to really snap like the dolby atmos dsp manages. 
Currently it is not perfect. Right now it is workable. Sounds decent but not perfect. The hardest part is retaining the overall level while cleaning up the track. i was able to get a really crisp sound at a lower level but by measurement it was about 6db lower in amplitude that running the windows dsp at full volume. So basically the main challenge has been getting the full max volume out of the speakers while also retaining sound quality.
Tracks used for testing are mostly classic soft rock tracks with lots of character and different instruments like Steely Dan and also high energy edm tracks to test the sound of overproduced tracks through the speakers.

I am not an audio engineer in the slightest. If you know ways to improve this dsp any help is gladly appreciated. If you know less than me and are looking for a simple audio solution for running linux on a Lenovo Yoga Slim 7x then look no further.

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
