#!/bin/bash
mkdir -p /tmp/android16
# Turn the development VM into something fit to hand to someone else.
# Run with BOTH VMs powered off, AFTER from-vmware.sh.
set -e
DIR=/home/student/Downloads/Android_16
VMDIR=$DIR/vmware/Android16
cd "$VMDIR"

if [ "$(ps -eo comm | grep -c vmware-vmx)" != "0" ] || \
   [ "$(ps -eo comm | grep -c '^qemu-system-x86')" != "0" ]; then
    echo "!! Shut the VMs down first."; exit 1
fi

echo "=== 1/3  boot settings (grubenv on the PERSIST partition) ==="
dd if=system.raw bs=512 skip=25432064 count=32768 status=none of=/tmp/android16/persist.img
cd /tmp/android16
mcopy -i persist.img ::grubenv ./ge -o
# Serial logcat was a debugging aid - it writes continuously. Off for release.
grub-editenv ./ge set serial_console_function=disable
# 10 seconds of boot menu is a long wait for a user who just wants Android.
grub-editenv ./ge set grub_timeout=3
grub-editenv ./ge set kms_display_resolution=480x854
grub-editenv ./ge set android_lcd_density=213
mcopy -i persist.img -o ./ge ::grubenv
cd "$VMDIR"
dd if=/tmp/android16/persist.img of=system.raw bs=512 seek=25432064 count=32768 conv=notrunc status=none
echo "   grubenv:"; grep -E "serial_console|grub_timeout|kms_display|lcd_density" /tmp/android16/ge | sed 's/^/     /'

echo
echo "=== 2/3  rebuilding the VMware disks from the raw disks ==="
bash "$DIR/to-vmware.sh" 2>&1 | grep -vE "\([0-9.]+/100%\)" | tail -4

echo
echo "=== 3/3  rewriting the disks with VMware's own tool ==="
echo "    (qemu-img writes valid but minimal sparse metadata; VMware's own"
echo "     writer is what VMware expects, and survives a hard power-off"
echo "     better - that is what broke userdata.vmdk overnight)"
for d in system.vmdk userdata.vmdk; do
    vmware-vdiskmanager -r "$d" -t 0 "native_$d" >/dev/null 2>&1 && mv -f "native_$d" "$d" \
        && echo "     $d rewritten" || echo "     $d: vdiskmanager declined, keeping qemu-img version"
done

echo
echo "=== integrity ==="
for d in system.vmdk userdata.vmdk; do
    printf "  %-16s %s\n" "$d" "$(qemu-img check "$d" 2>&1 | tail -1)"
done
