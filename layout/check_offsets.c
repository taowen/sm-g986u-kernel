/* 把 offsets_verified.h 里每个常量与真实结构体布局对账；不符合就编译失败。 */
#define __KERNEL__
#include <linux/sched.h>
#include <linux/cred.h>
#include <linux/fs.h>
#include <linux/pipe_fs_i.h>
#include <linux/miscdevice.h>
#include <linux/rtmutex.h>
#include <rtmutex_common.h>
#include <linux/configfs.h>
#include <linux/mutex.h>

#define CHECK(st, field, macro) \
	_Static_assert(__builtin_offsetof(struct st, field) == (macro), \
		       #st "." #field " != " #macro)

#define CHECKSZ(st, macro) \
	_Static_assert(sizeof(struct st) == (macro), #st " size != " #macro)

CHECK(task_struct, thread_info, TASK_THREAD_INFO_OFF);
CHECK(task_struct, state, TASK_STATE_OFF);
CHECK(task_struct, stack, TASK_STACK_OFF);
CHECK(task_struct, usage, TASK_USAGE_OFF);
CHECK(task_struct, flags, TASK_FLAGS_OFF);
CHECK(task_struct, tasks, TASK_TASKS_OFF);
CHECK(task_struct, mm, TASK_MM_OFF);
CHECK(task_struct, active_mm, TASK_ACTIVE_MM_OFF);
CHECK(task_struct, pid, TASK_PID_OFF);
CHECK(task_struct, tgid, TASK_TGID_OFF);
CHECK(task_struct, real_parent, TASK_REAL_PARENT_OFF);
CHECK(task_struct, parent, TASK_PARENT_OFF);
CHECK(task_struct, real_cred, TASK_REAL_CRED_OFF);
CHECK(task_struct, cred, TASK_CRED_OFF);
CHECK(task_struct, comm, TASK_COMM_OFF);
CHECK(task_struct, fs, TASK_FS_OFF);
CHECK(task_struct, files, TASK_FILES_OFF);
CHECK(task_struct, pi_lock, TASK_PI_LOCK_OFF);
CHECK(task_struct, pi_waiters, TASK_PI_WAITERS_OFF);
CHECK(task_struct, pi_top_task, TASK_PI_TOP_TASK_OFF);
CHECK(task_struct, pi_blocked_on, TASK_PI_BLOCKED_ON_OFF);
CHECK(task_struct, thread.cpu_context, TASK_THREAD_CPU_CTX_OFF);

CHECK(cred, uid, CRED_UID_OFF);
CHECK(cred, securebits, CRED_SECUREBITS_OFF);
CHECK(cred, cap_inheritable, CRED_CAP_INHERITABLE_OFF);
CHECK(cred, cap_permitted, CRED_CAP_PERMITTED_OFF);
CHECK(cred, cap_effective, CRED_CAP_EFFECTIVE_OFF);
CHECK(cred, cap_bset, CRED_CAP_BSET_OFF);
CHECK(cred, cap_ambient, CRED_CAP_AMBIENT_OFF);
CHECK(cred, security, CRED_SECURITY_OFF);
CHECK(cred, user_ns, CRED_USER_NS_OFF);

CHECK(file_operations, llseek, FOP_LLSEEK_OFF);
CHECK(file_operations, read, FOP_READ_OFF);
CHECK(file_operations, write, FOP_WRITE_OFF);
CHECK(file_operations, unlocked_ioctl, FOP_UNLOCKED_IOCTL_OFF);
CHECK(file_operations, compat_ioctl, FOP_COMPAT_IOCTL_OFF);
CHECK(file_operations, mmap, FOP_MMAP_OFF);
CHECK(file_operations, open, FOP_OPEN_OFF);
CHECK(file_operations, release, FOP_RELEASE_OFF);
CHECK(file_operations, splice_read, FOP_SPLICE_READ_OFF);
CHECK(file_operations, show_fdinfo, FOP_SHOW_FDINFO_OFF);

CHECK(pipe_inode_info, nrbufs, PIPE_NRBUFS_OFF);
CHECK(pipe_inode_info, curbuf, PIPE_CURBUF_OFF);
CHECK(pipe_inode_info, buffers, PIPE_BUFFERS_OFF);
CHECK(pipe_inode_info, bufs, PIPE_BUFS_OFF);
CHECK(pipe_inode_info, user, PIPE_USER_OFF);

CHECK(miscdevice, fops, MISCDEV_FOPS_OFF);

CHECK(rt_mutex_waiter, tree_entry, WAITER_TREE_ENTRY_OFF);
CHECK(rt_mutex_waiter, pi_tree_entry, WAITER_PI_TREE_ENTRY_OFF);
CHECK(rt_mutex_waiter, task, WAITER_TASK_OFF);
CHECK(rt_mutex_waiter, lock, WAITER_LOCK_OFF);
CHECK(rt_mutex_waiter, prio, WAITER_PRIO_OFF);
CHECK(rt_mutex_waiter, deadline, WAITER_DEADLINE_OFF);

CHECKSZ(task_struct, TASK_STRUCT_SZ);
CHECKSZ(cred, CRED_STRUCT_SZ);
CHECKSZ(file_operations, FILE_OPERATIONS_SZ);
CHECKSZ(pipe_inode_info, PIPE_INODE_INFO_SZ);
CHECKSZ(miscdevice, MISCDEV_SZ);
CHECKSZ(rt_mutex_waiter, RT_MUTEX_WAITER_SZ);
CHECKSZ(mutex, MUTEX_SZ);
CHECKSZ(pipe_buffer, PIPE_BUFFER_SZ);

/* configfs_buffer 不是公开头文件里的类型，单独用 probe3.c 算（见 run_layout.sh） */
