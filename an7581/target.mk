#
# Copyright (C) 2009 OpenWrt.org
#

ARCH:=aarch64
SUBTARGET:=an7581
BOARDNAME:=an7551/an7566/an7581 based boards
CPU_TYPE:=cortex-a53
FEATURES+=squashfs nand ramdisk ubifs
KERNELNAME:=vmlinux

DEFAULT_PACKAGES+=blkpg-part

define Target/Description
	Build firmware images for Airoha an7581 ARM based boards.
endef

ifndef DUMP
    include $(PLATFORM_SUBDIR)/UNION_AN7581_KITE_LOGAN_EMMC_OPTEE_KERNEL_5_4_demo.mak
    include $(PLATFORM_SUBDIR)/defines/dir.mak
    include $(PLATFORM_SUBDIR)/defines/rule_common.mak
    include $(PLATFORM_SUBDIR)/defines/rule.mak
    include $(PLATFORM_SUBDIR)/defines/econet_feed_paths.mk
endif
