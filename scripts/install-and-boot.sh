#!/bin/bash
# Full fresh install, end to end, in one visible window.
#
# Everything here is driven from the QEMU monitor, so the steps show on the
# VM window while this window narrates what is being sent.
cd /home/student/Downloads/Android_16
Q=/home/student/Downloads/Android_16/tools/qmon.py
export PATH="$HOME/platform-tools:$PATH"
key(){ python3 $Q cmd "sendkey $1" >/dev/null 2>&1; sleep "${2:-1}"; }

echo "==============================================================="
echo "  STEP 1/4  wiping disks and rebuilding the installer"
echo "==============================================================="
bash reinstall.sh

echo
echo "==============================================================="
echo "  STEP 2/4  booting the installer"
echo "==============================================================="
pkill -f qemu-system-x86_64 2>/dev/null
sleep 2
rm -f vmware/Android16/serial.log vmware/Android16/logcat.log
setsid ptyxis --new-window -- bash vmware/Android16/run-install3.sh >/dev/null 2>&1 &
sleep 35

echo "  GRUB menu -> Install LineageOS 23.2"
key ret 32

echo "  recovery -> Apply update -> Apply from ADB"
key down 1; key ret 4; key ret 7

adb kill-server >/dev/null 2>&1; sleep 1
adb connect localhost:5555 >/dev/null 2>&1; sleep 3
STATE=$(adb devices | awk '/5555/{print $2}')
echo "  adb state: ${STATE:-none}"
[ "$STATE" = "sideload" ] || { echo "!! not in sideload mode - stopping"; exit 1; }

ZIP=$(ls -t lineage/out/target/product/virtio_x86_64/lineage-23.2-*-UNOFFICIAL-virtio_x86_64.zip | head -1)
echo
echo "==============================================================="
echo "  STEP 3/4  sideloading $(basename "$ZIP")"
echo "  (adb stops around 47% - an A/B update only needs payload.bin,"
echo "   so recovery closes the stream before the whole zip is served."
echo "   That is a COMPLETED install, not a stall.)"
echo "==============================================================="
adb -s localhost:5555 sideload "$ZIP"
echo "  sideload returned $?"
sleep 5

echo
echo "==============================================================="
echo "  STEP 4/4  booting the installed system"
echo "==============================================================="
pkill -f "adb.*sideload" 2>/dev/null
sleep 2
pkill -f qemu-system-x86_64 2>/dev/null
sleep 3
rm -f vmware/Android16/serial.log vmware/Android16/logcat.log
setsid ptyxis --new-window -- bash vmware/Android16/run-final.sh >/dev/null 2>&1 &

echo "  waiting for boot, then checking whether /data mounted..."
sleep 75
echo
echo "=== by-name/userdata ==="
grep -iE "by-name/userdata" vmware/Android16/serial.log | tail -3
echo "=== /data ==="
grep -iE "mounted /data|Failed to mount /data|init_user0|metadata_encryption" vmware/Android16/serial.log | tail -6
echo
echo "  (if nothing above shows a failure, /data mounted cleanly)"
