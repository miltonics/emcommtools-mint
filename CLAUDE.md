# emcommtools-mint

Ansible playbook to set up a full emcomm ham radio station on Linux Mint 22 (Ubuntu Noble base).
Forked from thetechprepper/emcomm-tools-os-community but being reimplemented cleanly for Mint 22.
GitHub: https://github.com/miltonics/emcommtools-mint

## Station
- Operator: Milton KE8SWO, EN82
- Radios: QRP Labs QMX+ (hamlib model 2052, /dev/ttyACM0) and truSDX
- OS: Linux Mint 22 Cinnamon, Ubuntu Noble base

## Current Status
Playbook runs clean: ok=92, failed=0, ignored=1 (chattervox — abandoned upstream)
CAT control working: rigctld@2052 confirmed at 7.078 MHz

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
