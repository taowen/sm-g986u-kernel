#!/usr/bin/env bash
# 验证「自建内核」与「设备上的内核」是不是同一套链接布局。
#
#   adb shell "cat /proc/kallsyms" | awk '{print $3}' > device-kallsyms-names.txt
#   bash scripts/compare-kallsyms.sh device-kallsyms-names.txt [System.map]
#
# 设备侧 kptr_restrict=2，地址是 0，但符号名与顺序是真的。
# 顺序一致 => 链接布局一致 => target_symbols.h 的偏移可信。
set -euo pipefail

DEV=${1:?usage: compare-kallsyms.sh <device-names.txt> [System.map]}
MAP=${2:-${ART:-$PWD/artifacts}/System.map}
[ -f "$MAP" ] || { echo "missing $MAP"; exit 1; }

awk 'NF>=3 && $3!="" {print $3}' "$MAP" > /tmp/local.names
grep -v '^$' "$DEV" > /tmp/device.names

LN=$(wc -l < /tmp/local.names)
DN=$(wc -l < /tmp/device.names)
echo "local : $LN symbols"
echo "device: $DN symbols"

SAME=$(comm -12 <(sort /tmp/local.names) <(sort /tmp/device.names) | wc -l)
echo "common: $SAME  ($(awk -v s="$SAME" -v l="$LN" 'BEGIN{printf "%.2f%%", s*100/l}') of local)"

echo "--- 第一个分歧（按地址顺序）---"
diff /tmp/local.names /tmp/device.names | head -20 || true

echo
if [ "$SAME" -ge $((LN * 95 / 100)) ]; then
	echo "结论: 符号集合高度重合，可以认为同源构建；建议再抽查 10 个符号的相邻关系。"
else
	echo "结论: 重合度不足 95%，这棵树/这套工具链与出厂固件不是同一次构建，偏移不能直接用。"
fi
