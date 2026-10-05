#!/bin/bash
export PATH="$HOME/platform-tools:$PATH"
# Always the NEWEST build - a hardcoded date silently sideloads a stale zip.
ZIP=$(ls -t /home/student/Downloads/Android_16/lineage/out/target/product/virtio_x86_64/lineage-23.2-*-UNOFFICIAL-virtio_x86_64.zip | head -1)
echo "using: $(basename $ZIP)"
echo "==============================================="
echo "  Sideloading Android 16 + Google Play + ARM"
echo "  $(du -h $ZIP | cut -f1)"
echo "==============================================="
adb kill-server >/dev/null 2>&1
sleep 1
adb connect localhost:5555
sleep 2
adb devices
echo ""
adb -s localhost:5555 sideload "$ZIP"
echo ""
echo "=== sideload finished (rc=$?) ==="
