#!/bin/bash
# bootstrap.sh — one-shot setup for a fresh Linux Mint install
# Run this once to install Ansible, then it hands off to the playbook.
#
# Usage:
#   git clone <this-repo> hamradio-mint-setup
#   cd hamradio-mint-setup
#   chmod +x bootstrap.sh
#   ./bootstrap.sh
#
# To install only specific roles after the initial run:
#   ansible-playbook site.yml --tags trusdx -K

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║     Ham Radio Mint Setup — Bootstrap         ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── Detect distro ────────────────────────────────────────────────────────────
if ! grep -qiE "mint|ubuntu" /etc/os-release; then
  echo "ERROR: This setup targets Linux Mint or Ubuntu."
  echo "Detected: $(grep ^NAME= /etc/os-release | cut -d= -f2)"
  exit 1
fi

echo "Distro OK: $(grep ^PRETTY_NAME= /etc/os-release | cut -d= -f2 | tr -d '\"')"
echo ""

# ── Install Ansible ───────────────────────────────────────────────────────────
if ! command -v ansible-playbook &>/dev/null; then
  echo "Installing Ansible..."
  sudo apt update -qq
  sudo apt install -y software-properties-common
  sudo add-apt-repository --yes --update ppa:ansible/ansible
  sudo apt install -y ansible
else
  echo "Ansible already installed: $(ansible --version | head -1)"
fi

# ── Install required Ansible collections ─────────────────────────────────────
echo ""
echo "Installing Ansible collections..."
ansible-galaxy collection install community.general --upgrade

# ── Run the playbook ──────────────────────────────────────────────────────────
echo ""
echo "Starting installation. This will take 20–60 minutes depending on"
echo "your internet speed and whether JS8Call/Pat need to be downloaded."
echo ""
echo "You will be prompted for your sudo password once."
echo ""

ansible-playbook "$SCRIPT_DIR/site.yml" -K "$@"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         Installation Complete!               ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Next steps:                                 ║"
echo "║    1.  et-user    — set callsign & grid       ║"
echo "║    2.  et-radio   — select and detect radio   ║"
echo "║    3.  et-mode    — choose operating mode     ║"
echo "║    4.  et-info    — view system status        ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Log out and back in for group changes to    ║"
echo "║  take effect (dialout, audio, plugdev).      ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
