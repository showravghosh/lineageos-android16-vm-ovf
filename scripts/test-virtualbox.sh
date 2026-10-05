#!/bin/bash
# Import the OVF into VirtualBox and set the two options it needs.
set -e
OVF=/home/student/Downloads/Android_16/export/android16-universal/android16-universal.ovf
VM="Android16-VBoxTest"

VBoxManage unregistervm "$VM" --delete 2>/dev/null || true

echo "=== importing (decompresses ~11 GB, takes a while) ==="
VBoxManage import "$OVF" --vsys 0 --vmname "$VM"

echo
echo "=== applying the settings this image needs ==="
# EFI: the image boots via GRUB from an EFI System Partition. With BIOS
# firmware there is nothing to boot.
VBoxManage modifyvm "$VM" --firmware efi
# VMSVGA is VirtualBox's VMware SVGA II implementation - the same device the
# vmwgfx driver in this kernel binds to. VBoxVGA/VBoxSVGA have no driver here
# and would give a black screen with SurfaceFlinger crash-looping.
VBoxManage modifyvm "$VM" --graphicscontroller vmsvga --vram 128
# e1000 - CONFIG_E1000=y is built in.
VBoxManage modifyvm "$VM" --nic1 nat --nictype1 82540EM
# USB tablet: absolute pointer, same reason as the VMware vUSB mouse.
VBoxManage modifyvm "$VM" --mouse usbtablet
VBoxManage modifyvm "$VM" --audio-driver none 2>/dev/null || true
VBoxManage modifyvm "$VM" --memory 4096 --cpus 2

echo
echo "=== settings ==="
VBoxManage showvminfo "$VM" | grep -iE "^Firmware|^Memory size|^Number of CPUs|Graphics Controller|^NIC 1|Pointing Device" | head -8
echo
echo "=== starting ==="
VBoxManage startvm "$VM" --type gui
