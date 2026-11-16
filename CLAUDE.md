# emcommtools-mint

Ansible playbook to set up a full emcomm ham radio station on Linux Mint 22 (Ubuntu Noble base).
Forked from thetechprepper/emcomm-tools-os-community but being reimplemented cleanly for Mint 22.
GitHub: https://github.com/miltonics/emcommtools-mint

## Station
- Operator: Milton KE8SWO, EN82
- Radios: QRP Labs QMX+ (hamlib model 2052, /dev/ttyACM0), truSDX, BTECH UV-PRO (Bluetooth KISS TNC)
- Radio laptop: Dell Latitude 5420
- OS: Linux Mint 22 Cinnamon, Ubuntu Noble base

## Current Status
Playbook runs clean: ok=92, failed=0, ignored=1 (chattervox — abandoned upstream)
CAT control working: rigctld@2052 confirmed at 7.078 MHz

Nov 2026: added roles uvpro (et-uv-pro) and mercury, and et-winlink in the pat role.
Sandbox-tested (roles run clean, Pat drives Mercury's TNC, keying via rigctld).
NOT yet tested on real hardware: Bluetooth pairing/rfcomm, on-air packet, on-air Mercury.

The launcher role is disabled in site.yml on purpose. ~/radio (start_radio.sh,
stop_radio.sh, js8-tracker, JS8Spotter) is hand-managed. Do not re-enable the role
or write into ~/radio without asking.

## Reimplementation Order
1. et-* commands (et-user, et-radio, et-mode, et-info, et-time) — IN PROGRESS
2. fldigi suite
3. JS8Call-improved
4. Remaining roles TBD

## Key Files
- site.yml — master playbook
- group_vars/all.yml — all variables
- roles/glue/templates/et-radio.j2 — radio selection, rigctld startup
- roles/glue/templates/et-mode.j2 — operating mode switcher
- roles/hamlib/ — rigctld service + wrapper script
- roles/pat/templates/et-winlink.j2 — points Pat at uvpro/mercury/ardop/packet/telnet
- roles/uvpro/templates/et-uv-pro.j2 — UV-PRO Bluetooth pair/connect
- roles/mercury/templates/start-mercury.j2 — builds Mercury settings from state
- tests/run-test-suite.sh — post-install validation

## Run Commands
- Full install: ansible-playbook site.yml -K
- Test: sudo tests/run-test-suite.sh
- Tags: ansible-playbook site.yml --tags js8call -K

## Rules for Claude
- One role or one et-* script at a time
- Always check against original ETC for feature parity before marking done
- Test with ansible-playbook --check before applying changes
- Commit after each working change
- Never break the clean playbook run
