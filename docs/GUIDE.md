# emcommtools-mint: Radio Laptop Guide

An Ansible playbook that turns a fresh Linux Mint install into a ham radio and emergency communications laptop. It is based on EmComm Tools Community, adapted for Mint, and includes support for the (tr)uSDX and QRP Labs QMX.

- Repo: https://github.com/miltonics/emcommtools-mint
- Target: Linux Mint 22.x (Ubuntu 24.04 "noble" base)
- Current radio laptop: Dell Latitude 5420 (its hostname still says `milton-ThinkPad-T440`, which is harmless)

---

## How it fits together

```
Linux Mint
  └─ Ansible playbook (site.yml) runs "roles", one per piece of software
       ├─ base, audio, hamlib     foundation: packages, groups, rig control
       ├─ js8call, wsjtx, pat,    the radio programs
       │  ardop, fldigi, ...
       ├─ trusdx                  truSDX USB driver, runs as a background service
       ├─ etapi                   shared lookup service (callsigns, aircraft, grid)
       ├─ voacap, predict         HF propagation map (et-predict)
       ├─ aircraft                aircraft tracker (et-aircraft, needs RTL-SDR)
       ├─ uvpro                   BTECH UV-PRO over Bluetooth (et-uv-pro)
       ├─ linbpq                  your own packet node and BBS (et-bbs-server)
       ├─ paracon                 packet BBS client (et-paracon)
       ├─ mercury                 Mercury HF modem (Winlink over HF)
       └─ glue                    the et-* helper commands
```

The playbook is safe to run again. Anything already installed and correct gets skipped (shown as `ok`), and only what's missing or changed gets done (shown as `changed`).

---

## First-time install

```bash
cd ~
git clone https://github.com/miltonics/emcommtools-mint.git
cd emcommtools-mint
./install-basic.sh
```

| Command | What it does |
|---|---|
| `git clone ...` | Downloads the project from GitHub into `~/emcommtools-mint`. |
| `./install-basic.sh` | Installs Ansible if needed, then runs the playbook with the lean set of roles (see below). It asks once for your password (the "BECOME password"). Expect 15 to 40 minutes. |

After it finishes:

1. **Log out and back in.** This adds you to the `dialout` and `audio` groups. Without it, programs can't open the radio's USB port.
2. Run `et-user` once to set your callsign, grid, and Winlink password.
3. Download JS8Spotter from https://kf7mix.com/js8spotter.html and unzip it anywhere inside `~/radio`. (It isn't on GitHub, so the playbook can't fetch it.)

### What install-basic.sh includes

`base, audio, hamlib, ardop, mercury, wsjtx, js8call, pat, uvpro, linbpq, paracon, voacap, predict, aircraft, sdrpp, trusdx, glue`

It skips chattervox, APRS (yaac), Kiwix (offline Wikipedia, a very large download), and the conky desktop widget. You can add any of these later (see "Installing or updating one piece").

---

## Day-to-day operating

### Start Radio / Stop Radio

The Start Radio and Stop Radio icons run your own scripts, `~/radio/start_radio.sh` and `~/radio/stop_radio.sh`. They start JS8Call, then JS8Spotter, then the JS8-tracker map backend, for the QMX+.

**The playbook does not touch `~/radio`.** The `launcher` role that used to write those scripts (with a truSDX/QMX picker) is switched off in `site.yml` and left out of `install-basic.sh`, because it overwrote the working scripts and broke JS8-tracker. The role is still in `roles/launcher/` as the starting point for a radio picker later.

JS8-tracker map: open http://127.0.0.1:5000 in a browser while the radio is running.

### Same thing from a terminal

```bash
~/radio/start_radio.sh
~/radio/stop_radio.sh
tail -n 20 ~/radio/logs/js8tracker.log    # if the map does not come up
```

Running it from a terminal is handy when something isn't working, because you can see its messages.

---

## HF propagation prediction (et-predict)

et-predict shows a map. You pick a station (click the map, type a callsign, or type a grid square), set your power and mode, and it shows how likely a contact is on each band, hour by hour. It works with no internet: VOACAP runs on the laptop, and callsign lookups come from an offline copy of the FCC license database.

