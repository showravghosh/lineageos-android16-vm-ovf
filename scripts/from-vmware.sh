#!/bin/bash
# Pull VMware's disks BACK into the QEMU raw disks (vmdk -> raw).
#
# The counterpart to to-vmware.sh. Use it when work was done inside VMware -
# Play Store sign-in, apps installed - and that state needs to reach the QEMU
# side, or needs to survive a rebuild (which reinstalls onto the raw disks).
#
# Without this the conversion is one-way and anything done in VMware is lost
# the next time to-vmware.sh runs.
set -e
cd /home/student/Downloads/Android_16/vmware/Android16

if [ "$(ps -eo comm | grep -c '^qemu-system-x86')" != "0" ] || \
   [ "$(ps -eo comm | grep -c vmware-vmx)" != "0" ]; then
    echo "!! A VM is still running. Shut it down first, or the disks will be"
    echo "!! copied mid-write and come out corrupt."
    exit 1
fi

echo "=== system.vmdk -> system.raw ==="
qemu-img convert -p -f vmdk -O raw system.vmdk system.raw.new
mv -f system.raw.new system.raw

echo "=== userdata.vmdk -> userdata.raw ==="
qemu-img convert -p -f vmdk -O raw userdata.vmdk userdata.raw.new
mv -f userdata.raw.new userdata.raw

echo
echo "=== QEMU disks now match VMware ==="
ls -lh system.raw userdata.raw | awk '{print "  ", $9, $5}'
