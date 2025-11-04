define release_bindir_gen
    $$(echo $(1) | sed 's|$(TRUNK_DIR)|$(BIN_BAK_PATH)|')/$(TCPLATFORM)
endef
ifeq ($(strip $(TCSUPPORT_OPENWRT)),)
export TRUNK_DIR=$(shell pwd)
endif
export BIN_BAK_PATH=$(TRUNK_DIR)
export GLOBAL_INC_DIR=$(TRUNK_DIR)/global_inc
ifneq ($(strip $(TCSUPPORT_UBOOT)),)
    export BOOTROM_DIR=$(TRUNK_DIR)/bootloader
    export UBOOT_DIR=$(BOOTROM_DIR)/Uboot
    export ATF_DIR=$(BOOTROM_DIR)/ATF
else
    export BOOTROM_DIR=$(TRUNK_DIR)/bootrom
endif
export KERNEL_ECNT_DIR=$(TRUNK_DIR)/linux-ecnt
PROJECT_DIR=$(TRUNK_DIR)/Project
FT_DIR=$(TRUNK_DIR)/bootrom_ft
APP_DIR=$(TRUNK_DIR)/apps
BSP_DIR=$(TRUNK_DIR)/BSP
export APP_BSP_DIR=$(TRUNK_DIR)/app_bsp
export BSP_ROOTDIR=$(APP_BSP_DIR)
export ECNT_BSP_DIR=$(TRUNK_DIR)/ecnt_bsp
INSTALL_BSP_DIR=$(TRUNK_DIR)/install_bsp
export BSP_EXT_INSTALL=$(INSTALL_BSP_DIR)
MODULE_DIR=$(TRUNK_DIR)/modules
TOOLS_DIR=$(TRUNK_DIR)/tools
export FILESYSTEM_BSP_DIR=$(TRUNK_DIR)/filesystem
export FILESYSTEM_ORI_DIR=$(TRUNK_DIR)/filesystem_original
export RELEASE_BSP_DIR=$(TRUNK_DIR)/release_bsp
export DOC_DIR=$(TRUNK_DIR)/doc
####################################################################################
# sub-class of TOOLS_DIR=$(TRUNK_DIR)/tools
export TOOLS_UBOOT_DIR=$(TOOLS_DIR)/uboot
LZMA_LIB=$(TOOLS_DIR)/squashfs-tools/lzma/C/7zip/Compress/LZMA_Lib
LZMA_ALONE=$(TOOLS_DIR)/squashfs-tools/lzma/C/7zip/Compress/LZMA_Alone
SPI_NAND_ECC_GEN=$(TOOLS_DIR)/spi_nand_ctrl_ecc
export TOOLS_TRX_DIR=$(TOOLS_DIR)/trx
export MBEDTLS=$(TOOLS_DIR)/mbedtls-2.5.1
####################################################################################
# sub-class of KERNEL
KERNEL_EXT_DIR=$(TRUNK_DIR)/kernel_ext
export KERNEL_DIR=$(TRUNK_DIR)/linux
export KERNEL_HEADER=$(KERNEL_DIR)/include
export IPTABLE_KERNEL_DIR=$(KERNEL_DIR)
ifneq ($(strip $(TCSUPPORT_2_6_36_KERNEL)),)
    export KERNEL_DIR=$(TRUNK_DIR)/linux-2.6.36
endif
ifneq ($(strip $(TCSUPPORT_3_18_21_KERNEL)),)
    export KERNEL_DIR=$(TRUNK_DIR)/linux-3.18.21
    export KERNEL_HEADER=$(KERNEL_DIR)/usr/include
    IPTABLE_KERNEL_DIR=$(KERNEL_DIR)/usr
endif
ifneq ($(strip $(TCSUPPORT_4_4_KERNEL)),)
    export KERNEL_DIR=$(TRUNK_DIR)/linux-4.4.115
    export KERNEL_HEADER=$(KERNEL_DIR)/usr/include
    IPTABLE_KERNEL_DIR=$(KERNEL_DIR)/usr