| How to open it | What it does |
|---|---|
| **HF Prediction** icon on the desktop (or in the menu) | Starts the background lookup service if needed, then opens the map. The first launch after a reboot can take up to a minute while it builds its search indexes. |
| `et-predict` | Same thing from a terminal. |
| `et-voacap --rx-call W1AW -p 10 -m js8` | Text-only prediction from your grid square to W1AW at 10 watts in JS8. Prints a 24-hour chart by band. |

`et-voacap` options:

| Option | Meaning |
|---|---|
| `--rx-call`, `--rx-grid`, `--rx-latlon` | The station you want to reach, by callsign, grid square (e.g. `FN31`), or `lat,lon`. |
| `--tx-call`, `--tx-grid`, `--tx-latlon` | Where you're transmitting from. Leave it out to use the grid you set with `et-user`. |
| `-p` | Power in watts. One of 5, 10, 20, 50, 100, 500, 1500. |
| `-m` | Mode: `js8`, `ardop`, `cw`, `ssb`, `am`, `vara-500`, `vara-2300`, `vara-2750`. |

How to read the chart: rows are frequency in MHz (40 = 40 m band and so on), columns are hours UTC, and letters are reliability. A = 90 to 100%, B = 75 to 89%, C = 50 to 74%, lowercase letters are poor, and blank means no path.

Predictions use your grid square from `et-user`. If they start from the wrong place, run `et-user` again.

**Sunspot data:** VOACAP needs the monthly sunspot forecast. The install grabs a fresh copy. To refresh it later (needs internet), run:

```bash
cd ~/.local/share/emcomm-tools/voacap && ./fetch-ssn.sh
```

**Maps** come from OpenStreetMap over the internet. With no internet, the map background may be blank, but predictions still work if you type a callsign or grid.

The prediction service runs in the background after you log in. To check it: `systemctl --user status et-api`. To restart it: `systemctl --user restart et-api`.

---

## Aircraft tracking (et-aircraft)

Plug in the RTL-SDR (with its antenna) and the Aircraft Tracker shows planes near you on a map, using the ADS-B position reports they broadcast on 1090 MHz. Click a plane to see its registration (tail number, make, model, owner) from an offline copy of the FAA registry. Range depends on the antenna, typically 50 to 150 miles with a clear view of the sky.

| How to open it | What it does |
|---|---|
| **Aircraft Tracker** icon on the desktop (or in the menu) | Checks the dongle is plugged in, starts the lookup service and dump1090, then opens the map. Closing the map stops dump1090 so the dongle is free for other SDR software. |
| `et-aircraft` | Same thing from a terminal. |
| http://localhost:1090 | dump1090's own simple map, in a browser, while the tracker is running. |

Only one program can use the RTL-SDR at a time. Close SDR++ or anything else using it first.

The install also stops Linux from treating the RTL-SDR as a TV tuner. If the tracker says dump1090 couldn't open the dongle right after installing, unplug and replug it once.

---

## Winlink email over radio (Pat)

Pat is the Winlink program. It runs in the background and you use it from a web page at http://localhost:8080. One command, `et-winlink`, points Pat at the right radio path and opens it. `et-mode` has a menu entry for each path, or run them directly:

| Path | Start it with | Connect in Pat |
|---|---|---|
| UV-PRO over Bluetooth (VHF/UHF packet) | `et-uv-pro connect winlink`, or **Winlink (UV-PRO)** in the app menu | `W8CMN-9` (saved shortcut), or `ax25+linux:///<GATEWAY>` |
| HF with the Mercury modem | `et-mode`, pick "Winlink HF Mercury" | `varahf:///<GATEWAY>?freq=<dial kHz>` |
| HF with the ARDOP modem | `et-mode`, pick "Winlink HF ARDOP" | `ardop:///<GATEWAY>?freq=<dial kHz>` |
| Sound card packet through Direwolf | `et-mode`, pick "Winlink VHF/UHF Packet" | `ax25+agwpe:///<GATEWAY>` |
| Internet only | `et-winlink telnet` | `telnet` |

