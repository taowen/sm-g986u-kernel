# layout/ —— 结构体偏移（不需要 Linux）

用官方源码 + 设备 `/proc/config.gz`，让**编译器**告诉你每个字段在哪。不是手算，不是抄别人的表。

## 跑法

源码解到 `kernel/`（`bash scripts/fetch-source.sh`），然后：

```bash
bash layout/run_layout.sh
```

需要 `python3` 和 Android NDK 的 clang（`NDK_BIN` 可覆盖）。

## 原理

1. `config/device.config.gz` → `include/generated/autoconf.h`
   （设备的 resolved config 才是真值；defconfig 只有非默认项，缺依赖推导）
2. 按 `arch/arm64/include/{,uapi/}asm/Kbuild` 的 `generic-y` 生成 `gen/asm/*.h` 转接头
   （内核构建时由 `scripts/Makefile.asm-generic` 生成，这里手工补上）
3. NDK clang 编一个只含 `offsetof()` 的 TU：
   ```
   clang --target=aarch64-linux-gnu -nostdinc \
         -include kernel/include/linux/kconfig.h -include include/generated/autoconf.h \
         -Iinclude -Igen -Ikernel/include -Ikernel/arch/arm64/include ...
   ```
   → 常量落在 `.rodata`，`llvm-objdump -s -j .rodata` 读回来
4. 要**全字段**就加 `-g` + `llvm-dwarfdump` + `dump_offsets.py`（按 DWARF 树还原绝对偏移）
5. `check_offsets.c` 用 `_Static_assert` 把 `offsets_verified.h` 里每个宏和真实布局对账

## 为什么能信

- 结构体布局由 ABI + 配置决定，**与 clang 版本无关**（这里用 clang 21 算 4.19 的布局完全有效）
- 和运行时对账：`/proc/slabinfo` 的 objsize（64B 对齐）与算出来的 `sizeof` 一致 9/9，
  含 `task_struct` 3904=3904 —— 这个总大小对上了，基本排除"配置不同"的可能
- 与设备 config 里 `CONFIG_FAST_TRACK` / `CONFIG_KPERFMON` 的副作用一致（`struct mutex` = 0x40）

## 已发现的两个坑

| 结构体 | 通用 4.19 | 本机 | 原因 |
|---|---|---|---|
| `pipe_inode_info` | nrbufs `0x38`、bufs `0x78` | nrbufs **`0x60`**、bufs **`0xa0`** | `mutex` 0x20 → **0x40** |
| `configfs_buffer` | needs_read_fill `0x40`、bin_buffer `0x48` | **`0x60`** / **`0x68`** | 同上 |

照抄公开的 4.19 表，堆喷对象大小和写偏移会一起错，症状是"跑到一半再崩"。
