#!/usr/bin/env bash
set -euo pipefail
printf '\n--- namespaces ---\n'
ip netns list
printf '\n--- R1 OSPF neighbors ---\n'
vtysh -N r1 -c 'show ip ospf neighbor'
printf '\n--- R1 OSPF routes ---\n'
vtysh -N r1 -c 'show ip route ospf'
printf '\n--- R1 Internet default ---\n'
vtysh -N r1 -c 'show ip route 0.0.0.0/0'
printf '\n--- PC1 to PC2 ---\n'
ip netns exec pc1 ping -c 3 -W 2 192.168.20.10
printf '\n--- PC1 to Google DNS IP ---\n'
ip netns exec pc1 ping -c 3 -W 2 8.8.8.8
printf '\n--- DNS query ---\n'
ip netns exec pc1 dig @8.8.8.8 example.com A +time=3 +tries=2 +short