Your callsign, grid and Winlink password come from `et-user`. `et-winlink` copies them into Pat every time, and keeps any connect shortcuts you added yourself. To add a packet gateway shortcut for good, add it to `winlink_packet_gateways` in `group_vars/all.yml` and run `ansible-playbook site.yml -K --tags pat`.

Close Pat with `et-winlink stop`. Its log is `~/.local/state/hamradio/pat.log`.

### BTECH UV-PRO over Bluetooth (et-uv-pro)

The UV-PRO has a packet modem (KISS TNC) built in and shares it over Bluetooth, so no cable or sound card is involved.

One time:

1. Turn Bluetooth off on your phone, or close the BTECH app and WoAD. The radio only talks to one device at a time.
2. `et-uv-pro pair` and follow the prompts (radio: Menu > Pairing). If that fails, pair the radio from Mint's Bluetooth panel and run `et-uv-pro pair` again; it picks up the existing pairing.

Each session:

1. Tune the radio to the gateway (W8CMN-9 is 144.990).
2. `et-uv-pro connect winlink`. It asks you to power-cycle the radio and turn on Menu > General Settings > KISS TNC > Enable KISS TNC, then opens Pat.
3. In Pat: Action > Connect, pick `W8CMN-9`. Or in a terminal: `pat connect W8CMN-9`.
4. `et-uv-pro disconnect` when done.

| Command | What it does |
|---|---|
| `et-uv-pro connect` | Connects and asks what to run: Winlink, a packet terminal (`axcall`), or just the serial port. |
| `et-uv-pro connect serial` | Leaves `/dev/rfcomm0` free for Reticulum or another KISS program. |
| `et-uv-pro status` | Shows pairing, link, and whether Pat is running. |
| `et-uv-pro setchannel <n>` | Only if the link never comes up. `sdptool browse <MAC>` shows the radio's Serial Port channel. Default is 1. |

After any disconnect the radio needs a power cycle, or about 30 seconds, before it accepts a new link.

### Mercury HF modem

Mercury is an open-source HF modem from the HERMES project. Pat drives it the same way it would drive VARA, so there is no Wine and no licence. **Both ends must run Mercury** (1.9.20 or newer). It does not talk to VARA or ARDOP stations.

- Find gateways at https://winlink.org/RMSChannels: choose VARA and enter service code `MERCURY`.
- Radio in USB with a filter at least 2.4 kHz wide.
- The modem keys the radio through rig control (rigctld), so run `et-radio` first.
- **QMX/QDX:** in digital mode these radios send one tone at a time, so Mercury is set to transmit only its slow MFSK mode (receive is not limited). If your QMX+ runs the SSB firmware in USB mode, add `MERCURY_MFSK_ONLY=false` to `/etc/hamradio/state` for full speed.
- Test keying without sending data: `mercury -C ~/.config/mercury/et-mercury.ini -Q` keys the radio for one second.
- Log: `journalctl -u mercury -f`. Notes: `/var/lib/hamradio/MERCURY_NOTES.md`.
- Mercury's log shows `Command rejected (WRONG): CWID ON` and `WINLINK SESSION` when Pat connects. Pat carries on and places the call anyway.

---

## Packet BBS: client and your own node

Two pieces, both reachable from `et-mode` (BBS Client, BBS Server) or directly. Each asks which radio to use: the **UV-PRO over Bluetooth** (default) or **sound card packet through Direwolf**.

### Connect to other BBSs and nodes (Paracon)

```bash
et-paracon
```

Paracon opens in the terminal. Use Connect and enter the station, for example a node or BBS callsign. It also shows a monitor of all packets heard. Your callsign is filled in from `et-user`.

Paracon only speaks AGWPE and the UV-PRO only speaks KISS, so on the UV-PRO path `et-paracon` starts your LinBPQ node first and Paracon talks to the radio through it. That is normal; it is how the pieces fit.

### Run your own node and BBS (LinBPQ)

```bash
et-bbs-server start
```

