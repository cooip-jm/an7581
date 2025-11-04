# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2008-2011 OpenWrt.org

include $(TOPDIR)/rules.mk

BOARD:=airoha
BOARDNAME:=IOPSYS Airoha EN75xx / AN75XX
SUBTARGETS:=an7581 en7523 an7583
FEATURES:=squashfs usb ubifs

KERNEL_PATCHVER:=5.4
KERNEL_TESTING_PATCHVER:=5.4

# Workaround for build fail. Enable all packages beside ipt-offload
DEVICE_TYPE := basic
DEFAULT_PACKAGES += dnsmasq firewall ip6tables iptables odhcp6c ppp ppp-mod-pppoe

define Target/Description
	Build IOPSYS firmware images for Airoha EN75xx based boards.
endef

include $(INCLUDE_DIR)/target.mk

define Target/Config
	source "$(CURDIR)/Config.in"
endef

# We use OpenSSL, so replace libustream-mbedtls with libustream-openssl
DEFAULT_PACKAGES := $(patsubst libustream-mbedtls,libustream-openssl,$(DEFAULT_PACKAGES))

define Kernel/Prepare/Default
	$(LINUX_CAT) $(DL_DIR)/$(LINUX_SOURCE) | $(TAR) -C $(KERNEL_BUILD_DIR) $(TAR_OPTIONS)
ifneq ("$(wildcard $(PLATFORM_DIR)/files-$(KERNEL_PATCHVER))", "")
	$(CP) $(PLATFORM_DIR)/files-$(KERNEL_PATCHVER)/. $(LINUX_DIR)/
endif
	rm -rf $(LINUX_DIR)/patches; mkdir -p $(LINUX_DIR)/patches; \
	cd $(PLATFORM_DIR)/patches-$(KERNEL_PATCHVER); for patch in *.patch; do \
		cp -v $$$$patch $(LINUX_DIR)/patches; \
		echo $$$$patch >> $(LINUX_DIR)/patches/series; \
	done
	$(call PatchDir,$(LINUX_DIR),$(PATCH_DIR),)
endef

$(eval $(call BuildTarget))
