#!/usr/bin/env bash
# Temporary interface shutdown: only run in this lab. Auto-restores on exit.
set -euo pipefail
restore() {
  ip -n r1 link set r12 up || true
  ip -n r2 link set r21 up || true
}
trap restore EXIT
printf '=== Before failure: R1 route ===\n'
vtysh -N r1 -c 'show ip route 192.168.20.0/24'
printf '=== Disabling direct R1-R2 connection ===\n'
ip -n r1 link set r12 down
ip -n r2 link set r21 down
sleep 10
vtysh -N r1 -c 'show ip ospf neighbor'
vtysh -N r1 -c 'show ip route 192.168.20.0/24'
ip netns exec pc1 traceroute -n -I -m 6 -w 1 192.168.20.10 || true
ip netns exec pc1 ping -c 3 -W 2 192.168.20.10
printf '=== Restoring R1-R2 connection ===\n'
restore
sleep 45
vtysh -N r1 -c 'show ip route 192.168.20.0/24'
