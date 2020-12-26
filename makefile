PW    = $(shell cat ~/文档/PW)
# linux ========================================================================================
linux_clean:
	-make -C ./linux mrproper
linux/.config:
	make -C ./linux ARCH=x86_64 menuconfig
linux/arch/x86/boot/bzImage:linux/.config
	make -C ./linux -j16
# busybox ======================================================================================
busy_clean:
	-make -C ./busybox mrproper
busybox/.config:
	make -C ./busybox menuconfig
busybox/_install: busybox/.config
	docker run --rm  --user "$(id -u):$(id -g)" -v `pwd`:/io manylinux-shore /bin/bash /io/busy_compile.sh
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
clean: linux_clean busy_clean
	-make -C ./Driver clean