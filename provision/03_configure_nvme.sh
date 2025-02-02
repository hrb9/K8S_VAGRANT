#!/usr/bin/env bash
set -euxo pipefail

echo "[INFO] Configuring additional disk for LVM..."
ls /lib/modules/$(uname -r)/kernel/drivers/nvme/host/
echo "[INFO] Loading necessary kernel modules..."
# sudo modprobe dm_snapshot
# lsmod | grep dm_snapshot || echo "[WARN] dm_snapshot module not loaded?"