endif
ifneq ($(strip $(TCSUPPORT_5_4_KERNEL)),)
    export KERNEL_DIR=$(TRUNK_DIR)/linux-5.4.55
    export KERNEL_HEADER=$(KERNEL_DIR)/usr/include
    IPTABLE_KERNEL_DIR=$(KERNEL_DIR)/usr
endif
export KERNEL_ECNT_INC_DIR=$(KERNEL_ECNT_DIR)/include
export KERNEL_EXT_DIR=$(KERNEL_ECNT_DIR)
export KERNEL_EXT_INC_DIR=$(KERNEL_ECNT_DIR)/include
export KERNEL_EXT_SPI_NAND_DIR=$(KERNEL_ECNT_DIR)/drivers/mtd/chips
export KERNEL_EXT_LIB_DIR=$(KERNEL_ECNT_DIR)/lib
export KERNEL_ECNT_ARCH_ARM_ECNT_DIR=$(KERNEL_ECNT_DIR)/arch/arm/mach-econet
export KERNEL_ECNT_ARCH_ARM_INC_DIR=$(KERNEL_ECNT_DIR)/arch/arm/include
####################################################################################
# sub-class of INSTALL_BSP_DIR=$(TRUNK_DIR)/install_bsp and BSP_EXT_INSTALL
export LIB_INSTALL_DIR=$(INSTALL_BSP_DIR)/lib_install
export LIB_DIR=$(LIB_INSTALL_DIR)
export APP_BSP_LIB_DIR=$(LIB_INSTALL_DIR)
export FILESYSTEM_DIR=$(INSTALL_BSP_DIR)/filesystem
export TOOLS_APP_DIR=$(INSTALL_BSP_DIR)/tools
export PROJECT_APP_DIR=$(INSTALL_BSP_DIR)/Project
export FS_GEN_DIR = $(INSTALL_BSP_DIR)/filesystem_bsp
INIC_CLIENT_FILE_DIR=$(FILESYSTEM_DIR)/userfs/VDSL_CO_file
export APP_BSP_API_LIB_OUTPUT_DIR=$(APP_BSP_LIB_DIR)
export BSP_EXT_INC=$(BSP_EXT_INSTALL)/inc
export BSP_EXT_FS=$(BSP_EXT_INSTALL)/fs
export BSP_EXT_LIB=$(BSP_EXT_FS)/lib
export BSP_EXT_MODULE=$(BSP_EXT_FS)/lib/modules
export BSP_EXT_FS_BIN=$(BSP_EXT_FS)/bin
export BSP_EXT_FS_USR=$(BSP_EXT_FS)/usr/bin
export BSP_EXT_FS_USEFS_DIR=$(BSP_EXT_FS)/userfs
export BSP_EXT_FS_USEFS=$(BSP_EXT_FS)/userfs/bin
export BSP_EXT_MAKE=$(BSP_EXT_INSTALL)/make
export BSP_EXT_TCLINUX_BUILDER=$(BSP_EXT_INSTALL)/tclinux_builder
export BSP_EXT_TOOLS=$(BSP_EXT_INSTALL)/tools
export BSP_EXT_TOOLS_DTC=$(BSP_EXT_TOOLS)/dtc-1.4.0
export INSTALL_KERNELHEADER=$(BSP_EXT_INSTALL)/kernel_header
export INSTALL_GLOBALINC=$(BSP_EXT_INSTALL)/global_inc_install
ifneq ($(strip $(CUSTOM)),)
export PROFILE_APP_DIR=$(PROJECT_APP_DIR)/profile/$(CUSTOM)/$(PROFILE)
else
export PROFILE_APP_DIR=$(PROJECT_APP_DIR)/profile/$(PROFILE)
endif
export PROJECT_MAKE_INC_APP_DIR=$(PROJECT_APP_DIR)/make_inc
export PROJECT_LIB_APP_DIR=$(PROJECT_APP_DIR)/lib
####################################################################################
# sub-class of APP_BSP_DIR=$(TRUNK_DIR)/app_bsp and BSP_ROOTDIR
export BSP_PRIVATEDIR=$(APP_BSP_DIR)/private
export BSP_API_DIR=$(BSP_PRIVATEDIR)/API
export APP_COMPILEOPTION_LIB_DIR=$(APP_BSP_DIR)/private_exclusive/compileoption_lib
# for source code copy and install
APP_BSP_EXCLUSIVE_PRIVATE_DIR=$(APP_BSP_DIR)/private_exclusive
APP_BSP_EXCLUSIVE_PUBLIC_DIR=$(APP_BSP_DIR)/public_exclusive
APP_BSP_PRIVATEDIR=$(APP_BSP_DIR)/private
APP_BSP_PUBLICDIR=$(APP_BSP_DIR)/public
APP_BSP_ETHCMD_DIR=$(APP_BSP_PRIVATEDIR)/ethcmd
APP_BSP_RA_HWNAT_7510_DIR=$(APP_BSP_PRIVATEDIR)/hw_nat_7510
export BSP_INT_INSTALL=$(APP_BSP_DIR)/install_bsp_exclusive
export BSP_EXCL_INSTALL=$(APP_BSP_DIR)/install_bspapp_exclusive
export BSP_INT_INC=$(BSP_INT_INSTALL)/inc
export BSP_INT_BIN=$(BSP_INT_INSTALL)/bin
export BSP_INT_FS=$(BSP_INT_INSTALL)/fs
export BSP_INT_LIB=$(BSP_INT_FS)/lib
export BSP_INT_FS_BIN=$(BSP_INT_FS)/bin
export BSP_INT_FS_USR=$(BSP_INT_FS)/usr/bin
export BSP_INT_FS_USEFS=$(BSP_INT_FS)/userfs/bin
export BSP_INT_FS_USR_SCRIPT=$(BSP_INT_FS)/usr/script
export BSP_EXCL_FS=$(BSP_EXCL_INSTALL)/fs
export BSP_EXCL_LIB=$(BSP_EXCL_FS)/lib
export BSP_EXCL_INC=$(BSP_EXCL_INSTALL)/inc
export BSP_EXCL_FS_BIN=$(BSP_EXCL_FS)/bin
export BSP_EXCL_FS_USR=$(BSP_EXCL_FS)/usr/bin
export BSP_EXCL_FS_USEFS=$(BSP_EXCL_FS)/userfs
export BSP_EXCL_FS_USEFS_BIN=$(BSP_EXCL_FS)/userfs/bin
VERSION_DIR=$(APP_BSP_DIR)/version
####################################################################################
# sub-class of APP_DIR=$(TRUNK_DIR)/apps
APP_PRIVATE_DIR=$(APP_DIR)/private
export IS_APPS_DIR_EXIST=$(if $(wildcard $(APP_DIR)/.),Y,N)
####################################################################################
# sub-class of PROJECT_DIR=$(TRUNK_DIR)/Project
export IMAGE_DIR=$(PROJECT_DIR)/images
PROJECT_MENUCONFIG_DIR=$(PROJECT_DIR)/config/menuconfig
PROJECT_AUTOCONFIG_DIR=$(PROJECT_DIR)/config/autoconfig
PROJECT_LIB_DIR=$(PROJECT_DIR)/lib
ifneq ($(strip $(CUSTOM)),)
    PROFILE_DIR=$(PROJECT_DIR)/profile/$(CUSTOM)/$(PROFILE)
