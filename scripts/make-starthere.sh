#!/bin/bash
# Put a one-click setup script (Linux/Mac + Windows) into a folder holding
# an exported OVF, so the person receiving it does not have to run commands
# or know about Hyper-V, checksums or split files.
D="$1"
[ -d "$D" ] || { echo "usage: make-starthere.sh <folder>"; exit 1; }
N=$(basename "$D")

cat > "$D/START-HERE.sh" <<'EOF'
#!/bin/bash
# Prepares this folder and checks the computer can run the virtual machine.
cd "$(dirname "$0")"
echo "==============================================================="
echo "  Android 16 - setting up"
echo "==============================================================="
echo

if ls *.part000 >/dev/null 2>&1; then
    echo "[1/3] Joining the downloaded parts..."
    for base in $(ls *.part000 | sed 's/\.part000$//'); do
        cat "$base".part* > "$base" && rm -f "$base".part*
        echo "      $base"
    done
else
    echo "[1/3] No split parts to join - skipping."
fi
echo

echo "[2/3] Checking the files are undamaged..."
MF=$(ls *.mf 2>/dev/null | head -1)
if [ -n "$MF" ]; then
    if sed 's/^SHA256(\(.*\))= \(.*\)$/\2  \1/' "$MF" | sha256sum -c - >/tmp/_a16chk 2>&1; then
        echo "      all files OK"
    else
        echo "      *** SOME FILES ARE DAMAGED ***"
        grep -v ': OK$' /tmp/_a16chk | head -5
        echo
        echo "      Download or copy this folder again before continuing."
        rm -f /tmp/_a16chk; exit 1
    fi
    rm -f /tmp/_a16chk
else
    echo "      no manifest found - skipping"
fi
echo

echo "[3/3] Checking this computer can run virtual machines..."
if grep -qE '^flags.*(vmx|svm)' /proc/cpuinfo 2>/dev/null; then
    echo "      hardware virtualization: available"
else
    echo "      *** hardware virtualization NOT available ***"
    echo "      Turn on Intel VT-x / AMD-V in the BIOS, or the virtual"
    echo "      machine will not start (or will be extremely slow)."
fi
echo
echo "==============================================================="
echo "  Ready. Now open the virtual machine:"
echo
echo "  VMware:      File > Open...            and choose the .ovf file"
echo "  VirtualBox:  File > Import Appliance...and choose the .ovf file"
echo
echo "  VirtualBox users: after importing, open Settings and set"
echo "     System  > Motherboard > Enable EFI          (tick it)"
echo "     Display > Screen > Graphics Controller: VMSVGA"
echo "  Without those two the machine will not boot."
echo
echo "  See README.txt for the rest."
echo "==============================================================="
EOF
chmod +x "$D/START-HERE.sh"

cat > "$D/START-HERE.bat" <<EOF
@echo off
REM Prepares this folder and checks the computer can run the virtual machine.
cd /d "%~dp0"
echo ===============================================================
echo   Android 16 - setting up
echo ===============================================================
echo.

echo [1/3] Joining the downloaded parts...
if exist "$N-disk1.vmdk.gz.part000" (
    copy /b "$N-disk1.vmdk.gz.part*" "$N-disk1.vmdk.gz" >nul
    del "$N-disk1.vmdk.gz.part*"
    echo       $N-disk1.vmdk.gz
)
if exist "$N-disk2.vmdk.gz.part000" (
    copy /b "$N-disk2.vmdk.gz.part*" "$N-disk2.vmdk.gz" >nul
    del "$N-disk2.vmdk.gz.part*"
    echo       $N-disk2.vmdk.gz
)
if not exist "$N-disk1.vmdk.gz" echo       Nothing to join - skipping.
echo.

echo [2/3] Checking the files are undamaged...
for %%F in ("$N-disk1.vmdk.gz" "$N-disk2.vmdk.gz") do (
    echo       %%~nxF
    certutil -hashfile "%%~F" SHA256 ^| findstr /v "hash CertUtil"
)
echo       Compare the values above with those in $N.mf
echo.

echo [3/3] Checking Windows will allow virtual machines...
powershell -NoProfile -Command "if ((Get-ComputerInfo -Property HyperVisorPresent).HyperVisorPresent) { Write-Host '      *** Hyper-V is ON - VirtualBox and VMware will fail or crawl ***'; Write-Host '      Run this in an Administrator Command Prompt, then reboot:'; Write-Host '          bcdedit /set hypervisorlaunchtype off' } else { Write-Host '      Hyper-V is off - good' }" 2>nul
echo.
echo ===============================================================
echo   Ready. Now open the virtual machine:
echo.
echo   VMware:      File ^> Open...             and choose the .ovf file
echo   VirtualBox:  File ^> Import Appliance... and choose the .ovf file
echo.
echo   VirtualBox users: after importing, open Settings and set
echo      System  ^> Motherboard ^> Enable EFI          (tick it)
echo      Display ^> Screen ^> Graphics Controller: VMSVGA
echo   Without those two the machine will not boot.
echo.
echo   See README.txt for the rest.
echo ===============================================================
pause
EOF
echo "  START-HERE.sh + START-HERE.bat -> $N/"
