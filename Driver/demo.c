#include "demo.h"

static int __init demo_init(void)
{
    int ret;

    ENTER_FUNC;
    ret = setup_char_dev(&Dev_Struct.param, name);
    Dev_Struct.buf = (char *)kmalloc(BUF_SIZE, GFP_KERNEL);
    if(!Dev_Struct.buf){
        PRT_ERR("Failed to malloc buf\n");
        return -ENOMEM;
    }
    memset(Dev_Struct.buf, 0, BUF_SIZE);
    PRT_INFO("Init done\n");
    return ret; 
}

static void __exit demo_exit(void)
{
    ENTER_FUNC;
    rm_char_dev(&Dev_Struct.param);
    kfree(Dev_Struct.buf);
    PRT_INFO("Exit done\n");
}

static int demo_open(struct inode *inode, struct file *file)
{
    ENTER_FUNC;
    file->private_data = (void *)&Dev_Struct;
    return 0;
}
static int demo_release(struct inode *inode, struct file *file)
{
    ENTER_FUNC;
    return 0;
}
static ssize_t demo_read(struct file *file, char __user *buf, size_t size, loff_t *pos)
{
    int ret, read_bytes;
    dev_struct *ptr_dev = (dev_struct *)file->private_data;
    char *kbuf = ptr_dev->buf + *pos;

    ENTER_FUNC;

    CHECK_POS(size, read_bytes);

    ret = copy_to_user(buf, kbuf, read_bytes);
    if(ret){
        return -EFAULT;
    }

    *pos += read_bytes;

    return read_bytes;
}
static ssize_t demo_write(struct file *file, const char __user *buf, size_t size, loff_t *pos)
{
    int ret, write_bytes;
    dev_struct *ptr_dev = (dev_struct *)file->private_data;
    char *kbuf = ptr_dev->buf + *pos;

    ENTER_FUNC;
    
    CHECK_POS(size, write_bytes);

    ret = copy_from_user(kbuf, buf, write_bytes);
    if(ret){
        return -EFAULT;
    }
    
    *pos += write_bytes;

    return write_bytes;
}

static long demo_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
{
    int ret = 0;
    dev_struct *ptr_dev = (dev_struct *)file->private_data;
    
    ENTER_FUNC;
    switch(cmd){
        case DEMO_CLEAN:
            PRT_INFO("cmd-clean");
            memset(ptr_dev->buf, 0, BUF_SIZE);
            break;
        case DEMO_GETVAL:
            PRT_INFO("cmd-getval");
            put_user(ptr_dev->val, (int*)arg);
            break;
        case DEMO_SETVAL:
            PRT_INFO("cmd-setval");
            ptr_dev->val = (int)arg;
            break;
        default:
            break;
    }

    return (long)ret;
}

module_init(demo_init);
module_exit(demo_exit);

MODULE_LICENSE("GPL");//Must add, otherwise cannot find symbol