else
    PROFILE_DIR=$(PROJECT_DIR)/profile/$(PROFILE)
endif
SRCFS_DIR=$(PROFILE_DIR)/fs.src
####################################################################################
# sub-class of BSP_DIR=$(TRUNK_DIR)/BSP
export VOIP_BSP_DIR=$(TRUNK_DIR)/BSP/voip_bsp
export VOIP_APP_BSP_DIR=$(APP_BSP_PRIVATEDIR)/voip
export IS_VOIP_BSP_DIR_EXIST=$(if $(wildcard $(VOIP_BSP_DIR)/.),Y,N)
export IS_VOIP_APP_BSP_DIR_EXIST=$(if $(wildcard $(VOIP_APP_BSP_DIR)/.),Y,N)
export XPON_BSP_DIR=$(TRUNK_DIR)/BSP/xpon_bsp
export XPON_APP_SDK_DIR=$(TRUNK_DIR)/apps/xpon_app
export XPON_APP_BSP_DIR=$(TRUNK_DIR)/BSP/xpon_app
export IS_XPON_BSP_DIR_EXIST=$(if $(wildcard $(XPON_BSP_DIR)/.),Y,N)
export IS_XPON_APP_BSP_DIR_EXIST=$(if $(wildcard $(XPON_APP_BSP_DIR)/.),Y,N)
export IS_XPON_APP_SDK_DIR_EXIST=$(if $(wildcard $(XPON_APP_SDK_DIR)/.),Y,N)
####################################################################################
# sub-class of GLOBAL_INC_DIR=$(TRUNK_DIR)/linux-$(LINUX_VERSION)/include/global_inc
export GLOBAL_FLASH_LAYOUT_INC_DIR=$(GLOBAL_INC_DIR)/flash_layout
export ECNT_VERSION_DIR=$(GLOBAL_INC_DIR)/version
####################################################################################
# sub-class of BOOTROM_DIR=$(TRUNK_DIR)/bootrom
export BOOTROM_UNOPEN_IMG_DIR=$(BOOTROM_DIR)/unopen_img
export IS_BOOTROM_DIR_EXIST=$(if $(wildcard $(BOOTROM_DIR)/.),Y,N)
####################################################################################
# sub-class of PROJECT_DIR=$(TRUNK_DIR)/Project
export PROJECT_MAKE_INC_DIR=$(PROJECT_DIR)/make_inc
####################################################################################
# sub-class of MODULE_DIR=$(TRUNK_DIR)/modules
MODULES_PRIV_SRC_DIR=$(MODULE_DIR)/private
MODULES_PUBLIC_SRC_DIR=$(MODULE_DIR)/public
# Wi-Fi Related
RT2561AP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/rt61ap/Module
RT3390AP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/2009_1106_RT3390_LinuxAP_V2.3.2.0_DPA
RT5392AP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/RT5392_Linux_AP_V2.5.0.0_DPA
RT5592AP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/RT5592_LinuxAP_20111128_V2.6.0.0_DPA
RT3593AP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/RT3593_LinuxAP_V2.6.0.0_DPA
MT7601EAP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7601E_LinuxAP_20130305_DPA
ifneq ($(strip $(TCSUPPORT_WLAN_MT7592_V41)),)
    MT7592AP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7603_V4.1
