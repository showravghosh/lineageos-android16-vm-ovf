#!/bin/bash
set -e
cd /home/student/Downloads/Android_16/vmware/Android16
# Always the NEWEST built image - a hardcoded date here silently installs a
# stale build and every fix looks like it failed.
SRC=$(ls -t /home/student/Downloads/Android_16/lineage/out/target/product/virtio_x86_64/lineage-23.2-*-UNOFFICIAL-virtio_x86_64.img | head -1)
echo "using image: $(basename $SRC)"
pkill -f "qemu-system-x86_64" 2>/dev/null || true
sleep 2
echo "=== rebuilding installer disk from $(du -h $SRC | cut -f1) image ==="
FATSZ=$(stat -c%s "$SRC"); FATSEC=$((FATSZ/512)); TOTAL=$((2048 + FATSEC + 2048))
rm -f installer_gpt.raw
truncate -s $((TOTAL*512)) installer_gpt.raw
sgdisk --zap-all installer_gpt.raw >/dev/null 2>&1 || true
sgdisk -n 1:2048:$((2048+FATSEC-1)) -t 1:ef00 -c 1:"EFI System" installer_gpt.raw >/dev/null
dd if="$SRC" of=installer_gpt.raw bs=1M seek=1 conv=notrunc status=none
echo "=== wiping disks for a clean install ==="
rm -f system.raw userdata.raw
truncate -s 16G system.raw
# The userdata disk stays a RAW whole disk with no partition table - that is
# what the installer expects. It is reached as /dev/block/by-name/userdata via
# androidboot.partition_map on the kernel cmdline, which now maps both vdb
# (QEMU) and sdb (VMware) to the name "userdata".
truncate -s 128G userdata.raw
echo "=== ready ==="
ls -lh installer_gpt.raw system.raw userdata.raw | awk '{print "  ", $9, $5}'
