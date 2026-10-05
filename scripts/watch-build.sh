#!/bin/bash
# Live view of the running build, in the user's own Ptyxis terminal.
echo "==============================================================="
echo "  Android 16 build - LIVE"
echo "  /data by name (by-name/userdata) so QEMU and VMware agree"
echo "==============================================================="
tail -f -n 40 /home/student/Downloads/Android_16/build-byname.log
