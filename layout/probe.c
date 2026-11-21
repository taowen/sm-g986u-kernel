#define __KERNEL__
#include <linux/sched.h>
#include <linux/cred.h>
#include <linux/fs.h>
#include <linux/pipe_fs_i.h>
#include <linux/miscdevice.h>
#include <linux/rtmutex.h>
#include <rtmutex_common.h>

struct probe_sizes {
	struct task_struct t;
	struct cred c;
	struct file_operations f;
	struct pipe_inode_info p;
	struct miscdevice m;
	struct rt_mutex_waiter w;
};
volatile struct probe_sizes *probe_anchor;
