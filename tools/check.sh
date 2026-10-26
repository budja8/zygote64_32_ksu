#!/system/bin/sh
# Compatibility check, no root needed. Run from a PC:
#   adb push tools/check.sh /data/local/tmp/ && adb shell sh /data/local/tmp/check.sh

ok=0; warn=0; fail=0
pass() { echo "[ OK ] $*"; ok=$((ok+1)); }
note() { echo "[WARN] $*"; warn=$((warn+1)); }
bad()  { echo "[FAIL] $*"; fail=$((fail+1)); }

echo "Device:  $(getprop ro.product.model) ($(getprop ro.product.device))"
echo "SoC:     $(getprop ro.soc.model) / $(getprop ro.product.board)"
echo "Android: $(getprop ro.build.version.release) (SDK $(getprop ro.build.version.sdk))"
echo "ROM:     $(getprop ro.build.flavor)"
echo "Zygote:  $(getprop ro.zygote)  ABIs: $(getprop ro.product.cpu.abilist)"
echo

[ "$(getprop ro.product.cpu.abilist64)" ] && pass "64-bit device" || bad "not an arm64 device"

if [ -n "$(getprop ro.product.cpu.abilist32)" ]; then
    pass "ROM already supports 32-bit apps, you do not need this module"
fi

for f in /system/bin/app_process32 /system/bin/linker /system/lib/libandroid_runtime.so \
         /system/lib/libhwui.so /apex/com.android.art/lib/libart.so /system/framework/arm/boot.art; do
    [ -e "$f" ] && pass "$f" || bad "missing $f (ROM stripped 32-bit userspace)"
done

[ -n "$(ls /vendor/lib/egl 2>/dev/null)" ] && pass "32-bit GPU drivers in /vendor/lib/egl" \
    || note "no 32-bit GPU drivers, OpenGL apps may crash"

out=$(timeout 5 /system/bin/linker 2>&1); rc=$?
case "$out" in
    *"format error"*|*"not executable"*) bad "CPU/kernel cannot run 32-bit code" ;;
    *) [ $rc -lt 125 ] && pass "CPU/kernel can run 32-bit code" || bad "32-bit exec test failed (rc=$rc)" ;;
esac

if [ -f /sys/devices/system/cpu/aarch32_el0 ]; then
    note "mismatched AArch32 CPU: only cores $(cat /sys/devices/system/cpu/aarch32_el0) run 32-bit code"
fi

if [ -e /system/bin/su ] || [ -e /data/adb/ksud ]; then
    v=$(su -c '/data/adb/ksud -V' 2>/dev/null)
    if [ -n "$v" ]; then
        su -c '/data/adb/ksud initrc --help' >/dev/null 2>&1 \
            && pass "root: $v with initrc support" \
            || bad "root: $v has no 'ksud initrc' (need ReSukiSU/BakaSU)"
    else
        note "could not query ksud (grant root to shell to check root support)"
    fi
else
    bad "no KernelSU root detected"
fi

echo
echo "Result: $ok ok, $warn warnings, $fail failures"
[ $fail -eq 0 ] && echo "Looks compatible." || echo "Not compatible as-is."