else
    MT7592AP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7603
endif
WIFI_MULTI_DRIVER_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/DPA_RT5592_RT5392_LinuxAP_V2.7.x.x
MT7610EAP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/mt7610e_wifi_v3009_dpa_20150430
MT7612EAP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7612E_LinuxAP_3.0.4.0.P2_DPA
ifneq ($(strip $(TCSUPPORT_WLAN_MT7613_V60)),)
    MT7613EAP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7613/V6.0.2.0
else
    MT7613EAP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7613/V4.4.0.2
endif
MT7615EAP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7615
MT7615OFFLOAD_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7615_offload/V5.0.2.0
ifneq ($(strip $(TCSUPPORT_WLAN_MT7915_V74)),)
    MT7915EAP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7915_v7.4
    RT28xx_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7915_v7.4
    RT28xx_BIN_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7915_v7.4
else
    MT7915EAP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7915
    ifneq ($(strip $(TCSUPPORT_WLAN_MT7915_BUILD_IN)),)
        RT28xx_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7915
        RT28xx_BIN_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7915
    endif
endif
ifneq ($(strip $(TCSUPPORT_WLAN_MT7615_V33)),)
    ifeq ($(strip $(TCSUPPORT_WLAN_MT7615_BUILD_IN)),)
        MT7615V3X_DIR_SRC=$(MODULES_PRIV_SRC_DIR)/wifi/MT7615_V3.3
        MT7615V3X_DIR_DST=$(TRUNK_DIR)/MT7615_V3.3
    endif
    ifeq ($(strip $(TCSUPPORT_WLAN_MT7615_BUILD_IN)),)
        MT7615V3X_DIR=$(TRUNK_DIR)/MT7615_V3.3/V5.0.3.0
        MT7615V3X_CFG_DIR=$(TRUNK_DIR)/MT7615_V3.3/wlan_cfg
        MT7615V3X_BIN_DIR=$(TRUNK_DIR)/MT7615_V3.3/bin
    else
        MT7615V3X_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7615_V3.3/V5.0.3.0
        MT7615V3X_CFG_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7615_V3.3/wlan_cfg
        MT7615V3X_BIN_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7615_V3.3/bin
    endif
