#!/usr/bin/env bash
# 从三星开源包源码 + 设备 config 生成并校验结构体偏移（无需 Linux / 无需编译整个内核）
#
#   bash layout/run_layout.sh
#
# 依赖：Android NDK (clang / llvm-objdump / llvm-dwarfdump)、python3
set -euo pipefail
cd "$(dirname "$0")"

NDK_BIN=${NDK_BIN:-/c/tools/android-sdk/ndk/29.0.14206865/toolchains/llvm/prebuilt/windows-x86_64/bin}
CL_INC=${CL_INC:-$NDK_BIN/../lib/clang/21/include}

if [ -f ../kernel/Makefile ]; then K=../kernel
elif [ -f kernel/Makefile ]; then K=kernel
else echo "找不到内核源码：先跑 scripts/fetch-source.sh"; exit 1; fi

if [ -f ../config/device.config.gz ]; then CFG=../config/device.config.gz
elif [ -f config/device.config.gz ]; then CFG=config/device.config.gz
else echo "找不到 config/device.config.gz"; exit 1; fi

BASE_FLAGS="--target=aarch64-linux-gnu -nostdinc -isystem $CL_INC
 -include $K/include/linux/kconfig.h -include include/generated/autoconf.h
 -fno-builtin -Iinclude -Igen -I$K/kernel/locking
 -I$K/include -I$K/arch/arm64/include -I$K/include/uapi -I$K/arch/arm64/include/uapi"

echo "[1/5] autoconf.h  <- $CFG"
python3 gen_autoconf.py "$CFG" .

echo "[2/5] asm-generic 转接头"
python3 - "$K" <<'PY'
import os, re, sys
K = sys.argv[1]; out = 'gen/asm'; os.makedirs(out, exist_ok=True)
names = set()
for kb in ('arch/arm64/include/asm/Kbuild', 'arch/arm64/include/uapi/asm/Kbuild'):
    p = os.path.join(K, kb)
    if not os.path.exists(p):
        continue
    for line in open(p):
        m = re.match(r'\s*generic-y\s*\+=\s*(\S+)', line)
        if m:
            names.add(m.group(1))
for n in sorted(names):
    open(os.path.join(out, n), 'w', newline='\n').write('#include <asm-generic/%s>\n' % n)
print('  %d headers' % len(names))
PY

echo "[3/5] 编译探针（DWARF 全字段）"
$NDK_BIN/clang.exe $BASE_FLAGS -c -g -O0 probe.c -o probe.o
$NDK_BIN/llvm-dwarfdump.exe --debug-info probe.o > probe.dwarf.txt
python3 dump_offsets.py probe.dwarf.txt task_struct cred file_operations \
	pipe_inode_info miscdevice rt_mutex rt_mutex_waiter pipe_buffer > offsets_dump.txt
echo "  -> probe.dwarf.txt / offsets_dump.txt"

echo "[4/5] 编译期常量（.rodata）"
$NDK_BIN/clang.exe $BASE_FLAGS -c -O0 probe2.c -o probe2.o
$NDK_BIN/llvm-objdump.exe -s -j .rodata probe2.o | sed -n '1,20p'

echo "[5/5] 校验 offsets_verified.h（任何一条不符合会编译失败）"
$NDK_BIN/clang.exe $BASE_FLAGS -c -O0 -include offsets_verified.h check_offsets.c -o check_offsets.o \
	&& echo "  OK: offsets_verified.h 与源码布局一致"
