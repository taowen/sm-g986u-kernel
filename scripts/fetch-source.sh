#!/usr/bin/env bash
# 下载并解压三星官方内核源码包，校验 sha256
set -euo pipefail

EXPECT=a907ee24ad6bfd13df438f13e05a9179d8a5dece4257985bfc12236c6acfbe09
REPO=${GITHUB_REPOSITORY:-taowen/sm-g986u-kernel}
URL=${SOURCE_URL:-https://github.com/$REPO/releases/download/source-v1/Kernel.tar.gz}
TARBALL=${TARBALL:-/tmp/Kernel.tar.gz}

if [ -f kernel/Makefile ] && [ -d kernel/arch/arm64 ]; then
	echo "==> kernel source already extracted"
	exit 0
fi

if [ ! -f "$TARBALL" ] || ! echo "$EXPECT  $TARBALL" | sha256sum -c - >/dev/null 2>&1; then
	echo "==> downloading $URL"
	curl -fL --retry 3 --retry-delay 3 -o "$TARBALL" "$URL"
fi

echo "==> verifying sha256"
echo "$EXPECT  $TARBALL" | sha256sum -c -

echo "==> extracting"
rm -rf kernel
mkdir -p kernel
tar xzf "$TARBALL" -C kernel

grep -m1 -E "^(VERSION|PATCHLEVEL|SUBLEVEL)" kernel/Makefile >/dev/null
VER=$(awk '/^VERSION =/{v=$3} /^PATCHLEVEL =/{p=$3} /^SUBLEVEL =/{s=$3} END{print v"."p"."s}' kernel/Makefile)
echo "==> kernel version: $VER"
du -sh kernel