endif
ifneq ($(strip $(TCSUPPORT_WLAN_MT7615_V34)),)
    ifeq ($(strip $(TCSUPPORT_WLAN_MT7615_BUILD_IN)),)
        MT7615V3X_DIR_SRC=$(MODULES_PRIV_SRC_DIR)/wifi/MT7615_V3.4
        MT7615V3X_DIR_DST=$(TRUNK_DIR)/MT7615_V3.4
    endif
    ifeq ($(strip $(TCSUPPORT_WLAN_MT7615_BUILD_IN)),)
        MT7615V3X_DIR=$(TRUNK_DIR)/wifi/MT7615_V3.4/V5.0.4.0
        MT7615V3X_CFG_DIR=$(TRUNK_DIR)/wifi/MT7615_V3.4/wlan_cfg
        MT7615V3X_BIN_DIR=$(TRUNK_DIR)/wifi/MT7615_V3.4/bin
    else
        MT7615V3X_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7615_V3.4/V5.0.4.0
        MT7615V3X_CFG_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7615_V3.4/wlan_cfg
        MT7615V3X_BIN_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/MT7615_V3.4/bin
    endif
endif
RT3090AP_DIR=$(MODULES_PRIV_SRC_DIR)/wifi/2009_0904_RT3090_LinuxAP_v2.3.0.0_TC_for_3092
# END Wi-Fi Related
DMT_DIR=$(MODULES_PRIV_SRC_DIR)/dmt
MODULES_BACKUP=$(MODULES_PRIV_SRC_DIR)/ko/modules
MODULES_IGMPSNOOP_DIR=$(MODULES_PRIV_SRC_DIR)/net/igmpsnooping
MODULES_ACCESSLIMIT_DIR=$(MODULES_PRIV_SRC_DIR)/net/access_limit
MODULES_SWQOS_DIR=$(MODULES_PRIV_SRC_DIR)/net/qos_discipline
MODULES_SOFT_RATELIMIT_DIR=$(MODULES_PRIV_SRC_DIR)/net/soft_ratelimit
MODULES_URL_FILTER_DIR=$(MODULES_PRIV_SRC_DIR)/net/url_filter
MODULES_LOOP_DETECT_DIR=$(MODULES_PRIV_SRC_DIR)/net/loop_detect
MODULES_MAXNET_DPI_DIR=$(MODULES_PRIV_SRC_DIR)/net/maxnetdpi
MODULES_PLUGIN_NETLIMIT_DIR=$(MODULES_PRIV_SRC_DIR)/net/plugin_netlimit
MODULES_INFO_UTILITY_DIR=$(MODULES_PRIV_SRC_DIR)/net/info_utility
MODULES_TRAFFIC_PROCESS_DIR=$(MODULES_PRIV_SRC_DIR)/net/trafficprocess
MODULES_NP_LANHOST_MGR_DIR=$(MODULES_PRIV_SRC_DIR)/net/np_lanhost_mgr
MODULES_ATTACK_PROTECT_DIR=$(MODULES_PRIV_SRC_DIR)/net/attackprotector
MODULES_NP_LANHOST_MGR_DIR=$(MODULES_PRIV_SRC_DIR)/net/np_lanhost_mgr
MODULES_ETHERTYPE_FILTER_DIR=$(MODULES_PRIV_SRC_DIR)/net/ethertype_filter
MODULES_DATASPEED_LIMIT_DIR=$(MODULES_PRIV_SRC_DIR)/net/dataspeed_limit
MODULES_BRIDGE_DETECT_DIR=$(MODULES_PRIV_SRC_DIR)/net/bridge_detect
MODULES_ECNT_HOOK_DIR=$(MODULES_PRIV_SRC_DIR)/kernel_hook
MODULES_SIMCARD_DIR=$(MODULES_PRIV_SRC_DIR)/simcard_separation
ifneq ($(strip $(TCSUPPORT_SIMCARD_GENERAL)),)
    MODULES_SIMCARD_DIR=$(MODULES_PRIV_SRC_DIR)/simcard_separation_general
