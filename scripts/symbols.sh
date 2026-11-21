#!/usr/bin/env bash
# 从构建产物里抽出移植要用的符号偏移，生成 target_symbols.h
set -euo pipefail

TC=${TC:-$PWD/toolchain}
OUT=${OUT:-$PWD/out}
ART=${ART:-$PWD/artifacts}
NM=$TC/gcc-4.9/bin/aarch64-linux-android-nm

mkdir -p "$ART"
VMLINUX=$OUT/vmlinux
[ -f "$VMLINUX" ] || { echo "missing $VMLINUX"; exit 1; }

echo "==> nm -n"
"$NM" -n "$VMLINUX" > "$ART/vmlinux.nm"
awk 'NF==3 {print $3}' "$ART/vmlinux.nm" > "$ART/kallsyms-names.txt"
wc -l < "$ART/kallsyms-names.txt" | xargs echo "symbols:"

echo "==> strip debug copy"
$TC/gcc-4.9/bin/aarch64-linux-android-objcopy --strip-debug "$VMLINUX" "$ART/vmlinux.stripped"
cp "$OUT/System.map" "$ART/System.map"
cp "$OUT/arch/arm64/boot/Image" "$ART/Image"

echo "==> target_symbols.h"
python3 - "$ART/vmlinux.nm" "$ART/target_symbols.h" <<'PY'
import sys

nm_path, out_path = sys.argv[1], sys.argv[2]

WANT = {
    "_text": "映像基址（KASLR 后的 slide 基准）",
    "_stext": "代码段起点",
    "_etext": "代码段终点",
    "ashmem_misc": "miscdevice，fops 槽 = +0x10",
    "ashmem_fops": "file_operations",
    "ashmem_ioctl": "unlocked_ioctl",
    "compat_ashmem_ioctl": "compat_ioctl",
    "ashmem_mmap": "mmap",
    "ashmem_open": "open",
    "ashmem_release": "release",
    "ashmem_show_fdinfo": "show_fdinfo",
    "configfs_read_file": "configfs 读",
    "configfs_write_bin_file": "configfs 写（bin）",
    "generic_file_splice_read": "splice_read 默认实现",
    "noop_llseek": "llseek 桩",
    "init_task": "task 0",
    "init_uts_ns": "uts namespace",
    "empty_zero_page": "零页",
    "root_task_group": "root cgroup",
    "selinux_state": "SELinux 全局状态",
    "security_hook_heads": "LSM hook 表",
    "kmalloc_caches": "kmalloc cache 数组",
    "anon_pipe_buf_ops": "pipe_buf_operations",
    "nfulnl_logger": "nfnetlink_log",
    "sysctl_bootid": "boot_id（KASLR 侧信道常用）",
}

addr = {}
for line in open(nm_path, errors="replace"):
    parts = line.split()
    if len(parts) != 3:
        continue
    a, _t, name = parts
    if name not in addr:
        try:
            addr[name] = int(a, 16)
        except ValueError:
            pass

if "_text" not in addr:
    sys.exit("no _text in nm output")

base = addr["_text"]
lines = [
    "/* 由 scripts/symbols.sh 自动生成 —— 不要手改 */",
    "/* 源: 三星开源 4.19.113 (y2q_usa_singlew) 自建 vmlinux，偏移相对 _text */",
    "#ifndef Y2Q_TARGET_SYMBOLS_H",
    "#define Y2Q_TARGET_SYMBOLS_H",
    "",
    "#define KIMAGE_TEXT_BASE 0x%016xULL" % base,
    "",
]
missing = []
for name in WANT:
    if name not in addr:
        missing.append(name)
        continue
    off = addr[name] - base
    lines.append("#define %-28s 0x%08xULL   /* %s */" % (name.upper() + "_OFF", off, WANT[name]))

lines += ["", "#endif"]
open(out_path, "w").write("\n".join(lines) + "\n")

print("wrote %s (%d symbols)" % (out_path, len(WANT) - len(missing)))
if missing:
    print("MISSING: " + ", ".join(missing))
    sys.exit(1)
PY

echo "==> config diff vs device"
if [ -f config/device.config.gz ]; then
	zcat config/device.config.gz > /tmp/device.config
	diff <(sort /tmp/device.config) <(sort "$OUT/.config") > "$ART/config.diff" || true
	echo "$(grep -c '^[<>]' "$ART/config.diff" || true) differing lines -> artifacts/config.diff"
fi

ls -la "$ART"
