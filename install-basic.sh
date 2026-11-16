#!/bin/bash
# install-basic.sh: lean radio-laptop install on top of Linux Mint
#
# Installs: base system, audio, hamlib, JS8Call, WSJT-X, Pat (Winlink)
#           with ARDOP and Mercury HF modems, BTECH UV-PRO Bluetooth
#           packet (et-uv-pro), truSDX driver, et-* commands,
#           et-predict (offline HF propagation map, VOACAP), and
#           et-aircraft (RTL-SDR aircraft tracker).
# Skips:    packet/BBS, APRS, SDR, Kiwix, conky.
# Leaves ~/radio (your Start/Stop Radio scripts) alone.
#
# Usage:  ./install-basic.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/bootstrap.sh" \
  --tags "base,audio,hamlib,ardop,mercury,wsjtx,js8call,pat,uvpro,voacap,predict,aircraft,trusdx,glue" "$@"