endif
MODULES_TC3262_DIR=$(MODULES_PRIV_SRC_DIR)/tc3262
MODULES_MT7510_PTM_DIR=$(MODULES_PRIV_SRC_DIR)/mt7510_ptm
MODULES_BONDING_PCIE_DIR=$(MODULES_PRIV_SRC_DIR)/bonding_pcie
export MODULES_RAETH_DIR=$(MODULES_PRIV_SRC_DIR)/raeth
MODULES_ETHER_DIR=$(MODULES_PRIV_SRC_DIR)/ether/en7512
MODULES_FHT_VLAN_DIR=$(MODULES_PRIV_SRC_DIR)/fh_vlan/en7512
MODULES_ETHER_PHY_DIR=$(MODULES_PRIV_SRC_DIR)/tcphy
MODULES_THERMAL_DIR=$(MODULES_PRIV_SRC_DIR)/thermal
MODULES_DIAG_DIR=$(MODULES_PRIV_SRC_DIR)/diag_tools
ifneq ($(strip $(TCSUPPORT_XSI_ENABLE)),)
    MODULES_XSI_MAC_DIR=$(MODULES_PRIV_SRC_DIR)/xsi/xsi_mac
    MODULES_XSI_WAN_MAC_DIR=$(MODULES_PRIV_SRC_DIR)/xsi/xsi_wan_mac
    export MODULES_XSI_PHY_DIR=$(MODULES_PRIV_SRC_DIR)/xsi/xsi_phy
