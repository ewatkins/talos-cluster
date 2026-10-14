#!/bin/sh
# Adds every VM in the Proxmox pool `wings` to HA (state started), once.
#
# Runs as root on the Proxmox nodes (wings-ha-sync.timer). HA can only be
# managed with Sys.Console on /, which amounts to root, so the cluster's
# tofu token is never given it: tofu puts a wing in the pool, this puts the
# pool in HA. Removal needs nothing here: tofu destroys with purge, which
# drops the VM from HA too. A VM already in HA is never touched, so states
# set by hand (e.g. `--state stopped` for a WINGS.md rollback) stay.
set -eu

POOL=wings

members=$(pvesh get "/pools/$POOL" --output-format json | python3 -c '
import json, sys
print(" ".join(str(m["vmid"]) for m in json.load(sys.stdin).get("members", []) if m.get("type") == "qemu"))
')

for vmid in $members; do
  ha-manager config | grep -qx "vm:$vmid" && continue
  # Every node runs this timer; if another node won the race, that's fine.
  if ha-manager add "vm:$vmid" --state started --comment "pool $POOL (wings-ha-sync)" 2>/dev/null; then
    logger -t wings-ha-sync "added vm:$vmid to HA"
  elif ! ha-manager config | grep -qx "vm:$vmid"; then
    logger -t wings-ha-sync -p user.err "failed to add vm:$vmid to HA"
    exit 1
  fi
done
