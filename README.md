# sm-g986u-kernel

在 GitHub Actions 上编译 **三星 Galaxy S20+ 5G（SM-G986U / `y2q`）的官方开源内核 4.19.113**，
产出 `System.map` / `vmlinux` / 符号偏移表，用于**离线**做内核漏洞移植评估（CVE-2026-43499 / GhostLock）。

Build the stock Samsung 4.19.113 kernel for SM-G986U (Galaxy S20+ 5G) on a GitHub runner and
publish `System.map`, `vmlinux` and a generated `target_symbols.h` — no Linux host required.

---

## 为什么需要这个

在 `SM-G986U`（VZW、rev U3、bootloader 锁死）上做 CVE-2026-43499 的移植评估时，缺两类东西：

| 缺什么 | 为什么设备上拿不到 | 这个仓库怎么解决 |
|---|---|---|
| 结构体偏移（`task_struct` / `cred` / `pipe_inode_info` …） | —— | `layout/`：源码 + 设备 config 直接算，见下文 |
| 符号地址（`ashmem_fops` / `init_task` / `selinux_state` …） | `/proc/kallsyms` 被 SELinux 拒且 `kptr_restrict=2`，`boot` 分区 `brw------- root root` 不可读 | 编译同源内核 → `System.map` |

三星开源包只给源码、不给 `vmlinux`；本地又没有 Linux/Docker。公共仓库的 Actions runner 正好是
免费的 Linux + 4 核，于是把「编译」这一步搬上去。

## 产出的东西

`workflow_dispatch` 跑完后，artifact `kernel-out` 里：

| 文件 | 内容 |
|---|---|
| `System.map` | 完整符号表（`CONFIG_KALLSYMS_ALL=y`，含 `static` 符号） |
| `Image` | 未压缩内核镜像 |
| `vmlinux.stripped` | 去掉 debug 段的 `vmlinux`，可直接反汇编 |
| `target_symbols.h` | 24 个关键符号相对 `_text` 的偏移（**注意下面的局限说明，不能直接用于出厂固件**） |
| `kallsyms-names.txt` | 按地址排序的符号名（用来和设备侧 `/proc/kallsyms` 对顺序） |
| `config.diff` | 本次 `.config` 与设备 `/proc/config.gz` 的差异 |

`layout/offsets_verified.h` 是结构体偏移（本仓库自带，已与设备 `/proc/slabinfo` 交叉验证 9/9）。

## 工具链（为什么不用 apt 里的 clang）

设备 `/proc/version`：

```
Linux version 4.19.113-25305888 (dpi@SWDK6904) (clang version 10.0.6 for Android NDK) #1 SMP PREEMPT
```

`build_kernel.sh` 要求 `toolchain/llvm-arm-toolchain-ship/10.0/bin/clang` + `aarch64-linux-android-4.9` 的 binutils。

- binutils **4.9** 好办：`prebuilts/gcc/.../aarch64-linux-android-4.9`（googlesource `android10-release`）公开可得
- clang **10.0.6 for Android NDK** 是**三星/高通 BSP 里的私有构建**，公开渠道没有镜像。
  这里用最接近的 **AOSP clang 10.0.5（r377782c）**：AOSP 侧 10.0.4 = r377782b、10.0.5 = r377782c，
  10.0.6 只有厂商内部版本

> **这是本项目已知的最大不确定性，而且不止工具链一处。** 三星这颗内核还带
> `CONFIG_CFP=y` / `CONFIG_CFP_ROPP=y`：链接后要跑 `scripts/cfp/instrument.py` 往每个函数
> 入口/出口的 NOP 槽里插桩，**而那版编译器（会主动塞 NOP 的定制 clang/gcc）和 python2 都拿不到**。
> 本项目默认跳过这段插桩（`SKIP_CFP=1`，见 `scripts/build.sh`）。
>
> 结论：**产物里的符号偏移不能直接当 `target.h` 用** —— 缺插桩填充 + 工具链差一个补丁级，
> 函数排布已经和出厂固件不同。它适合用来：确认符号是否存在、看 struct 布局、验证编译链、
> 以及给以后拿到厂商工具链时做回归基线。**要精确偏移，仍然得从 `boot.img` 的 kallsyms 取。**

用 apt 的 clang-12 / gcc-11 也能编，但函数排布差得更远，符号偏移基本不可用，所以不省这一步。
（顺带：`gcc 11` 的 `-fno-common` 默认值会让 4.19 的 `scripts/dtc` 链接失败，脚本里加了 `HOSTCFLAGS=-fcommon`。）

## 怎么跑

