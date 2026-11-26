#!/usr/bin/env bash
set -euxo pipefail
exec > >(tee /var/log/terraform-ospf-bootstrap.log) 2>&1
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y frr iproute2 iputils-ping tcpdump traceroute dnsutils iptables git
# The in-guest lab is installed separately with lab/install-lab.sh.
echo 'BASE_PACKAGES_INSTALLED' > /opt/terraform-ospf-status
