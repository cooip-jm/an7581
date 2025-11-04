#Overwite ECONET PATHS to properly migrate to OpenWRT

export ECNT_FEEDS_DIR=$(TOPDIR)/feeds/airoha32
export ECNT_BUILD_DIR=$(ECNT_FEEDS_DIR)/include
export BSP_ROOTDIR=$(ECNT_BUILD_DIR)
export BSP_API_DIR=$(ECNT_FEEDS_DIR)/package/apps/ecnt_api/
export KERNEL_BUILD_DIR
export KERNEL_DIR=$(LINUX_DIR)
export RELEASE_PROFILE=UNION_EN7523_GLIBC_7915D_ActiveEthWan_KERNEL_5_4_demo
