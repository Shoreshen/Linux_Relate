#include <linux/init.h>
#include <linux/module.h>
#include <linux/cdev.h>
#include <linux/fs.h>
#include <linux/device.h>
#include <linux/slab.h>

#define ENTER_FUNC printk(KERN_INFO "Enter: %s\n", __func__)
#define PRT_ERR(msg) printk(KERN_ERR "%s: " msg, name)
#define PRT_INFO(msg) printk(KERN_INFO "%s: " msg, name)
#define CHECK_POS(SIZE, BYTES) \
        if(*pos >= BUF_SIZE) {\
            return 0;\
        }\
        if(SIZE >= (BUF_SIZE - *pos)) {\
            BYTES = BUF_SIZE - *pos;\
        }else{\
            BYTES = SIZE;\
        }

typedef struct{
    int count;
    int ma;
    int mi;
    struct cdev *cdev;
    const struct file_operations *f_op;
    struct class *cls;
} param_cdev;

static inline int setup_char_dev(param_cdev *param, char *name)
{
    int ret = -1, i, j;
    dev_t dev_no;
    struct device *devp = NULL;

    //char device initialization
    if(!param->cdev){
        param->cdev = cdev_alloc();
        if(!param->cdev){
            PRT_ERR("cdev_alloc failed\n");
            return -ENOMEM;
        }
        param->cdev->ops = param->f_op;
    } else{
        cdev_init(param->cdev, param->f_op);
    }
    param->cdev->owner = THIS_MODULE;

    //Dynamically register device number
    ret = alloc_chrdev_region(&dev_no, param->mi, param->count, name);
    if(ret < 0){
        PRT_ERR("Allocate chrdev region failed\n");
        return ret;
    }
    param->ma = MAJOR(dev_no);

    //Add char device
    ret = cdev_add(param->cdev, dev_no, param->count);
    if(ret < 0){
        PRT_ERR("Add cdev failed\n");
        goto ERR_CDEV_ADD;
    }

    //Create class files: /sys/class/<name>
    param->cls = class_create(THIS_MODULE, name);
    if(IS_ERR(param->cls)){
        PRT_ERR("Create class failed\n");
        ret = PTR_ERR(param->cls);
        goto ERR_CLS_CREATE;
    }
    /*
     * Create device files: /sys/class/<name>/printk("%s%d", name, i)
     * According to /sys/class/<name>/printk("%s%d", name, i)/uevent 
     * linux will auto call mknod to create /dev/printk("%s%d", name, i)
     */
    for(i = param->mi; i< param->mi + param->count; i++){
        devp = device_create(param->cls, NULL, dev_no, NULL, C_NAME(name, i));
        if(IS_ERR(param->cls)){
            PRT_ERR("Create device failed\n");
            goto ERR_DEV_CREATE;
        }
    }

    return 0;

ERR_DEV_CREATE:
    for(j = param->mi; j < i; j++){
        device_destroy(param->cls, MKDEV(param->ma, j));
    }
    class_destroy(param->cls);
ERR_CLS_CREATE:
    cdev_del(param->cdev);
ERR_CDEV_ADD:
    unregister_chrdev_region(dev_no, param->count);
    return ret;
}

static inline void rm_char_dev(param_cdev *param)
{
    int i;
    for(i = param->mi; i < param->mi + param->count; i++){
        device_destroy(param->cls, MKDEV(param->ma, i));
    }
    class_destroy(param->cls);
    cdev_del(param->cdev);
    unregister_chrdev_region(MKDEV(param->ma, param->mi), param->count);
}
