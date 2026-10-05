#!/bin/bash
# Enable the SSH server on this PC so the other lab PC can copy the OVF folders.
echo "==============================================================="
echo "  Enabling SSH on this PC so the other lab PC can pull files"
echo "==============================================================="
echo
echo "You will be asked for your password (this needs sudo)."
echo

sudo apt install -y openssh-server || exit 1
sudo systemctl enable --now ssh || exit 1

echo
echo "=== status ==="
systemctl is-active ssh && echo "  ssh is running"
IP=$(ip -4 -o addr show eno1 2>/dev/null | awk '{print $4}' | cut -d/ -f1)
echo "  this PC: $IP   user: $USER"
echo
echo "==============================================================="
echo "  NOW GO TO THE OTHER LAB PC and run this there:"
echo ""
echo "    rsync -avP $USER@$IP:/home/student/Downloads/Android_16/export/android16-desktop/ ~/android16-desktop/"
echo ""
echo "  It will ask for this PC's password. rsync resumes if the"
echo "  transfer breaks, so a dropped connection is not a restart."
echo ""
echo "  Then on that PC, check nothing was corrupted in transit:"
echo ""
echo "    cd ~/android16-desktop"
echo "    sha256sum -c <(sed 's/^SHA256(\\(.*\\))= /\\1  /' android16-desktop.mf)"
echo ""
echo "  Every line should say OK. Then import the .ovf in VMware."
echo "==============================================================="
