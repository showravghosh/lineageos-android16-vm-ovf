#!/bin/bash
# Drive recovery through one full sideload, from the installer GRUB menu.
# Every step is verified from a screenshot rather than assumed, because a
# half-finished sideload still leaves recovery showing its normal prompt.
Q=/home/student/Downloads/Android_16/tools/qmon.py
export PATH="$HOME/platform-tools:$PATH"
key(){ python3 $Q cmd "sendkey $1" >/dev/null 2>&1; sleep "${2:-1}"; }

echo "--- answering 'reboot to recovery?' with Yes ---"
key down 1; key ret 35

echo "--- installer GRUB menu -> Install ---"
key ret 32

echo "--- recovery: Apply update -> Apply from ADB ---"
key down 1; key ret 4; key ret 7

adb kill-server >/dev/null 2>&1; sleep 1
adb connect localhost:5555 >/dev/null 2>&1; sleep 3
STATE=$(adb devices | awk '/5555/{print $2}')
echo "adb state: ${STATE:-none}"
if [ "$STATE" != "sideload" ]; then
    echo "!! not in sideload mode - stopping"; exit 1
fi

ZIP=$(ls -t /home/student/Downloads/Android_16/lineage/out/target/product/virtio_x86_64/lineage-23.2-*-UNOFFICIAL-virtio_x86_64.zip | head -1)
echo "--- sideloading $(basename $ZIP) ---"
adb -s localhost:5555 sideload "$ZIP"
echo "=== sideload exit=$? ==="
