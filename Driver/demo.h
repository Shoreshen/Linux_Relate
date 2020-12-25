#include "iocmd.h"
#define C_NAME(name, i) "%s", name
#include "Devlib.h"

#define name "demo"
#define BUF_SIZE 1024

static int demo_open(struct inode *inode, struct file *file);
static int demo_release(struct inode *inode, struct file *file);
static ssize_t demo_read(struct file *file, char __user *buf, size_t size, loff_t *pos);
static ssize_t demo_write(struct file *file, const char __user *buf, size_t size, loff_t *pos);
static long demo_ioctl(struct file *ioctl, unsigned int cmd, unsigned long arg);

static struct file_operations f_op = {
    .owner      = THIS_MODULE,
    .open       = demo_open,
    .read       = demo_read,
    .release    = demo_release,
    .write      = demo_write,
    .unlocked_ioctl = demo_ioctl,
};
struct cdev demo_cdev;

typedef struct{
    int val;
    char* buf;
    param_cdev param;
} dev_struct;

dev_struct Dev_Struct = {
    .param.cdev = &demo_cdev,
    .param.f_op = &f_op,
    .param.count = 1,
    .val = 0,
    .buf = NULL,
};