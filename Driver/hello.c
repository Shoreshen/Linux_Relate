#include "Devlib.h"

static int __init hello_init(void)
{
    printk(KERN_INFO "Enter: %s\n", __func__);
    return 0; 
}

static void __exit hello_exit(void)
{
    printk(KERN_INFO "Exit: %s\n", __func__);
}

module_init(hello_init);
module_exit(hello_exit);