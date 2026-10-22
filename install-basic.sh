#!/bin/bash
# install-basic.sh: lean radio-laptop install on top of Linux Mint
#
# Installs: base system, audio, hamlib, JS8Call, WSJT-X, Pat + ARDOP,
#           truSDX driver, et-* commands, and the Start/Stop Radio
#           launcher (JS8Spotter + JS8-tracker) with desktop icons,
#           et-predict (offline HF propagation map, VOACAP), and
#           et-aircraft (RTL-SDR aircraft tracker).
# Skips:    packet/BBS, APRS, SDR, Kiwix, conky.
#
# Usage:  ./install-basic.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/bootstrap.sh" \
  --tags "base,audio,hamlib,ardop,wsjtx,js8call,pat,voacap,predict,aircraft,trusdx,glue,launcher" "$@"