| | |
|---|---|
| Node | `KE8SWO-7`. People connect to it over the air. |
| BBS (mailbox) | `KE8SWO-11`, or type `BBS` once connected to the node. |
| Chat | `KE8SWO-12`, or type `CHAT` on the node. |
| Your own console | `telnet localhost 8010`, user `sysop` |
| Web admin | http://localhost:8012, user `sysop` |
| Sysop password | `~/linbpq/sysop-password` (made at first start; not your Winlink password) |

`et-bbs-server stop` stops it. `et-bbs-server status` shows whether it is running.

The config `~/linbpq/bpq32.cfg` is rewritten from your callsign and grid each start. To take it over by hand, delete its first line and it will be left alone. Mail and chat settings (`linmail.cfg`, `chatconfig.cfg`) are LinBPQ's own and are never touched.

**One program at a time on the UV-PRO.** Winlink (`et-uv-pro connect winlink`) and the node both need the radio's Bluetooth link. Run `et-uv-pro disconnect` before switching. Stopping LinBPQ takes up to about 40 seconds, which is normal.

**Running a node is transmitting unattended.** It IDs every 10 minutes and answers anyone who connects. Pick a frequency that local packet users agree on before leaving it running.

---

## The et-* commands

These are short commands installed in `/usr/local/bin`, so they work from any folder.

| Command | What it does |
|---|---|
| `et-user` | Sets callsign, grid square, operator name, and Winlink password. Updates Pat's config too. Run once after install, or whenever these change. |
| `et-radio` | Picks your radio from a menu and finds its USB port. Saves the result for `et-mode`. |
| `et-mode` | Picks an operating mode (JS8Call, WSJT-X, Fldigi, Winlink ARDOP, etc.). Stops whatever else was running, rewrites configs for the chosen radio, and starts the needed services. This is the alternative to the Start Radio icon when you want something other than JS8Call. |
| `et-info` | Shows a status box: callsign, radio, port, audio devices, mode, and whether rig control and the modems are running. Run it first when something seems off. |
| `et-audio` | Lists every sound card and audio device. Useful for finding the radio's name when choosing audio in JS8Call or WSJT-X. |
| `et-trusdx status` | Shows whether the truSDX driver is running. Also takes `start`, `stop`, `restart`, and `log` (live driver messages; press Ctrl+C to leave). |
| `et-winlink <path>` | Points Pat (Winlink) at `uvpro`, `mercury`, `ardop`, `packet` or `telnet` and opens it. `et-winlink stop` closes it. |
| `et-uv-pro` | Pairs and connects the BTECH UV-PRO over Bluetooth (see above). |
| `et-paracon` | Packet BBS client. Asks UV-PRO or Direwolf. |
| `et-bbs-server` | Your own packet node and BBS (LinBPQ): `start`, `stop`, `status`. |
| `et-kill-all` | Stops all radio services, Pat, and any Bluetooth radio link. Use it when things are tangled and you want a clean slate. |
| `et-predict` | Opens the HF propagation map (see above). |
| `et-voacap` | Text-only HF prediction (see above). |
| `et-aircraft` | Opens the aircraft tracker (see above). |
| `et-api-start` | Starts the background lookup service and copies your grid from `et-user` to it. The app icons run this for you. |
| `et-time` | Shows clock sync status. FT8 and JS8 need the clock to be within about a second. |
| `et-user-backup` | Saves your settings (identity, Pat/Winlink mail, WSJT-X, Fldigi) to a `.tar.gz` file in your home folder. |
| `et-user-restore <file>` | Puts a backup made by `et-user-backup` back in place. |

Note: `et-user-backup` does not save JS8Call's settings files. Back those up by hand:

```bash
cp ~/.config/JS8Call*.ini ~/
```

---

## Installing or updating one piece

Every role has a "tag" with the same name. `--tags` runs just those roles.

```bash
cd ~/emcommtools-mint
ansible-playbook site.yml -K --tags js8call
```

