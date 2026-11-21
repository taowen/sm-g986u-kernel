/*
 * offsets_verified.h - SM-G986U (y2q) / 4.19.113-25305888
 *
 * 来源：官方开源包 sm-986u Kernel.tar.gz（4.19.113）+ 设备解析后 config.gz，
 *      用 NDK clang 编一个只做 offsetof 的 TU（见 layout/probe2.c），
 *      从 .rodata 读回编译期常量。不是手算、也不是从 K40 抄的。
 *
 * 复现： bash layout/run_layout.sh
 *
 * 可信度：
 *   [A] 编译器 offsetof（构造/ABI 直接决定，与 clang 版本无关）
 *   [B] 编译器 sizeof
 *
 * 注意：本文件只解决「结构体布局」。符号地址（kallsyms）与 KASLR slide
 *      仍然只能从 boot.img / vmlinux 取，见 PORTING_ASSESSMENT.md §4.2/§4.3。
 */
#ifndef Y2Q_OFFSETS_VERIFIED_H
#define Y2Q_OFFSETS_VERIFIED_H

/* -------- 内核身份 -------- */
/* uname -r        : 4.19.113-25305888            (设备实测) */
/* 源码 Makefile   : VERSION 4 PATCHLEVEL 19 SUBLEVEL 113 */
/* defconfig       : arch/arm64/configs/vendor/y2q_usa_singlew_defconfig */

/* -------- task_struct  [A] -------- */
#define TASK_THREAD_INFO_OFF        0x0000
#define TASK_STATE_OFF              0x0058
#define TASK_STACK_OFF              0x0060
#define TASK_USAGE_OFF              0x0068
#define TASK_FLAGS_OFF              0x006c
#define TASK_TASKS_OFF              0x0540
#define TASK_MM_OFF                 0x0590
#define TASK_ACTIVE_MM_OFF          0x0598
#define TASK_PID_OFF                0x0640
#define TASK_TGID_OFF               0x0644
#define TASK_REAL_PARENT_OFF        0x0650
#define TASK_PARENT_OFF             0x0658
#define TASK_REAL_CRED_OFF          0x07f0   /* K40 = 0x7e0，差 +0x10 */
#define TASK_CRED_OFF               0x07f8
#define TASK_COMM_OFF               0x0800   /* K40 = 0x7f0 */
#define TASK_FS_OFF                 0x0818
#define TASK_FILES_OFF              0x0820
#define TASK_PI_LOCK_OFF            0x08c8
#define TASK_PI_WAITERS_OFF         0x08e0
#define TASK_PI_TOP_TASK_OFF        0x08f0
#define TASK_PI_BLOCKED_ON_OFF      0x08f8   /* GhostLock 关键字段 */
#define TASK_THREAD_CPU_CTX_OFF     0x0b40
#define TASK_STRUCT_SZ              0x0f40   /* [B] 3904 B */

/* -------- cred  [A] -------- */
#define CRED_UID_OFF                0x0004
#define CRED_SECUREBITS_OFF         0x0024
#define CRED_CAP_INHERITABLE_OFF    0x0028
#define CRED_CAP_PERMITTED_OFF      0x0030
#define CRED_CAP_EFFECTIVE_OFF      0x0038
#define CRED_CAP_BSET_OFF           0x0040
#define CRED_CAP_AMBIENT_OFF        0x0048
#define CRED_SECURITY_OFF           0x0078
#define CRED_USER_NS_OFF            0x0088
/* CONFIG_KDP_CRED 在尾部追加 4 个字段，对象比通用 4.19 大 0x20 */
#define CRED_USE_CNT_OFF            0x00a8
#define CRED_BP_TASK_OFF            0x00b0
#define CRED_BP_PGD_OFF             0x00b8
#define CRED_KDP_TYPE_OFF           0x00c0
#define CRED_STRUCT_SZ              0x00c8   /* [B] 200 B（通用 4.19 为 0xa8） */

