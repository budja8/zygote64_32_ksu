#!/system/bin/sh
MODDIR=${0%/*}
LOG=$MODDIR/zygote32.log

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 2; done
{
    echo "boot_completed $(date)"
    echo "init.svc.zygote=$(getprop init.svc.zygote)"
    echo "init.svc.zygote32_ksu=$(getprop init.svc.zygote32_ksu)"
    ls -l /dev/socket/zygote_secondary 2>&1
    ps -A | grep -E 'zygote|app_process'
} >> "$LOG"