```
gh workflow run build.yml -R taowen/sm-g986u-kernel
gh run watch -R taowen/sm-g986u-kernel
```

或者网页上 Actions → build → Run workflow。跑完在 run 页面底部下载 `kernel-out`。

首次约 60~90 分钟（4 核 + `CONFIG_DEBUG_INFO=y`）；工具链有 `actions/cache`，第二次省 3~5 分钟。

## 怎么用产物（关键一步：验证同源）

**同源代码 ≠ 同源二进制。** 编译器小版本、binutils、甚至链接顺序变了，函数地址就会漂。
所以拿到 `System.map` 后必须先验证，再拿去当 `target.h`：

```bash
# 设备侧：只取符号名（地址是 0，但名字和顺序是真的）
adb shell "cat /proc/kallsyms" | awk '{print $3}' > device-kallsyms-names.txt

# 和构建产物的符号顺序对比（数量 + 逐行）
diff <(awk '{print $3}' System.map) device-kallsyms-names.txt | head
```

- 两个列表**长度、顺序基本一致** → 链接布局一致，`target_symbols.h` 可用
- 差很多 → 说明这棵树/这套工具链和出厂固件不是同一次构建，偏移不能直接用（但结构体偏移仍然有效）

仓库里 `scripts/compare-kallsyms.sh` 就是干这个的。

## 首次构建结果（2026-11-21，run 44867433642，17 分钟）

| 项 | 结果 |
|---|---|
| 编译 | `make -j4` 通，`LD vmlinux` → `SYSMAP System.map` → `OBJCOPY Image`（51.8 MB / `System.map` 6.2 MB） |
| 符号 | 24/24 全部命中（`_text` 起算，`_text = 0xffffff8008080000`） |
| **配置一致性** | 本次 `.config` vs 设备 `/proc/config.gz`：只差 30 来行 `# CONFIG_XXX is not set` 注释 + 编译器版本行 → **defconfig 就是出厂配置** |
| **结构体布局** | `pahole` 读这次 vmlinux 的 DWARF：`cred 0x7f8`、`comm 0x800`、`pi_blocked_on 0x8f8`、`mutex 0x40`、`nrbufs 0x60`、`configfs.bin_buffer 0x68` —— 与 `layout/offsets_verified.h` 逐项相同 |
| 地址可用性 | ❌ 差一层 CFP 插桩（见上文），函数排布与出厂固件不同 |

所以这个仓库现在的价值是：**证明结构体偏移正确 + 提供一份可复现的基线**，
而不是「一键产出 `target.h` 地址」。真要地址，还是得从 `boot.img` 的 kallsyms 取。

`Image` 里也能看出这层插桩的痕迹：三星的 `scripts/cfp/instrument.py` 会在每个函数入口/出口
（`stp x29,x30` / `ldp x29,x30` 前后）预留 NOP 槽，那些 NOP 是定制编译器主动塞的，普通 clang 不生成。

## 结构体偏移（`layout/`）

不依赖 Linux，只要有 python3 + Android NDK 的 clang：

```bash
bash layout/run_layout.sh     # 需要先在 kernel/ 放好源码，见 scripts/fetch-source.sh
```

原理：`reference` config → `include/generated/autoconf.h` → 编一个只含 `offsetof()` 的 TU →
从 `.rodata` 读回编译期常量 → `_Static_assert` 逐条对账。详见 `layout/README.md`。

已与设备 `/proc/slabinfo` 的 objsize 对上（64B 对齐后）：`task_struct` 3904=3904、
`cred` 200→256、`file` 328→384、`files` 704、`signal` 1072→1088、`sighand` 2104→2112、
`mm` 968→1024、`pid` 104→128、`dentry` 208、`vma` 192 —— 9/9。

## 源码出处

`Kernel.tar.gz`（215,891,343 B）原样取自三星开源发布中心：

- 包：`SM-G986U_NA_13_Opensource.zip`（对应固件 `G986USQU3GVK1`，Android 13）
- sha256：`a907ee24ad6bfd13df438f13e05a9179d8a5dece4257985bfc12236c6acfbe09`
- 本仓库 Release `source-v1` 里有一份未修改的镜像，CI 直接从那里下载

详见 [SOURCE.md](SOURCE.md)。

## 声明

- 内核源码版权归三星及各自权利人，**GPL-2.0**（见 [LICENSE](LICENSE)）；本仓库只是原样再分发 + 构建脚本。
- 构建脚本同样以 GPL-2.0 发布。
- 本项目面向**自有设备的内核漏洞研究与移植可行性评估**。不要用它做未授权的事。
- 破解他人设备、绕过他人设备的访问控制可能违法。使用者自担责任。
