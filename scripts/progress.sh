#!/bin/bash
# LineageOS sync progress
SRC=/home/student/Downloads/Android_16/lineage
BASE=$SRC/.repo/manifests
TOTAL=$(python3 -c "
import xml.etree.ElementTree as ET, os
base='$BASE'; total=0; seen=set(); files=[os.path.join(base,'default.xml')]
while files:
    p=files.pop()
    if p in seen or not os.path.exists(p): continue
    seen.add(p); r=ET.parse(p).getroot()
    total+=len(r.findall('project'))
    for inc in r.findall('include'): files.append(os.path.join(base,inc.get('name')))
print(total)" 2>/dev/null)
DONE=$(find $SRC/.repo/projects -maxdepth 6 -name "*.git" -type d 2>/dev/null | wc -l)
SIZE=$(du -sh $SRC 2>/dev/null | cut -f1)
PROCS=$(pgrep -fc repo 2>/dev/null)
PCT=0; [ "$TOTAL" -gt 0 ] && PCT=$((DONE*100/TOTAL))
BAR=$(printf '%*s' $((PCT/2)) '' | tr ' ' '#')
printf "\n  LineageOS 23.2 (Android 16) sync\n"
printf "  [%-50s] %d%%\n" "$BAR" "$PCT"
printf "  projects : %d / %d\n  on disk  : %s\n" "$DONE" "$TOTAL" "$SIZE"
if [ "$PROCS" -gt 0 ]; then printf "  status   : downloading (%s processes)\n\n" "$PROCS"
else printf "  status   : NOT RUNNING - sync finished or stopped\n\n"; fi
