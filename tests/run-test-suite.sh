#!/bin/bash
# tests/run-test-suite.sh — post-install validation for emcommtools-mint
# Tests that key tools are installed, services are present, and state is valid.

PASS=0
FAIL=0
WARN=0
STATE=/etc/hamradio/state

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() { echo -e "${GREEN}  PASS${NC}  $1"; ((PASS++)); }
fail() { echo -e "${RED}  FAIL${NC}  $1"; ((FAIL++)); }
warn() { echo -e "${YELLOW}  WARN${NC}  $1"; ((WARN++)); }

section() {
  echo ""
  echo "── $1 ──────────────────────────────────────"
}

# ── Binaries ─────────────────────────────────────────────────────────────────
section "Binaries"

check_bin() {
  if command -v "$1" >/dev/null 2>&1 || [ -x "/usr/local/bin/$1" ]; then
    pass "$1 found"
  else
    fail "$1 not found"
  fi
}

check_bin js8call
check_bin wsjtx
check_bin rigctld
check_bin direwolf
check_bin pat
check_bin fldigi
check_bin flrig
check_bin paracon
check_bin voacapl
check_bin sdrpp

if command -v js8call >/dev/null 2>&1 || [ -x "/usr/local/bin/js8call" ]; then
  pass "js8call executable"
else
  fail "js8call not executable"
fi

# ── et-* commands ─────────────────────────────────────────────────────────────
section "et-* Commands"

for cmd in et-user et-radio et-mode et-info et-time et-trusdx; do
  if [ -x "/usr/local/bin/$cmd" ]; then
    pass "$cmd installed"
  else
    fail "$cmd missing"
  fi
done

# ── State file ────────────────────────────────────────────────────────────────
section "State File (/etc/hamradio/state)"

if [ -f "$STATE" ]; then
  pass "state file exists"
else
  fail "state file missing — run et-user"
fi

source "$STATE" 2>/dev/null

if [ -n "$CALLSIGN" ] && [ "$CALLSIGN" != "N0CALL" ]; then
  pass "CALLSIGN set: $CALLSIGN"
else
  warn "CALLSIGN not set or still placeholder — run et-user"
fi

if [ -n "$GRIDSQUARE" ] && [ "$GRIDSQUARE" != "AA00aa" ]; then
  pass "GRIDSQUARE set: $GRIDSQUARE"
else
  warn "GRIDSQUARE not set or still placeholder — run et-user"
fi

if [ -n "$OPERATOR_NAME" ]; then
  pass "OPERATOR_NAME set: $OPERATOR_NAME"
else
  warn "OPERATOR_NAME not set — run et-user"
fi

if [ -n "$RADIO" ]; then
  pass "RADIO set: $RADIO"
else
  warn "RADIO not set — run et-radio"
fi

if [ -n "$RADIO_PORT" ]; then
  pass "RADIO_PORT set: $RADIO_PORT"
else
  warn "RADIO_PORT not set — run et-radio"
fi

# ── Config files ──────────────────────────────────────────────────────────────
section "Config Files"

RADIO_USER="${SUDO_USER:-$USER}"
RADIO_HOME="/home/$RADIO_USER"

check_config() {
  if [ -f "$1" ]; then
    pass "$2 config exists"
  else
    warn "$2 config missing: $1"
  fi
}

check_config "$RADIO_HOME/.config/JS8Call.ini"        "JS8Call"
check_config "$RADIO_HOME/.config/WSJT-X.ini"         "WSJT-X"
check_config "/etc/direwolf/direwolf.conf"             "Direwolf"
check_config "$RADIO_HOME/linbpq/bpq32.cfg"           "LinBPQ"
check_config "$RADIO_HOME/.config/pat/config.json"    "Pat"
check_config "$RADIO_HOME/.config/paracon/paracon.ini" "Paracon"

# ── Systemd services ──────────────────────────────────────────────────────────
section "Systemd Services"

check_service() {
  if systemctl list-unit-files "$1" 2>/dev/null | grep -q "$1"; then
    pass "$1 unit present"
  else
    fail "$1 unit missing"
  fi
}

check_service direwolf.service
check_service linbpq.service
check_service ardopc.service
check_service trusdx.service

# ── Audio ─────────────────────────────────────────────────────────────────────
section "Audio"

if aplay -l 2>/dev/null | grep -qi "loopback"; then
  pass "ALSA loopback device present"
else
  fail "ALSA loopback not found — check audio role"
fi

if lsmod | grep -q snd_aloop; then
  pass "snd_aloop kernel module loaded"
else
  warn "snd_aloop not loaded — may need reboot"
fi

if command -v pw-cli >/dev/null 2>&1; then
  pass "PipeWire present"
else
  warn "PipeWire not found"
fi

# ── Hamlib ────────────────────────────────────────────────────────────────────
section "Hamlib"

if rigctld --version >/dev/null 2>&1; then
  pass "rigctld runs"
else
  fail "rigctld failed to run"
fi

# Test with dummy rig (model 1)
rigctld -m 1 -t 4532 >/dev/null 2>&1 &
RIGPID=$!
sleep 1
if kill -0 $RIGPID 2>/dev/null; then
  pass "rigctld dummy rig starts"
  kill $RIGPID 2>/dev/null
else
  fail "rigctld dummy rig failed to start"
fi

# ── QMX+ specific ─────────────────────────────────────────────────────────────
section "QMX+ (plug in to test)"

if lsusb 2>/dev/null | grep -qi "0483:a34f\|QRP Labs\|QMX"; then
  pass "QMX+ detected on USB"
  if ls /dev/ttyACM* /dev/ttyUSB* 2>/dev/null | head -1 | grep -q tty; then
    pass "QMX+ serial port present"
  else
    warn "QMX+ USB detected but no serial port — check udev rules"
  fi
else
  warn "QMX+ not detected — plug in to test USB detection"
fi

# ── truSDX specific ───────────────────────────────────────────────────────────
section "truSDX (plug in to test)"

if lsusb 2>/dev/null | grep -qi "1a86:7523\|CH340\|CH341"; then
  pass "truSDX CH340/CH341 USB chip detected"
  if ls /dev/ttyUSB* 2>/dev/null | head -1 | grep -q ttyUSB; then
    pass "truSDX serial port present"
  else
    warn "CH340 detected but no ttyUSB — check udev/driver"
  fi
else
  warn "truSDX not detected — plug in to test USB detection"
fi

# ── User groups ───────────────────────────────────────────────────────────────
section "User Groups"

RADIO_USER="${SUDO_USER:-$USER}"
for grp in dialout audio plugdev; do
  if id "$RADIO_USER" 2>/dev/null | grep -q "$grp"; then
    pass "$RADIO_USER in group: $grp"
  else
    fail "$RADIO_USER not in group: $grp — may need relogin"
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════"
echo " Results: ${PASS} passed  ${WARN} warnings  ${FAIL} failed"
echo "════════════════════════════════════════════"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "Some tests failed. Review output above and re-run the playbook."
  exit 1
elif [ "$WARN" -gt 0 ]; then
  echo "All critical tests passed. Review warnings above."
  exit 0
else
  echo "All tests passed. System ready."
  exit 0
fi
