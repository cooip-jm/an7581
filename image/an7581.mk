#
# EN7581 Profiles
#

include ../../iopsys-common/iopsys-packages.mk
include iopsys-secure-boot.mk
include iopsys-image-common.mk

KERNEL_LOADADDR := 0x80088000
UBOOT_LOADADDR := 0x81e00000
UBOOT_DTS := en7581-basic

define Device/Default
  $(Device/Default-airoha-common)
  UBOOT_TARGET := an7581-aarch64
#
# DEVICE_DTS_LOADADDR must be below memory area used by pstore,
# see:
#   * en7581-pstore.dtsi,
#   * reserved[2] area in the output of u-boot "bdinfo" command
  DEVICE_DTS_LOADADDR := 0x9e400000
endef

define Device/en7581_evb
  DEVICE_MODEL := EN7581EVB
  DEVICE_DTS := en7581_evb en7581_eagle en7581_kite
  DEVICE_PACKAGES := $(DEFAULT_DEVICE_PACKAGES) \
                     $(WIRELESS_PACKAGES) \
                     $(PON_PACKAGES)
endef

define Device/en7581_eagle
  DEVICE_MODEL := EN7581EVB_EAGLE
  DEVICE_DTS := en7581_eagle
  DEVICE_PACKAGES := $(DEFAULT_DEVICE_PACKAGES) \
                     $(WIRELESS_PACKAGES) \
                     $(PON_PACKAGES) logan_eagle
endef

define Device/en7581_kite
  DEVICE_MODEL := EN7581EVB_KITE
  DEVICE_DTS := en7581_kite
  DEVICE_PACKAGES := $(DEFAULT_DEVICE_PACKAGES) \
                     $(WIRELESS_PACKAGES) \
                     $(PON_PACKAGES) logan_kite kmod-mt_cfg80211 kmod-mt_wifi7 \
                     kmod-mt_hwifi kmod-en_npu kmod-mtk_pci kmod-mt7992 kmod-mt799a \
                     kmod-connac_if kmod-mt_wifi_cmn  mwctl
endef

TARGET_DEVICES += en7581_evb en7581_eagle en7581_kite
