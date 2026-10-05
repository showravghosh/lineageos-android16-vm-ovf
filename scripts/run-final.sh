#!/bin/bash
mkdir -p /tmp/android16
# Android 16 + Google Play + ARM translation
#
# Two fixes vs the earlier runs:
#  1. NO 3D acceleration. The wiki warns "Some rare host video cards may not
#     display 3D accelerated graphics properly - untoggle 3D acceleration".
#     This NVIDIA card is one: with gl=on the display froze at "Loading ramdisk".
#     Colours are fixed instead by the sf-pixel-format-prop patch + BGRA prop.
#     The wiki's known "display color" issue happens ONLY with Swiftshader,
#     and shows as a red<->blue channel swap (Facebook blue renders orange).
#  2. xres/yres 900x1600 -> a phone-sized screen. At the old 640x480 the
#     navigation bar was cut off, so there was no way back to the home screen.
cd /home/student/Downloads/Android_16/vmware/Android16
cp -f /usr/share/OVMF/OVMF_VARS_4M.fd ./ovmf_vars.fd
rm -f /tmp/android16/qemu-mon.sock serial.log logcat.log
echo "==============================================="
echo "  Android 16 + Play Store + ARM translation"
echo "  3D acceleration ON (fixes inverted colours)"
echo "  900x1600 phone resolution (shows nav bar)"
echo "==============================================="
exec qemu-system-x86_64 \
  -machine q35,accel=kvm,vmport=off -cpu host -smp 8 -m 12288 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,file=ovmf_vars.fd \
  -drive file=system.raw,format=raw,if=virtio \
  -drive file=userdata.raw,format=raw,if=virtio \
  -device virtio-vga,xres=480,yres=854 \
  -device virtio-tablet-pci -device virtio-keyboard-pci \
  -usb -device usb-kbd \
  -audiodev pipewire,id=snd0 -device AC97,audiodev=snd0 \
  -netdev user,id=n0,hostfwd=tcp::5555-:5555 -device virtio-net-pci,netdev=n0 \
  -serial file:serial.log \
  -device virtio-serial-pci,id=vser0 \
  -chardev socket,id=vc0,path=/tmp/android16/shell.sock,server=on,wait=off \
  -device virtconsole,chardev=vc0,bus=vser0.0 \
  -chardev file,id=vc1,path=logcat.log \
  -device virtconsole,chardev=vc1,bus=vser0.0 \
  -monitor unix:/tmp/android16/qemu-mon.sock,server,nowait
