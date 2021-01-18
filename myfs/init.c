#include "init.h"

int main()
{
    char cmd[MAX_CMD_LEN], *argv[MAX_ARG_NUM], *ptr_cmd;
    unsigned int argc, i;
    unsigned long rip;

    while(1){
        // __asm__ __volatile__(
        //     "leaq (%%rip),%0\n\t"
        //     :"=a"(rip)
        // );
        // printf("Current addr:%p\n", rip);
        argc = 0;
        ptr_cmd = 0;
        memset(&cmd[0] ,0 ,MAX_CMD_LEN);
        memset(&argv[0],0,sizeof(char *)*MAX_ARG_NUM);
        printf("[SHELL]#:");

        ptr_cmd = fgets(&cmd[0], MAX_CMD_LEN, stdin); 
        if(!ptr_cmd){
            continue;
        }
         
        i = 0;
        while(cmd[i] != 0 && argc < MAX_ARG_NUM && i < MAX_CMD_LEN){
            if(cmd[i] == ' ' || cmd[i] == '\n'){
                cmd[i] = 0;
            }else if(i==0 || (cmd[i] != 0 && cmd[i-1] == 0)){
                argv[argc] = &cmd[i];
                argc++; 
            }
            i++;
        }
        if(argc){
            for(i = 0; i < argc; i++){
                printf("args[%d]: %s\n",i, argv[i]);
            }
            run_cmd(argc,&argv[0]);
        }
    }
    return 0;
}

int run_cmd(unsigned int argc, char **argv)
{
    int i;
    for(i = 0; i < NO_SHELL_CMD; i++){
        if(!strcmp(argv[0], Shell_CMD[i].name)){
            Shell_CMD[i].handler(argc, &argv[1]);
        }
    }
    return 0;
}

int time_handler(unsigned int argc, char **argv)
{
    time_t tt=0;
    struct tm *t=NULL;
    __asm__ __volatile__(
        "mov $0,%%rdi\n\t"
        "mov $0xc9,%%rax\n\t"
        "syscall\n\t" 
        "mov %%rax,%0\n\t"  
        : "=m" (tt) 
        :
        :"rax"
    );
    t = localtime(&tt);
    printf("time:%d:%d:%d:%d:%d:%d\n",t->tm_year+1900, t->tm_mon, t->tm_mday, t->tm_hour, t->tm_min, t->tm_sec);
    return 0;
}