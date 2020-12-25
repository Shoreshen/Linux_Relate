# make file name has to be "Makefile"
# need to install "base-devel" and kernel headers (e.g. "linux59-headers") packages

# Base variable =========================================================================
module_name = demo
TEST_TRG = test
# Extend variable =======================================================================
DEV_PATH = /dev/$(module_name)
obj-m = $(module_name).o
KDIR  = /lib/modules/$(shell uname -r)/build
PWD   = $(shell pwd)
PW    = $(shell cat ~/文档/PW)
CFLAGS = -m64 -g -o $(TEST_TRG).run -D 'DEV_PATH="$(DEV_PATH)"'
# Module relatec ========================================================================
$(module_name).ko: $(module_name).c $(module_name).h Devlib.h iocmd.h
	make -C $(KDIR) M=$(PWD) modules
clean:
	make -C $(KDIR) M=$(PWD) clean
	rm $(TEST_TRG).run
insmod:$(module_name).ko
	echo $(PW) | sudo -S insmod $(module_name).ko
	sudo chmod 666 $(DEV_PATH)
rmmod: $(DEV_PATH)
	echo $(PW) | sudo -S rmmod $(module_name)
dmsg:
	echo $(PW) | sudo -S dmesg | grep $(module_name)
# Test program ==========================================================================
test: $(TEST_TRG).c iocmd.h
	gcc $(CFLAGS) $(TEST_TRG).c 
test_run: $(TEST_TRG).run
	./$(TEST_TRG).run
# Others ================================================================================
search:
	@echo "Please type in search key: "; \
	read key; \
	find /usr/lib/modules/5.9.11-3-MANJARO/build/ -type f -name "*.h" -print0 | xargs -P 8 -0 grep "$$key"
	# If the last file found by "find" does not contain $$key, will return 1 from "grep", then make will return erro