PW     = $(shell cat ~/文档/PW)
QFLAGS = -machine q35 -cpu EPYC -accel kvm -smp 4 -m 8G -append "root=/dev/ram init=/linuxrc" -serial stdio
# linux ========================================================================================
linux_clean:
	-make -C ./linux mrproper
linux/.config:
	make -C ./linux ARCH=x86_64 menuconfig
linux/arch/x86/boot/bzImage:linux/.config
	make -C ./linux -j16
# busybox ======================================================================================
busy_clean:
	echo $(PW) | sudo -S make -C ./busybox mrproper
busybox/.config:
	make -C ./busybox menuconfig
busybox/_install: busybox/.config
	docker run --rm -v `pwd`:/io manylinux-shore sh -c "cd /io/busybox && make -j16 && make && make install"
# filesys ======================================================================================
_install:busybox/_install
	mkdir _install
	cp -rf busybox/_install/* _install
_install/dev:_install
	-mkdir $@
_install/etc:_install
	-mkdir $@
./_install/mnt:_install
	-mkdir $@
_install/etc/init.d:_install/etc
	-mkdir -p $@
_install/etc/fstab:_install/etc
	touch $@
	echo -e "proc  /proc proc  defaults 0 0\ntemps /tmp  rpoc  defaults 0 0\nnone  /tmp  ramfs defaults 0 0\nsysfs /sys  sysfs defaults 0 0\nmdev  /dev  ramfs defaults 0 0" > $@
_install/etc/init.d/rcS:_install/etc/init.d
	touch $@
	echo -e "mkdir -p /proc\nmkdir -p /tmp\nmkdir -p /sys\nmkdir -p /mnt\n/bin/mount -a\nmkdir -p /dev/pts\nmount -t devpts devpts /dev/pts\necho /sbin/mdev > /proc/sys/kernel/hotplug\nmdev -s" > $@
	chmod 755 $@
_install/etc/inittab:_install/etc
	touch $@
	echo -e "::sysinit:/etc/init.d/rcS\n::respawn:-/bin/sh\n::askfirst:-/bin/sh\n::cttlaltdel:/bin/umount -a -r" > $@
	chmod 755 $@
_install/dev/console:_install/dev
	-echo $(PW) | sudo -S mknod $@ c 5 1
_install/dev/null:_install/dev
	-echo $(PW) | sudo -S mknod $@ c 1 3
_install/dev/tty1:_install/dev
	-echo $(PW) | sudo -S mknod $@ c 4 1
mnt:
	mkdir mnt
test: _install/dev/console
	@echo $@
rootfs.ext3: mnt ./_install/mnt _install/etc/fstab _install/etc/init.d/rcS _install/etc/inittab _install/dev/console _install/dev/null _install/dev/tty1
	-rm -rf rootfs.ext3
	dd if=/dev/zero of=./rootfs.ext3 bs=1M count=32
	mkfs.ext3 rootfs.ext3
	echo $(PW) | sudo -S mount -o loop rootfs.ext3 mnt
	sudo cp -rf ./_install/* mnt
	sudo umount mnt
rootfs.img.gz:rootfs.ext3
	gzip --best -c rootfs.ext3 > rootfs.img.gz

# qemu =========================================================================================
run: linux/arch/x86/boot/bzImage rootfs.img.gz
	qemu-system-x86_64 $(QFLAGS) -kernel $(word 1,$^) -initrd $(word 2,$^)
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
	-rm rootfs.ext3 rootfs.img.gz
	#-make -C ./Driver clean