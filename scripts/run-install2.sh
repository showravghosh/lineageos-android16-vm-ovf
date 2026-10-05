#!/bin/bash
mkdir -p /tmp/android16
# Install run WITH serial logging from the start, so a crash-loop is
# visible within a minute instead of after twenty.
cd /home/student/Downloads/Android_16/vmware/Android16
cp -f /usr/share/OVMF/OVMF_VARS_4M.fd ./ovmf_vars.fd
rm -f /tmp/android16/qemu-mon.sock serial.log
echo "==============================================="
echo "  Android 16 + Google Play + ARM translation"
echo "  12 GB RAM / 8 vCPU / 128 GB storage"
echo "  serial -> serial.log"
echo "==============================================="
exec qemu-system-x86_64 \
  -machine q35,accel=kvm -cpu host -smp 8 -m 12288 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,file=ovmf_vars.fd \
  -drive file=system.raw,format=raw,if=none,id=d0 -device virtio-blk-pci,drive=d0 \
  -drive file=userdata.raw,format=raw,if=none,id=d1 -device virtio-blk-pci,drive=d1 \
  -drive file=installer_gpt.raw,format=raw,if=none,id=d2 -device virtio-blk-pci,drive=d2 \
  -vga virtio -usb -device usb-tablet -device usb-kbd \
  -netdev user,id=n0,hostfwd=tcp::5555-:5555 -device virtio-net-pci,netdev=n0 \
  -serial file:serial.log \
  -monitor unix:/tmp/android16/qemu-mon.sock,server,nowait
