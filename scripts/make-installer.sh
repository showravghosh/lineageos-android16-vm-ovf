#!/bin/bash
D="$1"; [ -d "$D" ] || exit 1; N=$(basename "$D")

cat > "$D/INSTALL-AND-RUN.sh" <<'EOF'
#!/bin/bash
# Installs Android 16 and starts it. Nothing to choose, nothing to configure.
cd "$(dirname "$0")"
OVF=$(ls *.ovf 2>/dev/null | head -1)
NAME="${OVF%.ovf}"

echo "==============================================================="
echo "  Android 16 - install and run"
echo "==============================================================="
echo

# --- join split parts, if this came from a split download -------------
if ls *.part000 >/dev/null 2>&1; then
    echo "Joining downloaded parts..."
    for b in $(ls *.part000 | sed 's/\.part000$//'); do
        cat "$b".part* > "$b" && rm -f "$b".part*
    done
fi

# --- check the files are intact ---------------------------------------
MF=$(ls *.mf 2>/dev/null | head -1)
if [ -n "$MF" ]; then
    echo "Checking files..."
    if ! sed 's/^SHA256(\(.*\))= \(.*\)$/\2  \1/' "$MF" | sha256sum -c - >/dev/null 2>&1; then
        echo "  Some files are damaged. Please download this folder again."
        exit 1
    fi
fi

# --- check the computer can run virtual machines -----------------------
if ! grep -qE '^flags.*(vmx|svm)' /proc/cpuinfo 2>/dev/null; then
    echo
    echo "  This computer does not have hardware virtualization enabled."
    echo "  Turn on Intel VT-x / AMD-V in the BIOS and try again."
    exit 1
fi

# --- VirtualBox -------------------------------------------------------
if command -v VBoxManage >/dev/null 2>&1; then
    echo "Using VirtualBox."
    VBoxManage showvminfo "$NAME" >/dev/null 2>&1 && {
        echo "Already installed - starting it."
        VBoxManage startvm "$NAME" --type gui; exit 0; }

    echo "Installing (this takes a few minutes)..."
    VBoxManage import "$OVF" --vsys 0 --vmname "$NAME" || exit 1
    # Settings this image needs: it boots via EFI, and its graphics driver
    # binds to the VMSVGA device. The VirtualBox defaults do neither.
    VBoxManage modifyvm "$NAME" --firmware efi
    VBoxManage modifyvm "$NAME" --graphicscontroller vmsvga --vram 128
    VBoxManage modifyvm "$NAME" --mouse usbtablet
    VBoxManage modifyvm "$NAME" --nic1 nat --nictype1 82540EM
    VBoxManage modifyvm "$NAME" --audio-enabled=on --audio-controller=ac97 --audio-codec=ad1980 --audio-driver=default --audio-out=on
    echo "Starting..."
    VBoxManage startvm "$NAME" --type gui
    exit 0
fi

# --- VMware -----------------------------------------------------------
if command -v ovftool >/dev/null 2>&1 && command -v vmrun >/dev/null 2>&1; then
    echo "Using VMware."
    DEST="$HOME/$NAME"
    if [ ! -f "$DEST/$NAME.vmx" ]; then
        echo "Installing (this takes a few minutes)..."
        mkdir -p "$DEST"
        ovftool --acceptAllEulas --overwrite "$OVF" "$DEST/$NAME.vmx" || exit 1
    else
        echo "Already installed."
    fi
    echo "Starting..."
    vmrun -T ws start "$DEST/$NAME.vmx" gui 2>/dev/null || vmware -x "$DEST/$NAME.vmx" &
    exit 0
fi

echo "Neither VirtualBox nor VMware was found on this computer."
echo "Install one of them, then run this again:"
echo "   VirtualBox   https://www.virtualbox.org/"
echo "   VMware       https://www.vmware.com/products/workstation-player.html"
exit 1
EOF
chmod +x "$D/INSTALL-AND-RUN.sh"

