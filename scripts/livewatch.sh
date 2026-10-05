#!/bin/bash
OUT=/home/student/Downloads/Android_16/lineage/out
while true; do
  clear
  echo "================================================================"
  echo "   ANDROID 16 + GOOGLE PLAY  --  live status   $(date '+%H:%M:%S')"
  echo "================================================================"
  echo ""
  if pgrep -x ninja >/dev/null; then
    echo "  BUILD      : RUNNING"
  else
    echo "  BUILD      : not running (finished or stopped)"
  fi
  echo "  ninja steps: $(wc -l < $OUT/.ninja_log 2>/dev/null)"
  echo "  out/ size  : $(du -sh $OUT 2>/dev/null | cut -f1)"
  echo "  memory     : $(free -g | awk '/^Mem:/{printf "%dG used / %dG", $3,$2}')"
  echo "  mem pressure: $(awk '/^some/{print $2}' /proc/pressure/memory 2>/dev/null | cut -d= -f2)%"
  echo ""
  echo "  --- errors ---"
  if [ -s $OUT/error.log ]; then head -3 $OUT/error.log | sed 's/^/  /'; else echo "  none"; fi
  echo ""
  echo "  --- output images ---"
  ls -lh $OUT/target/product/virtio_x86_64/lineage-23.2-*.zip 2>/dev/null | awk '{print "  zip:", $5, $6, $7, $8}'
  ls -lh $OUT/target/product/virtio_x86_64/lineage-23.2-*.img 2>/dev/null | awk '{print "  img:", $5, $6, $7, $8}'
  echo ""
  echo "  --- Google Play in staging ---"
  for a in Phonesky PrebuiltGmsCore GoogleServicesFramework; do
    if [ -d "$OUT/target/product/virtio_x86_64/product/priv-app/$a" ]; then
      echo "  [ok] $a"
    else
      echo "  [--] $a"
    fi
  done
  echo ""
  echo "  --- ARM translation (for Facebook/Instagram/WhatsApp) ---"
  if [ -f "$OUT/target/product/virtio_x86_64/system/lib64/libndk_translation.so" ]; then
    echo "  [ok] injected"
  else
    echo "  [--] not yet - happens after this build"
  fi
  echo ""
  echo "================================================================"
  echo "  refreshes every 10s   |   Ctrl+C to close"
  sleep 10
done
