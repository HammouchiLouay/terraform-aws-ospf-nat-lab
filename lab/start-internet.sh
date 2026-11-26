#!/usr/bin/env bash
# Host-level source NAT, plus OSPF-advertised default through R2.
# No changes to AWS network interfaces, AWS route tables or Security Groups.
set -euo pipefail
ip -n r2 link show lan0 >/dev/null
WAN_IF="$(ip -4 route show default | awk 'NR==1 {print $5}')"
if [ -z "$WAN_IF" ] || [ "$WAN_IF" = 'ospf-uplink' ]; then
  echo '[internet] could not determine AWS egress interface' >&2; exit 1
fi
if ! ip link show ospf-uplink >/dev/null 2>&1; then
  if ip -n r2 link show r2-uplink >/dev/null 2>&1; then
    echo '[internet] orphaned r2-uplink detected; manual repair required' >&2; exit 1
  fi
  ip link add ospf-uplink type veth peer name r2-uplink
  ip link set r2-uplink netns r2
fi
ip -n r2 link show r2-uplink >/dev/null
ip -4 addr show dev ospf-uplink | grep -q '172.31.250.1/30' ||
  ip addr add 172.31.250.1/30 dev ospf-uplink
ip -n r2 -4 addr show dev r2-uplink | grep -q '172.31.250.2/30' ||
  ip -n r2 addr add 172.31.250.2/30 dev r2-uplink
ip link set ospf-uplink up
ip -n r2 link set r2-uplink up
ip -n r2 route replace default via 172.31.250.1 dev r2-uplink
ip route replace 192.168.10.0/24 via 172.31.250.2 dev ospf-uplink
ip route replace 192.168.20.0/24 via 172.31.250.2 dev ospf-uplink
sysctl -qw net.ipv4.ip_forward=1
for NET in 192.168.10.0/24 192.168.20.0/24 172.31.250.2/32; do
  iptables -C FORWARD -i ospf-uplink -o "$WAN_IF" -s "$NET" -j ACCEPT 2>/dev/null ||
    iptables -I FORWARD -i ospf-uplink -o "$WAN_IF" -s "$NET" -j ACCEPT
  iptables -t nat -C POSTROUTING -s "$NET" -o "$WAN_IF" -j MASQUERADE 2>/dev/null ||
    iptables -t nat -A POSTROUTING -s "$NET" -o "$WAN_IF" -j MASQUERADE
done
iptables -C FORWARD -i "$WAN_IF" -o ospf-uplink -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null ||
  iptables -I FORWARD -i "$WAN_IF" -o ospf-uplink -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
printf '[internet] host NAT ready on %s; R2 default route points to 172.31.250.1\n' "$WAN_IF"
