#!/usr/bin/env bash
# 拉取与出厂固件同版本的两套工具链（clang 10.0.6 + gcc-4.9 binutils）
set -euo pipefail

TC=${TC:-$PWD/toolchain}
mkdir -p "$TC"

GCC_URL="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/heads/android10-release.tar.gz"
CLANG_URL="https://github.com/Cyborg2017/prebuilts_clang_host_linux-x86_clang-r365631c/archive/refs/heads/master.tar.gz"

if [ ! -x "$TC/gcc-4.9/bin/aarch64-linux-android-ld" ]; then
	echo "==> gcc-4.9 binutils"
	curl -fL --retry 3 --retry-delay 2 -o /tmp/gcc-4.9.tar.gz "$GCC_URL"
	rm -rf "$TC/gcc-4.9"
	mkdir -p "$TC/gcc-4.9"
	tar xzf /tmp/gcc-4.9.tar.gz -C "$TC/gcc-4.9"
fi

if [ ! -x "$TC/clang-10/bin/clang" ]; then
	echo "==> clang 10.0.6 (AOSP clang-r365631c)"
	curl -fL --retry 3 --retry-delay 2 -o /tmp/clang-10.tar.gz "$CLANG_URL"
	rm -rf /tmp/clang-10 "$TC/clang-10"
	mkdir -p /tmp/clang-10
	tar xzf /tmp/clang-10.tar.gz -C /tmp/clang-10 --strip-components=1
	mv /tmp/clang-10 "$TC/clang-10"
fi

# 老 AOSP clang 动态链接 libtinfo.so.5，Ubuntu 22.04 只有 libtinfo.so.6
if ldd "$TC/clang-10/bin/clang" 2>/dev/null | grep -q "libtinfo.so.5 => not found"; then
	TI6=$(ldconfig -p | awk '/libtinfo\.so\.6 /{print $NF; exit}')
	echo "==> shim libtinfo.so.5 -> $TI6"
	sudo ln -sf "$TI6" /usr/lib/x86_64-linux-gnu/libtinfo.so.5
fi

echo "==> toolchain versions"
"$TC/clang-10/bin/clang" --version | head -2
"$TC/gcc-4.9/bin/aarch64-linux-android-ld" --version | head -1
"$TC/gcc-4.9/bin/aarch64-linux-android-as" --version | head -1
