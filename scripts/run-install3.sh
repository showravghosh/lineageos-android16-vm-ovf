#!/bin/bash
mkdir -p /tmp/android16
# Install run with installer disk AND the VirtIO logcat console attached,
# so any crash is diagnosable immediately (see wiki "Text consoles").
cd /home/student/Downloads/Android_16/vmware/Android16
cp -f /usr/share/OVMF/OVMF_VARS_4M.fd ./ovmf_vars.fd
rm -f /tmp/android16/qemu-mon.sock serial.log logcat.log
echo "==============================================="
echo "  Android 16 + Google Play + ARM translation"
echo "  GSF privapp whitelist fix applied"
echo "  12 GB RAM / 8 vCPU / 128 GB"
echo "  serial.log = kernel   logcat.log = logcat"
echo "==============================================="
exec qemu-system-x86_64 \
  -machine q35,accel=kvm,vmport=off -cpu host -smp 8 -m 12288 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,file=ovmf_vars.fd \
  -drive file=system.raw,format=raw,if=virtio \
  -drive file=userdata.raw,format=raw,if=virtio \
  -device ahci,id=ahci \
  -drive file=installer_gpt.raw,format=raw,if=none,id=inst -device ide-hd,drive=inst,bus=ahci.0 \
  -vga virtio -usb -device usb-tablet -device usb-kbd \
  -netdev user,id=n0,hostfwd=tcp::5555-:5555 -device virtio-net-pci,netdev=n0 \
  -serial file:serial.log \
  -device virtio-serial-pci,id=vser0 \
  -chardev socket,id=vc0,path=/tmp/android16/shell.sock,server=on,wait=off \
  -device virtconsole,chardev=vc0,bus=vser0.0 \
  -chardev file,id=vc1,path=logcat.log \
  -device virtconsole,chardev=vc1,bus=vser0.0 \
  -monitor unix:/tmp/android16/qemu-mon.sock,server,nowait
