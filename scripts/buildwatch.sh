#!/bin/bash
# Build progress + memory pressure monitor
OUT=/home/student/Downloads/Android_16/lineage/out
EDGES=$(wc -l < $OUT/.ninja_log 2>/dev/null)
SIZE=$(du -sh $OUT 2>/dev/null | cut -f1)
RUNNING=$(pgrep -fc "ninja|soong_ui" 2>/dev/null)
PRESSURE=$(awk '/^some/{print $2}' /proc/pressure/memory 2>/dev/null | cut -d= -f2)
MEM=$(free -g | awk '/^Mem:/{printf "%dG used / %dG total, %dG avail", $3,$2,$7}')
SWAP=$(free -g | awk '/^Swap:/{printf "%dG/%dG", $3,$2}')
OOMD=$(systemctl is-active systemd-oomd.service 2>/dev/null)
printf "\n  Android 16 build\n"
printf "  ninja edges : %s\n" "$EDGES"
printf "  out/ size   : %s\n" "$SIZE"
printf "  memory      : %s\n" "$MEM"
printf "  swap        : %s\n" "$SWAP"
printf "  mem pressure: avg10=%s%%  (oomd killed at 50%% before)\n" "$PRESSURE"
printf "  systemd-oomd: %s %s\n" "$OOMD" "$([ "$OOMD" = active ] && echo '<-- WARNING, stop it again')"
if [ "$RUNNING" -gt 0 ]; then printf "  status      : BUILDING\n\n"; else printf "  status      : NOT RUNNING\n\n"; fi
