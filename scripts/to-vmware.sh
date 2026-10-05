#!/bin/bash
# Copy the EXACT state of the QEMU disks over to VMware.
#
# This is the whole point: VMware must not be a separate install with its own
# settings and its own apps. Both disks are converted, every time:
#
#   system.raw   -> system.vmdk    Android itself, plus the PERSIST partition
#                                  that holds grubenv - so the boot-menu
#                                  settings (900x1600 resolution, density,
#                                  A/B slot) travel with it. That is why the
#                                  UI looks identical.
#   userdata.raw -> userdata.vmdk  /data - the Play Store sign-in, Messenger,
#                                  WhatsApp, Instagram, Telegram, launcher
#                                  layout, every app installed later.
#
# Converting only system.vmdk was the earlier mistake: fixes made on the QEMU
# side were invisible to VMware, and VMware kept its own stale /data.
set -e
cd /home/student/Downloads/Android_16/vmware/Android16

if [ "$(ps -eo comm | grep -c "^qemu-system-x86")" != "0" ]; then
    echo "!! QEMU is still running - power Android off first, or the disks"
    echo "!! will be copied mid-write and VMware will see a corrupt /data."
    exit 1
fi

echo "=== system.raw -> system.vmdk ==="
rm -f system.vmdk
qemu-img convert -p -f raw -O vmdk -o subformat=monolithicSparse,adapter_type=lsilogic system.raw system.vmdk

echo "=== userdata.raw -> userdata.vmdk ==="
rm -f userdata.vmdk
qemu-img convert -p -f raw -O vmdk -o subformat=monolithicSparse,adapter_type=lsilogic userdata.raw userdata.vmdk

# NOTE: do NOT post-process these files. A monolithicSparse VMDK is a binary
# container with its text descriptor embedded inside it, so "sed -i" rewrites
# the file and changes the descriptor length. VMware then refuses to power on:
#   "The disk has one or more internal errors ... needs repair"
#   "Module 'Disk' power on failed."
# The adapter type is set during conversion instead, via -o adapter_type.

echo ""
echo "=== ready for VMware ==="
ls -lh system.vmdk userdata.vmdk | awk '{print "  ", $9, $5}'
echo ""
echo "In VMware: sata0:0 = system.vmdk, sata0:1 = userdata.vmdk (already in the .vmx)."
