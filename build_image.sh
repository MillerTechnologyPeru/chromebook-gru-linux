#!/bin/sh
#set -x

# Bash script to build a bootable kernel for the RK3399 Chromebooks

# Set defaults
CMDLINE=./cmdline
ITS=./kernel.its

echo ".its file: $ITS"
echo "Kernel command line:\n `cat $CMDLINE`"

# Run mkimage to build a kernel image. Input: its file Output: image in uimg format
mkimage "-D -I dts -O dtb -p 2048" -f $ITS vmlinux.uimg

if [ "$?" -ne 0 ]; 
	then echo "mkimage failed with $?"
	exit 1 
fi
echo "---> mkimage: SUCCESS"

# Check if bootloader.bin available before running vbutil, otherwise create it
	if ! [ -f bootloader.bin ]; then
	echo "---> Generating empty booloader.bin..."
	dd if=/dev/zero of=bootloader.bin bs=512 count=1
fi

# Run vbutil_kernel to get a bootable image for the chromebook
vbutil_kernel \
	--pack vmlinux.kpart \
	--version 1 \
	--vmlinuz vmlinux.uimg \
	--arch aarch64 \
	--keyblock /usr/share/vboot/devkeys/kernel.keyblock \
	--signprivate /usr/share/vboot/devkeys/kernel_data_key.vbprivk \
	--config cmdline \
	--bootloader bootloader.bin

if [ "$?" -ne 0 ]; 
	then echo "vbutil failed."
	exit 1 
fi
echo "---> vbutil_kernel: SUCCESS"
