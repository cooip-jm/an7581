include $(INCLUDE_DIR)/kernel.mk
#include $(ECNT_BUILD_DIR)/ecnt-trunkdir.mk

ifeq ($(strip $(REBUILDCODE)),)
    MODULE_DIR=$(KERNEL_BUILD_DIR)
    MODULES_PRIV_SRC_DIR=$(MODULE_DIR)
    MODULES_PUBLIC_SRC_DIR=$(MODULE_DIR)
    TOOLS_DIR=$(GLOBAL_INC_DIR)
    export TOOLS_TRX_DIR=$(TOOLS_DIR)/trx
    export TRUNK_DIR=$(KERNEL_BUILD_DIR)
else
    MODULE_DIR=$(TRUNK_DIR)/modules
    MODULES_PRIV_SRC_DIR=$(MODULE_DIR)/private
    MODULES_PUBLIC_SRC_DIR=$(MODULE_DIR)/public
    TOOLS_DIR=$(TRUNK_DIR)/tools
    export TOOLS_TRX_DIR=$(TOOLS_DIR)/trx
endif

ifneq ($(strip $(TCSUPPORT_QDMA_OPENSOURCE)),)
    export MODULES_ALL_QDMA_DIR=$(MODULES_PRIV_SRC_DIR)/qdma_opensource
else
    export MODULES_ALL_QDMA_DIR=$(MODULES_PRIV_SRC_DIR)/qdma
endif

export GLOBAL_INC_DIR=$(TRUNK_DIR)/linux-$(LINUX_VERSION)/include/global_inc
export KERNEL_ECNT_DIR=$(TRUNK_DIR)/linux-$(LINUX_VERSION)/
export BOOTROM_DIR=$(PKG_BUILD_DIR)/src
export MBEDTLS=$(PKG_BUILD_DIR)/tools/mbedtls-2.5.1

export BSP_EXT_INSTALL=$(KERNEL_BUILD_DIR)/install_bsp
export BSP_EXCL_INSTALL=$(KERNEL_BUILD_DIR)/install_bspapp_exclusive
export BSP_INT_INSTALL=$(KERNEL_BUILD_DIR)/install_bsp_exclusive
VERSION_DIR=$(GLOBAL_INC_DIR)/version
export PROFILE_DIR=$(TOPDIR)/target/linux/$(BOARD)/$(SUBTARGET)/