| Command | What it does |
|---|---|
| `ansible-playbook site.yml -K` | Runs the full playbook (every role, including the big optional ones). `-K` makes it ask for your password. |
| `... --tags js8call` | Runs only the JS8Call role. |
| `... --tags "pat,uvpro"` | Runs several roles. Quote the list and separate with commas. |
| `... --skip-tags kiwix` | Runs everything except Kiwix. |
| `... --check` | Dry run. Shows what would change without changing anything. |
| `./install-basic.sh` | Re-runs the lean set. Safe to repeat any time. |

Role names you can use with `--tags`:
`base audio hamlib direwolf ardop wsjtx js8call fldigi pat linbpq paracon chattervox yaac sdrpp voacap predict aircraft kiwix trusdx uvpro mercury glue conky`

**Upgrading JS8Call:** the playbook skips the download if `/usr/local/bin/js8call` already exists. To get a newer release:

```bash
sudo rm /usr/local/bin/js8call
ansible-playbook site.yml -K --tags js8call
```

---

## Getting updates from GitHub

```bash
cd ~/emcommtools-mint
git pull
./install-basic.sh
```

| Command | What it does |
|---|---|
| `git pull` | Downloads the latest version of the playbook. |
| `git status` | Shows files you've changed locally. If any are listed, `git pull` may refuse to run. |
| `git reset --hard origin/main` | Throws away your local changes and matches GitHub exactly. Only use it when you're sure the local edits aren't needed. |

### Saving a change you made back to GitHub

```bash
git add -A
git commit -m "Short description of the change"
git push
```

`add` stages your changes, `commit` records them with a note, and `push` uploads them. Your GitHub token is saved, so `push` shouldn't ask for it.

---

## Troubleshooting

| Symptom | Check / fix |
|---|---|
| Wall of `[WARNING]: Unable to parse ... as an inventory source` at the start of every run | Harmless. Ansible is scanning the project folder. The play itself runs fine. |
| `Could not resolve 'archive.ubuntu.com'` | DNS/network problem, not the playbook. Check with `ping -c 2 archive.ubuntu.com`. If a VPN is on, turn it off and retry. |
| `503 Service Unavailable` from a mirror during apt | That Ubuntu mirror is flaky. Look in `/etc/apt/sources.list.d/official-package-repositories.list` and change the mirror to `http://archive.ubuntu.com/ubuntu`, then `sudo apt update`. |
| JS8Call can't connect to the radio (CAT error) | Run `et-info`. Make sure you logged out and back in after install. For truSDX, check `et-trusdx status`. Then check Settings > Radio in JS8Call. |
| truSDX driver won't start | `et-trusdx log` shows why. Usually the radio isn't plugged in, or the USB port changed. `ls /dev/ttyTRUSDX` should exist when it's connected. |
| truSDX audio missing in JS8Call | The driver runs as a background service and may not see your desktop's audio system. Note what `et-audio` shows and what `et-trusdx log` says, and it can be fixed in the trusdx role. |
| No audio devices for the QMX | Run `et-audio` with the radio plugged in. The QMX shows up as "QMX Transceiver". |
| Callsign search finds nothing for a valid callsign | The lookup index was probably built incompletely. Run `systemctl --user stop et-api`, then `rm -rf /opt/emcomm-tools-api/index/*`, then `systemctl --user start et-api`. Wait a full minute before searching. |
| Aircraft Tracker says "No RTL-SDR found" | Check `lsusb` shows `0bda:2838`. Try another USB port. |
| Aircraft Tracker says dump1090 could not open the RTL-SDR | Another program is using it, or the TV driver grabbed it. Close SDR software, unplug and replug the dongle, and try again. |
| No planes appear | Give it a few minutes. Put the antenna near a window or outside. Check http://localhost:1090 to see whether dump1090 hears anything. |
| HF Prediction says the service did not start | Run `journalctl --user -u et-api` to see why. Check `java -version` works. Then `systemctl --user restart et-api` and try again. |
| et-voacap: "Sunspot number file not available" | Run the `fetch-ssn.sh` line from the et-predict section (needs internet). |
| FT8 / JS8 decodes nothing | Run `et-time`. The clock may be off. |
| JS8-tracker map does not open after Start Radio | `tail -n 20 ~/radio/logs/js8tracker.log` shows why. If an old copy is still holding the port: `~/radio/stop_radio.sh`, then `pkill -f js8_tracker_backend.py`, then start again. |
| `et-uv-pro connect` says the Bluetooth serial link did not come up | Phone Bluetooth off. Power-cycle the radio, wait 30 seconds, try again. Check KISS TNC is enabled on the radio. |
| UV-PRO connects but the gateway never answers | Check the frequency and that squelch opens on the gateway's signal. Watch traffic with `sudo axlisten -a -tttt -c`. |
| Pat says the Winlink account cannot be confirmed | Wrong or missing password. Run `et-user`, then `et-winlink config`. |
| `et-bbs-server start` says LinBPQ did not come up | `journalctl -u linbpq -n 30`. On the UV-PRO path, check `et-uv-pro status` shows the serial link up. If you just stopped it, wait 40 seconds and try again. |
| Paracon cannot connect to its server | The node or Direwolf is not running. Start Paracon with `et-paracon`, not `paracon`, so it starts them. |
| Mercury starts then stops | `journalctl -u mercury -n 30`. Usually no radio sound card picked: run `et-radio` with the radio plugged in. |
| Something tangled and you want to start over | `~/radio/stop_radio.sh`, then `et-kill-all`, then Start Radio again. |

