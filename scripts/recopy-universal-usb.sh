#!/bin/bash
# Replace the universal profile on the USB stick and prove it is readable.
set -e
M=/run/media/student/ANDROID16
SRC=/home/student/Downloads/Android_16/export/android16-universal

echo "==============================================================="
echo "  Re-copying android16-universal to the USB stick"
echo "==============================================================="
echo
[ -d "$M" ] || { echo "  Stick not mounted."; exit 1; }

echo "=== before ==="
df -h "$M" | tail -1 | awk '{print "   ", $3, "used,", $4, "free"}'

echo
echo "=== removing the damaged copy ==="
rm -rf "$M/android16-universal"
sync
sleep 2
df -h "$M" | tail -1 | awk '{print "   ", $3, "used,", $4, "free"}'

echo
echo "=== copying again (11 GB - takes a while) ==="
rsync -a --info=progress2 "$SRC/" "$M/android16-universal/"

echo
echo "=== flushing to the drive ==="
# Without this the data can still be in memory, and pulling the stick out
# loses it silently - the file looks the right size but the tail is missing.
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
sleep 3

echo
echo "=== reading it BACK OFF the stick to check it ==="
echo "    (this is the step that catches a bad drive - it re-reads"
echo "     every byte from the flash rather than from memory)"
cd "$M/android16-universal"
bash verify.sh
