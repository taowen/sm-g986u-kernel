#define __KERNEL__
#include <linux/sched.h>
#include <linux/cred.h>
#include <linux/fs.h>
#include <linux/pipe_fs_i.h>
#include <linux/miscdevice.h>
#include <linux/rtmutex.h>
#include <rtmutex_common.h>

const unsigned long probe_values[] = {
  __builtin_offsetof(struct task_struct, thread_info.flags),
  __builtin_offsetof(struct task_struct, thread_info.addr_limit),
  __builtin_offsetof(struct task_struct, thread_info.preempt_count),
  __builtin_offsetof(struct task_struct, state),
  __builtin_offsetof(struct task_struct, stack),
  __builtin_offsetof(struct task_struct, usage),
  __builtin_offsetof(struct task_struct, flags),
  __builtin_offsetof(struct task_struct, tasks),
  __builtin_offsetof(struct task_struct, mm),
  __builtin_offsetof(struct task_struct, active_mm),
  __builtin_offsetof(struct task_struct, pid),
  __builtin_offsetof(struct task_struct, tgid),
  __builtin_offsetof(struct task_struct, real_cred),
  __builtin_offsetof(struct task_struct, cred),
  __builtin_offsetof(struct task_struct, comm),
  __builtin_offsetof(struct task_struct, fs),
  __builtin_offsetof(struct task_struct, files),
  __builtin_offsetof(struct task_struct, pi_lock),
  __builtin_offsetof(struct task_struct, pi_waiters),
  __builtin_offsetof(struct task_struct, pi_top_task),
  __builtin_offsetof(struct task_struct, pi_blocked_on),
  __builtin_offsetof(struct task_struct, thread.cpu_context),
  __builtin_offsetof(struct task_struct, real_parent),
  __builtin_offsetof(struct task_struct, parent),
  __builtin_offsetof(struct cred, uid),
  __builtin_offsetof(struct cred, cap_permitted),
  __builtin_offsetof(struct cred, cap_effective),
  __builtin_offsetof(struct cred, security),
};
const unsigned long probe_meta[] = { sizeof(struct task_struct), sizeof(struct cred), sizeof(struct file_operations), sizeof(struct pipe_inode_info), sizeof(struct rt_mutex_waiter), sizeof(struct miscdevice) };