cat > "$D/INSTALL-AND-RUN.bat" <<EOF
@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
set NAME=$N

echo ===============================================================
echo   Android 16 - install and run
echo ===============================================================
echo.

if exist "%NAME%-disk1.vmdk.gz.part000" (
    echo Joining downloaded parts...
    copy /b "%NAME%-disk1.vmdk.gz.part*" "%NAME%-disk1.vmdk.gz" >nul
    del "%NAME%-disk1.vmdk.gz.part*"
    copy /b "%NAME%-disk2.vmdk.gz.part*" "%NAME%-disk2.vmdk.gz" >nul
    del "%NAME%-disk2.vmdk.gz.part*"
)

powershell -NoProfile -Command "if ((Get-ComputerInfo -Property HyperVisorPresent).HyperVisorPresent) { exit 1 } else { exit 0 }" >nul 2>&1
if errorlevel 1 (
    echo   Hyper-V is switched on. VirtualBox and VMware cannot run
    echo   properly while it is.
    echo.
    echo   Open Command Prompt as Administrator, run:
    echo       bcdedit /set hypervisorlaunchtype off
    echo   then restart Windows and run this again.
    echo.
    pause
    exit /b 1
)

set VBOX=
if exist "%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe" set VBOX=%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe
if exist "%ProgramFiles(x86)%\Oracle\VirtualBox\VBoxManage.exe" set VBOX=%ProgramFiles(x86)%\Oracle\VirtualBox\VBoxManage.exe

if not "%VBOX%"=="" (
    echo Using VirtualBox.
    "%VBOX%" showvminfo "%NAME%" >nul 2>&1
    if not errorlevel 1 (
        echo Already installed - starting it.
        "%VBOX%" startvm "%NAME%" --type gui
        exit /b 0
    )
    echo Installing ^(this takes a few minutes^)...
    "%VBOX%" import "%NAME%.ovf" --vsys 0 --vmname "%NAME%"
    if errorlevel 1 goto :failed
    "%VBOX%" modifyvm "%NAME%" --firmware efi
    "%VBOX%" modifyvm "%NAME%" --graphicscontroller vmsvga --vram 128
    "%VBOX%" modifyvm "%NAME%" --mouse usbtablet
    "%VBOX%" modifyvm "%NAME%" --nic1 nat --nictype1 82540EM
    "%VBOX%" modifyvm "%NAME%" --audio-enabled=on --audio-controller=ac97 --audio-codec=ad1980 --audio-driver=default --audio-out=on
    echo Starting...
    "%VBOX%" startvm "%NAME%" --type gui
    exit /b 0
)

set OVFT=
if exist "%ProgramFiles%\VMware\VMware Workstation\OVFTool\ovftool.exe" set OVFT=%ProgramFiles%\VMware\VMware Workstation\OVFTool\ovftool.exe
if exist "%ProgramFiles(x86)%\VMware\VMware Workstation\OVFTool\ovftool.exe" set OVFT=%ProgramFiles(x86)%\VMware\VMware Workstation\OVFTool\ovftool.exe

if not "%OVFT%"=="" (
    echo Using VMware.
    if not exist "%USERPROFILE%\%NAME%\%NAME%.vmx" (
        echo Installing ^(this takes a few minutes^)...
        "%OVFT%" --acceptAllEulas --overwrite "%NAME%.ovf" "%USERPROFILE%\%NAME%\%NAME%.vmx"
        if errorlevel 1 goto :failed
    )
    echo Starting...
    start "" "%USERPROFILE%\%NAME%\%NAME%.vmx"
    exit /b 0
)

echo Neither VirtualBox nor VMware was found on this computer.
echo Install one of them, then run this again:
echo    VirtualBox   https://www.virtualbox.org/
echo    VMware       https://www.vmware.com/
pause
exit /b 1

:failed
echo.
echo Something went wrong during installation. See the messages above.
pause
exit /b 1
EOF
echo "  INSTALL-AND-RUN.sh + .bat -> $N/"
