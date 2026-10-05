#!/bin/bash
mkdir -p /tmp/android16
cd /home/student/Downloads/Android_16/vmware/Android16
cp -f /usr/share/OVMF/OVMF_VARS_4M.fd ./ovmf_vars.fd
rm -f /tmp/android16/qemu-mon.sock
echo "==============================================="
echo "  Android 16 installer - QEMU"
echo "  disk1: system.raw   (16 GB)"
echo "  disk2: userdata.raw (128 GB)"
echo "  disk3: installer"
echo "  driven through the QEMU monitor socket."
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
  -monitor unix:/tmp/android16/qemu-mon.sock,server,nowait
