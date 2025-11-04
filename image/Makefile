# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2008-2011 OpenWrt.org

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk
include ../../iopsys-common/iopsys-fit-image.mk
include ../../iopsys-common/iopsys-sign-image.mk

DTS_DIR := ../dts
DEVICE_VARS += DEVICE_UBI_LAYOUT UBOOT_TARGET GPT_LAYOUT_STR GPT_PRIMARY_ENTRY_OFFSET GPT_ALTERNATE_OFFSET FIT_PARTITION ROOTFS_DATA_ALIGMENT

define airoha-emmc-production
  append_emmc_production_image $(1)
endef

define airoha-nand-production
  append-uboot-nand | append-ff-pad-to 0x100000 | append-ubi-image $(1)
endef

define Device/Default-airoha-nand
  $(Device/nand)
  FIT_PARTITION :=
  KERNEL := kernel-bin | lzma | generate-uboot-images | prepare-atf-blobs | airoha-iowrt-kernel-fit lzma external-static
  DEVICE_UBI_LAYOUT := ubinize.cfg.in
  UBINIZE_OPTS := -m 2048 -p 131072 -s 2048
  ARTIFACTS := u-boot-nand.bin u-boot-recovery.bin u-boot-ram.itb bootext.ram
  IMAGE/production.img := $$(call airoha-nand-production)
endef

define Device/Default-airoha-emmc
  $(Device/emmc)
  FIT_PARTITION := 1
  KERNEL := kernel-bin | lzma | generate-uboot-images | prepare-atf-blobs | airoha-iowrt-kernel-fit lzma external-static-with-rootfs
  ARTIFACT/u-boot-emmc.fip := append-uboot-emmc
  ARTIFACTS := u-boot-emmc.fip u-boot-nand.bin u-boot-recovery.bin u-boot-ram.itb bootext.ram
  IMAGE/production.img := $$(call airoha-emmc-production)
  ROOTFS_DATA_ALIGMENT := 0x00080000
endef

define Device/Default-airoha-common
  $(Device/iopsys-common)
  $(Device/non-secure-boot)
  $(Device/Default-airoha-nand)
  PROFILES = Default
  DEVICE_VENDOR := IOPSYS
  IMAGE_LAST_LINK = -squashfs-sysupgrade.itb
  IMAGE/sysupgrade.itb = iopsys-fit-upgrade-image | iopsys-sign-image | create-last-link $$(IMAGE_LAST_LINK) last.itb
  IMAGES := sysupgrade.itb production.img
  KERNEL_INITRAMFS := kernel-bin | lzma | iowrt-kernel-fit lzma external-static-with-initrd
  KERNEL_NAME := vmlinux
  UBOOT_RAM_NODTB_IMAGE = $(STAGING_DIR_IMAGE)/$$(UBOOT_TARGET)-u-boot-nodtb.bin
  UBOOT_RAM_LOADADDR := $(UBOOT_LOADADDR)
  UBOOT_RAM_COMPRESSION := lzma
  UBOOT_ENV_BLACKLIST := $(DEFAULT_UBOOT_ENV_BLACKLIST)
  ARTIFACT/u-boot-recovery.bin := append-uboot-recovery
  ARTIFACT/u-boot-nand.bin := append-uboot-nand
  ARTIFACT/u-boot-ram.itb := append-uboot-ram | lzma | iowrt-uboot-fit lzma
  ARTIFACT/bootext.ram := append-bootext-ram
endef

define Device/non-secure-boot
  SECURE_BOOT := 0
endef

define Device/secure-boot
  SECURE_BOOT := 1
  KERNEL := kernel-bin | lzma | iopsys-secure-boot | squashfs-hash | iowrt-kernel-fit lzma external-static
  ARTIFACT/keys.tar := copy-keys
  ARTIFACT/efuse.bin := generate-rotpk-fuse
  ARTIFACTS += keys.tar efuse.bin
  DEVICE_PACKAGES += u-boot-en7523-arm-sb
  UBOOT_TARGET := en7523-arm-sb
endef

define Device/secure-boot-demo-keys
  DEVICE_MODEL += (Secure Boot, demo keys)
  SECURE_BOOT_KEY_DIR := $(TOPDIR)/feeds/airoha/bootloader/bootloader/ATF/arm-trusted-firmware-2.3/plat/ecnt/key
  SECURE_BOOT_ROTPK := rot_key_4096.pem
  SECURE_BOOT_ROTPK_HASH_ALG := sha512
  SECURE_BOOT_ROTPK_KEY_ALG := rsa
  SECURE_BOOT_ROTPK_KEY_SIZE := 4096
  SECURE_BOOT_ENC_ALG := aes256
  SECURE_BOOT_ENC_KEY := aes_aes256
  SECURE_BOOT_FITPK := fit_key
endef

BSP_CORE_PACKAGES := \
	kmod-airoha_bootr \
	kmod-ether \
	kmod-fe \
	kmod-hsgmii_lan \
	kmod-hw_nat \
	kmod-ifc \
	kmod-qdma_lan \
	kmod-qdma_wan \
	kmod-tccicmd \
	kmod-tcphy \
	compileoption_lib \
	libbsd \
	ecnt_api \
	ecnt_bsp \
	ecnt_prepare \
	ecnt_prolinecmd \
	ecnt_sys \
	ecnt_wl_e2p_chk \
	ethcmd \
	hwnat_7510 \
	arm-trusted-firmware-airoha

ifneq ($(SUBTARGET),en7523)
BSP_CORE_PACKAGES += \
	kmod-ae_wan \
	-kmod-sif \
	kmod-sif-compat \
	kmod-lro_lan \
	kmod-lro_wan \
	kmod-tcledctrl \
	-kmod-tcledctrl_stub \
	kmod-ecnt_legacy_api
