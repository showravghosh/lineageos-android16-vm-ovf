# Android 16 / LineageOS 23.2 — state at end of 2026-09-21

## WORKING IN BOTH QEMU AND VMWARE WORKSTATION PRO

Verified on screen in both hypervisors from the SAME image:

| | QEMU | VMware |
|---|---|---|
| Boots to home screen | yes | yes |
| /data mounts + persists | yes (vdb) | yes (sdb) |
| Display | virtio-vga | vmwgfx |
| Network | virtio-net | e1000 |
| Mouse / cursor | virtio-tablet | USB HID (mouse.vusb) |
| Screen 480x854, 9:16 | yes | yes |
| App labels not clipped | yes | yes |
| Play Store present | yes | yes |

## NEXT STEP — THE USER'S PART (not yet done)

Install the apps in EITHER hypervisor - both work. What matters is which
disks the work lands on, and syncing before any conversion:

  QEMU   -> system.raw  / userdata.raw
  VMware -> system.vmdk / userdata.vmdk

  to-vmware.sh    raw  -> vmdk   (overwrites the vmdk)
  from-vmware.sh  vmdk -> raw    (overwrites the raw)

Installing in VMware is the natural choice: the OVF is exported from the
VMware VM, so apps in the vmdk go straight into it, no conversion needed.
The ONLY risk is a later image fix, which rebuilds and reinstalls onto the
RAW disks - run from-vmware.sh FIRST in that case, or the apps are lost.

1. Power on VMware and install there (recommended), or start QEMU with:
     bash /home/student/Downloads/Android_16/vmware/Android16/run-final.sh
   Never run both at once - they are separate disks and would diverge.
2. Open Play Store, sign in with the Google account.
3. Install WhatsApp, Instagram, Telegram from Play Store.
4. Messenger: do NOT use the Play Store build (ARM-only, crashes under
   translation). Sideload the x86_64 APK from APKMirror — v553.0.0.60.55
   is the version that was confirmed working.

## THEN — MY PART

5. Power off VMware, then: bash to-vmware.sh   (converts BOTH disks; apps
   live in /data on userdata.raw, so they only reach VMware via this)
6. Export the two OVFs:
     - user profile:  12 GB RAM / 8 vCPU
     - universal:     4 GB RAM / 2 vCPU
   hardware version 19, ovftool --compress=9, produce .ovf and .ova
7. Test-import one OVF and boot it.

## HOW IT ALL HANGS TOGETHER (do not "simplify" these)

- /data is found by NAME, never by device path:
    fstab            -> /dev/block/by-name/userdata
    bootconfig       -> androidboot.partition_map="vdb,userdata"   (QEMU)
    kernel cmdline   -> androidboot.partition_map=sdb,userdata     (VMware)
  ueventd parses BOTH /proc/cmdline and /proc/bootconfig and appends each,
  which is why the two mappings can live in separate places. They CANNOT be
  combined as "vdb,userdata;sdb,userdata": the ';' breaks the build (shell
  splits it) and escaping it as '\;' is invalid JSON in soong.variables.

- device/virt/virtio_x86_64/configs/kernel/vmware.config adds the VMware
  drivers (vmwgfx, e1000, vmxnet3, ens1371, VMCI). It deliberately does NOT
  enable CONFIG_MOUSE_PS2_VMMOUSE — see the comment in that file. vmmouse
  binds the VMware backdoor port, which QEMU ALSO emulates, and then hijacks
  the pointer. Enabling it broke the cursor in BOTH hypervisors at once.

- androidboot.graphics=mesa_swrast on the kernel cmdline is what sets
  ro.hardware.egl. Without it VMware has no GL implementation at all and
  SurfaceFlinger aborts in a loop (virtgpu_detect only fires for virtio-gpu).

- Screen/density live in grubenv on the PERSIST partition of system.raw:
    kms_display_resolution=480x854   -> virtio_gpu.force_resolution AND
                                        vmwgfx.force_resolution
    android_lcd_density=213          -> 361dp x 642dp, the standard phone
                                        layout; at 240 the labels clip
  Edit with: dd the partition out (offset 25432064, 32768 sectors), mcopy
  grubenv out, grub-editenv, mcopy back, dd back. VM must be OFF.
  480x854 was chosen because the host is 1920x1080 and VMware's chrome
  leaves only ~900px — a 1280-tall guest put the nav bar off-screen.

## TRAPS ALREADY HIT — DO NOT REPEAT

- adb sideload parks at ~47% and does NOT exit. Killing it makes recovery
  mark the install FAILED, which forces androidboot.mode=recovery and the
  system never boots. Let adb finish on its own.
- Never sed a monolithicSparse .vmdk — the descriptor is inside the binary
  and sed corrupts it ("disk needs repair"). Set adapter_type at convert time.
- Convert BOTH disks every time. system.vmdk alone leaves VMware with a
  stale /data.
- "BUILD SUCCEEDED" is not proof. A failed build left a truncated
  vendor-bootconfig.img that ninja then considered current. Verify the
  ARTIFACT (strings vendor_boot.img | grep androidboot).
- Do not let ccache into the compile commands (USE_CCACHE in ~/.bashrc):
  it changes every command line and forces a ~2h full rebuild for nothing.
  rebuild.sh unsets it.
- Run work in the user's own Ptyxis window (setsid ptyxis --new-window),
  not a hidden background shell.

## v1.1 (4 Oct) - sound and quiet boot

- `setup_sound_card.cpp`: cards it does not know (QEMU AC97/STAC9700,
  VirtualBox HDA) were left muted. It now enables the playback switch and
  volume of every output stage (Master, PCM, Front, Headphone, Speaker,
  Surround, Center, LFE, Side, Line Out) and never touches inputs.
- Installed as an OTA over existing data (Apply update -> Apply from ADB),
  no factory reset - /metadata keeps the encryption key.
- VMware: `sound.virtualDev = "hdaudio"`. ES1371 plays once, then never
  resumes after Android closes the PCM (3 s standby).
- VirtualBox: HD Audio is limited to 16/22.05/44.1 kHz; Android opens the
  primary output at 48 kHz -> "cannot set hw params". Use ICH AC97
  (AD1980); INSTALL-AND-RUN sets it.
- QEMU: `-audiodev pipewire,id=snd0 -device AC97,audiodev=snd0`.
- Quiet boot: `grub-boot.cfg` adds `quiet loglevel=0`; grubenv `quiet=1`.
  GRUB's own progress lines stay; nothing is lost from the kernel log.
- Do not turn off the master "Use developer options" switch to disable
  debugging - it resets every developer setting (cursor disappeared).
  Turn off only "USB debugging".

