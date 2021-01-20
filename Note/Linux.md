[TOC]

current mark: 16

# Kernel

## Create config file

<code>x86_64</code> default config file can be copied from <code>./arch/x86/configs/x86_64_defconfig</code>

```shell
make ARCH=x86_64 x86_64_defconfig
```

Or use <code>menuconfig</code> (need to use xfce4-terminal, bash ):

```shell
make ARCH=x86_64 menuconfig
```

And process relevant option in the following graphic menu:

<img src="截图_2020-07-27_16-30-15.png">

### Options

#### Debug (using GDB)

Pick the following compiling options:

1. <code>General setup -> Initial RAM filesystem and RAM disk support</code>
2. <code>Device Drivers -> Blockdevices -> RAM block device support</code>, set "number=16" and "size=65536"
3. <code>Kernel hacking -> Compile-times checks and compiler options -> Compile the kernel with debug info</code>
4. <code>Kernel hacking -> Compile-times checks and compiler options -> Provide GDB scripts for kernel debugging</code>

For the supporting of ram-disk file system and debug.

## Compile kernel

Simply type:

```shell
make
```

to compile kernel, or use multi-thread compilation:

```shell
make -j16
```

where <code>16</code> is the maximum number of threads

(note: do not only type <code>make -j</code>, machine will die)

If succeed, the following will prompt:

```bash
Setup is 13884 bytes (padded to 14336 bytes).
System is 8831 kB
CRC 16fc05a9
Kernel: arch/x86/boot/bzImage is ready  (#1)
```

Compilation result <code>./arch/x86/boot/bzImage</code>, which is a gzip compressed form, and <code>./vmlinux</code>, which is not compressed.

## Clean compiled files

The following clean all compiled files.

```shell
make mrproper
```

# GNU Assembly

## Operators

### Infix

| Operator | Priority | Functionality                                         |
| -------- | -------- | ----------------------------------------------------- |
| *        | High     | Multiplication                                        |
| /        | High     | Division                                              |
| %        | High     | Reminder                                              |
| >>       | High     | Shift right                                           |
| <<       | High     | Shift left                                            |
| \|       | median   | Bitwise or                                            |
| &        | median   | Bitwise and                                           |
| ^        | median   | Bitwise xor                                           |
| !        | median   | Bitwise or not                                        |
| +        | low      | Addition                                              |
| ==       | low      | Equal, return -1 if true, 0 otherwise                 |
| !=       | low      | Not equal, return -1 if true, 0 otherwise             |
| >        | low      | Greater than, return -1 if true, 0 otherwise          |
| <        | low      | Less than, return -1 if true, 0 otherwise             |
| >=       | low      | Greater than or equal, return -1 if true, 0 otherwise |
| <=       | low      | Less then or equal, return -1 if true, 0 otherwise    |

## macro

By using commands <code>.macro</code> and <code>.endm</code> allow you to define macros that generate assembly output.

<code>.macro *name* [*arg1*] [*arg2*] ...</code> defines a macro with name of *name* and several arguments.

There are several attribute can be put on arguments:

| Attribute   | definition                                                |
| ----------- | --------------------------------------------------------- |
| arg:req     | This argument require a non-blank value for this argument |
| arg:vararg  | This argument takes all of the remaining arguments        |
| arg=default | This argument has a default value                         |

Argument <code>arg</code> can be referenced as <code>\arg</code> inside the macro definition.

After finishing defining the macro, using <code>.endm</code> to indicate an end of definition.

## Section

Defined as block of bytes complied by as, which the size and order does not change in the following linking stage.

Default 3 sections from GAS is text, data and bss. These sections can be empty. text section at address 0 of the object file, data and bss follows

### Section attribute

For ELF format, the following flags can be set:

| Flag | Meaning                                                 |
| ---- | ------------------------------------------------------- |
| a    | section is allocatable                                  |
| d    | section is a GNU MBIND section                          |
| e    | section is excluded from executable and shared library. |
| w    | section is writable                                     |
| x    | section is executable                                   |
| M    | section is mergeable                                    |
| S    | section contains zero terminated strings                |
| G    | section is a member of a section group                  |
| T    | section is used for thread-local-storage                |

### linking section

Without <code>*.lds</code> file present, linker will only deal with the following sections.

| Section   | Use                                                                  | Storage                  | Accessability             |
| --------- | -------------------------------------------------------------------- | ------------------------ | ------------------------- |
| Text      | Used for storing executable code                                     | Saved in the object file | readable but not writable |
| Data      | Used for storing data                                                | Saved in the object file | readable & writable       |
| Bss       | Used to store uninitialized global, static variables                 | Allocate at runtime      | readable & writable       |
| Absolute  | Address 0 of this section is always “relocated” to runtime address 0 |                          |                           |
| Undefined | All address references to objects not in the preceding sections      |                          |                           |

### as internal sections

These sections are meant only for the internal use of **as** compiler.

### Subsection

A section could has subsection of 0~8192, which will re-ordered from lower to higher by **as** when creating obj files.

This allow users to write discontinues source code and put them in continues address when creating obj file.

The default subsection is 0, so if <code>.text</code> was used only, the code will be included in subsection of <code>.text 0</code>.

Thus if no subsection is applied, all code will be compiled into subsection 0.

*e.g: To declare subsection of <code>.text</code>, use numeric after section name such as <code>.text 1</code>*

### ELF section stack manipulation directives