endif
MODULES_AE_WAN_MAC_DIR=$(MODULES_PRIV_SRC_DIR)/xsi/ae_wan_mac
MODULES_HSGMII_LAN_MAC_DIR=$(MODULES_PRIV_SRC_DIR)/xsi/hsgmii_lan_mac
MODULES_DIAG_TOOL=$(MODULES_PRIV_SRC_DIR)/diag_tools
MODULES_HWNAT_DIR=$(MODULES_PRIV_SRC_DIR)/hwnat
MODULES_RA_HWNAT_DIR=$(MODULES_PRIV_SRC_DIR)/ra_hwnat
export MODULES_RA_HWNAT_7510_DIR=$(MODULES_PRIV_SRC_DIR)/ra_hwnat_7510
export MODULES_RA_HWNAT_V3_DIR=$(MODULES_PRIV_SRC_DIR)/ra_hwnat_v3
MODULES_FE_PPE_TEST_DIR=$(MODULES_PRIV_SRC_DIR)/fe_ppe_test
MODULES_KPROFILE_DIR=$(MODULES_PRIV_SRC_DIR)/kprofile
MODULES_FTTDP_INIC_DIR=$(MODULES_PRIV_SRC_DIR)/fttdp_inic
MODULES_FULLCONE_DIR=$(MODULES_PRIV_SRC_DIR)/net/full_cone
MODULES_MULTIWAN_DIR=$(MODULES_PRIV_SRC_DIR)/net/multi_wan
MODULES_PORTBIND_DIR=$(MODULES_PRIV_SRC_DIR)/net/portbind
MODULES_SWNAT_DIR=$(MODULES_PRIV_SRC_DIR)/net/sw_nat
MODULES_VLAN_TAG_DIR=$(MODULES_PRIV_SRC_DIR)/net/vlan_tag
MODULES_CT_VLAN_TAG_DIR=$(MODULES_PRIV_SRC_DIR)/net/vlan_tag_ct
MODULES_AUTOBENCH_DIR=$(MODULES_PRIV_SRC_DIR)/auto_bench
MODULES_DYING_GASP_DIR=$(MODULES_PRIV_SRC_DIR)/net/dying_gasp
MODULES_PWM_DIR=$(MODULES_PRIV_SRC_DIR)/net/pwm
MODULES_FASTBRIDGE_DIR=$(MODULES_PRIV_SRC_DIR)/net/fastbridge
export MODULES_FE_7512_DIR=$(MODULES_PRIV_SRC_DIR)/fe/en7512
MODULES_TSO_DIR=$(MODULES_PRIV_SRC_DIR)/tso
MODULES_TSO_VERIFY_DIR=$(MODULES_PRIV_SRC_DIR)/tso/verify
MODULES_LRO_DIR=$(MODULES_PRIV_SRC_DIR)/lro
MODULES_LRO_VERIFY_DIR=$(MODULES_PRIV_SRC_DIR)/lro/verify
ifneq ($(strip $(TCSUPPORT_QDMA_OPENSOURCE)),)
export MODULES_QDMA_7516_DIR=$(MODULES_PRIV_SRC_DIR)/qdma_opensource/EN7516
else
export MODULES_QDMA_7516_DIR=$(MODULES_PRIV_SRC_DIR)/qdma/EN7516
endif
export MODULES_QDMA_7512_DIR=$(MODULES_PRIV_SRC_DIR)/qdma/EN7512
export MODULES_QDMA_DIR=$(MODULES_PRIV_SRC_DIR)/bufmgr
export MODULES_SLM_DIR=$(MODULES_PRIV_SRC_DIR)/slm_verify
export MODULES_IFC_DIR=$(MODULES_PRIV_SRC_DIR)/IFC
export MODULES_PHY_DIR=$(MODULES_PRIV_SRC_DIR)/xpon_phy
export MODULES_PHY_10G_DIR=$(MODULES_PRIV_SRC_DIR)/xpon_phy_10g
export MODULES_VDSL_WAN_DIR=$(MODULES_PRIV_SRC_DIR)/mt7510_ptm
MODULES_CRYPTO_DRIVER=$(MODULES_PRIV_SRC_DIR)/cryptoDriver
MODULES_EIP93_DRIVERS=$(MODULES_PRIV_SRC_DIR)/eip93_drivers
MODULES_ETHER_DOWNVLAN_DIR=$(MODULES_PRIV_SRC_DIR)/net/ether_downvlan
ifneq ($(strip $(TCSUPPORT_EASYMESH_R13)),)
    MODULE_MAP_FILTER_DIR=$(MODULES_PRIV_SRC_DIR)/mapfilter_v2
else
    MODULE_MAP_FILTER_DIR=$(MODULES_PRIV_SRC_DIR)/mapfilter
endif
MODULES_USB_CAMERA_DRIVER=$(MODULES_PUBLIC_SRC_DIR)/usb_camera
export MODULES_INSTALL_PRIV_DIR=modules/private/ko/modules/$(TCPLATFORM)/
ifneq ($(strip $(TCSUPPORT_OPENWRT)),)
    include $(PLATFORM_SUBDIR)/defines/openwrt_specify.mk
endif