#!/usr/bin/env bash
# Install Slim 7x speaker DSP on Ubuntu (Yoga Slim 7 14Q8X9 / Snapdragon X Elite).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"
[[ -n "$USER_HOME" && -d "$USER_HOME" ]] || { echo "Cannot resolve home for $USER_NAME"; exit 1; }

log() { printf '\n==> %s\n' "$*"; }

need_root_for_system=0
for arg in "$@"; do
  case "$arg" in
    --user-only) USER_ONLY=1 ;;
  esac
done
USER_ONLY="${USER_ONLY:-0}"

if [[ "$USER_ONLY" -eq 0 && "$EUID" -ne 0 ]]; then
  log "Re-running with sudo for system pieces (UCM, IRs, apt)…"
  exec sudo -E bash "$ROOT/install.sh" "$@"
fi

if [[ "$USER_ONLY" -eq 0 ]]; then
  log "Installing packages"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq
  apt-get install -y \
    pipewire pipewire-pulse pipewire-alsa wireplumber \
    libpipewire-0.3-modules \
    lsp-plugins lsp-plugins-lv2 \
    bankstown-lv2 calf-plugins \
    alsa-utils alsa-ucm-conf

  log "Installing impulse responses → /usr/share/dolby-audio"
  install -d /usr/share/dolby-audio
  install -m 644 "$ROOT"/irs/*.wav /usr/share/dolby-audio/

  log "Patching ALSA UCM (PA/COMP/digital) + holding alsa-ucm-conf"
  bash "$ROOT/slim7x-audio-patch.sh"
fi

runuser_cmd() {
  if [[ "$EUID" -eq 0 ]]; then
    sudo -u "$USER_NAME" -H bash -lc "$*"
  else
    bash -lc "$*"
  fi
}

log "Installing user PipeWire DSP config → $USER_HOME/.config/pipewire"
runuser_cmd "mkdir -p \"$USER_HOME/.config/pipewire/pipewire.conf.d\""
install -o "$USER_NAME" -g "$USER_NAME" -m 644 \
  "$ROOT/config/pipewire/slim7x-crossover-module.conf" \
  "$USER_HOME/.config/pipewire/slim7x-crossover-module.conf"
install -o "$USER_NAME" -g "$USER_NAME" -m 644 \
  "$ROOT/config/pipewire/pipewire.conf.d/60-slim7x-crossover.conf" \
  "$USER_HOME/.config/pipewire/pipewire.conf.d/60-slim7x-crossover.conf"
if [[ -f "$ROOT/config/pipewire/pipewire.conf.d/50-quantum.conf" ]]; then
  install -o "$USER_NAME" -g "$USER_NAME" -m 644 \
    "$ROOT/config/pipewire/pipewire.conf.d/50-quantum.conf" \
    "$USER_HOME/.config/pipewire/pipewire.conf.d/50-quantum.conf"
fi

log "Installing scripts → $USER_HOME/.local/bin"
runuser_cmd "mkdir -p \"$USER_HOME/.local/bin\""
for s in "$ROOT"/bin/*; do
  install -o "$USER_NAME" -g "$USER_NAME" -m 755 "$s" "$USER_HOME/.local/bin/$(basename "$s")"
done

log "Installing systemd user units"
runuser_cmd "mkdir -p \"$USER_HOME/.config/systemd/user/pipewire.service.d\""
install -o "$USER_NAME" -g "$USER_NAME" -m 644 \
  "$ROOT/config/systemd/user/pipewire.service.d/allow-lv2.conf" \
  "$USER_HOME/.config/systemd/user/pipewire.service.d/allow-lv2.conf"
for u in slim7x-crossover.service slim7x-speaker-gains.service slim7x-speaker-guard.service; do
  install -o "$USER_NAME" -g "$USER_NAME" -m 644 \
    "$ROOT/config/systemd/user/$u" \
    "$USER_HOME/.config/systemd/user/$u"
done

log "Enabling user services"
# Must run in user systemd session context when possible
if [[ "$EUID" -eq 0 ]]; then
  uid="$(id -u "$USER_NAME")"
  if [[ -S "/run/user/$uid/bus" ]]; then
    sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$uid" \
      systemctl --user daemon-reload
    sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$uid" \
      systemctl --user enable --now slim7x-crossover.service slim7x-speaker-gains.service slim7x-speaker-guard.service || true
    sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$uid" \
      systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service || true
    sleep 2
    sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$uid" \
      systemctl --user restart slim7x-crossover.service || true
    sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$uid" \
      "$USER_HOME/.local/bin/slim7x-load-crossover" || true
    sudo -u "$USER_NAME" XDG_RUNTIME_DIR="/run/user/$uid" \
      "$USER_HOME/.local/bin/slim7x-speaker-gains" || true
  else
    echo "No user bus yet — enable after login:"
    echo "  systemctl --user daemon-reload"
    echo "  systemctl --user enable --now slim7x-crossover slim7x-speaker-gains slim7x-speaker-guard"
  fi
else
  systemctl --user daemon-reload
  systemctl --user enable --now slim7x-crossover.service slim7x-speaker-gains.service slim7x-speaker-guard.service
  systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service || true
  sleep 2
  systemctl --user restart slim7x-crossover.service || true
  "$USER_HOME/.local/bin/slim7x-load-crossover" || true
  "$USER_HOME/.local/bin/slim7x-speaker-gains" || true
fi

log "Done"
cat <<EOF

Slim 7x audio installed for $USER_NAME.

Verify:
  wpctl status | grep -i crossover
  amixer -c 0 sget Speakers
  amixer -c 0 sget 'WooferLeft BOOST'
  amixer -c 0 sget 'TweeterLeft BOOST'

Docs: $ROOT/docs/ARCHITECTURE.md  $ROOT/docs/TUNING.md
EOF