Due to the [subsection](#subsection) mechanism, a conceptual section stack will be used to illustrate the operation of section.

#### .previous

This directive swaps the current section (and subsection) with most recently referenced section or subsection pair prior to this one. 

e.g:

```S
.section A
   .subsection 1
      # Now in section A subsection 1
      # Section stack: |A|A1|
      .word 0x1234
.section B
   .subsection 0  
      # Now in section B subsection 0
      .word 0x5678
   .subsection 1
      # Now in section B subsection 1
      .word 0x9abc
.previous
   # Now in section B subsection 0
   .word 0xdef0
```

Above code will place 0x1234 into section A, 0x5678 and 0xdef0 into subsection 0 of section B and 0x9abc into subsection 1 of section B.

#### .pushsection & .popsection

<code>.pushsection *name* [,*subsection*] ["*flat*"]</code> save the current section and subsection to the top of section stack, and replace the current section and subsection with *name* and *subsection*.

<code>.pushsection</code> replaces the current section and subsection with the top section and subsection on the section stack, then pop them out.

##### Sample

The following is ARM code:

```c
unsigned long ret;

asm volatile(
   "1: ldr %0,[%1]\n"
   "2:\n"
   ".pushsection .text.fixup, \"ax\"\n"
   "3b\n"
   "mov %0, $0x89\n"
   "b 2b\n"
   ".popsection\n"
   ".pushsection __ex_table, \"ax\"\n"
   ".long 1b, 3b\n"
   ".popsection\n"
   :"=&r"(ret)
   :"r"(addr)
);
```
###### Target & background

The purpose of this code is to test if <code>addr</code> is a valid aligned. If yes, then return the value addr pointed at, if not, return 0x89.

ARM generate an interrupt for non aligned instruction, then interrupt handler will search an specific array with the following structure:

```c
struct exception_table_entry
{
   unsigned long insn, fixup;
}
```

<code>insn</code> is the address of instruction cause interrupt, <code>fixup</code> is the pointer of code that if <code>insn</code> interrupt is generated.

###### Analyze of code

The body of code is <code>ldr %0,[%1]</code> it simply load the value pointed by argument 1 (which is <code>addr</code>) into argument 0 (which is <code>ret</code>). If the <code>addr</code> is not an aligned address, interrupt is generated.

Interrupt handler will scan <code>exception_table_entry</code>, which located in section <code>__ex_table</code>, thus using <code>.pushsection</code> switch to define an entry as <code>.long 1b, 3b</code> with <code>insn</code> pointing to the body of code and <code>fixup</code> pointing to the process of fixup, and using <code>.popsection</code> to switch back to the current section.

Fixup at symbol <code>3b</code> also should be placed in specific section named <code>.text.fixup</code>. Same as above with the combined using of <code>.pushsection</code> and <code>.popsection</code> to insert fixup code into the target section, even if the source code is in here.

## Other directive

### .skip/.space

<code>.skip *size*, *fill*</code> is the same as <code>.space *size*, *fill*</code>, which filling the following *size* byte with *fill* value.

# Rootfs

## busybox

### Clone source

Clone the busybox source code from github:

```shell
mkdir busybox
cd busybox
git clone git@github.com:mirror/busybox.git ./
```

### Configure

Same as linux, use menuconfig to select relative settings:

```shell
make menuconfig
```

select <code>Settings -> Build static binary (no shared libs)</code>

Exit and save the config files.

### Compile

Since Arch do not provide static glibc, need to compile and install it in docker:

```shell
docker run -it --rm -e PLAT=manylinux1_x86_64 -v `pwd`:/io quay.io/pypa/manylinux2014_x86_64 /bin/bash
yum update
yum install glibc-static
cd io
make -j16
make install
exit
sudo chown shore ./_install #change owner of the file so that user can manipulate
```

Since we do not save the container, each time will need update and install <code>glibc-static</code>.

By default, the installation destination will by <code>./_install</code> 

## Extra file/dirs

Get current directory to <code>path/to/busybox/_install</code> which result from [busybox](#busybox) installation. 

Execute the following to create neccessary file structures:

```shell
mkdir etc dev mnt
mkdir -p etc/init.d/
touch etc/fstab etc/init.d/rcS etc/inittab
cd dev
sudo mknod console c 5 1
sudo mknod null c 1 3
sudo mknod tty1 c 4 1 
```

Fill in <code>./_install/etc/fstab</code> with the following:

```
proc  /proc proc  defaults 0 0
temps /tmp  rpoc  defaults 0 0
none  /tmp  ramfs defaults 0 0
sysfs /sys  sysfs defaults 0 0
mdev  /dev  ramfs defaults 0 0
```

Fill in <code>./_install/etc/init.d/rcS</code> with the following:

```
mkdir -p /proc
mkdir -p /tmp
mkdir -p /sys
mkdir -p /mnt
/bin/mount -a
mkdir -p /dev/pts
mount -t devpts devpts /dev/pts
echo /sbin/mdev > /proc/sys/kernel/hotplug
mdev -s
```

Fill in <code>./_install/etc/inittab</code> with the following:

```
::sysinit:/etc/init.d/rcS
::respawn:-/bin/sh
::askfirst:-/bin/sh
::cttlaltdel:/bin/umount -a -r
```

Finally, change the file attribute of some files:

```shell
chmod 755 etc/inittab
chmod 755 etc/init.d/rcS

```

## Packup runable filesystem

The process summarized as:

1. Create image with <code>ext3</code> format
2. Copy all files under <code>./_install</code> into the image
3. Create a compressed zip file of the target image

Shell operation as follow

```shell
rm -rf rootfs.ext3
rm -rf fs
dd if=/dev/zero of=./rootfs.ext3 bs=1M count=32
mkfs.ext3 rootfs.ext3
mkdir fs
mount -o loop rootfs.ext3 ./fs
cp -rf ./_install/* ./fs
umount ./fs
gzip --best -c rootfs.ext3 > rootfs.img.gz 
```

# Debug

To make it able to debug, need to select [relevant option](#debug-using-gdb) in the config file.

## Compiler optimization

It is said that the code is written based on assumption of "-O2" compiler option.

So simply turnoff optimization will cause crash of the whole compilation.

However, it might be possible to add attribute to specific function:

```c
void __attribute__((optimize("O0"))) foo(unsigned char data) {
    // unmodifiable compiler code
}
```

## vscode

Add debug configuration in <code>launch.json</code>:

```json
"configurations": [
   {
      "name": "kernel-debug",
      "type": "cppdbg",
      "request": "launch",
      "miDebuggerServerAddress": "127.0.0.1:1234",
      "program": "输入程序名称，例如 ${workspaceFolder}/vmlinux",
      "args": [],
      "stopAtEntry": false,
      "cwd": "${workspaceFolder}",
      "environment": [],
      "externalConsole": false,
      "MIMode": "gdb",
      "setupCommands": [
            {
               "description": "为 gdb 启用整齐打印",
               "text": "-enable-pretty-printing",
               "ignoreFailures": true
            }
      ]
   }
]
```

## qemu

Adding gdb support by adding <code>-S -s</code>.

Using Linux/Multiboot boot by specifying <code>-kernel,-initrd,-append</code> so that do not need to install it in the disk image.

Sample:

```shell
qemu-system-x86_64 -S -s -kernel <bzImage> -initrd <file> -append <cmd>
```

Parameters:
1. <code>-S -s</code>: Setup support for GDB, default port is 1234
2. <code>-kernel</code>: Use \<bzImage\> as kernel image
3. <code>-initrd</code>: Use \<file\> (compressed in specific format) used as initial ram disk
4. <code>-append</code>: Use \<cmd\> as kernel command line

Please note:
1. To debug, the accelerator should be turned off, thus do not put <code>-accel kvm</code> into the command
2. To insert a break point, should either compile the kernel without <code>CONFIG_RANDOMIZE_BASE</code>, or add "nokaslar" to kernel command by using <code>-append</code>

## GDB

Start gdb and loading linux symbols:

```shell
gdb ./vmlinux
```

Connect to debug port:

```shell
(gdb) target remote:1234
```

Set break point:

```shell
(gdb) break start_kernel
```

Run until the break point with <code>c</code> command, then switch to source layout to view source code:

```shell
(gdb) layout src
```

### GDB commands

#### Break

1. <code>break XXXX</code>: place break point at symbol "XXXX"
2. <code>hbreak *0xXXXX</code>: place hard break point at (virtual) address "0xXXXX"
3. <code>info break</code>: list all break points
4. <code>delete #No</code>: delete break point by "#No" listed in <code>info break</code>

#### Step

1. <code>si</code>: single step for assembly instruction
2. <code>ni</code>: next step for assembly instruction
3. <code>s</code>: single step for source code
4. <code>n</code>: next step for source code
5. <code>c</code>: run untill meet break point

#### View content

1. <code>info r</code>: print registers(including segments)
2. <code>x/nfu expression</code>: n = number, f = format(x=hex), u = len(g=8byte); 
   1. <code>x/16xg $rsp</code>: display 16 of length 8 byte with hex format start at address pointed by rsp register
   2. <code>x/16xg 0xffffffff82000210+(8* 201)</code>: display 16 of length 8 byte with hex format start at address of <code>0xffffffff82000858 = 0xffffffff82000210+(8*201) - 16</code>
3. <code>info r</code>: print registers(including segments)
4. <code>display /fmt expr</code>: display the value of "expr" each break with format "/fmt"
   1. <code>/x</code>: hex format
   2. <code>/c</code>: char format
   3. <code>/f</code>: float format
5. <code>undisplay #No1 #No2...</code>: cancel display of expression <code>#No1 #No2...</code>
6. <code>p /fmt expr</code>: view the value of "expr" with format "/fmt"

#### Others

1. <code>layout XXXX</code>: use "XXXX" view as layout
   1. <code>r</code>: Assembly view
   2. <code>src</code>: Source code view
2. <code>quit</code>: quit gdb
3. <code>disassmble 0xXXXX,+length</code>: disassmble from address "XXXX" 
4. <code>bt</code>: view calling stack(trace caller of the function)

# Source code

## System call

### Stack structure

The stack structure and relative definitions will be applied in the following processes

```c
// arch/x86/include/asm/ptrace.h:56
struct pt_regs {
/*
 * C ABI says these regs are callee-preserved. They aren't saved on kernel entry
 * unless syscall needs a complete, fully filled "struct pt_regs".
 */
	unsigned long r15;
	unsigned long r14;
	unsigned long r13;
	unsigned long r12;
	unsigned long bp;
	unsigned long bx;
/* These regs are callee-clobbered. Always saved on kernel entry. */
	unsigned long r11;
	unsigned long r10;
	unsigned long r9;
	unsigned long r8;
	unsigned long ax;
	unsigned long cx;
	unsigned long dx;
	unsigned long si;
	unsigned long di;
/*
 * On syscall entry, this is syscall#. On CPU exception, this is error code.
 * On hw interrupt, it's IRQ number:
 */
	unsigned long orig_ax;
/* Return frame for iretq */
	unsigned long ip;
	unsigned long cs;
	unsigned long flags;
	unsigned long sp;
	unsigned long ss;
/* top of stack page */
};

// arch/x86/include/uapi/asm/ptrace.h:44
struct pt_regs {
/*
 * C ABI says these regs are callee-preserved. They aren't saved on kernel entry
 * unless syscall needs a complete, fully filled "struct pt_regs".
 */
	unsigned long r15;
	unsigned long r14;
	unsigned long r13;
	unsigned long r12;
	unsigned long rbp;
	unsigned long rbx;
/* These regs are callee-clobbered. Always saved on kernel entry. */
	unsigned long r11;
	unsigned long r10;
	unsigned long r9;
	unsigned long r8;
	unsigned long rax;
	unsigned long rcx;
	unsigned long rdx;
	unsigned long rsi;
	unsigned long rdi;
/*
 * On syscall entry, this is syscall#. On CPU exception, this is error code.
 * On hw interrupt, it's IRQ number:
 */
	unsigned long orig_rax;
/* Return frame for iretq */
	unsigned long rip;
	unsigned long cs;
	unsigned long eflags;
	unsigned long rsp;
	unsigned long ss;
/* top of stack page */
};

// arch/x86/entry/calling.h:70
/*
 * C ABI says these regs are callee-preserved. They aren't saved on kernel entry
 * unless syscall needs a complete, fully filled "struct pt_regs".
 */
#define R15		0*8
#define R14		1*8
#define R13		2*8
#define R12		3*8
#define RBP		4*8
#define RBX		5*8
/* These regs are callee-clobbered. Always saved on kernel entry. */
#define R11		6*8
#define R10		7*8
#define R9		8*8
#define R8		9*8
#define RAX		10*8
#define RCX		11*8
#define RDX		12*8
#define RSI		13*8
#define RDI		14*8
/*
 * On syscall entry, this is syscall#. On CPU exception, this is error code.
 * On hw interrupt, it's IRQ number:
 */
#define ORIG_RAX	15*8
/* Return frame for iretq */
#define RIP		16*8
#define CS		17*8
#define EFLAGS		18*8
#define RSP		19*8
#define SS		20*8
```

### Defining system call function

Using a special function as in <code>kernel/time/time.c:62</code> with the following source code to illustrate:

```c
SYSCALL_DEFINE1(time, __kernel_old_time_t __user *, tloc)
{
	__kernel_old_time_t i = (__kernel_old_time_t)ktime_get_real_seconds();

	if (tloc) {
		if (put_user(i,tloc))
			return -EFAULT;
	}
	force_successful_syscall_return();
	return i;
}
```

#### Find out exact expression of function

According to the following macro definition:

```c
// include/linux/syscalls.h:213
#define SYSCALL_DEFINE1(name, ...) SYSCALL_DEFINEx(1, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE2(name, ...) SYSCALL_DEFINEx(2, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE3(name, ...) SYSCALL_DEFINEx(3, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE4(name, ...) SYSCALL_DEFINEx(4, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE5(name, ...) SYSCALL_DEFINEx(5, _##name, __VA_ARGS__)
#define SYSCALL_DEFINE6(name, ...) SYSCALL_DEFINEx(6, _##name, __VA_ARGS__)

#define SYSCALL_DEFINE_MAXARGS	6

#define SYSCALL_DEFINEx(x, sname, ...)				\
	SYSCALL_METADATA(sname, x, __VA_ARGS__)			\
	__SYSCALL_DEFINEx(x, sname, __VA_ARGS__)

// include/linux/syscalls.h:197
#define SYSCALL_METADATA(sname, nb, ...)
```

We transform the code into the following

```c
__SYSCALL_DEFINEx(1, _time, __kernel_old_time_t __user *, tloc)
{
	__kernel_old_time_t i = (__kernel_old_time_t)ktime_get_real_seconds();

	if (tloc) {
		if (put_user(i,tloc))
			return -EFAULT;
	}
	force_successful_syscall_return();
	return i;
}
```

According to the following macro definition:

```c
// arch/x86/include/asm/syscall_wrapper.h:74
#define __SYS_STUBx(abi, name, ...)					\
	long __##abi##_##name(const struct pt_regs *regs);		\
	ALLOW_ERROR_INJECTION(__##abi##_##name, ERRNO);			\
	long __##abi##_##name(const struct pt_regs *regs)		\
	{								\
		return __se_##name(__VA_ARGS__);			\
	}

// arch/x86/include/asm/syscall_wrapper.h:95
#define __X64_SYS_STUBx(x, name, ...)					\
	__SYS_STUBx(x64, sys##name,					\
		    SC_X86_64_REGS_TO_ARGS(x, __VA_ARGS__))

// arch/x86/include/asm/syscall_wrapper.h:126
#define __IA32_SYS_STUBx(x, name, ...)

// arch/x86/include/asm/syscall_wrapper.h:227
#define __SYSCALL_DEFINEx(x, name, ...)					\
	static long __se_sys##name(__MAP(x,__SC_LONG,__VA_ARGS__));	\
	static inline long __do_sys##name(__MAP(x,__SC_DECL,__VA_ARGS__));\
	__X64_SYS_STUBx(x, name, __VA_ARGS__)				\
	__IA32_SYS_STUBx(x, name, __VA_ARGS__)				\
	static long __se_sys##name(__MAP(x,__SC_LONG,__VA_ARGS__))	\
	{								\
		long ret = __do_sys##name(__MAP(x,__SC_CAST,__VA_ARGS__));\
		__MAP(x,__SC_TEST,__VA_ARGS__);				\
		__PROTECT(x, ret,__MAP(x,__SC_ARGS,__VA_ARGS__));	\
		return ret;						\
	}								\
	static inline long __do_sys##name(__MAP(x,__SC_DECL,__VA_ARGS__))
```

Transform the code into following:

```c
static long __se_sys_time(__MAP(1,__SC_LONG,__kernel_old_time_t __user *, tloc)); 
static inline long __do_sys_time(__MAP(1,__SC_DECL,__kernel_old_time_t __user *, tloc)); 
__X64_SYS_STUBx(1, _time, __kernel_old_time_t __user *, tloc) 
__IA32_SYS_STUBx(1, _time, __kernel_old_time_t __user *, tloc) 
static long __se_sys_time(__MAP(1,__SC_LONG,__kernel_old_time_t __user *, tloc)) 
{ 
	long ret = __do_sys_time(__MAP(1,__SC_CAST,__kernel_old_time_t __user *, tloc)); 
	__MAP(1,__SC_TEST,__kernel_old_time_t __user *, tloc); 
	__PROTECT(1, ret,__MAP(1,__SC_ARGS,__kernel_old_time_t __user *, tloc)); 
	return ret; 
} 
static inline long __do_sys_time(__MAP(1,__SC_DECL,__kernel_old_time_t __user *, tloc))
{
	__kernel_old_time_t i = (__kernel_old_time_t)ktime_get_real_seconds();

	if (tloc) {
		if (put_user(i,tloc))
			return -EFAULT;
	}
	force_successful_syscall_return();
	return i;
}
```

According to following macro definition:

```c
// arch/x86/include/asm/syscall_wrapper.h:74
#define __SYS_STUBx(abi, name, ...)					\
	long __##abi##_##name(const struct pt_regs *regs);		\
	ALLOW_ERROR_INJECTION(__##abi##_##name, ERRNO);			\
	long __##abi##_##name(const struct pt_regs *regs)		\
	{								\
		return __se_##name(__VA_ARGS__);			\
	}

// arch/x86/include/asm/syscall_wrapper.h:95
#define __X64_SYS_STUBx(x, name, ...)					\
	__SYS_STUBx(x64, sys##name,					\
		    SC_X86_64_REGS_TO_ARGS(x, __VA_ARGS__))

// arch/x86/include/asm/syscall_wrapper.h:126
#define __IA32_SYS_STUBx(x, name, ...)
```

Thus we eleminate IA32 entry of system call and get the following tranformed code:

```c
static long __se_sys_time(__MAP(1,__SC_LONG,__kernel_old_time_t __user *, tloc)); 
static inline long __do_sys_time(__MAP(1,__SC_DECL,__kernel_old_time_t __user *, tloc)); 
long __x64_sys_time(const struct pt_regs *regs); 
ALLOW_ERROR_INJECTION(__x64_sys_time, ERRNO); 
long __x64_sys_time(const struct pt_regs *regs) 
{ 
	return __se_sys_time(SC_X86_64_REGS_TO_ARGS(1, __kernel_old_time_t __user *, tloc)); 
}
static long __se_sys_time(__MAP(1,__SC_LONG,__kernel_old_time_t __user *, tloc)) 
{ 
	long ret = __do_sys_time(__MAP(1,__SC_CAST,__kernel_old_time_t __user *, tloc)); 
	__MAP(1,__SC_TEST,__kernel_old_time_t __user *, tloc); 
	__PROTECT(1, ret,__MAP(1,__SC_ARGS,__kernel_old_time_t __user *, tloc)); 
	return ret; 
} 
static inline long __do_sys_time(__MAP(1,__SC_DECL,__kernel_old_time_t __user *, tloc))
{
	__kernel_old_time_t i = (__kernel_old_time_t)ktime_get_real_seconds();

	if (tloc) {
		if (put_user(i,tloc))
			return -EFAULT;
	}
	force_successful_syscall_return();
	return i;
}
```

For now we ignore some error and protection mechanism, so the final code we gonna analyze is as follow

```c
static long __se_sys_time(__MAP(1,__SC_LONG,__kernel_old_time_t __user *, tloc)); 
static inline long __do_sys_time(__MAP(1,__SC_DECL,__kernel_old_time_t __user *, tloc)); 
long __x64_sys_time(const struct pt_regs *regs); 
long __x64_sys_time(const struct pt_regs *regs) 
{ 
	return __se_sys_time(SC_X86_64_REGS_TO_ARGS(1, __kernel_old_time_t __user *, tloc)); 
}
static long __se_sys_time(__MAP(1,__SC_LONG,__kernel_old_time_t __user *, tloc)) 
{ 
	long ret = __do_sys_time(__MAP(1,__SC_CAST,__kernel_old_time_t __user *, tloc)); 
	return ret; 
} 
static inline long __do_sys_time(__MAP(1,__SC_DECL,__kernel_old_time_t __user *, tloc))
{
	__kernel_old_time_t i = (__kernel_old_time_t)ktime_get_real_seconds();

	if (tloc) {
		if (put_user(i,tloc))
			return -EFAULT;
	}
	force_successful_syscall_return();
	return i;
}
```

#### Deal with parameters

##### Mapping macros

According to following macro definition
<a id='bkmk5'></a>
```c
// include/linux/syscalls.h:106
#define __MAP0(m,...)
#define __MAP1(m,t,a,...) m(t,a)
#define __MAP2(m,t,a,...) m(t,a), __MAP1(m,__VA_ARGS__)
#define __MAP3(m,t,a,...) m(t,a), __MAP2(m,__VA_ARGS__)
#define __MAP4(m,t,a,...) m(t,a), __MAP3(m,__VA_ARGS__)
#define __MAP5(m,t,a,...) m(t,a), __MAP4(m,__VA_ARGS__)
#define __MAP6(m,t,a,...) m(t,a), __MAP5(m,__VA_ARGS__)
#define __MAP(n,...) __MAP##n(__VA_ARGS__)
```

Thus we replace all the <code>__MAP</code> macro:

```c
static long __se_sys_time(__SC_LONG(__kernel_old_time_t __user *,tloc)); 
static inline long __do_sys_time(__SC_DECL(__kernel_old_time_t __user *,tloc)); 
long __x64_sys_time(const struct pt_regs *regs); 
long __x64_sys_time(const struct pt_regs *regs) 
{ 
	return __se_sys_time(SC_X86_64_REGS_TO_ARGS(1, __kernel_old_time_t __user *, tloc)); 
}
static long __se_sys_time(__SC_LONG(__kernel_old_time_t __user *,tloc)) 
{ 
	long ret = __do_sys_time(__SC_CAST(__kernel_old_time_t __user *,tloc)); 
	return ret; 
} 
static inline long __do_sys_time(__SC_DECL(__kernel_old_time_t __user *, tloc))
{
	__kernel_old_time_t i = (__kernel_old_time_t)ktime_get_real_seconds();

	if (tloc) {
		if (put_user(i,tloc))
			return -EFAULT;
	}
	force_successful_syscall_return();
	return i;
}
```

Step by step, next we find the following macro definition:

<a id='bkmk6'></a>
```c
// include/linux/syscalls.h:115
#define __SC_DECL(t, a)	t a
#define __TYPE_AS(t, v)	__same_type((__force t)0, v)
#define __TYPE_IS_L(t)	(__TYPE_AS(t, 0L))
#define __TYPE_IS_UL(t)	(__TYPE_AS(t, 0UL))
#define __TYPE_IS_LL(t) (__TYPE_AS(t, 0LL) || __TYPE_AS(t, 0ULL))
#define __SC_LONG(t, a) __typeof(__builtin_choose_expr(__TYPE_IS_LL(t), 0LL, 0L)) a
#define __SC_CAST(t, a)	(__force t) a
#define __SC_ARGS(t, a)	a
#define __SC_TEST(t, a) (void)BUILD_BUG_ON_ZERO(!__TYPE_IS_LL(t) && sizeof(t) > sizeof(long))

// include/linux/compiler_types.h:256
#define __same_type(a, b) __builtin_types_compatible_p(typeof(a), typeof(b))

// include/linux/compiler_types.h:50
#define __force
```

We then furthur explan our code by macros defined above:

```c
static long __se_sys_time(
	__typeof(__builtin_choose_expr(
		__builtin_types_compatible_p(typeof((__kernel_old_time_t __user *)0), typeof(0LL)) ||
		__builtin_types_compatible_p(typeof((__kernel_old_time_t __user *)0), typeof(0ULL))
		, 0LL, 0L
	)) tloc
); 
static inline long __do_sys_time(__kernel_old_time_t __user * tloc); 
long __x64_sys_time(const struct pt_regs *regs); 
long __x64_sys_time(const struct pt_regs *regs) 
{ 
	return __se_sys_time(SC_X86_64_REGS_TO_ARGS(1, __kernel_old_time_t __user *, tloc)); 
}
static long __se_sys_time(
	__typeof(__builtin_choose_expr(
		__builtin_types_compatible_p(typeof((__kernel_old_time_t __user *)0), typeof(0LL)) ||
		__builtin_types_compatible_p(typeof((__kernel_old_time_t __user *)0), typeof(0ULL))
		, 0LL, 0L
	)) tloc
) 
{ 
	long ret = __do_sys_time((__kernel_old_time_t __user *) tloc)); 
	return ret; 
} 
static inline long __do_sys_time(__kernel_old_time_t __user * tloc)
{
	__kernel_old_time_t i = (__kernel_old_time_t)ktime_get_real_seconds();

	if (tloc) {
		if (put_user(i,tloc))
			return -EFAULT;
	}
	force_successful_syscall_return();
	return i;
}
```

According to [this post](https://stackoverflow.com/questions/14877415/difference-between-typeof-typeof-and-typeof-in-objective-c#:~:text=3%20Answers&text=__typeof__()%20and%20__typeof,not%20include%20such%20an%20operator.&text=typeof()%20is%20exactly%20the,every%20modern%20compiler%20supports%20it.) it is equivalent for <code>typedef</code>, <code>__typedef</code> and <code>_\_typedef\_\_</code>.

Further we import 2 compiler build in function:
1. <code>int __builtin_types_compatible_p(type1, type2)</code> return 1 if type1 is same as type2.
2. <code>type __builtin_choose_expr(const_exp,exp1,exp2)</code> return <code>exp1</code> if <code>const_exp</code> is none zero, <code>exp2</code> otherwise.

Now the problem would be to figure out the type of <code>__kernel_old_time_t __user *</code>, thus we found the following definition:

```c
// include/uapi/asm-generic/posix_types.h:89
typedef __kernel_long_t	__kernel_old_time_t;

// include/uapi/asm-generic/posix_types.h:15
typedef long		__kernel_long_t;
```

Thus we know that <code>__kernel_old_time_t __user *</code> is equivalent to <code>long *</code>, it neither a <code>long long</code> type nor a <code>unsigned long long</code> type. Therefore, for the following expression:

```c
__typeof(__builtin_choose_expr(
	__builtin_types_compatible_p(typeof((__kernel_old_time_t __user *)0), typeof(0LL)) ||
	__builtin_types_compatible_p(typeof((__kernel_old_time_t __user *)0), typeof(0ULL))
	, 0LL, 0L
))
```

Will be valued as <code>typeof(0L)=long</code>, so in this stage we can display the function as follow:

```c
static long __se_sys_time(long tloc); 
static inline long __do_sys_time(__kernel_old_time_t __user * tloc); 
long __x64_sys_time(const struct pt_regs *regs); 
long __x64_sys_time(const struct pt_regs *regs) 
{ 
	return __se_sys_time(SC_X86_64_REGS_TO_ARGS(1, __kernel_old_time_t __user *, tloc)); 
}
static long __se_sys_time(long tloc) 
{ 
	long ret = __do_sys_time((__kernel_old_time_t __user *) tloc)); 
	return ret; 
} 
static inline long __do_sys_time(__kernel_old_time_t __user * tloc)
{
	__kernel_old_time_t i = (__kernel_old_time_t)ktime_get_real_seconds();

	if (tloc) {
		if (put_user(i,tloc))
			return -EFAULT;
	}
	force_successful_syscall_return();
	return i;
}
```

##### Passing parameter

According to following macro definition and [stack structure](#stack-structure):

```c
// arch/x86/include/asm/syscall_wrapper.h:56
#define SC_X86_64_REGS_TO_ARGS(x, ...)					\
	__MAP(x,__SC_ARGS						\
		,,regs->di,,regs->si,,regs->dx				\
		,,regs->r10,,regs->r8,,regs->r9)			\
```

According to [MAPPING](#bkmk5) and [SC](#bkmk6) definition we find that only the first argument make effect in this macro, and finally we present the comprehensive definition of time system call function.
<a id='bkmk7'></a>
```c
static long __se_sys_time(long tloc); 
static inline long __do_sys_time(__kernel_old_time_t __user * tloc); 
long __x64_sys_time(const struct pt_regs *regs); 
long __x64_sys_time(const struct pt_regs *regs) 
{ 
	return __se_sys_time(regs->di); 
}
static long __se_sys_time(long tloc) 
{ 
	long ret = __do_sys_time((__kernel_old_time_t __user *) tloc)); 
	return ret; 
} 
static inline long __do_sys_time(__kernel_old_time_t __user * tloc)
{
	__kernel_old_time_t i = (__kernel_old_time_t)ktime_get_real_seconds();

	if (tloc) {
		if (put_user(i,tloc))
			return -EFAULT;
	}
	force_successful_syscall_return();
	return i;
}
```

### Linking system call function

#### Entry point of syscall

##### Assembly entry

By debugging the [init](../myfs/init.c) target created by [makefile](../makefile) with Qemu, we found the entry point of <code>syscall</code> as follow;

```c
// arch/x86/entry/entry_64.S:95
SYM_CODE_START(entry_SYSCALL_64)
	UNWIND_HINT_EMPTY

	swapgs
	/* tss.sp2 is scratch space. */
	movq	%rsp, PER_CPU_VAR(cpu_tss_rw + TSS_sp2)
	SWITCH_TO_KERNEL_CR3 scratch_reg=%rsp
	movq	PER_CPU_VAR(cpu_current_top_of_stack), %rsp
```

According to the above [SWITCH_TO_KERNEL_CR3](#bkmk8), [ALTERNATIVE](#alternative) definition and the debugging info indicating not setting of <code>X86_FEATURE_PTI</code>, we got the result that <code>jmp .Lend_\@</code> in [SWITCH_TO_KERNEL_CR3](#bkmk8) will not be replaced and this macro will be jumped over. Thus this part of code only switch <code>%rsp</code> register. Next codes are:

<a id='bkmk10'></a>
```c
// arch/x86/entry/entry_64.S:106
	/* Construct struct pt_regs on stack */
	pushq	$__USER_DS				/* pt_regs->ss */
	pushq	PER_CPU_VAR(cpu_tss_rw + TSS_sp2)	/* pt_regs->sp */
	pushq	%r11					/* pt_regs->flags */
	pushq	$__USER_CS				/* pt_regs->cs */
	pushq	%rcx					/* pt_regs->ip */
SYM_INNER_LABEL(entry_SYSCALL_64_after_hwframe, SYM_L_GLOBAL)
	pushq	%rax					/* pt_regs->orig_ax */
```

The above code saves user <code>%ss</code>, <code>%rsp</code>, <code>%rflag</code>(syscall saves <code>%rflag</code> to <code>%r11</code>), <code>%cs</code>, <code>%rip</code>(syscall saves <code>%rip</code> to <code>%rcx</code>) and <code>orig_ax</code> according to [stack structure](#stack-structure). Next codes are:

<a id='bkmk12'></a>
```c
// arch/x86/entry/entry_64.S:115
	PUSH_AND_CLEAR_REGS rax=$-ENOSYS

	/* IRQs are off. */
	movq	%rax, %rdi
	movq	%rsp, %rsi
	call	do_syscall_64		/* returns with IRQs disabled */
```

According to [PUSH_AND_CLEAR_REGS](#bkmk9) saves all the rest of relevant registers in stack and call [do_syscall_64()](#do_syscall_64) function with parameter of <code>unsigned long nr %rax</code> and <code>struct pt_regs * %rsp</code>

##### do_syscall_64()

The assembly instruction then call <code>do_syscall_64()</code> function in file <code>arch/x86/entry/common.c:39</code> with following source code:

```c
__visible noinstr void do_syscall_64(unsigned long nr, struct pt_regs *regs)
{
	nr = syscall_enter_from_user_mode(regs, nr);

	instrumentation_begin();
	if (likely(nr < NR_syscalls)) {
		nr = array_index_nospec(nr, NR_syscalls);
		regs->ax = sys_call_table[nr](regs);
	}
	instrumentation_end();
	syscall_exit_to_user_mode(regs);
}
```

Obviously the function will call the system call table (<code>sys_call_table</code>) with relative entry to find the function.

#### System call table

System call table is an array of function pointer define in file <code>arch/x86/include/asm/syscall.h:19</code> as follow

```c
typedef long (*sys_call_ptr_t)(const struct pt_regs *);
```

It is initialized in file <code>arch/x86/entry/syscall_64.c:20</code> as follow

```c
asmlinkage const sys_call_ptr_t sys_call_table[__NR_syscall_max+1] = {
	/*
	 * Smells like a compiler bug -- it doesn't work
	 * when the & below is removed.
	 */
	[0 ... __NR_syscall_max] = &__x64_sys_ni_syscall,
#include <asm/syscalls_64.h>
};
```

Further each entry define in <code>arch/x86/include/generated/asm/syscalls_64.h</code>(Which is generated while compiling) looks like:

```c
__SYSCALL_COMMON(0, sys_read)
__SYSCALL_COMMON(1, sys_write)
__SYSCALL_COMMON(2, sys_open)
__SYSCALL_COMMON(3, sys_close)
...
__SYSCALL_COMMON(201, sys_time)
...
```

We now decompose the <code>__SYSCALL_COMMON</code> macro according to the following definitions:

```c
// arch/x86/entry/syscall_64.c:12
#define __SYSCALL_COMMON(nr, sym) __SYSCALL_64(nr, sym)

// arch/x86/entry/syscall_64.c:18
#define __SYSCALL_64(nr, sym) [nr] = __x64_##sym,
```

Thus the fully explained initialization of system call table is as follow:

```c
asmlinkage const sys_call_ptr_t sys_call_table[__NR_syscall_max+1] = {
	[0] = __x64_sys_read,
	[1] = __x64_sys_write,
	[2] = __x64_sys_open,
	[3] = __x64_sys_close,
	...
	[3] = __x64_sys_time,
	...
};
```

Which the time function pointer is corresponding to the line 4 of [previous definition](#bkmk7).

Hence, the total loop for x86_64 system call for time function is completed.

#### Return from system call

The return process are steps to check return status. If exception found, program will jump to the error handling return process labeled <code>swapgs_restore_regs_and_return_to_usermode</code>. Currently we only analyze the normal return process.

Then the first step is to check the return address, <code>%rcx</code> is the return address set for <code>sysret</code>, it should be the same with <code>%rip</code>:

```c
// arch/x86/entry/entry_64.S:127
movq	RCX(%rsp), %rcx
movq	RIP(%rsp), %r11

cmpq	%rcx, %r11	/* SYSRET requires RCX == RIP */
jne	swapgs_restore_regs_and_return_to_usermode
```

This code test user <code>rcx</code>, <code>rip</code> saved in stack according to [struct pt_regs](#stack-structure). According to [push sequence](#bkmk10) in [assembly entry](#assembly-entry) they should be same if stack is not polluted. Next step:

```c
// arch/x86/entry/entry_64.S：144
#ifdef CONFIG_X86_5LEVEL
	ALTERNATIVE "shl $(64 - 48), %rcx; sar $(64 - 48), %rcx", \
		"shl $(64 - 57), %rcx; sar $(64 - 57), %rcx", X86_FEATURE_LA57
#else
	shl	$(64 - (__VIRTUAL_MASK_SHIFT+1)), %rcx
	sar	$(64 - (__VIRTUAL_MASK_SHIFT+1)), %rcx
#endif

	/* If this changed %rcx, it was not canonical */
	cmpq	%rcx, %r11
	jne	swapgs_restore_regs_and_return_to_usermode
```

By debugging and <code>.config</code> file, we found that <code>CONFIG_X86_5LEVEL</code> is set and <code>X86_FEATURE_LA57</code> is not set, thus with the help of [ALTERNATIVE](#alternative), the first part of code simplified to <code>shl \$(64 - 48), %rcx; sar \$(64 - 48), %rcx</code>.

This is set to prevent non-canonical return address (<code>sar</code> instruction adding the same as the highest bit when shifting). Next we have:

```c
// arch/x86/entry/entry_64.S:156
	cmpq	$__USER_CS, CS(%rsp)		/* CS must match SYSRET */
	jne	swapgs_restore_regs_and_return_to_usermode

	movq	R11(%rsp), %r11
	cmpq	%r11, EFLAGS(%rsp)		/* R11 == RFLAGS */
	jne	swapgs_restore_regs_and_return_to_usermode

// arch/x86/entry/entry_64.S:186
	cmpq	$__USER_DS, SS(%rsp)		/* SS must match SYSRET */
	jne	swapgs_restore_regs_and_return_to_usermode
```

This part of code checks the user <code>cs</code>, <code>eflags</code> and <code>ss</code> in stack with [stack structure](#stack-structure), also meant to prevent stack pollution. Next:

```c
// arch/x86/entry/entry_64.S:181
	testq	$(X86_EFLAGS_RF|X86_EFLAGS_TF), %r11
	jnz	swapgs_restore_regs_and_return_to_usermode
```

This part check if <code>eflags.RF</code> and <code>eflags.TF</code> are set. The <code>eflags.RF</code> should be cleared by <code>syscall</code> and cannot be restored by <code>sysret</code>, further process was required to restore it correctly. <code>eflags.TF</code> should not be set in user mode, otherwise will cause infinite loop when #DB (debug exception). Next we have:

```c
// arch/x86/entry/entry_64.S:193
	/* rcx and r11 are already restored (see code above) */
	POP_REGS pop_rdi=0 skip_r11rcx=1
```

According to [POP_REGS](#bkmk11) we can clarify that this is the anti-process against [previous push](#bkmk12). It restores the saved user registers up to and except <code>%rdi</code> according to [stack structure](#stack-structure). The current stack pointer at <code>pt_regs->di</code>. Next:

```c
// arch/x86/entry/entry_64.S:201
	movq	%rsp, %rdi
	movq	PER_CPU_VAR(cpu_tss_rw + TSS_sp0), %rsp
	UNWIND_HINT_EMPTY

	pushq	RSP-RDI(%rdi)	/* RSP */
	pushq	(%rdi)		/* RDI */
```

This code save the current <code>%rsp</code> to <code>%rdi</code>, move restore sp0 value into <code>%rsp</code>. Then push the user <code>%rdi</code> and <code>%rsp</code> into stack. Next:

```c
// arch/x86/entry/entry_64.S:212
	STACKLEAK_ERASE_NOCLOBBER

	SWITCH_TO_USER_CR3_STACK scratch_reg=%rdi
```

With debugging we know that <code>X86_FEATURE_PTI</code> is not set, <code>CONFIG_GCC_PLUGIN_STACKLEAK</code> is not set. Along with the definition of [STACKLEAK_ERASE_NOCLOBBER](#bkmk15), [SWITCH_TO_USER_CR3_STACK](#bkmk14), [SWITCH_TO_USER_CR3_NOSTACK](#bkmk13) and [ALTERNATIVE](#alternative), it is concluded that no code is applied from these macro. Next

```c
	popq	%rdi
	popq	%rsp
	USERGS_SYSRET64
```

By dumping <code>arch/x86/entry/entry_64.o</code> we confirmed the definition of [USERGS_SYSRET64](#bkmk16). So the last code just popped out the user <code>%rdi</code> and <code>%rsp</code> (this will restore to user stack) saved in current stack, then <code>swapgs</code> and <code>0x48 sysret</code>

### Other references

<a id='bkmk16'>USERGS_SYSRET64</a> [GAS macro](#macro) in file <code>arch/x86/include/asm/irqflags.h:147</code>

```c
#define USERGS_SYSRET64				\
	swapgs;					\
	sysretq;
```

<a id='bkmk15'>STACKLEAK_ERASE_NOCLOBBER</a> [GAS macro](#macro) in file <code>arch/x86/entry/calling.h:336</code>

```c
.macro STACKLEAK_ERASE_NOCLOBBER
#ifdef CONFIG_GCC_PLUGIN_STACKLEAK
	PUSH_AND_CLEAR_REGS
	call stackleak_erase
	POP_REGS
#endif
.endm
```

<a id='bkmk14'>SWITCH_TO_USER_CR3_STACK</a> [GAS macro](#macro) in file <code>arch/x86/entry/calling.h:244</code>

```c
.macro SWITCH_TO_USER_CR3_STACK	scratch_reg:req
	pushq	%rax
	SWITCH_TO_USER_CR3_NOSTACK scratch_reg=\scratch_reg scratch_reg2=%rax
	popq	%rax
.endm
```

<a id='bkmk13'>SWITCH_TO_USER_CR3_NOSTACK</a> [GAS macro](#macro) in file <code>arch/x86/entry/calling.h:210</code>

```c
.macro SWITCH_TO_USER_CR3_NOSTACK scratch_reg:req scratch_reg2:req
	ALTERNATIVE "jmp .Lend_\@", "", X86_FEATURE_PTI
	mov	%cr3, \scratch_reg

	ALTERNATIVE "jmp .Lwrcr3_\@", "", X86_FEATURE_PCID

	/*
	 * Test if the ASID needs a flush.
	 */
	movq	\scratch_reg, \scratch_reg2
	andq	$(0x7FF), \scratch_reg		/* mask ASID */
	bt	\scratch_reg, THIS_CPU_user_pcid_flush_mask
	jnc	.Lnoflush_\@

	/* Flush needed, clear the bit */
	btr	\scratch_reg, THIS_CPU_user_pcid_flush_mask
	movq	\scratch_reg2, \scratch_reg
	jmp	.Lwrcr3_pcid_\@

.Lnoflush_\@:
	movq	\scratch_reg2, \scratch_reg
	SET_NOFLUSH_BIT \scratch_reg

.Lwrcr3_pcid_\@:
	/* Flip the ASID to the user version */
	orq	$(PTI_USER_PCID_MASK), \scratch_reg

.Lwrcr3_\@:
	/* Flip the PGD to the user version */
	orq     $(PTI_USER_PGTABLE_MASK), \scratch_reg
	mov	\scratch_reg, %cr3
.Lend_\@:
.endm
```

<a id='bkmk8'>SWITCH_TO_KERNEL_CR3</a> [GAS macro](#macro) in file <code>arch/x86/entry/calling.h:199</code>

```c
.macro SWITCH_TO_KERNEL_CR3 scratch_reg:req
	ALTERNATIVE "jmp .Lend_\@", "", X86_FEATURE_PTI
	mov	%cr3, \scratch_reg
	ADJUST_KERNEL_CR3 \scratch_reg
	mov	\scratch_reg, %cr3
.Lend_\@:
.endm
```

<a id='bkmk9'>PUSH_AND_CLEAR_REGS</a> [GAS macro](#macro) in file <code>arch/x86/entry/calling.h:100</code>

```c
.macro PUSH_AND_CLEAR_REGS rdx=%rdx rax=%rax save_ret=0
	.if \save_ret
	pushq	%rsi		/* pt_regs->si */
	movq	8(%rsp), %rsi	/* temporarily store the return address in %rsi */
	movq	%rdi, 8(%rsp)	/* pt_regs->di (overwriting original return address) */
	.else
	pushq   %rdi		/* pt_regs->di */
	pushq   %rsi		/* pt_regs->si */
	.endif
	pushq	\rdx		/* pt_regs->dx */
	pushq   %rcx		/* pt_regs->cx */
	pushq   \rax		/* pt_regs->ax */
	pushq   %r8		/* pt_regs->r8 */
	pushq   %r9		/* pt_regs->r9 */
	pushq   %r10		/* pt_regs->r10 */
	pushq   %r11		/* pt_regs->r11 */
	pushq	%rbx		/* pt_regs->rbx */
	pushq	%rbp		/* pt_regs->rbp */
	pushq	%r12		/* pt_regs->r12 */
	pushq	%r13		/* pt_regs->r13 */
	pushq	%r14		/* pt_regs->r14 */
	pushq	%r15		/* pt_regs->r15 */
	UNWIND_HINT_REGS

	.if \save_ret
	pushq	%rsi		/* return address on top of stack */
	.endif

	/*
	 * Sanitize registers of values that a speculation attack might
	 * otherwise want to exploit. The lower registers are likely clobbered
	 * well before they could be put to use in a speculative execution
	 * gadget.
	 */
	xorl	%edx,  %edx	/* nospec dx  */
	xorl	%ecx,  %ecx	/* nospec cx  */
	xorl	%r8d,  %r8d	/* nospec r8  */
	xorl	%r9d,  %r9d	/* nospec r9  */
	xorl	%r10d, %r10d	/* nospec r10 */
	xorl	%r11d, %r11d	/* nospec r11 */
	xorl	%ebx,  %ebx	/* nospec rbx */
	xorl	%ebp,  %ebp	/* nospec rbp */
	xorl	%r12d, %r12d	/* nospec r12 */
	xorl	%r13d, %r13d	/* nospec r13 */
	xorl	%r14d, %r14d	/* nospec r14 */
	xorl	%r15d, %r15d	/* nospec r15 */

.endm
```

<a id='bkmk11'>POP_REGS</a> [GAS macro](#macro) in file <code>arch/x86/entry/calling.h:149</code>

```c
.macro POP_REGS pop_rdi=1 skip_r11rcx=0
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %rbp
	popq %rbx
	.if \skip_r11rcx
	popq %rsi
	.else
	popq %r11
	.endif
	popq %r10
	popq %r9
	popq %r8
	popq %rax
	.if \skip_r11rcx
	popq %rsi
	.else
	popq %rcx
	.endif
	popq %rdx
	popq %rsi
	.if \pop_rdi
	popq %rdi
	.endif
.endm
```

## ALTERNATIVE

This is an [GAS macro](#macro), located in <code>arch/x86/include/asm/alternative-asm.h:54</code>. Source code is as follow:

```c
/*
 * Define an alternative between two instructions. If @feature is
 * present, early code in apply_alternatives() replaces @oldinstr with
 * @newinstr. ".skip" directive takes care of proper instruction padding
 * in case @newinstr is longer than @oldinstr.
 */
.macro ALTERNATIVE oldinstr, newinstr, feature
140:
	\oldinstr
141:
	.skip -(((144f-143f)-(141b-140b)) > 0) * ((144f-143f)-(141b-140b)),0x90
142:

	.pushsection .altinstructions,"a"
	altinstruction_entry 140b,143f,\feature,142b-140b,144f-143f,142b-141b
	.popsection

	.pushsection .altinstr_replacement,"ax"
143:
	\newinstr
144:
	.popsection
.endm
```

### Analyze

#### Body & basic logic

The body of macro is <code>oldinstr+skip pad</code>. And if the <code>feature</code> argument has specific bit set, then will replace <code>oldinstr</code> with <code>newinstr</code>. So that system can auto adjust best code for specific situation (e.g: select best code for different type of CPU). The following will illustrate some of the code to make the whole picture:

<a id = "bkmk4"></a>```c
.skip -(((144f-143f)-(141b-140b)) > 0) * ((144f-143f)-(141b-140b)),0x90
```

According to [operator](#infix) that the operator of <code>></code> will return $-1$ if true, $0$ otherwise. Thus if the <code>len(newinstr)>len(oldinstr)</code> the <code>-(((144f-143f)-(141b-140b)) > 0)=-(-1)=1</code>, then this code will add <code>0x90</code>(No operation) instruction for the rest of length.

```c
.pushsection .altinstructions,"a"
altinstruction_entry 140b,143f,\feature,142b-140b,144f-143f,142b-141b
.popsection
```

This piece of code switch to <code>.altinstructions</code> section and using [altinstruction_entry](#bkmk3) macro to create an [struct alt_instr]($bkmk1) structure. Then switch back to the current section.

```c
.pushsection .altinstr_replacement,"ax"
\newinstr
.popsection
```

This piece of code save <code>newinstr</code> in a special section named <code>.altinstr_replacement</code>.

#### apply_alternatives()

After the above preparation, kernel will call <code>apply_alternatives</code> function to replace the relative string. It's located and code are as [follow](#bkmk2).

The function will scan from <code>start</code> to <code>end</code> of section <code>.altinstructions</code> And replace the instructions according to <code>(struct alt_instr *)a->cpuid</code> value. The next content of this chapter will analyze some of the code to illustrate the replacing mechanism:

```c
if (!boot_cpu_has(a->cpuid)) {
   if (a->padlen > 1)
      optimize_nops(a, instr);

   continue;
}
```

<code>boot_cpu_has(a->cpuid)</code> macro check if the cpu has specific target bit set. If yes, replace the old instruction. Otherwise use <code>optimize_nops()</code> to clear the <code>0x90</code>(No operation) instruction created by [previous instruction](#bkmk4).

```c
memcpy(insn_buff, replacement, a->replacementlen);
```

This piece of code replace the old instruction with the new instruction.

The rest of code doing 2 things:
1. Resolve the relative <code>jmp</code> (machine code <code>0xe8</code>) address
2. Add <code>0x90</code>(No operation) instruction if old instruction is longer than new instruction.

### Other reference

<a id = "bkmk1">struct alt_instr</a> structure in file <code>linux/arch/x86/include/asm/alternative.h:58</code>:

```c
struct alt_instr {
	s32 instr_offset;    /* original instruction */
	s32 repl_offset;     /* offset to replacement instruction */
	u16 cpuid;           /* cpuid bit set for replacement */
	u8  instrlen;        /* length of original instruction */
	u8  replacementlen;  /* length of new instruction */
	u8  padlen;          /* length of build-time padding */
} __packed;
```

<a id = "bkmk2">apply_alternatives</a> function in file <code>arch/x86/kernel/alternative.c:372</code>

```c
void __init_or_module noinline apply_alternatives(struct alt_instr *start,
						  struct alt_instr *end)
{
	struct alt_instr *a;
	u8 *instr, *replacement;
	u8 insn_buff[MAX_PATCH_LEN];

	DPRINTK("alt table %px, -> %px", start, end);
	/*
	 * The scan order should be from start to end. A later scanned
	 * alternative code can overwrite previously scanned alternative code.
	 * Some kernel functions (e.g. memcpy, memset, etc) use this order to
	 * patch code.
	 *
	 * So be careful if you want to change the scan order to any other
	 * order.
	 */
	for (a = start; a < end; a++) {
		int insn_buff_sz = 0;

		instr = (u8 *)&a->instr_offset + a->instr_offset;
		replacement = (u8 *)&a->repl_offset + a->repl_offset;
		BUG_ON(a->instrlen > sizeof(insn_buff));
		BUG_ON(a->cpuid >= (NCAPINTS + NBUGINTS) * 32);
		if (!boot_cpu_has(a->cpuid)) {
			if (a->padlen > 1)
				optimize_nops(a, instr);

			continue;
		}

		DPRINTK("feat: %d*32+%d, old: (%pS (%px) len: %d), repl: (%px, len: %d), pad: %d",
			a->cpuid >> 5,
			a->cpuid & 0x1f,
			instr, instr, a->instrlen,
			replacement, a->replacementlen, a->padlen);

		DUMP_BYTES(instr, a->instrlen, "%px: old_insn: ", instr);
		DUMP_BYTES(replacement, a->replacementlen, "%px: rpl_insn: ", replacement);

		memcpy(insn_buff, replacement, a->replacementlen);
		insn_buff_sz = a->replacementlen;

		/*
		 * 0xe8 is a relative jump; fix the offset.
		 *
		 * Instruction length is checked before the opcode to avoid
		 * accessing uninitialized bytes for zero-length replacements.
		 */
		if (a->replacementlen == 5 && *insn_buff == 0xe8) {
			*(s32 *)(insn_buff + 1) += replacement - instr;
			DPRINTK("Fix CALL offset: 0x%x, CALL 0x%lx",
				*(s32 *)(insn_buff + 1),
				(unsigned long)instr + *(s32 *)(insn_buff + 1) + 5);
		}

		if (a->replacementlen && is_jmp(replacement[0]))
			recompute_jump(a, instr, replacement, insn_buff);

		if (a->instrlen > a->replacementlen) {
			add_nops(insn_buff + a->replacementlen,
				 a->instrlen - a->replacementlen);
			insn_buff_sz += a->instrlen - a->replacementlen;
		}
		DUMP_BYTES(insn_buff, insn_buff_sz, "%px: final_insn: ", instr);

		text_poke_early(instr, insn_buff, insn_buff_sz);
	}
}
```

<a id = "bkmk3">altinstruction_entry</a> macro in file <code>arch/x86/include/asm/alternative-asm.h:39</code>:

```c
.macro altinstruction_entry orig alt feature orig_len alt_len pad_len
	.long \orig - .
	.long \alt - .
	.word \feature
	.byte \orig_len
	.byte \alt_len
	.byte \pad_len
.endm
```

## __raw_cmpxchg(ptr, old, new, size, lock)

### Location

<code>./arch/x86/include/asm/cmpxchg.h</code>

### Parameter

| Name | illustration                                              |
| ---- | --------------------------------------------------------- |
| ptr  | Pointer to the target value                               |
| old  | Old value                                                 |
| new  | new value                                                 |
| size | To determine the size (2/4/8) in byte the operation is on |
| lock | Lock preffix, make sure atomic operation                  |

### Logic

If <code>*ptr == old</code> then <code>*ptr = new</code>

Else <code>old = *ptr</code>

Return <code>old</code>

## arch_atomic_try_cmpxchg_acquire(atomic_t *v, int *old, int new)

### Location

<code>./include/linux/atomic-arch-fallback.h</code>

### Logic

If <code>(int)*v == *old</code> then <code>*v = (atomic_t)new</code>

Else <code>*old = (int)*v</code>

Retrun <code>*v == *old</code>

# Linux command

## stdin/stdout/stderr & redirection

### stdin/stdout/stderr

Standard in/out/error are defualt file descriptors (<code>current->filp[0/1/2]</code>) within linux process structure. While executing command, linux will write(<code>current->filp.write()</code>) standard in/out/error data into 0,1,2 file descriptor respectively.

The defualt of the three are screen. With write(<code>current->filp.write()</code>)  method, the related infomation will be printed on screen.

In command line, the file descriptor 0/1/2 natively named "0,1,2" respectively.

### redirection

<code>a > b</code> : 

1. For file name "a" and "b", locate related file descriptor <code>current->filp[x]</code> and <code>current->filp[y]</code>
2. Make <code>current->filp[x]=current->filp[y]</code>
3. If <code>a=0/1/2</code> means standard in/out/error

<code>a >> b</code> :

1. Similar to <code>a > b</code> but will set data pointer of "b" to <code>EOF</code> (End Of File)
2. More like write append
3. If <code>a=0/1/2</code> means standard in/out/error

<code>a >& b</code> :

1. Similar to <code>a > b</code>
2. If <code>a=0/1/2</code> or <code>b=0/1/2</code> means standard in/out/error

### sample

```shell
nohup java -jar app.jar 1>>log 2>&1
```

Firstly, the above command uses <code>1>>log</code>, according to [redicrection](#redirection), it equals stdout to file "log" and set the data pointer of "log" to <code>EOF</code>.

Secondly, it uses <code>2>&1</code>, according to [redicrection](#redirection), it equals stderr to stdout, which is now file "log".

While executing the command, the programm will:

1. Open file descritptor of stdin/stdout/stderr and "log"
2. Set the data pointer of "log" to <code>EOF</code>
3. Write standard output to "1", which is redirected to file "log"
4. Write standard error to "2", which is redirected to "1" and redirected to "log"

## "&&" and "||"

```shell
command1 && command2 [&& command3 ...]
```

Only execute command on the right when command on the left return true.

```shell
command1 || command2 [|| command3 ...]
```

Only execute command on the right when command on the left return false.

## man

Display mannual for specific linux command.

Example for displaying mannual for <code>ls</code> command

```shell
man ls
```

## dmesg

Display the messages in "kernel-ring buffer", where linux will dump kernel related informations.

<code>-c, --read-clear</code> : Clear the ring buffer after first printing its contents
<code>-C, --clear</code> : Clear the ring buffer 
<code>-s, --buffer-size size</code> : Use  a buffer of size to query the kernel ring buffer.  This is 16392 by default
<code>-n, --console-level level</code> : Set the level at which printing of messages is done to the console

example:

```shell
sudo dmesg | grep DMA
```

## grep

Catch lines from command output that include specific string 

example:

```shell
sudo dmesg | grep DMA
```

## ld

Format as

```shell
ld [options] <obj files>
```

<code>-o</code>: Specify output file name
<code>-l</code>: "lc" same as "-l c", format is "l <namespec>" while in this case <namespec>=c. It tell ld to find "lib<namespec>.a" which in this case "libc.a"

## find

```shell
find path -option [-print]
```

<code>path</code>: Directory to execute search
<code>-print</code>: Output to stdout

### Option

<code>-name</code>: Specify name without leading directory, can use "?" for one uncertain character and "*" for uncertain string.
<code>-path</code>: Specify the whole directory (includeing file name & leading directory) pattern for search
<code>-type</code>: "b/d/c/p/l/f" stand for "block device, directory, character device, normal files"
<code>\<expr1\> -a \<expr2\></code>: <code>\<expr2\></code> only valued if <code>\<expr1\></code> return true
<code>\<expr1\> -o \<expr2\></code>: <code>\<expr2\></code> only valued if <code>\<expr1\></code> return false
<code>!\<expr\></code>:  return inverse of <code>\<expr\></code>
<code>-prune</code>: If the file is a directory, descend into it.

#### Sample 1

```shell
find ~/OneDrive -path ~/OneDrive/manjaro_note -a -prune -o -name *.org -a -print
```

will first:

1. Only "~/OneDrive/manjaro_note" match <code>-path</code>, return ture
2. <code>-a</code> indicating execute <code>-prune</code> when found is "~/OneDrive/manjaro_note"
3. <code>-prune</code> return true since "~/OneDrive/manjaro_note" is a directory, and do not descend into it.
4. <code>-o</code> will not execute only if <code>-path ~/OneDrive/manjaro_note -a -prune</code> is false
5. <code>-name</code> match the filename.

In conclusion, <code>-path ~/OneDrive/manjaro_note -a -prune</code> return ture only if what found is "~/OneDrive/manjaro_note" and stop search any files under the direcotry. Other files not in "~/OneDrive/manjaro_note" will be valued by <code>-name *.org</code> and if true, will be printed.

#### Sample 2

```shell
find ~/OneDrive -type f -print0 | xargs -0 -P 8 grep -n "DESCRIPTION"
```

1. <code>-type f</code>: Only display file objects (not directory)
2. <code>-print0</code>: Use null character as separator of results to display
3. <code>xargs -0 -P 8</code>: Process each null separated input as parameter of the following cammand
   "-0" indicates the input is null separated
   "-P 8" indicates max parallel of 8 processing unit
4. <code>grep -n "DESCRIPTION"</code>: Find string "DESCRIPTION", "-n" display line number

This command find all files that containning string of "DESCRIPTION" under directory of <code>~/OneDrive</code>
# gcc

Format as

```shell
gcc [options] <source files>
```
| Option                      | Illustration                                                                                                                                  |
| --------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| <code>-m64</code>           | Set int to 32 bits, long & pointer to 64 bits, generate x86_64 architechture                                                                  |
| <code>-c</code>             | Compile but do not link, create .o files                                                                                                      |
| <code>-g</code>             | Compile with debug information                                                                                                                |
| <code>-o</code>             | Specify output file name                                                                                                                      |
| <code>-fPIC</code>          | If supported for the target machine, produce position-independent code                                                                        |
| <code>-fvisibility=[default | internal                                                                                                                                      | hidden | protected]</code> | Set the defualt attribute for export table of executable, can be overridden by <code>\_\_attribute__ ((visibility("default | internal | hidden | protected")))</code> within source codes. |
| <code>-z muldefs</code>     | Allow multiple definition                                                                                                                     |
| <code>-s</code>             | Remove all symbol table and relocation information from the executable.                                                                       |
| <code>-D</code>             | Provide command line macro definition e.g. <code>-D 'DEV_PATH="/dev/demo"'</code> same as <code>#define DEV_PATH "/dev/demo"</code> in C code |