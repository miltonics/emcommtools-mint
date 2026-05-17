# Ham Radio Mint Setup

A re-deployable Ansible-based installer for ham radio digital communications
software on **Linux Mint 21.x / 22.x** (or Ubuntu 22.04/24.04).

Functionally equivalent to [EmComm Tools Community](https://community.emcommtools.com/)
but targeting Mint instead of Ubuntu 22.10, and adding support for the
[(tr)uSDX transceiver](https://github.com/miltonics/truSDX-Linux).

---

## Quick Start

### 1. Fresh Mint install — first time

```bash
git clone https://github.com/miltonics/emcommtools-mint.git
cd emcommtools-mint

# No pre-editing needed — run the bootstrap directly.
# Your callsign, grid, and Winlink password are set interactively by et-user
# after the install completes.
chmod +x bootstrap.sh
./bootstrap.sh
```

After the playbook finishes, run `et-user` to set your callsign and identity.
Then log out and back in so group changes (dialout, audio, plugdev) take effect.

### 2. Re-deploying to a new machine

```bash
git clone https://github.com/miltonics/emcommtools-mint.git
cd emcommtools-mint
./bootstrap.sh
```

Your `group_vars/all.yml` is already in git with your callsign, so no editing needed.

### 3. Adding a single role to an existing install

```bash
ansible-playbook site.yml --tags trusdx -K
ansible-playbook site.yml --tags pat -K
```

### 4. Dry run (check what would change, don't apply)

```bash
ansible-playbook site.yml --check -K
```

---

## Configuration

**`group_vars/all.yml`** controls install options — you don't need to edit it for a standard install. Your callsign, grid, and Winlink password are set at runtime by `et-user`.

Key options worth reviewing:

| Variable | Description | Default |
|---|---|---|
| `js8call_install_method` | `"appimage"` (fast) or `"build"` (fixes dark-mode glitches) | `appimage` |
| `trusdx_install` | Install the (tr)uSDX driver | `true` |
| `audio_use_pipewire_virtuals` | Create PipeWire virtual radio sink/source | `true` |
| `sdrpp_install_method` | `"ppa"` or `"build"` | `ppa` |
| `offline_map_state` | US state for offline Navit map (e.g. `WA`) | empty |
| `vara_install` | Install WINE+VARA (manual license required) | `false` |

---

## Daily Use — the et-* Commands

These are the only commands you need to operate:

| Command | What it does |
|---|---|
| `et-user` | Set callsign, grid square, name, Winlink password |
| `et-radio` | Select radio model, auto-detect USB port and audio card |
| `et-mode` | Choose operating mode (JS8Call, WSJT-X, Winlink, APRS, etc.) |
| `et-info` | Show current system status (callsign, radio, mode, CAT) |
| `et-time` | Show GPS/NTP time sync status |
| `et-audio` | List available audio devices |
| `et-trusdx` | Start/stop/status the (tr)uSDX driver service |
| `et-user-backup` | Back up all ham radio configs and Winlink mail |
| `et-user-restore` | Restore from a backup |

### Typical session

```bash
et-radio       # select your radio (only needed when changing radios)
et-mode        # pick JS8Call, Winlink, APRS, etc.
et-info        # confirm everything is connected
```

---

## Supported Radios

### Full CAT control (Tier 1)

| Radio | Interface |
|---|---|
| Yaesu FT-817ND / FT-818ND | DigiRig Mobile + Yaesu FT-8xx cables |
| Yaesu FT-857D / FT-897D | DigiRig Mobile + Yaesu FT-8xx cables |
| Yaesu FT-991A | USB cable |
| Icom IC-705 | USB cable |
| Icom IC-7100 | USB cable |

### Most features (Tier 2)

| Radio | Interface |
|---|---|
| Icom IC-7200 / IC-7300 | USB cable |
| Elecraft KX2 | DigiRig + Elecraft KX cables |
| QRP Labs QMX | USB cable (JS8Call, HF only) |
| Lab599 TX-500MP | DigiRig TX-500 config |
| Xiegu G90 | DigiRig + G90 cables |
| BG2FX FX-4CR | USB |

### truSDX (this project adds)

| Radio | Interface |
|---|---|
| (tr)uSDX / uSDX | USB (CH340/CH341), full driver via trusdx service |

### VHF/UHF audio-only

| Radio | Interface |
|---|---|
| Quansheng UV-K5 Pro | Audio interface via headphone/mic jack; use with Direwolf for APRS/packet |

### Dumb radios (audio only)

Any radio with DigiRig Mobile or DigiRig Lite. No CAT — set freq/mode on radio manually.

---

## Operating Modes

| Mode | What runs |
|---|---|
| JS8Call | JS8Call (auto-configured callsign, grid, CAT + audio) |
| WSJT-X (FT8 / FT4) | WSJT-X (auto-configured callsign, grid, CAT + audio) |
| Fldigi | fldigi (+ flmsg, flamp) |
| APRS Client | Direwolf TNC → YAAC |
| BBS Client | Direwolf TNC → Paracon |
| BBS Server | Direwolf TNC → LinBPQ node |
| Chat | Direwolf TNC → Chattervox |
| APRS Digipeater | Direwolf (SSID -4) |
| Packet Digipeater | Direwolf (SSID -2) |
| Winlink VHF/UHF | Direwolf TNC → Pat |
| Winlink HF ARDOP | ardopc modem → Pat |

---

## Software Installed

| Package | Source |
|---|---|
| Direwolf | apt |
| Hamlib / rigctld | apt |
| WSJT-X | apt |
| JS8Call (improved) | GitHub release AppImage or build from source |
| fldigi / flmsg / flamp | apt |
| Pat (Winlink) | GitHub release |
| ardopc | WB2OSZ binary |
| LinBPQ | G8BPQ binary |
| Paracon | GitHub release (.pyz zipapp, no deb) |
| Chattervox | npm |
| YAAC | ka2ddo.org |
| SDR++ | PPA or build |
| VOACAP | pip (voacapy) |
| Kiwix | static binary |
| truSDX driver | miltonics/truSDX-Linux |

---

## Project Structure

```
hamradio-mint-setup/
├── bootstrap.sh          # Run this on a fresh Mint install
├── site.yml              # Master Ansible playbook
├── group_vars/all.yml    # YOUR SETTINGS — edit before first run
├── roles/
│   ├── base/             # apt update, groups, udev rules
│   ├── audio/            # ALSA loopback + PipeWire virtual devices
│   ├── hamlib/           # rigctld + systemd service template
│   ├── direwolf/         # AX.25 TNC
│   ├── ardop/            # HF soundcard modem
│   ├── wsjtx/            # WSJT-X
│   ├── js8call/          # JS8Call
│   ├── fldigi/           # fldigi + flmsg + flamp
│   ├── pat/              # Winlink client
│   ├── linbpq/           # Packet node/BBS
│   ├── paracon/          # Packet terminal client
│   ├── chattervox/       # AX.25 chat
│   ├── yaac/             # APRS client
│   ├── sdrpp/            # SDR++
│   ├── voacap/           # Propagation prediction
│   ├── kiwix/            # Offline content
│   ├── trusdx/           # (tr)uSDX driver
│   └── glue/             # et-user, et-radio, et-mode, et-info, etc.
└── docs/
    └── ARDOP_NOTES.md    # Kernel tuning notes for ARDOP
```

---

## Differences from EmComm Tools Community

| Feature | ETC | This project |
|---|---|---|
| Base OS | Ubuntu 22.10 (frozen) | Mint 21.x/22.x (LTS-based, updatable) |
| truSDX support | Dumb radio only | Full driver with CAT emulation |
| Deployment | Cubic ISO build (hour+) | `git clone && ./bootstrap.sh` |
| Re-deployment | Rebuild ISO | Re-run playbook |
| GUI | Conky desktop widget | Conky desktop widget + `et-info` CLI |
| VARA | Experimental add-on | Same (unsupported, manual) |
| Offline maps | Navit (US states) | Planned (see TODO) |

---

---



- [ ] Navit offline maps (US state selection) not yet automated
- [ ] VARA FM/HF Wine integration not automated (manual, same as ETC)
- [ ] Bluetooth TNC radios (BTech UV Pro, VR-N76, TH-D74) not yet implemented
- [ ] `et-aircraft` and `et-predict` apps not yet ported
- [ ] SDR++ `build` method not yet scripted (use PPA for now)
- [ ] GPS chrony integration needs testing with real hardware

---

## License

MIT. See LICENSE file. Ham radio software included by this installer retains
its own respective licenses.
