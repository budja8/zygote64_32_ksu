# Changelog

## v1.1
- Installer checks: KernelSU with `ksud initrc`, 32-bit userspace, real 32-bit exec test, 32-bit GPU drivers warning.
- post-fs-data only flips ABIs when `zygote32_ksu` is present in the spliced `modules.rc`.
- Fallback `dalvik.vm.isa.arm.variant` / `features` when the ROM does not set them.
- `updateJson` support.

## v1.0
- First working version. Tested on POCO F4 (munch, SM8250), NeoTeric OS Android 16, ReSukiSU v4.2.0.
