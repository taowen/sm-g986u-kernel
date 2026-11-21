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

# 三星的 CFP（Code Flow Protection）后处理需要：python2 + 打过补丁的编译器
# （往函数入口/出口塞 NOP 的那版）。两者都拿不到，这里跳过链接后插桩，
# 否则 vmlinux 链接完就断在 `python scripts/cfp/instrument.py`。
if [ "${SKIP_CFP:-1}" = "1" ]; then
	python3 - <<'EOF'
p = 'kernel/scripts/link-vmlinux.sh'
s = open(p, encoding='utf-8', errors='surrogateescape').read()
old = 'if [ -n "${CONFIG_CFP}" ]; then'
new = 'if [ -n "${CONFIG_CFP_CI_DISABLED}" ]; then  # CI: 缺厂商插桩工具链，跳过'
if old in s and 'CONFIG_CFP_CI_DISABLED' not in s:
    open(p, 'w', encoding='utf-8', errors='surrogateescape').write(s.replace(old, new, 1))
    print('==> CFP post-link instrumentation disabled')
EOF
fi

echo "==> defconfig (vendor/y2q_usa_singlew_defconfig)"
make -C kernel "${ARGS[@]}" vendor/y2q_usa_singlew_defconfig

echo "==> build Image (-j$JOBS)"
make -C kernel "${ARGS[@]}" -j"$JOBS" Image

echo "==> done"
ls -la "$OUT/arch/arm64/boot/Image" "$OUT/System.map" "$OUT/vmlinux"
