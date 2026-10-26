#!/system/bin/sh
MODDIR=${0%/*}
LOG=$MODDIR/zygote32.log

. "$MODDIR/common.sh"

echo "post-fs-data $(date)" > "$LOG"

missing=$(missing_32bit_files)
if [ -n "$missing" ]; then
    echo "missing 32-bit files, not enabling: $missing" >> "$LOG"
    exit 0
fi

# Without our service in the spliced rc, flipping the ABIs would let 32-bit apps
# install but crash on launch, so only enable when the rc is in place
rc=$(modules_rc_path)
if [ -z "$rc" ] || ! grep -q zygote32_ksu "$rc"; then
    echo "zygote32_ksu not found in modules.rc, not enabling (reboot once more)" >> "$LOG"
    exit 0
fi

ABI=arm64-v8a,armeabi-v7a,armeabi
ABI32=armeabi-v7a,armeabi

for p in ro.product.cpu ro.system.product.cpu ro.vendor.product.cpu ro.odm.product.cpu ro.product.product.cpu ro.system_ext.product.cpu; do
    if [ -n "$(getprop $p.abilist64)" ]; then
        resetprop -n $p.abilist $ABI
        resetprop -n $p.abilist32 $ABI32
    fi
done
resetprop -n ro.zygote zygote64_32

# dex2oat needs an ARM variant; cortex-a53 is a safe baseline for any AArch32-capable core
[ -n "$(getprop dalvik.vm.isa.arm.variant)" ] || resetprop -n dalvik.vm.isa.arm.variant cortex-a53
[ -n "$(getprop dalvik.vm.isa.arm.features)" ] || resetprop -n dalvik.vm.isa.arm.features default

resetprop -n ksu.zygote32.enable 1

getprop | grep -E 'abilist|ro.zygote|dalvik.vm.isa.arm|ksu.zygote32' >> "$LOG"
