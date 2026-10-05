#!/bin/bash
# Format the USB stick to exFAT and copy both Android 16 profiles onto it.
#
# exFAT is used because FAT32 cannot hold a file larger than 4 GB, and the
# data disk in each profile is 7.5 GB. exFAT works on Windows, Mac and Linux.
#
# THIS ERASES THE STICK - the Kali Linux installer on it will be gone.
set -e
DEV=/dev/sdb
PART=/dev/sdb1
SRC=/home/student/Downloads/Android_16/export

echo "==============================================================="
echo "  Format USB stick and copy Android 16 onto it"
echo "==============================================================="
echo

# --- refuse to run against anything that is not a removable USB disk ---
if [ "$(cat /sys/block/sdb/removable 2>/dev/null)" != "1" ]; then
    echo "  /dev/sdb is not removable. Stopping."; exit 1
fi
SIZE=$(lsblk -bno SIZE "$DEV" | head -1)
if [ "$SIZE" -gt 137438953472 ]; then
    echo "  /dev/sdb is larger than 128 GB - that does not look like the"
    echo "  USB stick. Stopping, to be safe."; exit 1
fi

echo "  Device : $DEV  ($(lsblk -dno SIZE,MODEL $DEV))"
echo "  This will ERASE it, including the Kali Linux installer."
echo
read -p "  Type ERASE to continue: " OK
[ "$OK" = "ERASE" ] || { echo "  Cancelled - nothing changed."; exit 1; }
echo
echo "You will be asked for your password."
echo

echo "=== 1/4  unmounting ==="
# The Files app keeps the drive open, which makes mkfs fail with
# "Device or resource busy". Closing the file manager releases it; GNOME
# restarts it automatically the next time a folder is opened.
if fuser -m "$PART" 2>/dev/null | grep -q .; then
    echo "  something has the drive open - closing the Files app"
    nautilus -q 2>/dev/null || true
    sleep 3
fi
udisksctl unmount -b "$PART" 2>/dev/null || sudo umount "$PART" 2>/dev/null || true
sleep 2
# last resort: detach the mount even if a process still references it
mountpoint -q "$(lsblk -no MOUNTPOINT "$PART" | head -1)" 2>/dev/null && \
    sudo umount -l "$PART" 2>/dev/null || true
sleep 2
if fuser -m "$PART" 2>/dev/null | grep -q .; then
    echo
    echo "  The drive is still in use. Close any window or terminal that is"
    echo "  showing it, then run this again."
    exit 1
fi

echo "=== 2/4  formatting as exFAT ==="
sudo mkfs.exfat -n "ANDROID16" "$PART"
sleep 2

echo "=== 3/4  mounting ==="
udisksctl mount -b "$PART" >/dev/null 2>&1 || true
sleep 3
MNT=$(lsblk -no MOUNTPOINT "$PART" | head -1)
[ -n "$MNT" ] || { echo "  Could not mount. Unplug and replug the stick."; exit 1; }
echo "  mounted at: $MNT"

echo "=== 4/4  copying both profiles (about 22 GB) ==="
for p in android16-desktop android16-universal; do
    echo "-- $p"
    rsync -a --info=progress2 "$SRC/$p/" "$MNT/$p/"
done
sync

echo
echo "=== done ==="
df -h "$MNT" | tail -1 | awk '{print "   used", $3, "of", $2}'
ls -1 "$MNT"
echo
echo "On the other PC: copy a folder off the stick, then run"
echo "INSTALL-AND-RUN (.bat on Windows, .sh on Linux)."
