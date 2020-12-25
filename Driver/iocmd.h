#include <linux/ioctl.h>

#define DEMO_TYPE   'k'
#define DEMO_CLEAN  _IO(DEMO_TYPE, 0x10)
#define DEMO_SETVAL _IOW(DEMO_TYPE, 0x11, int)
#define DEMO_GETVAL _IOR(DEMO_TYPE, 0x12, int)