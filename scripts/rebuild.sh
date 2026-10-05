#!/bin/bash
cd /home/student/Downloads/Android_16/lineage
rm -f out/error.log
echo "==============================================="
echo "  Rebuild - making VMware a first-class target"
echo ""
echo "  1. /data by NAME:  /dev/block/by-name/userdata"
echo "     (vdb in QEMU, sdb in VMware - one record now)"
echo "  2. SELinux:        sda2/sda3/sdb1 labelled"
echo "  3. KERNEL:         VMware drivers added -"
echo "        vmwgfx (display), e1000e/vmxnet3 (network),"
echo "        ens1371 (sound), vmmouse (pointer)"
echo "     None of these were compiled in before, so"
echo "     VMware had disks and nothing else."
echo "  4. minigbm:        vmwgfx gralloc backend"
echo "==============================================="
echo ""
# Keep ccache OUT of the compile command lines. The cache here is empty (0.1%
# hit rate), so it saves nothing - but ninja compares command lines, so adding
# the "/usr/bin/ccache" prefix makes all ~124k targets look stale and forces a
# 2-hour full rebuild. Without it the command lines match what is already in
# out/.ninja_log and only the changed targets are rebuilt.
unset USE_CCACHE CCACHE_EXEC

source build/envsetup.sh
breakfast virtio_x86_64
echo ""
m -j20 espimage-install
RC=$?
echo ""
echo "=== verify VMware kernel drivers ==="
K=out/target/product/virtio_x86_64/obj/KERNEL_OBJ/.config
for c in DRM_VMWGFX E1000E VMXNET3 SND_ENS1371 MOUSE_PS2_VMMOUSE VMWARE_VMCI; do
  printf "  %-20s %s\n" "$c" "$(grep -E "^CONFIG_$c=" $K || echo '*** MISSING ***')"
done
echo ""
echo "=== verify built fstab ==="
find out/target/product/virtio_x86_64 -name "fstab.virtio-common" 2>/dev/null | head -3 | \
  while read f; do echo "--- $f"; grep -v '^#' "$f" | grep -E "data|sdcard"; done
echo ""
echo "==============================================="
if [ $RC -eq 0 ]; then echo "   BUILD SUCCEEDED"; else echo "   BUILD FAILED (rc=$RC)"; fi
echo "==============================================="
