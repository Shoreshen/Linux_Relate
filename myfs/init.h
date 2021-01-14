#include <stdio.h>
#include <string.h>
#include <time.h>

#define MAX_CMD_LEN 1024
#define MAX_ARG_NUM 32
#define NO_SHELL_CMD 1

int time_handler(unsigned int argc, char **argv);
int run_cmd(unsigned int argc, char **argv);

typedef struct{
    char *name;
    int (*handler)(unsigned int argc, char **argv);
} shell_cmd;

shell_cmd Shell_CMD[NO_SHELL_CMD] = {
    {
        .name = "time",
        .handler = time_handler,
    }
};