---

## Where things live

| Path | What's there |
|---|---|
| `~/emcommtools-mint/` | This project (the playbook). |
| `~/emcommtools-mint/group_vars/all.yml` | Settings for the playbook: which optional pieces install, download URLs, install methods. |
| `~/radio/` | Your own start_radio.sh, stop_radio.sh, js8-tracker, JS8Spotter. Not managed by the playbook. |
| `~/radio/logs/` | Logs from programs started by Start Radio (`js8call.log`, `js8tracker.log`, ...). Look here when something closes right after starting. |
| `~/truSDX-Linux/` | The truSDX driver. |
| `/etc/hamradio/state` | Your callsign, grid, chosen radio, and mode (written by `et-user`, `et-radio`, `et-mode`). |
| `~/.config/JS8Call.ini` | JS8Call settings. |
| `/usr/local/bin/js8call` | The JS8Call program (JS8Call-improved AppImage). |
| `/usr/local/bin/et-*` | The helper commands. |
| `~/.config/pat/config.json` | Pat (Winlink) settings. `et-winlink` keeps callsign, password and transports current. |
| `~/.local/share/pat/` | Winlink mailbox. |
| `~/linbpq/` | LinBPQ: `bpq32.cfg`, mail and chat data, logs, `sysop-password`. |
| `~/.config/paracon/paracon.cfg` | Paracon settings. |
| `~/.config/hamradio/uvpro.conf` | The UV-PRO's Bluetooth address, saved by `et-uv-pro pair`. |
| `~/.config/mercury/et-mercury.ini` | Mercury settings, rewritten at every start from `/etc/hamradio/state`. |
| `/opt/emcomm-tools-api/` | The prediction service and its offline data (FCC licenses, ZIP codes, Winlink stations). |
| `~/.local/share/emcomm-tools/voacap/` | VOACAP scripts and the sunspot forecast (`ssn.txt`). |
| `~/.local/share/emcomm-tools/dump1090/` | dump1090's working folder and web map page. |
| `~/itshfbc/` | VOACAP's working folder. The last prediction is in `run/`. |

---

## Radios

| Radio | How it connects |
|---|---|
| (tr)uSDX | USB (CH340 chip, shows up as `/dev/ttyTRUSDX`). The truSDX driver turns its single USB connection into normal CAT control and audio. Start it with `et-trusdx start`. |
| QRP Labs QMX | USB (shows up as `/dev/ttyACM0` plus a "QMX Transceiver" sound card). Hamlib model 2052. No driver needed. |
| BTECH UV-PRO | Bluetooth, using the radio's built-in KISS TNC. Packet and Winlink only (no audio). See `et-uv-pro`. |