/* -------- file_operations  [A]（与 K40 完全一致） -------- */
#define FOP_LLSEEK_OFF              0x0008
#define FOP_READ_OFF                0x0010
#define FOP_WRITE_OFF               0x0018
#define FOP_READ_ITER_OFF           0x0020
#define FOP_WRITE_ITER_OFF          0x0028
#define FOP_POLL_OFF                0x0040
#define FOP_UNLOCKED_IOCTL_OFF      0x0048
#define FOP_COMPAT_IOCTL_OFF        0x0050
#define FOP_MMAP_OFF                0x0058
#define FOP_OPEN_OFF                0x0068
#define FOP_RELEASE_OFF             0x0078
#define FOP_SPLICE_WRITE_OFF        0x00b8
#define FOP_SPLICE_READ_OFF         0x00c0
#define FOP_SHOW_FDINFO_OFF         0x00d8
#define FILE_OPERATIONS_SZ          0x0100   /* [B] */

/* -------- pipe_inode_info  [A]（与文档旧表不同！） -------- */
/* 本机 struct mutex 被 CONFIG_FAST_TRACK + CONFIG_KPERFMON 撑到 0x40，
 * 所以 nrbufs 不是 0x38 而是 0x60，整张表整体后移 0x28。 */
#define PIPE_NRBUFS_OFF             0x0060
#define PIPE_CURBUF_OFF             0x0064
#define PIPE_BUFFERS_OFF            0x0068
#define PIPE_READERS_OFF            0x006c
#define PIPE_WRITERS_OFF            0x0070
#define PIPE_FILES_OFF              0x0074
#define PIPE_WAITING_WRITERS_OFF    0x0078
#define PIPE_BUFS_OFF               0x00a0
#define PIPE_USER_OFF               0x00a8
#define PIPE_INODE_INFO_SZ          0x00b0   /* [B] 176 B */

/* -------- miscdevice  [A]（与 K40 一致） -------- */
#define MISCDEV_MINOR_OFF           0x0000
#define MISCDEV_NAME_OFF            0x0008
#define MISCDEV_FOPS_OFF            0x0010   /* ashmem_misc + 0x10 */
#define MISCDEV_SZ                  0x0050   /* [B] */

/* -------- rt_mutex / rt_mutex_waiter  [A]（与 K40 一致） -------- */
#define WAITER_TREE_ENTRY_OFF       0x0000
#define WAITER_PI_TREE_ENTRY_OFF    0x0018
#define WAITER_TASK_OFF             0x0030
#define WAITER_LOCK_OFF             0x0038
#define WAITER_PRIO_OFF             0x0040
#define WAITER_DEADLINE_OFF         0x0048
#define RT_MUTEX_WAITER_SZ          0x0050   /* [B]；无 wake_state / ww_ctx */
#define RTM_WAIT_LOCK_OFF           0x0000
#define RTM_WAITERS_OFF             0x0010
#define RTM_OWNER_OFF               0x0020
#define RT_MUTEX_SZ                 0x0028   /* [B] */

/* -------- configfs_buffer  [A]（本机 mutex 0x40，比旧表后移 0x20） -------- */
#define CFGBUF_COUNT_OFF            0x0000
#define CFGBUF_POS_OFF              0x0008
#define CFGBUF_PAGE_OFF             0x0010
#define CFGBUF_OPS_OFF              0x0018
#define CFGBUF_NEEDS_READ_FILL_OFF  0x0060
#define CFGBUF_BIN_BUFFER_OFF       0x0068
#define CFGBUF_BIN_BUFFER_SIZE_OFF  0x0070
#define CFGBUF_CB_MAX_SIZE_OFF      0x0074
#define CFGBUF_ITEM_OFF             0x0078
#define CFGBUF_OWNER_OFF            0x0080
#define CONFIGFS_BUFFER_SZ          0x0090   /* [B] */

/* -------- 其它常用 [B] -------- */
#define MUTEX_SZ                    0x0040   /* FAST_TRACK + KPERFMON */
#define PIPE_BUFFER_SZ              0x0028

#endif /* Y2Q_OFFSETS_VERIFIED_H */
