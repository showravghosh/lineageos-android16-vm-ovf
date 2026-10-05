#!/bin/bash
mkdir -p /tmp/android16
# Inject ARM64 translation + Google apps into the LineageOS Android 16 staging tree.
# Source: Google's official x86_64 API-36 emulator system image.
set -e
SRC=/tmp/android16/sysx/system          # Google's system partition
PSRC=/tmp/android16/gmsx                # Google's product partition
OUT=/home/student/Downloads/Android_16/lineage/out/target/product/virtio_x86_64

echo "=== 1. ARM64 translation libraries -> system/lib64 ==="
cp -a $SRC/lib64/libndk_translation*.so $OUT/system/lib64/ && echo "   21 translator libs"
# libberberis_exec_region.so backs the translator's executable memory regions.
# It does NOT match the libndk_translation* glob. Without it Messenger aborts:
#   exec_region_elf_backed.cc:47: CHECK failed: 0 != 0
cp -a $SRC/lib64/libberberis_*.so $OUT/system/lib64/ && echo "   libberberis_exec_region.so"
mkdir -p $OUT/system/lib64/arm64
cp -a $SRC/lib64/arm64/. $OUT/system/lib64/arm64/ && echo "   arm64 native libs ($(du -sh $OUT/system/lib64/arm64 | cut -f1))"

echo "=== 1b. ARM64 binaries -> system/bin/arm64 ==="
# app_process64 + linker64. Without these the native bridge aborts with
#   native_bridge_initialize: unable to open "/system/bin/arm64/app_process64"
# Facebook/Instagram survive without them; Messenger does not.
mkdir -p $OUT/system/bin/arm64
cp -a $SRC/bin/arm64/. $OUT/system/bin/arm64/ && echo "   app_process64, linker64"

echo "=== 2. native bridge runner + init + binfmt ==="
cp -a $SRC/bin/ndk_translation_program_runner_binfmt_misc_arm64 $OUT/system/bin/
mkdir -p $OUT/system/etc/init $OUT/system/etc/binfmt_misc
cp -a $SRC/etc/init/ndk_translation.rc $OUT/system/etc/init/
cp -a $SRC/etc/binfmt_misc/arm64_exe $SRC/etc/binfmt_misc/arm64_dyn $OUT/system/etc/binfmt_misc/
cp -a $SRC/etc/cpuinfo.arm64.txt $OUT/system/etc/ 2>/dev/null || true
echo "   runner, ndk_translation.rc, binfmt_misc registrations"

echo "=== 3. Google apps -> product/app ==="
mkdir -p $OUT/product/app
for a in PrebuiltGmail Maps YouTube Drive Photos Chrome TrichromeLibrary GoogleTTS CalendarGooglePrebuilt; do
  [ -d "$PSRC/app/$a" ] && cp -r "$PSRC/app/$a" $OUT/product/app/ && echo "   + $a"
done

echo "=== 3b. system_ext privapp whitelist (GoogleServicesFramework) ==="
# GSF comes from Google's system_ext partition and its privileged-permission
# whitelist lives there too. Without this, Android 16's permission subsystem
# throws IllegalStateException and system_server crash-loops at boot.
cp -a /tmp/android16/sysextx/etc/permissions/privapp-permissions-google-se.xml \
      $OUT/product/etc/permissions/ && echo "   + privapp-permissions-google-se.xml"

echo "=== 4. build.prop: enable the native bridge ==="
BP=$OUT/system/build.prop
grep -q "ro.dalvik.vm.isa.arm64" $BP || cat >> $BP <<'PROPS'

# ARM translation (ndk_translation from Google's x86_64 API-36 image)
ro.dalvik.vm.isa.arm64=x86_64
ro.enable.native.bridge.exec=1
ro.ndk_translation.version=0.2.3
PROPS
# advertise ARM ABIs so Play Store offers ARM-only apps
sed -i 's/^ro\.product\.cpu\.abilist=.*/ro.product.cpu.abilist=x86_64,arm64-v8a/' $BP
grep -q "^ro.product.cpu.abilist=" $BP || echo "ro.product.cpu.abilist=x86_64,arm64-v8a" >> $BP
sed -i 's/^ro\.product\.cpu\.abilist64=.*/ro.product.cpu.abilist64=x86_64,arm64-v8a/' $BP
grep -q "^ro.product.cpu.abilist64=" $BP || echo "ro.product.cpu.abilist64=x86_64,arm64-v8a" >> $BP
echo "   abilist now: $(grep '^ro.product.cpu.abilist=' $BP)"
echo "   $(grep '^ro.dalvik.vm.isa.arm64' $BP)"

echo ""
echo "=== injection complete ==="
du -sh $OUT/system $OUT/product
