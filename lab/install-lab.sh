#!/usr/bin/env bash
# Run after Terraform deploy and clone this repository onto the EC2 instance.
# Reconstructed workflow: not verified on a fresh EC2 instance.
set -euo pipefail
if [ "$(id -u)" -ne 0 ]; then echo 'Run with sudo' >&2; exit 1; fi
SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
command -v vtysh >/dev/null || { echo 'FRRouting missing' >&2; exit 1; }
command -v iptables >/dev/null || { echo 'iptables missing' >&2; exit 1; }
install -d /opt/ospf-lab
for item in setup-topology.sh configure-frr.sh start-lab.sh start-internet.sh; do
  install -m 0755 "$SOURCE_DIR/$item" "/opt/ospf-lab/$item"
done
install -d /opt/ospf-lab/frr
cp -a "$SOURCE_DIR/frr/." /opt/ospf-lab/frr/
/opt/ospf-lab/setup-topology.sh
/opt/ospf-lab/configure-frr.sh
install -m 0644 "$SOURCE_DIR/systemd/ospf-lab.service" /etc/systemd/system/ospf-lab.service
install -m 0644 "$SOURCE_DIR/systemd/ospf-internet.service" /etc/systemd/system/ospf-internet.service
systemctl daemon-reload
systemctl enable ospf-lab.service ospf-internet.service
systemctl start ospf-lab.service
systemctl start ospf-internet.service
printf '\n[install] validate with: sudo bash lab/verify.sh (from repository directory)\n'
