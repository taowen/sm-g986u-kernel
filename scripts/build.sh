#!/usr/bin/env bash
# 编译 Image（= vmlinux + Image），参数与三星 build_kernel.sh 对齐
set -euo pipefail

TC=${TC:-$PWD/toolchain}
OUT=${OUT:-$PWD/out}
JOBS=${JOBS:-$(nproc)}
LOCALVER=${KERNEL_LOCALVERSION:--25305888}

CROSS=$TC/gcc-4.9/bin/aarch64-linux-android-
CLANG=$TC/clang-10/bin/clang

[ -x "$CLANG" ] || { echo "missing $CLANG (run scripts/fetch-toolchain.sh)"; exit 1; }
[ -x "${CROSS}ld" ] || { echo "missing ${CROSS}ld (run scripts/fetch-toolchain.sh)"; exit 1; }
[ -f kernel/Makefile ] || { echo "missing kernel/ (run scripts/fetch-source.sh)"; exit 1; }

mkdir -p "$OUT"

# 让 scripts/setlocalversion 不去读外层仓库的 git（否则版本串会被追加 -g<hash>）
: > kernel/.scmversion

ARGS=(
	ARCH=arm64
	CROSS_COMPILE="$CROSS"
	CC="$CLANG"
	CLANG_TRIPLE=aarch64-linux-gnu-
	LOCALVERSION="$LOCALVER"
	HOSTCFLAGS=-fcommon
	O="$OUT"
)

echo "==> defconfig (vendor/y2q_usa_singlew_defconfig)"
make -C kernel "${ARGS[@]}" vendor/y2q_usa_singlew_defconfig

echo "==> build Image (-j$JOBS)"
make -C kernel "${ARGS[@]}" -j"$JOBS" Image

echo "==> done"
ls -la "$OUT/arch/arm64/boot/Image" "$OUT/System.map" "$OUT/vmlinux"
