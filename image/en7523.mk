#
# EN7523 Profiles
#

include ../../iopsys-common/iopsys-packages.mk
include iopsys-secure-boot.mk
include iopsys-image-common.mk

KERNEL_LOADADDR := 0x80088000
UBOOT_LOADADDR := 0x81e00000
UBOOT_DTS := en7523-basic

define Device/Default
  $(Device/Default-airoha-common)
  UBOOT_TARGET := en7523-arm
#
# DEVICE_DTS_LOADADDR must be below memory area used by pstore,
# see:
#   * en7581-pstore.dtsi,
#   * reserved[2] area in the output of u-boot "bdinfo" command
  DEVICE_DTS_LOADADDR := 0x9e400000
endef


define Device/en7523_evb
  DEVICE_MODEL := EN7523EVB
  DEVICE_DTS := en7523_evb
  DEVICE_PACKAGES := $(DEFAULT_DEVICE_PACKAGES) \
			$(WIRELESS_PACKAGES) \
			$(PON_PACKAGES)
endef
TARGET_DEVICES += en7523_evb

define Device/en7523_evb_secure_boot_demo
  $(Device/en7523_evb)
  $(Device/secure-boot)
  $(Device/secure-boot-demo-keys)
endef
TARGET_DEVICES += en7523_evb_secure_boot_demo

