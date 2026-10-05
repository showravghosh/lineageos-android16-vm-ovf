#!/bin/bash
# Rebuild export/Github_Push/release from the current OVF exports.
# Only release/ is replaced; repo/ (with its git history) is not touched.
# The originals in export/android16-* stay whole.
set -e
SRC=/home/student/Downloads/Android_16
DEST=$SRC/export/Github_Push/release
KEEP=$SRC/sound-fix/keep
PARTMB=1900           # GitHub allows 2 GB per release asset; stay under it

rm -rf "$DEST"; mkdir -p "$DEST"
for n in android16-desktop android16-universal; do
    echo "=== $n ==="
    D="$DEST/$n"
    cp -r "$SRC/export/$n" "$D"
    WIN=""
    for f in "$D"/*.vmdk.gz; do
        B=$(basename "$f")
        split -b ${PARTMB}M -d -a 3 "$f" "$f.part"
        rm -f "$f"
        PARTS=$(cd "$D" && ls "$B".part* | tr '\n' ' ' | sed 's/ $//; s/ / + /g')
        WIN="$WIN    copy /b $PARTS $B
"
        echo "   $B -> $(ls "$D/$B".part* | wc -l) parts"
    done
    cp "$KEEP/rejoin.sh" "$D/rejoin.sh"; chmod +x "$D/rejoin.sh"
    cat > "$D/JOIN-PARTS.txt" <<JEOF
The two disk files were split so they could be uploaded - GitHub does not
accept a single file larger than 2 GB.

Download EVERY .part file, then put them back together.
(INSTALL-AND-RUN and START-HERE do this for you automatically.)


LINUX / MAC
-----------
    bash rejoin.sh

or by hand:

    cat $n-disk1.vmdk.gz.part* > $n-disk1.vmdk.gz
    cat $n-disk2.vmdk.gz.part* > $n-disk2.vmdk.gz
    rm $n-disk*.part*


WINDOWS (Command Prompt, in this folder)
----------------------------------------
$WIN
then delete the .part files.


AFTERWARDS
----------
Check the rejoined files are correct:

    bash verify.sh          (Linux/Mac)

Every line should say OK. Then follow README.txt to import the .ovf.
JEOF
    # prove the parts rejoin to the exact original
    for f in "$SRC/export/$n"/*.vmdk.gz; do
        B=$(basename "$f")
        A=$(cat "$D/$B".part* | sha256sum | cut -d' ' -f1)
        O=$(grep "($B)" "$SRC/export/$n"/*.mf | sed 's/.*= //')
        [ "$A" = "$O" ] && echo "   rejoin check $B: OK" || { echo "   rejoin check $B: MISMATCH"; exit 1; }
    done
done
du -sh "$DEST"/*
echo "release-done"
