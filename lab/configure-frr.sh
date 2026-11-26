#!/usr/bin/env bash
# Copy the reviewed FRR pathspace configurations to /etc/frr/<router>.
set -euo pipefail
DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [ "$(id -u)" -ne 0 ]; then echo 'Run with sudo' >&2; exit 1; fi
for router in r1 r2 r3; do
  if ! ip netns list | awk '{print $1}' | grep -qx "$router"; then
    echo "Missing router namespace $router; create topology first" >&2; exit 1
  fi
done
for router in r1 r2 r3; do
  target="/etc/frr/$router"
  mkdir -p "$target"
  cp /etc/frr/daemons "$target/daemons"
  # Ubuntu's packaged FRR typically uses zebra=yes and ospfd=no.
  sed -i -E 's/^ospfd=.*/ospfd=yes/; s/^staticd=.*/staticd=no/' "$target/daemons"
  # Remove any active watchfrr_options setting before adding the pathspace binding.
  sed -i '/^watchfrr_options=/d' "$target/daemons"
  printf '\nwatchfrr_options="--netns=%s"\n' "$router" >> "$target/daemons"
  install -o frr -g frrvty -m 0660 "$DIR/frr/$router/frr.conf" "$target/frr.conf"
  touch "$target/vtysh.conf"
  chown frr:frrvty "$target/vtysh.conf"
  chmod 0640 "$target/vtysh.conf"
  echo "[frr] configured $router"
done
