# Shared checks, sourced by customize.sh and post-fs-data.sh

# Files the 32-bit zygote needs from the ROM; the module ships none of them
REQUIRED_32BIT="
/system/bin/app_process32
/system/bin/linker
/system/lib/libandroid_runtime.so
/system/lib/libhwui.so
/apex/com.android.art/lib/libart.so
/system/framework/arm/boot.art
"

missing_32bit_files() {
    for f in $REQUIRED_32BIT; do
        [ -e "$f" ] || echo "$f"
    done
}

# 0 if the kernel/CPU can exec a 32-bit ARM binary.
# timeout execs directly, so ENOEXEC is not masked by a shell script fallback.
can_exec_32bit() {
    out=$(timeout 5 /system/bin/linker 2>&1)
    rc=$?
    case "$out" in
        *"format error"*|*"not executable"*) return 1 ;;
    esac
    [ $rc -lt 125 ]
}

# Path of the preinit rc the kernel splices into init.rc (ReSukiSU/BakaSU)
modules_rc_path() {
    for d in /metadata/vold/ksu /metadata/watchdog/ksu /metadata/ksu; do
        [ -f "$d/modules.rc" ] && { echo "$d/modules.rc"; return 0; }
    done
    return 1
}

ksud_has_initrc() {
    /data/adb/ksud initrc --help >/dev/null 2>&1
}
