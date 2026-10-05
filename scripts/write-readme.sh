#!/bin/bash
# Write the end-user instructions into each export folder.
# Kept separate because export-ovf.sh wipes the folder before writing, so the
# README has to go back afterwards - easy to forget by hand.
OUT=/home/student/Downloads/Android_16/export
for n in android16-desktop android16-universal; do
  [ -d "$OUT/$n" ] || continue
  if [ "$n" = "android16-desktop" ]; then
      MEM="12 GB RAM / 8 CPU cores"
      COMPAT="VMware Workstation 17.5 or newer"
  else
      MEM="4 GB RAM / 2 CPU cores"
      COMPAT="older VMware versions, Player and ESXi as well"
  fi
cat > "$OUT/$n/README.txt" <<INNER
Android 16 (LineageOS 23.2) - virtual machine
=============================================

$MEM
Google Play Store and Google services included.
ARM app translation included, so ARM-only apps run too.


CHECK THE COPY FIRST
--------------------
After copying this folder from a USB drive or over a network, run:

    bash verify.sh

Every line should say OK. Large files can be damaged in transit with
no error shown, and a damaged disk shows up later as a confusing
import failure. This takes a few seconds and rules that out.


WHAT TO COPY
------------
Copy this ENTIRE FOLDER. All of these files are needed:

  $n.ovf              the description of the machine (small text file)
  $n-disk1.vmdk.gz    Android itself
  $n-disk2.vmdk.gz    apps and data
  $n.mf               checksums, used to detect a damaged copy
  verify.sh           checks the files against those checksums

Opening the .ovf on its own will not work - it only points at the disk
files, which must sit beside it in the same folder.


VMWARE WORKSTATION / PLAYER
---------------------------
  File -> Open...  ->  select  $n.ovf
  Choose where to store it, wait for the import, then press Play.
  Nothing else to change. Requires $COMPAT.


ORACLE VIRTUALBOX
-----------------
  File -> Import Appliance...  ->  select  $n.ovf  ->  Import

  Then, BEFORE starting it, change these settings (the first two are
  needed to boot, the third gives sound):

    Settings -> System -> Motherboard  ->  tick "Enable EFI"
    Settings -> Display -> Screen      ->  Graphics Controller: VMSVGA
    Settings -> Audio                  ->  Audio Controller: ICH AC97

  Recommended as well:
    Settings -> Display -> Video Memory: 128 MB
    Settings -> Input/Motherboard -> Pointing Device: USB Tablet


USING IT
--------
The window is small at first - that is the bootloader. It becomes a
phone screen once Android starts. First boot takes a few minutes.

To install apps: open Play Store and sign in with a Google account.

Messenger: install it from APKMirror, choosing an x86_64 build. The
Play Store version is built for ARM phones only and will close itself
on this machine.


SHUTTING DOWN - PLEASE READ
---------------------------
Shut Android down from inside it (power menu -> Power off), or use
  VMware:     VM -> Power -> Shut Down Guest
  VirtualBox: Machine -> ACPI Shutdown

Avoid "Power Off" or closing the window while it runs. That is the
equivalent of pulling the plug and can damage the virtual disk, after
which the machine refuses to start.


SOUND
-----
Sound works in VMware, VirtualBox and QEMU.
  VMware:     HD Audio sound card (set by the .ovf - nothing to do).
  VirtualBox: needs the ICH AC97 sound card. INSTALL-AND-RUN sets it
              automatically. After importing by hand, set
              Settings -> Audio -> Audio Controller: ICH AC97
              (VirtualBox's HD Audio cannot play at 48 kHz, so it stays
              silent).

A virtual machine has no volume buttons, so Android shows no volume
slider while a video plays. To change the volume:
  - the speaker icon of your own computer (controls everything), or
  - Settings -> Sound & vibration -> Media volume, or
  - Settings -> Accessibility -> Accessibility Menu -> turn on; its
    on-screen button gives Volume up / Volume down.
If there is no sound at all, check your computer's own output and that
the VM's sound card is connected (VMware: VM -> Settings -> Sound Card).
INNER
  echo "  README.txt -> $n/"
done
