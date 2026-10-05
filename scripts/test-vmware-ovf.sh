#!/bin/bash
# Import the exported OVF into VMware as a SEPARATE VM and boot it.
# This tests the OVF package itself, not the VM it was made from.
set -e
OVF=/home/student/Downloads/Android_16/export/android16-desktop/android16-desktop.ovf
DEST=/home/student/Downloads/Android_16/ovf-import-test
VMX="$DEST/android16-universal/android16-universal.vmx"

rm -rf "$DEST"; mkdir -p "$DEST"

echo "=== importing the OVF into VMware (decompresses ~11 GB) ==="
ovftool --acceptAllEulas --overwrite "$OVF" "$DEST/android16-desktop.vmx" 2>&1 | grep -viE "AppLoader|libaio" | tail -4

VMX=$(find "$DEST" -name "*.vmx" | head -1)
echo
echo "=== imported as: $VMX ==="
grep -E "^(displayName|memsize|numvcpus|firmware|virtualHW.version)" "$VMX" | sed 's/^/   /'

echo
echo "=== starting it ==="
setsid vmware -x "$VMX" >/dev/null 2>&1 &
sleep 5
echo "vmx processes: $(ps -eo comm | grep -c vmware-vmx)"
