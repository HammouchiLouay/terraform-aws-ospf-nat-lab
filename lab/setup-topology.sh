#!/usr/bin/env bash
# Reconstructed from the validated November 2026 lab commands.
set -euo pipefail
NAMESPACES=(pc1 r1 r2 r3 pc2)
found=0
for ns in "${NAMESPACES[@]}"; do
  if ip netns list | awk '{print $1}' | grep -qx "$ns"; then found=$((found+1)); fi
done
if [ "$found" -eq 5 ]; then
  echo '[topology] namespaces already exist; verifying interfaces'
  for entry in 'pc1:eth0' 'r1:lan0' 'r1:r12' 'r1:r13' 'r2:r21' 'r2:r23' 'r2:lan0' 'r3:r31' 'r3:r32' 'pc2:eth0'; do
    ip -n "${entry%%:*}" link show "${entry#*:}" >/dev/null
  done
  exit 0
fi
if [ "$found" -ne 0 ]; then
  echo "[topology] partial namespace set ($found/5); refusing to modify it" >&2
  exit 1
fi

for ns in "${NAMESPACES[@]}"; do
  ip netns add "$ns"
  ip -n "$ns" link set lo up
done
make_link() {
  local n1="$1" a="$2" ip1="$3" n2="$4" b="$5" ip2="$6"
  ip link add "$a" type veth peer name "$b"
  ip link set "$a" netns "$n1"
  ip link set "$b" netns "$n2"
  ip -n "$n1" addr add "$ip1" dev "$a"
  ip -n "$n2" addr add "$ip2" dev "$b"
  ip -n "$n1" link set "$a" up
  ip -n "$n2" link set "$b" up
}
make_link pc1 eth0 192.168.10.10/24 r1 lan0 192.168.10.1/24
make_link r1 r12 10.0.12.1/30 r2 r21 10.0.12.2/30
make_link r1 r13 10.0.13.1/30 r3 r31 10.0.13.2/30
make_link r2 r23 10.0.23.1/30 r3 r32 10.0.23.2/30
make_link r2 lan0 192.168.20.1/24 pc2 eth0 192.168.20.10/24
for ns in r1 r2 r3; do
  ip netns exec "$ns" sysctl -qw net.ipv4.ip_forward=1
  ip netns exec "$ns" sysctl -qw net.ipv4.conf.all.rp_filter=0
done
ip -n pc1 route replace default via 192.168.10.1
ip -n pc2 route replace default via 192.168.20.1
echo '[topology] five namespaces and five point-to-point veth links ready'
