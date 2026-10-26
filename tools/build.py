"""Package module/ into dist/zygote64_32_ksu-<version>.zip with LF line endings."""
import os
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "module")

props = dict(
    line.strip().split("=", 1)
    for line in open(os.path.join(SRC, "module.prop"), encoding="utf-8")
    if "=" in line
)
out = os.path.join(ROOT, "dist", f"{props['id']}-{props['version']}.zip")
os.makedirs(os.path.dirname(out), exist_ok=True)

with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    for root, _, files in os.walk(SRC):
        for fn in sorted(files):
            path = os.path.join(root, fn)
            data = open(path, "rb").read().replace(b"\r\n", b"\n")
            z.writestr(os.path.relpath(path, SRC).replace(os.sep, "/"), data)

print(out)
