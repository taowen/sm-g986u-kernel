#!/usr/bin/env bash
# 用真实构建出来的 vmlinux（CONFIG_DEBUG_INFO=y）反查结构体布局，
# 与仓库里的 layout/offsets_verified.h 对照。
set -euo pipefail

OUT=${OUT:-$PWD/out}
ART=${ART:-$PWD/artifacts}
VMLINUX=$OUT/vmlinux

[ -f "$VMLINUX" ] || { echo "missing $VMLINUX"; exit 1; }

if ! command -v pahole >/dev/null 2>&1; then
	echo "pahole not found (apt-get install -y dwarves); skip"
	exit 0
fi

mkdir -p "$ART"
for s in task_struct cred file_operations pipe_inode_info configfs_buffer \
	 rt_mutex_waiter rt_mutex miscdevice; do
	pahole -C "$s" "$VMLINUX" > "$ART/pahole-$s.txt" 2>/dev/null || true
done

echo "==> task_struct 关键字段"
grep -E "^\s+(struct cred|const struct cred|char comm|struct files_struct|struct fs_struct|struct list_head tasks|raw_spinlock_t pi_lock|struct rb_root_cached pi_waiters|struct task_struct \*pi_top_task|struct rt_mutex_waiter \*pi_blocked_on)" \
	"$ART/pahole-task_struct.txt" 2>/dev/null || echo "(pahole 没输出，可能 vmlinux 无 DWARF)"

echo "==> 与 layout/offsets_verified.h 对照（人工看一眼即可）"
echo "  期望: real_cred 0x7f0 / cred 0x7f8 / comm 0x800 / pi_blocked_on 0x8f8 / size 0xf40"