endif

ifeq ($(SUBTARGET),an7581)
BSP_CORE_PACKAGES += \
	u-boot-an7581-aarch64
endif

ifeq ($(SUBTARGET),an7583)
BSP_CORE_PACKAGES += \
	u-boot-an7583-aarch64
endif

ifeq ($(SUBTARGET),en7523)
BSP_CORE_PACKAGES += \
	kmod-tso \
	kmod-sif \
	-kmod-sif-compat \
	kmod-ecnt_thermal \
	kmod-tcledctrl_stub \
	-kmod-tcledctrl \
	u-boot-en7523-arm
endif

PERIPHERAL_PACKAGES := \
	kmod-ata-core \
	kmod-ata-ahci \
	kmod-usb3 \
	kmod-usb-ledtrig-usbport \
	kmod-gpio-button-hotplug \
	kmod-gpio-nxp-74hc164 \
	kmod-leds-gpio \
	kmod-spi-gpio \
	kmod-i2c-core \
	kmod-usb-storage \
	i2c-tools

NETWORK_PACKAGES := \
	kmod-ebtables \
	kmod-ebtables-ipv4 \
	kmod-ebtables-ipv6 \
	kmod-ipt-nathelper-rtsp \
	kmod-npu \
	kmod-npu_wifi_offload \
	-kmod-ipt-offload \
	-kmod-nf-flow \
	ebtables-legacy \
	ebtables-legacy-utils \
	mcproxy

ifneq ($(SUBTARGET),en7523)
NETWORK_PACKAGES += \
	kmod-npu_wifi \
	kmod-en_npu \
	kmod-speedtest \
	kmod-airoha_gre_hw_offload \
	kmod-mdio_arht \
	kmod-8811_bbu_api \
	kmod-8831 \
	kmod-8831_bbu_api \
	kmod-air_en8811h \
	kmod-airoha_l2tp_offload \
	kmod-airoha_vxlan_hw_offload
endif

ifeq ($(SUBTARGET),an7581)
NETWORK_PACKAGES += \
	npu-firmware-an7581-mt7916 \
	npu-firmware-an7581-mt7992 \
	npu-firmware-an7581-mt7996
endif

ifeq ($(SUBTARGET),an7583)
NETWORK_PACKAGES += \
	npu-firmware-an7583-mt7916 \
	npu-firmware-an7583-mt7992 \
	npu-firmware-an7583-mt7993 \
	npu-firmware-an7583-mt7996
endif

ifeq ($(SUBTARGET),en7523)
NETWORK_PACKAGES += \
	kmod-gre_hw_offload \
	kmod-sdn_igmp
endif

WIRELESS_PACKAGES := \
	MAC80211_DEBUGFS \
	MAC80211_MESH \
	wireless-regdb \
	iw

ifneq ($(SUBTARGET),en7523)
WIRELESS_PACKAGES += \
	kmod-cfg80211_logan \
	kmod-mac80211_logan \
	hostapd_logan-openssl \
	hostapd_logan-utils \
	wpa-supplicant_logan-openssl \
	wpa-cli_logan \
	logan_kite \
	kmod-mt_wifi_cmn_kite \
	kmod-mt_wifi7_kite \
	kmod-mt_hwifi_kite \
	kmod-en_npu_kite \
	kmod-mtk_pci_kite \
	kmod-connac_if_kite \
	kmod-mt7992 \
	kmod-mt799a \
	mwctl \
	ated_ext \
	wificonf
endif

ifeq ($(SUBTARGET),en7523)
WIRELESS_PACKAGES += \
	kmod-cfg80211_en7523 \
	kmod-mac80211_en7523 \
	hostapd_en7523-openssl \
	hostapd_en7523-utils \
	wpa-supplicant_en7523-openssl \
	wpa-cli_en7523 \
	kmod-mt76-core_en7523 \
	kmod-mt7615-common_en7523 \
	kmod-mt7915e_en7523 \
	kmod-whnat \
	airoha-mt76-eeproms \
	mt76-test_en7523

NETWORK_PACKAGES += \
	kmod-npu-firmware
endif

UTILITY_PACKAGES := \
	e2fsprogs \
	fdtextract \
	uboot-envtools

DEFAULT_DEVICE_PACKAGES := \
	$(BSP_CORE_PACKAGES) \
	$(PERIPHERAL_PACKAGES) \
	$(NETWORK_PACKAGES) \
	$(UTILITY_PACKAGES)

PON_PACKAGES := \
	kmod-pon_vlan \
	kmod-pon_mac_filter \
	kmod-xpon_1g \
	kmod-xpon_igmp \
	kmod-xpon_int \
	kmod-xpon_map \
	xpon_app \
	xpon_bsp

ifneq ($(SUBTARGET),en7523)
PON_PACKAGES += \
	kmod-dpoe_service \
	kmod-an8901 \
	kmod-bbf247 \
	kmod-lddla \
	kmod-lddla_1g \
	kmod-xpon_hal \
	kmod-xpon_10g \
	kmod-xpon_phy_10g
endif

ifeq ($(SUBTARGET),en7523)
PON_PACKAGES += \
	kmod-gpon_flow \
	kmod-xpon_phy
endif

VOICE_PACKAGES := \
	voip_app

ifneq ($(SUBTARGET),en7523)
VOICE_PACKAGES += \
	kmod-voip_driver
endif

ifeq ($(SUBTARGET),en7523)
VOICE_PACKAGES += \
	kmod-voip_driver-mxl_bin
endif

define Image/Build
	$(call Image/Build/$(1),$(1))
endef

include $(SUBTARGET).mk
-include $(TOPDIR)/target/linux/feed-devices/Makefile
$(eval $(call BuildImage))
