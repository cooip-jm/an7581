#
# Copyright (C) 2009 OpenWrt.org
#

ARCH:=arm
SUBTARGET:=en7523
BOARDNAME:=en7523/en7529/en7562 based boards
CPU_TYPE:=cortex-a7
FEATURES+=squashfs nand ramdisk ubifs
KERNELNAME:=vmlinux

define Target/Description
	Build firmware images for Econet en7523 ARM based boards.
endef

ifndef DUMP
    include $(PLATFORM_SUBDIR)/UNION_EN7523_7915D_ActiveEthWan_KERNEL_5_4_demo.mak
    include $(PLATFORM_SUBDIR)/defines/dir.mak
    include $(PLATFORM_SUBDIR)/defines/rule.mak
    include $(PLATFORM_SUBDIR)/defines/econet_feed_paths.mk
endif
