# Android 16 (LineageOS 23.2) for x86_64 virtual machines

A LineageOS 23.2 / Android 16 build that runs in **VMware Workstation**,
**VirtualBox** and **QEMU** from one image, with Google Play Store, Google
services and ARM app translation.

Built from the LineageOS `virtio_x86_64` target, which targets QEMU only
upstream. The changes in `patches/` are what make the same image work under
VMware and VirtualBox as well.

> This repository is the **OVF version**. The same virtual machine is also available as the **OVA version** (one single `.ova` file per machine): <https://github.com/showravghosh/lineageos-android16-vm-ova>

## 1. Which version?

| Release | Memory / CPU | Choose it if |
|---|---|---|
| [**v1.1-universal**](https://github.com/showravghosh/lineageos-android16-vm-ovf/releases/tag/v1.1-universal) | 6 GB / 4 cores | most PCs — **start here** |
| [**v1.1-desktop**](https://github.com/showravghosh/lineageos-android16-vm-ovf/releases/tag/v1.1-desktop) | 12 GB / 8 cores | your PC has 16 GB RAM or more |

**New in v1.1:** sound works in VMware, VirtualBox and QEMU · no error text on
screen while starting · touch sounds off.

## 2. What you need

- A 64-bit **Intel or AMD** PC (Windows, Linux or an Intel Mac — **not** Apple Silicon M1–M4)
- **8 GB RAM** or more for *universal*, **16 GB** or more for *desktop*
- About **40 GB** free disk space (download + installed machine)
- One of these free programs:
  - **VMware Workstation** — 16.2 or newer for *universal*, 17.5 or newer for *desktop*
  - **Oracle VirtualBox** — 7.0 or newer
- **Virtualization switched on** in the BIOS/UEFI (Intel VT-x / AMD-V). Most PCs have it on.
- **Windows only:** Hyper-V off. If VMware/VirtualBox complains, open Command
  Prompt as Administrator, run `bcdedit /set hypervisorlaunchtype off` and restart.

## 3. Download

Open the release you chose and download **every file** listed under *Assets*
into **one empty folder** (about 13 GB, 17 files). The two big disk files are
split into `.part000`, `.part001`, … because GitHub accepts at most 2 GB per
file — they are joined again automatically in the next step.

## 4. Install

**Easiest — one click:**
- **Windows:** double-click `INSTALL-AND-RUN.bat`
- **Linux / Mac:** open a terminal in the folder and run `bash INSTALL-AND-RUN.sh`

It joins the parts, checks every file is undamaged, finds VirtualBox or VMware,
imports the machine with the right settings and starts it.

**Or by hand** (run `rejoin.sh`, or follow `JOIN-PARTS.txt` on Windows, first):
- **VMware:** *File → Open…* → `android16-xxx.ovf` → *Import* → *Power on*
- **VirtualBox:** *File → Import Appliance…* → `android16-xxx.ovf` → *Import*,
  then **before starting** set *System → Enable EFI*, *Display → Graphics
  Controller: VMSVGA* and *Audio → Audio Controller: ICH AC97* → *Start*

> Prefer a single file with no settings at all? Use the **OVA version**: <https://github.com/showravghosh/lineageos-android16-vm-ova>

## 5. First start

1. A boot menu appears and starts **LineageOS 23.2** by itself after 3 seconds
   (if the countdown has stopped, press **Enter**).
2. A few grey "Loading…" lines, a black screen, then the LineageOS animation.
3. The lock screen — drag upwards with the mouse to unlock.

The first start takes about **1 minute** (up to 3 on slower PCs).
Use the mouse like a finger: click = tap, click-and-drag = swipe.
To get the mouse back to your PC: **Ctrl + Alt** (VMware) or **right Ctrl** (VirtualBox).

## 6. Using Android

- **Google Play Store:** open it, sign in with your Google account, install apps
  as on a phone. Messenger is already installed.
- **Internet:** works automatically through your PC's connection.
- **Volume:** a VM has no volume buttons, so no volume slider pops up during a
  video. Use your PC's own volume, *Settings → Sound & vibration → Media volume*,
  or the on-screen *Accessibility Menu* button (*Settings → Accessibility →
  Accessibility Menu*), which has Volume up / down, Screenshot and Power.
- **No calls or SMS:** there is no SIM card. Apps that need a phone number send
  the code to your real phone.

## 7. Shutting down

Shut Android down like a phone: Accessibility Menu → **Power → Power off**, or
**VM → Power → Shut Down Guest** (VMware) / **Machine → ACPI Shutdown** (VirtualBox).
Do **not** use "Power Off" or close the window while it runs — that is like
pulling the battery and can damage the virtual disk. Apps and data are kept
between starts.

## 8. Problems and fixes

| Problem | Fix |
|---|---|
| "VT-x is not available" / virtualization disabled | Enable it in the BIOS; on Windows switch Hyper-V off (section 2) |
| Stays at the boot menu | Press **Enter** |
| Black screen on first start | Wait up to 3 minutes |
| No sound | Check your PC's own sound/volume first. VirtualBox: sound card must be **ICH AC97** |
| Import fails / "error on read" | A part or file is damaged or missing — download it again and check it |
| PC has only 8 GB RAM | Before the first start set the VM's memory to 4096 MB |

`README.txt` in the download is the full manual with every detail.

---

# For developers

## What is in this repository

```
patches/     the device-tree changes that make the image work
scripts/     build, install, disk conversion and export scripts
docs/        BUILD-NOTES.md - why each change is needed
Android16.vmx   the VMware configuration used
```

## The changes that matter

**`/data` is found by partition name, never a device path.** The userdata
disk is `vdb` under QEMU and `sdb` under VMware, so a fixed path can only
be right in one of them. `androidboot.partition_map` gives the disk the
name `userdata` on both, and fstab asks for
`/dev/block/by-name/userdata`.

**VMware and VirtualBox drivers** (`patches/vmware.config`): `vmwgfx`,
`e1000`, sound (`ens1371`, HD Audio, AC97), VMCI. The upstream target has none of them, because
QEMU provides everything over virtio. Note that `MOUSE_PS2_VMMOUSE` is
deliberately left out — see the comments in that file.

**Sound** (`patches/setup_sound_card.cpp`): ALSA brings every sound card
up muted at volume 0. The boot service that un-mutes it only knew a few
cards, so for example QEMU's AC97 card stayed muted. It now
switches on the output controls (Master, PCM, Front, Headphone, ...) of
any card, never inputs. The VMware configuration uses the HD Audio card:
the older ES1371 card stops after Android pauses playback.

**Quiet boot** (`patches/grub-boot.cfg`): with the boot menu's quiet
option the kernel gets `quiet loglevel=0`, so no kernel or error text is
printed on screen; everything is still recorded in the kernel log.

**`androidboot.graphics=mesa_swrast`** selects the software EGL driver.
Without it `ro.hardware.egl` is never set under VMware — the usual
mechanism probes for virtio-gpu, which VMware does not have — and
SurfaceFlinger aborts in a loop.

**A gralloc backend for vmwgfx** in minigbm, which otherwise has no entry
for that DRM driver.

`docs/BUILD-NOTES.md` explains each of these in full, along with the
traps worth knowing before changing anything.

## Building it yourself

Follow the LineageOS wiki for `virtio_x86_64`
(<https://wiki.lineageos.org/libvirt-qemu>), apply the files in
`patches/` over `device/virt/`, then use `scripts/rebuild.sh`.

## Licence

LineageOS and AOSP are licensed under the Apache License 2.0.
Google applications included in the virtual machine images are
redistributed under their own terms and are not covered by this
repository's licence.
