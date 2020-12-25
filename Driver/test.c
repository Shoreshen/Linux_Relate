#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>  //open function
#include <unistd.h> //write & read function
#include <sys/ioctl.h> //ioctl function
#include <string.h>
#include <stdio.h> //printf
#include "iocmd.h"

int main(void)
{
    int fd, ret, n, val;
    char buf[50] = "test program write";
    
    fd = open(DEV_PATH, O_RDWR);
    if(fd < 0){
        printf("Failed open file\n");
        return -1;
    }

    n = write(fd, &buf[0], strlen(buf));
    if(n < 0){
        printf("Failed write\n");
        close(fd);
        return -1;
    }
    printf("Written to demo %d bytes\n", n);

    ret = ioctl(fd, DEMO_GETVAL, &val);
    if(ret < 0){
        printf("Failed ioctl\n");
        close(fd);
        return -1;
    }
    ret = ioctl(fd, DEMO_SETVAL, 100);
    if(ret < 0){
        printf("Failed ioctl\n");
        close(fd);
        return -1;
    }
    ret = ioctl(fd, DEMO_GETVAL, &val);
    if(ret < 0){
        printf("Failed ioctl\n");
        close(fd);
        return -1;
    }
    printf("val = %d\n", val);
    close(fd);
    return 0;
}

