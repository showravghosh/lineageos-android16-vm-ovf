#!/bin/bash
# Repair the VMware disks after a hard power-off.
#
# Symptom this fixes (VMware refuses to power on):
#   "The disk '...userdata.vmdk' has one or more internal errors that cannot
#    be fixed. Restore from a backup copy of this disk.
#    The specified virtual disk needs repair.  Module 'Disk' power on failed."
#
# Cause: a monolithicSparse VMDK grows on demand through a grain directory.
# Killing the VM mid-write (Power Off, closing the window, host crash) can
# leave that directory inconsistent. The filesystem INSIDE is journalled and
# fine - it is the VMDK container that breaks.
#
# Nothing is lost: the .raw disks are the source of truth and are rebuilt
# from, or - if the newest state only exists in VMware - vmware-vdiskmanager
# is asked to repair in place first.
set -e
cd /home/student/Downloads/Android_16/vmware/Android16

if [ "$(ps -eo comm | grep -c vmware-vmx)" != "0" ] || \
   [ "$(ps -eo comm | grep -c '^qemu-system-x86')" != "0" ]; then
    echo "!! Shut the VM down first."; exit 1
fi
rm -rf Android16.vmx.lck

echo "=== 1. asking VMware to repair the disks in place ==="
OK=1
for d in system.vmdk userdata.vmdk; do
    [ -f "$d" ] || continue
    if vmware-vdiskmanager -R "$d" 2>&1 | tee /tmp/vdm-$d.log | tail -2; then :; fi
    grep -qiE "success|no errors|repaired" /tmp/vdm-$d.log || OK=0
done

if [ "$OK" = "1" ]; then
    echo
    echo "=== repaired in place - your VMware state is kept ==="
else
    echo
    echo "=== in-place repair did not succeed - rebuilding from the raw disks ==="
    echo "    (this restores the last state that was converted with to-vmware.sh;"
    echo "     anything done ONLY inside VMware since then is not in the raws)"
    bash /home/student/Downloads/Android_16/to-vmware.sh
fi

echo
echo "=== integrity ==="
for d in system.vmdk userdata.vmdk; do
    printf "  %-16s %s\n" "$d" "$(qemu-img check "$d" 2>&1 | tail -1)"
done
echo
echo "Now press Play in VMware."
