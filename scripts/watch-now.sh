#!/bin/bash
# Live view of whatever the current step is, in the user's own terminal.
cd /home/student/Downloads/Android_16
echo "==============================================================="
echo "  ANDROID 16 - LIVE"
echo "  step: building image with androidboot.partition_map fix"
echo "    bootconfig     vdb,userdata   (QEMU)"
echo "    kernel cmdline sdb,userdata   (VMware)"
echo "  one name - /dev/block/by-name/userdata - in both"
echo "==============================================================="
LOG=$(ls -t build-partmap4.log build-partmap3.log 2>/dev/null | head -1)
echo "log: $LOG"
echo
tail -f -n 40 "$LOG"
