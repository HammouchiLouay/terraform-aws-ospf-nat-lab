#!/usr/bin/env bash
set -euo pipefail
/opt/ospf-lab/setup-topology.sh
for router in r1 r2 r3; do
  if vtysh -N "$router" -c 'show ip ospf' >/dev/null 2>&1; then
    echo "[ospf] $router already active"
  else
    /usr/lib/frr/frrinit.sh start "$router"
  fi
done
printf '[ospf] router pathspaces started; allow time for adjacency formation\n'
