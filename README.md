# Zygote64_32 for ReSukiSU

Bring back **32-bit (armeabi-v7a) app support** on Android ROMs that were built 64-bit only but still ship the 32-bit userspace.

Some ROMs set `ro.zygote=zygote64` and drop `armeabi-v7a` from the ABI list, so 32-bit apps fail to install with:

```
INSTALL_FAILED_NO_MATCHING_ABIS: Failed to extract native libraries, res=-113
```

Very often the ROM still contains `/system/lib`, `app_process32`, the 32-bit ART runtime and the `framework/arm` boot image, and only the 32-bit zygote is switched off. This module switches it back on. It does not ship or modify any libraries, and it does not touch `/system` or the boot image.

## How it works

ReSukiSU/BakaSU can splice `initrc/*.rc` files from enabled modules into `init.rc` at boot, through `/metadata/.../ksu/modules.rc`. The module uses that to:

1. **Define a secondary 32-bit zygote** (`zygote32_ksu`, running `/system/bin/app_process32` on the standard `zygote_secondary` socket). The service is `disabled` and only starts when the module enables it.
2. **Flip the ABI props in `post-fs-data`** with `resetprop`: `ro.*.product.cpu.abilist` / `abilist32` and `ro.zygote=zygote64_32`. It also sets a fallback `dalvik.vm.isa.arm.*`, then sets `ksu.zygote32.enable=1`.
3. **Start the 32-bit zygote at `zygote-start`.** Android's `ZygoteProcess` already knows the `zygote_secondary` socket, so system_server uses it for 32-bit apps.

If the module is disabled, removed or skipped by safe mode, `post-fs-data.sh` doesn't run, so the property is never set and nothing starts, even if an old `modules.rc` is still around.

This is the same prop-level approach as the [Pixel 7 Magisk fork](https://github.com/Namelesswonder/magisk-files). Magisk modules run too late to add init services, which is why that project had to fork Magisk itself.

## Requirements

All of these must be true:

| Requirement | Why |
|---|---|
| **CPU with AArch32 at EL0** | Hardware must execute 32-bit ARM code (see table below) |
| **Kernel with `CONFIG_COMPAT`** | Needed to exec 32-bit binaries |
| **ROM still ships 32-bit userspace** | The module ships no libraries |
| **ReSukiSU / BakaSU** with `ksud initrc` | Needed for module init rc injection. Magisk and builds without `initrc` won't work |

### CPU compatibility

| CPU cores | Example SoCs | Status |
|---|---|---|
| Cortex-A55/A76/A77/A78/X1 | Snapdragon 855/865/870/888, Tensor G1/G2, Dimensity 1200 | ✅ All cores run 32-bit |
| Cortex-X2/A710/A510 | Snapdragon 8 Gen 1 / 8+ Gen 1 | ⚠️ X2 is 64-bit only; kernel must pin 32-bit tasks to capable cores |
| Cortex-X3/A715 + A710/A510 | Snapdragon 8 Gen 2, Tensor G3 | ⚠️ Only some cores, kernel dependent |
| Cortex-X4/A720/A520, Oryon | Snapdragon 8 Gen 3, 8 Elite, Tensor G4+ | ❌ No AArch32 at all, impossible |

### Check your device first

No root needed:

```sh
adb push tools/check.sh /data/local/tmp/
adb shell sh /data/local/tmp/check.sh
```

The installer runs the same checks and aborts if something is missing.

## Install

1. Download the zip from [Releases](../../releases) (or build it, see below).
2. Install it from the ReSukiSU manager and reboot.
3. Verify:
   ```sh
   adb shell getprop ro.product.cpu.abilist32        # armeabi-v7a,armeabi
   adb shell getprop init.svc.zygote32_ksu           # running
   adb shell su -c cat /data/adb/modules/zygote64_32_ksu/zygote32.log
   ```

If the log says `zygote32_ksu not found in modules.rc`, reboot once more.

### Installing old 32-bit apps

Most 32-bit-only apps are old, and Android 14+ blocks apps targeting SDK < 23 (`INSTALL_FAILED_DEPRECATED_SDK_VERSION`). Install them with:

```sh
adb install --bypass-low-target-sdk-block app.apk
```

Backup apps (DataBackup, Swift Backup, etc.) don't use that flag. Install the APK manually first, then restore **data only** (untick APK).

## Recovery if it bootloops

From easiest to last resort:

1. **ReSukiSU safe mode**: press Volume Down repeatedly while booting. This disables all modules.
2. **ADB**: `adb shell su -c "ksud module disable zygote64_32_ksu"` (adbd usually still starts).
3. **Custom recovery**: create an empty file `/data/adb/modules/zygote64_32_ksu/disable`, or delete that folder. This needs a recovery that decrypts `/data`.
4. **Last resort**: in recovery, mount `/metadata` (not encrypted) and empty `/metadata/watchdog/ksu/modules.rc`.

## Tested on

| Device | SoC | ROM | Android | Root | Result |
|---|---|---|---|---|---|
| POCO F4 (munch) | SM8250 (Snapdragon 870) | NeoTeric OS | 16 | ReSukiSU v4.2.0 | ✅ Adobe Photoshop Touch (armeabi-v7a, targetSdk 17) runs |

Tested it on another device? Open an issue or PR with your result.

## Security note

Re-enabling 32-bit apps increases kernel attack surface: compat syscalls and a second zygote. Hardened allocators may also not apply to 32-bit processes. This is why projects like GrapheneOS [refuse to do it](https://github.com/GrapheneOS/os-issue-tracker/issues/1944). Use it only if you need a specific 32-bit app.

## Building

```sh
python tools/build.py   # -> dist/zygote64_32_ksu-<version>.zip
```

The build normalizes line endings to LF. Shell scripts and rc files break with CRLF.

## Layout

```
module/
  module.prop
  customize.sh       installer checks
  common.sh          shared checks
  post-fs-data.sh    flips ABI props, enables the service
  service.sh         writes diagnostics after boot
  initrc/zygote32.rc secondary 32-bit zygote service
tools/
  check.sh           pre-install compatibility check
  build.py           packages the module zip
update.json          ReSukiSU/KernelSU update channel
```

## Disclaimer

Use at your own risk. This project does not include or distribute any third-party APKs.

## License

[MIT](LICENSE)
