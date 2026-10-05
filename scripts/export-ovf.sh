#!/bin/bash
# Export the VM as OVF/OVA, in two profiles.
#
#  android16-desktop   12 GB / 8 vCPU  - matches this machine, what was asked for
#  android16-universal  4 GB / 2 vCPU  - imports on modest hosts, and at a lower
#                                        hardware version so older Workstation,
#                                        Player and ESXi accept it
set -e
DIR=/home/student/Downloads/Android_16
VMDIR=$DIR/vmware/Android16
OUT=$DIR/export
SRC=$DIR
mkdir -p "$DIR/.exportwork"
cd "$VMDIR"

if [ "$(ps -eo comm | grep -c vmware-vmx)" != "0" ]; then
    echo "!! VMware is running - shut it down first."; exit 1
fi
rm -rf "$VMDIR/Android16.vmx.lck"

build() {
    NAME=$1; MEM=$2; CPU=$3; HW=$4
    echo
    echo "==============================================="
    echo "  $NAME   ${MEM}MB RAM / ${CPU} vCPU / hw v$HW"
    echo "==============================================="
    # Work on the same disk as the project, NOT in /tmp. /tmp here is a
    # 31 GB RAM-backed tmpfs, and each profile copies ~15 GB of disk images
    # into the work directory - which silently filled RAM and killed the
    # export with "Disk quota exceeded".
    WORK=$(mktemp -d -p "$SRC/.exportwork")
    cp -f "$VMDIR"/*.vmdk "$WORK"/ 2>/dev/null
    rm -f "$WORK/installer.vmdk"
    # cpuid.coresPerSocket must be dropped, not inherited: the source VM has 8,
    # and a profile with 2 vCPUs would then claim 8 cores per socket. ovftool
    # only accepts that with --lax and warns
    #   "Unsupported value '8' for element 'CoresPerSocket'"
    # while a stricter importer (ESXi) can reject the appliance outright.
    grep -vE '^(memsize|numvcpus|virtualHW.version|displayName|annotation|cpuid.coresPerSocket)' Android16.vmx > "$WORK/$NAME.vmx"
    {
        echo "memsize = \"$MEM\""
        echo "numvcpus = \"$CPU\""
        echo "cpuid.coresPerSocket = \"1\""
        echo "virtualHW.version = \"$HW\""
        echo "displayName = \"Android 16 (LineageOS 23.2)\""
    } >> "$WORK/$NAME.vmx"

    # OVF, not OVA: a folder holding the .ovf descriptor, the disk files and
    # the .mf manifest. An OVA is simply that same set rolled into one tar.
    rm -rf "$OUT/$NAME"
    mkdir -p "$OUT/$NAME"
    ovftool --acceptAllEulas --overwrite --compress=9 \
            --name="$NAME" \
            "$WORK/$NAME.vmx" "$OUT/$NAME/$NAME.ovf" 2>&1 | tail -4
    rm -rf "$WORK"
    echo "  -> $OUT/$NAME/"
    ls -lh "$OUT/$NAME/" | tail -n +2 | awk '{print "     ", $9, $5}'
}

# Optional argument limits the export to one profile, so a change to one
# does not cost a re-export of the other.
ONLY="$1"

[ -z "$ONLY" ] || [ "$ONLY" = "desktop" ] && \
build android16-desktop   12288 8 21
# 6 GB / 4 vCPU, not 4 GB / 2. This image renders graphics in software
# (mesa_swrast) because neither VMware nor VirtualBox gives Android a usable
# 3D driver, and software rendering is CPU-bound. On 2 vCPUs first boot took
# about 3 minutes versus well under one on 8 - slow enough that people assume
# it has hung and give up. 4 cores keeps it modest while still usable.
[ -z "$ONLY" ] || [ "$ONLY" = "universal" ] && \
build android16-universal  6144 4 19

echo
echo "=== exported ==="
ls -lh "$OUT" | tail -5

echo
echo "=== putting the user-facing files back in ==="
# export wipes each profile folder before writing, so everything that is not
# produced by ovftool has to be restored here. Doing it by hand is how
# verify.sh and the installers went missing twice.
bash /home/student/Downloads/Android_16/write-readme.sh
for n in android16-desktop android16-universal; do
    D="$OUT/$n"
    [ -d "$D" ] || continue
    cat > "$D/verify.sh" <<'VEOF'
#!/bin/bash
# Check that every file in this folder arrived undamaged.
cd "$(dirname "$0")"
MF=$(ls *.mf 2>/dev/null | head -1)
if [ -z "$MF" ]; then echo "No .mf manifest found here."; exit 1; fi
echo "Checking files against $MF ..."
echo
sed "s/^SHA256(\(.*\))= \(.*\)$/\2  \1/" "$MF" | sha256sum -c -
RC=$?
echo
if [ $RC -eq 0 ]; then
    echo "All files are intact. You can import the .ovf now."
else
    echo "One or more files are damaged. Copy them again."
fi
exit $RC
VEOF
    chmod +x "$D/verify.sh"
    bash /home/student/Downloads/Android_16/make-starthere.sh "$D" >/dev/null
    bash /home/student/Downloads/Android_16/make-installer.sh "$D" >/dev/null
    echo "   restored helpers -> $n/"
done
