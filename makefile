PW     = $(shell cat ~/文档/PW)
QFLAGS = -machine q35 -cpu EPYC -smp 4 -m 8G -serial stdio -net nic -net user
BUSY_BRANCH = $(shell cd busybox && git rev-parse --abbrev-ref HEAD)
LINUX_BRANCH = $(shell cd linux && git rev-parse --abbrev-ref HEAD)
MENU_BRANCH = $(shell cd menu && git rev-parse --abbrev-ref HEAD)
MYFS_SRC_C = $(wildcard myfs/*.c)
MYFS_SRC_H = $(wildcard myfs/*.h)
CFLAGS = -static -g -o
run_busy: QMEUFL = $(QFLAGS) -accel kvm
run_myfs: QMEUFL = $(QFLAGS) -accel kvm
run_myfs: CFLAGS = -static -o
dbg_busy: QMEUFL = $(QFLAGS) -S -s
dbg_myfs: QMEUFL = $(QFLAGS) -S -s
dbg_myfs: CFLAGS = -static -g -o
test:
	@echo $(BUSY_BRANCH)
	@echo $(LINUX_BRANCH)
# linux ========================================================================================
linux_clean:
	-make -C ./linux mrproper
	-make -C ./linux cleandocs
linux/.config:
	make -C ./linux ARCH=x86_64 menuconfig
linux/arch/x86/boot/bzImage:linux/.config
	make -C ./linux -j16
# busybox ======================================================================================
busy_clean:
	echo $(PW) | sudo -S make -C ./busybox mrproper
busybox/.config:
	make -C ./busybox menuconfig
_install: busybox busybox/.config # Arch doesn't provide glibc-static, use docker to compile
	-rm -rf _install
	docker run --rm -v `pwd`:/io manylinux-shore sh -c "cd /io/busybox && make -j16 && make && make CONFIG_PREFIX=../_install  install"
	echo $(PW) | sudo -S chmod -Rf 777 _install
# filesys ======================================================================================
_install/dev:|_install
	mkdir $@
_install/etc:|_install
	mkdir $@
_install/mnt:|_install
	mkdir $@
_install/etc/init.d:|_install/etc
	mkdir -p $@
_install/etc/fstab:|_install/etc
	touch $@
	echo -e "proc  /proc proc  defaults 0 0\ntemps /tmp  rpoc  defaults 0 0\nnone  /tmp  ramfs defaults 0 0\nsysfs /sys  sysfs defaults 0 0\nmdev  /dev  ramfs defaults 0 0" > $@
_install/etc/init.d/rcS:|_install/etc/init.d
	touch $@
	echo -e "mkdir -p /proc\nmkdir -p /tmp\nmkdir -p /sys\nmkdir -p /mnt\n/bin/mount -a\nmkdir -p /dev/pts\nmount -t devpts devpts /dev/pts\necho /sbin/mdev > /proc/sys/kernel/hotplug\nmdev -s" > $@
	chmod 755 $@
_install/etc/inittab:|_install/etc
	touch $@
	echo -e "::sysinit:/etc/init.d/rcS\n::respawn:-/bin/sh\n::askfirst:-/bin/sh\n::cttlaltdel:/bin/umount -a -r" > $@
	chmod 755 $@
_install/dev/console:|_install/dev
	echo $(PW) | sudo -S mknod $@ c 5 1
_install/dev/null:|_install/dev
	echo $(PW) | sudo -S mknod $@ c 1 3
_install/dev/tty1:|_install/dev
	echo $(PW) | sudo -S mknod $@ c 4 1
mnt:
	mkdir mnt
rootfs.ext3: mnt _install/etc/fstab _install/etc/init.d/rcS _install/etc/inittab _install/dev/console _install/dev/null _install/dev/tty1 |_install/mnt
	-rm -rf rootfs.ext3
	dd if=/dev/zero of=./rootfs.ext3 bs=1M count=32
	mkfs.ext3 rootfs.ext3
	echo $(PW) | sudo -S mount -o loop rootfs.ext3 mnt
	sudo cp -rf ./_install/* mnt
	sudo umount mnt
rootfs.img.gz:rootfs.ext3
	gzip --best -c rootfs.ext3 > rootfs.img.gz
# myfs =========================================================================================
init: $(MYFS_SRC_C) $(MYFS_SRC_H)
	gcc $(CFLAGS) $@ $(MYFS_SRC_C)
init.s: init
	objdump -D $^ > $@
rootfs: init
	echo init | cpio -o --format=newc > $@
# qemu =========================================================================================
run_busy: linux/arch/x86/boot/bzImage rootfs.img.gz
	qemu-system-x86_64 $(QMEUFL) -kernel $(word 1,$^) -initrd $(word 2,$^) 
dbg_busy: linux/arch/x86/boot/bzImage rootfs.img.gz
	qemu-system-x86_64 $(QMEUFL) -kernel $(word 1,$^) -initrd $(word 2,$^) -append "nokaslr"
run_myfs: linux/arch/x86/boot/bzImage rootfs
	qemu-system-x86_64 $(QMEUFL) -kernel $(word 1,$^) -initrd $(word 2,$^)
dbg_myfs: linux/arch/x86/boot/bzImage rootfs
	qemu-system-x86_64 $(QMEUFL) -kernel $(word 1,$^) -initrd $(word 2,$^) -append "nokaslr"
# GitHub =======================================================================================
sub_init:
	git submodule update --init --recursive
sub_pull:
	# cd busybox && git pull origin $(BUSY_BRANCH)
	# cd linux && git pull origin $(LINUX_BRANCH)
	git submodule foreach --recursive 'git pull origin'
commit: clean
	git add -A
	@echo "Please type in commit comment: "; \
	read comment; \
	git commit -m"$$comment"
sync: commit
	git push -u origin master
# General ======================================================================================
clean:
	-rm -rf init *.s
	-rm rootfs.ext3 rootfs.img.gz rootfs
	-make -C ./Driver clean