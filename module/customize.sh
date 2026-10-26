SKIPUNZIP=0

. "$MODPATH/common.sh"

[ "$ARCH" = "arm64" ] || abort "! Only for arm64 devices"

[ "$KSU" = "true" ] || abort "! Requires KernelSU-based root (ReSukiSU/BakaSU). Magisk modules cannot inject init rc."
ksud_has_initrc || abort "! This KernelSU build has no 'ksud initrc' (module init rc injection). Use ReSukiSU/BakaSU."

missing=$(missing_32bit_files)
[ -z "$missing" ] || abort "! ROM has no 32-bit userspace, missing: $missing"
ui_print "- 32-bit userspace found"

can_exec_32bit || abort "! CPU/kernel cannot execute 32-bit ARM code (no AArch32 EL0)"
ui_print "- CPU/kernel can execute 32-bit code"

if [ -z "$(ls /vendor/lib/egl 2>/dev/null)" ]; then
    ui_print "! Warning: no 32-bit GPU drivers in /vendor/lib/egl"
    ui_print "! 32-bit apps using OpenGL may crash"
fi

ui_print "- Reboot to enable the 32-bit zygote"
ui_print "- Log: /data/adb/modules/zygote64_32_ksu/zygote32.log"
