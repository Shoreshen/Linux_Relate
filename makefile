PW    = $(shell cat ~/文档/PW)
# linux =======================================================================================
linux_clean:
	-make -C ./linux mrproper
linux/.config:
	make -C ./linux ARCH=x86_64 menuconfig
linux/arch/x86/boot/bzImage:linux/.config
	make -C ./linux -j16
# busybox =======================================================================================
busy_clean:
	-make -C ./busybox mrproper
busybox/.config:
	make -C ./busybox menuconfig
busybox/_install: busybox/.config
	docker run --rm --user "$$(id -u):$$(id -g)" -v `pwd`:/io manylinux-shore /bin/bash /io/busy_compile.sh
# filesys =======================================================================================
busybox/_install/dev:busybox/_install
	mkdir $@
busybox/_install/etc:busybox/_install
	mkdir $@
busybox/_install/mnt:busybox/_install
	mkdir $@
busybox/_install/etc/init.d:busybox/_install/etc
	mkdir -p $@
busybox/_install/etc/fstab:busybox/_install/etc
	touch $@
	echo -e "proc  /proc proc  defaults 0 0\ntemps /tmp  rpoc  defaults 0 0\nnone  /tmp  ramfs defaults 0 0\nsysfs /sys  sysfs defaults 0 0\nmdev  /dev  ramfs defaults 0 0" > $@
busybox/_install/etc/init.d/rcS:busybox/install/etc/init.d
	touch $@
	echo -e "mkdir -p /proc\nmkdir -p /tmp\nmkdir -p /sys\nmkdir -p /mnt\n/bin/mount -a\nmkdir -p /dev/pts\nmount -t devpts devpts /dev/pts\necho /sbin/mdev > /proc/sys/kernel/hotplug\nmdev -s" > $@
	chmod 755 $@
busybox/_install/etc/inittab:busybox/_install/etc
	touch $@
	echo -e "::sysinit:/etc/init.d/rcS\n::respawn:-/bin/sh\n::askfirst:-/bin/sh\n::cttlaltdel:/bin/umount -a -r" > $@
	chmod 755 $@
busybox/_install/dev/console:
	echo $(PW) | sudo -S mknod $@ c 5 1
busybox/_install/dev/null:
	echo $(PW) | sudo -S mknod $@ c 1 3
busybox/_install/dev/tty1:
	echo $(PW) | sudo -S mknod $@ c 4 1
_install:busybox/_install/mnt busybox/_install/etc/fstab busybox/_install/etc/init.d/rcS busybox/_install/etc/inittab busybox/_install/dev/console busybox/_install/dev/null busybox/_install/dev/tty1
	mkdir _install
	cp -Rf busybox/_install/* _install
mnt:
	mkdir mnt
rootfs.ext3: linux/arch/x86/boot/bzImage _install/linuxrc mnt _install
	rm -rf rootfs.ext3
	dd if=/dev/zero of=./rootfs.ext3 bs=1M count=32
	mkfs.ext3 rootfs.ext3
# GitHub =======================================================================================
sub_init:
	git submodule update --init --recursive
sub_pull:
	git submodule foreach --recursive 'git pull origin master'
commit: clean
	git add -A
	@echo "Please type in commit comment: "; \
	read comment; \
	git commit -m"$$comment"
sync: commit
	git push -u origin master
# General ======================================================================================
clean:
	-rm -rf _install
	-rm -rf busybox/_install
	-rm rootfs.ext3
	#-make -C ./Driver clean