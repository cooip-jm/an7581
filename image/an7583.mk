#
# AN7583 Profiles
#

include ../../iopsys-common/iopsys-packages.mk
include iopsys-secure-boot.mk
include iopsys-image-common.mk

KERNEL_LOADADDR := 0x80088000
UBOOT_LOADADDR := 0x81e00000
UBOOT_DTS := an7583-basic

define Device/Default
  $(Device/Default-airoha-common)
  UBOOT_TARGET := an7583-aarch64
#
# DEVICE_DTS_LOADADDR must be below memory area used by pstore,
# see:
#   * an7583-pstore.dtsi,
#   * reserved[2] area in the output of u-boot "bdinfo" command
  DEVICE_DTS_LOADADDR := 0x9e400000
endef

define Device/an7583_evb
  DEVICE_MODEL := AN7583EVB
  DEVICE_DTS := an7583_evb
  DEVICE_PACKAGES := $(DEFAULT_DEVICE_PACKAGES) \
                     $(WIRELESS_PACKAGES) \
                     $(PON_PACKAGES)
endef

TARGET_DEVICES += an7583_evb
