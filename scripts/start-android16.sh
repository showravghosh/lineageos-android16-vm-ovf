#!/bin/bash
# One-click start for Android 16 in VMware.
#
# Does the housekeeping a user should never have to think about:
#   - refuses to start a second copy
#   - clears a stale lock left by a crash
#   - checks the disks and repairs them if a hard power-off broke them
#   - then powers on the VM
DIR=/home/student/Downloads/Android_16
VMDIR=$DIR/vmware/Android16
cd "$VMDIR"

echo "==============================================="
echo "   Android 16  (LineageOS 23.2)"
echo "==============================================="

if [ "$(ps -eo comm | grep -c vmware-vmx)" != "0" ]; then
    echo "It is already running - bringing the window to the front."
    vmware -x "$VMDIR/Android16.vmx" >/dev/null 2>&1 &
    exit 0
fi
if [ "$(ps -eo comm | grep -c '^qemu-system-x86')" != "0" ]; then
    echo "The QEMU copy is running. Close it first - running both at once"
    echo "makes two different systems that drift apart."
    exit 1
fi

# A lock directory left behind by a crash stops the VM powering on.
rm -rf "$VMDIR/Android16.vmx.lck"

echo -n "Checking disks... "
BAD=0
for d in system.vmdk userdata.vmdk; do
    qemu-img check "$d" >/dev/null 2>&1 || BAD=1
done

if [ "$BAD" = "1" ]; then
    echo "damaged."
    echo
    echo "The last shutdown was not clean, so a disk needs repairing."
    echo "Doing that now - nothing is lost, this takes a few minutes."
    echo
    bash "$DIR/fix-vmware-disk.sh"
    echo
else
    echo "ok."
fi

echo "Starting..."
vmware -x "$VMDIR/Android16.vmx" >/dev/null 2>&1 &
sleep 3
echo
echo "The window is opening. It looks small at first - that is the"
echo "bootloader; it becomes a phone screen once Android starts."
echo
echo "When finished, shut it down from inside Android (power menu ->"
echo "Power off), or VM -> Power -> Shut Down Guest. Avoid 'Power Off',"
echo "which is a hard kill and is what damages the disk."
