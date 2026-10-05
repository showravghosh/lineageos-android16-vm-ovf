#!/bin/bash
# Build the GitHub upload folder: export/Github_Push
#
# The two exported OVF folders are COPIED into it and the COPIES are split.
# The originals in export/android16-desktop and export/android16-universal are
# left whole and stay usable for importing locally.
set -e
SRC=/home/student/Downloads/Android_16
DEST=/home/student/Downloads/Android_16/export/Github_Push
PARTMB=1900           # GitHub allows 2 GB per release asset; stay under it

rm -rf "$DEST"
mkdir -p "$DEST/release" "$DEST/repo/scripts" "$DEST/repo/patches" "$DEST/repo/docs"

echo "=== copying the exports (originals untouched) ==="
for n in android16-desktop android16-universal; do
    [ -d "$SRC/export/$n" ] || continue
    cp -r "$SRC/export/$n" "$DEST/release/$n"
    echo "   copied $n"
done

echo
echo "=== splitting the disk files into parts under ${PARTMB}MB ==="
for n in android16-desktop android16-universal; do
    D="$DEST/release/$n"
    [ -d "$D" ] || continue
    echo "-- $n"
    for f in "$D"/*.vmdk.gz; do
        [ -f "$f" ] || continue
        B=$(basename "$f")
        split -b ${PARTMB}M -d -a 3 "$f" "$f.part"
        rm -f "$f"
        echo "     $B -> $(ls "$D/$B".part* | wc -l) parts"
    done
done

echo
echo "=== collecting the project files for the repo ==="
cp -f "$SRC"/*.sh "$DEST/repo/scripts/" 2>/dev/null || true
cp -f "$SRC/tools"/*.sh "$SRC/tools"/*.py "$SRC/tools"/*.c "$DEST/repo/scripts/" 2>/dev/null || true
cp -f "$SRC/vmware/Android16"/run-*.sh "$DEST/repo/scripts/" 2>/dev/null || true
cp -f "$SRC/vmware/Android16/Android16.vmx" "$DEST/repo/" 2>/dev/null || true
# the device-tree changes that make this work
L="$SRC/lineage/device/virt"
cp -f "$L/virtio_x86_64/configs/kernel/vmware.config"              "$DEST/repo/patches/" 2>/dev/null || true
cp -f "$L/virtio_x86_64/BoardConfig.mk"                            "$DEST/repo/patches/" 2>/dev/null || true
cp -f "$L/virtio-common/BoardConfigCommon.mk"                      "$DEST/repo/patches/" 2>/dev/null || true
cp -f "$L/virtio-common/configs/fstab/fstab.virtio-common"         "$DEST/repo/patches/" 2>/dev/null || true
cp -f "$L/virtio-common/sepolicy/vendor/file_contexts"             "$DEST/repo/patches/" 2>/dev/null || true
cp -f "$SRC/RESUME_TOMORROW.md"                                    "$DEST/repo/docs/BUILD-NOTES.md" 2>/dev/null || true

echo
echo "=== done ==="
du -sh "$DEST/release" "$DEST/repo" 2>/dev/null | sed 's/^/   /'
echo
echo "   upload folder:  $DEST"
echo "   originals kept whole: $SRC/export/android16-desktop"
echo "                         $SRC/export/android16-universal"
