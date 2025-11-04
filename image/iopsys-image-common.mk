define Build/iopsys-fit-upgrade-image
	@echo Generate filtered U-Boot environment file for sysupgrade
	$(call iopsys-filter-uboot-env, \
		"$(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump.bin", \
		"$(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump_filtered.bin", \
		"$(UBOOT_ENV_BLACKLIST)")

	@echo GenerateUpgradeFIT
	$(call iopsys-fit-upgrade-image-prepare, $@, \
		bootloader $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-nand.bin \
		bootloader-emmc $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-emmc.fip \
		boot $(IMAGE_KERNEL) \
		$(if $(FIT_PARTITION),,rootfs $(IMAGE_ROOTFS)) \
		u-boot-env $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump_filtered.bin \
		u-boot-script $(CURDIR)/u-boot-script \
		$(if $(GPT_PRIMARY_ENTRY_OFFSET), \
			gpt-primary-header $(dir $@)/$(DEVICE_IMG_PREFIX)-gpt.img.start \
			gpt-primary-entry $(dir $@)/$(DEVICE_IMG_PREFIX)-gpt.img.entry \
			gpt-alternate $(dir $@)/$(DEVICE_IMG_PREFIX)-gpt.img.end) \
	)
	$(call iopsys-fit-upgrade-image-add-configs-same, $@.its, \
		compat_versions:"1 0", \
		first, \
			bootloader \
			bootloader-emmc \
			boot \
			$(if $(FIT_PARTITION),,rootfs) \
			u-boot-env \
			u-boot-script \
			$(if $(GPT_PRIMARY_ENTRY_OFFSET), \
				gpt-primary-header \
				gpt-primary-entry \
				gpt-primary-entry-offset:$(GPT_PRIMARY_ENTRY_OFFSET) \
				gpt-alternate \
				gpt-alternate-offset:$(GPT_ALTERNATE_OFFSET)) \
			$(if $(CONFIG_TARGET_UPGRADE_BUNDLE),upgrade_bundle) \
	)
	$(if $(GPT_PRIMARY_ENTRY_OFFSET), $(call add_fit_sub_image_script_type, $@))
	$(call iopsys-fit-upgrade-image-build, $@)
endef

define Build/generate_gpt_entries
	ptgen -a100 -v -g -b -o $(dir $@)/$(DEVICE_IMG_PREFIX)-gpt.img $(GPT_LAYOUT_STR)
endef

# Add type property to sub-image u-boot script
define add_fit_sub_image_script_type
	echo -e '/ { \n\
	    images {\n\
	        u-boot-script {\n\
	            type = "script";\n\
	        };\n\
	    };\n\
	};' >> $(1).its
endef

# Generate U-Boot RAM image
define generate-uboot-ram
	@echo Generate fit-dtb image for $(DEVICE_NAME)
	mkdir -p $@-fit-dtb.dir

	$(call Image/BuildDTB, \
	    $(DTS_DIR)/$(UBOOT_DTS).dts, \
	    $@-fit-dtb.dir/$(UBOOT_DTS).dtb)

	for dts in $(DEVICE_DTS); do \
		cp $(KERNEL_BUILD_DIR)/image-$${dts}.dtb $@-fit-dtb.dir/$${dts}.dtb || exit $$?; \
	done

	$(call secure-boot,secure-boot-add-pk-to-dtb)

	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage \
		-f auto -A $(LINUX_KARCH) -T firmware -C none -O u-boot \
		-a 0 -e 0 -E \
		$(foreach dts,$(UBOOT_DTS) $(DEVICE_DTS),-b $@-fit-dtb.dir/$(dts).dtb) -d /dev/null \
		-B 0x8 $@-fit-dtb.blob

	@echo Generate U-Boot-RAM for $(DEVICE_NAME)
	cat $(UBOOT_RAM_NODTB_IMAGE) $@-fit-dtb.blob > $@-u-boot-ram.bin
	rm -rf $@-fit-dtb.dir $@-fit-dtb.blob

	cp $@-u-boot-ram.bin  $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-ram.bin
endef

# Generate U-Boot NAND image
define generate-uboot-nand
	@echo Creating U-Boot NAND image for $(DEVICE_NAME)
	@rm -rf $(WORK_PATH)-$(notdir $(1))
	@mkdir -vp $(WORK_PATH)-$(notdir $(1)) $(CERT_PATH)-$(notdir $(1))

# This is lzma/config dependent
	lzma e $(2) $(WORK_PATH)-$(notdir $(1))/u-boot-ram.lzma

	$(call secure-boot,secure-boot-create-cert,$(1))

# This is mostly generic (depends on which fiptool is used though)
	fiptool create                                                                             \
		$(if $(call secure-boot-check),                                                    \
			--trusted-key-cert      $(CERT_PATH)-$(notdir $(1))/trusted_key.crt        \
			--tb-fw-cert            $(CERT_PATH)-$(notdir $(1))/tb_fw.crt              \
		    $(if $(TCSUPPORT_TPL_SUPPORT),,                                                \
			--soc-fw-cert           $(CERT_PATH)-$(notdir $(1))/soc_fw_content.crt     \
			--soc-fw-key-cert       $(CERT_PATH)-$(notdir $(1))/soc_fw_key.crt         \
		    )                                                                              \
		)                                                                                  \
		--align 1024                                                                       \
		--tb-fw                 $(STAGING_DIR_IMAGE)/$(TCPLATFORM)-bl2.bin                 \
		$(WORK_PATH)-$(notdir $(1))/bootext.ram

	fiptool create                                                                             \
		$(if $(call secure-boot-check),                                                    \
			--trusted-key-cert      $(CERT_PATH)-$(notdir $(1))/trusted_key.crt        \
			--tb-fw-cert            $(CERT_PATH)-$(notdir $(1))/tb_fw.crt              \
			--soc-fw-cert           $(CERT_PATH)-$(notdir $(1))/soc_fw_content.crt     \
			--soc-fw-key-cert       $(CERT_PATH)-$(notdir $(1))/soc_fw_key.crt         \
		    $(if $(TCSUPPORT_TPL_SUPPORT),,                                                \
			--nt-fw-cert            $(CERT_PATH)-$(notdir $(1))/nt_fw_content.crt      \
			--nt-fw-key-cert        $(CERT_PATH)-$(notdir $(1))/nt_fw_key.crt          \
		    )                                                                              \
		)                                                                                  \
		--align 1024                                                                       \
		--tb-fw                 $(STAGING_DIR_IMAGE)/$(TCPLATFORM)-bl2.bin                 \
		$(if $(TCSUPPORT_TPL_SUPPORT),                                                     \
		    --soc-fw            $(WORK_PATH)-$(notdir $(1))/u-boot-ram.lzma                \
		,                                                                                  \
		    --soc-fw            $(STAGING_DIR_IMAGE)/$(TCPLATFORM)-bl31.lzma               \
		    --nt-fw             $(WORK_PATH)-$(notdir $(1))/u-boot-ram.lzma                \
		)                                                                                  \
		$(WORK_PATH)-$(notdir $(1))/tcboot.fip

	fiptool info $(WORK_PATH)-$(notdir $(1))/tcboot.fip

# This is airoha specific
	# create nand image (tcboot.bin)
	cp $(STAGING_DIR_IMAGE)/$(TCPLATFORM)-bl1.bin $(WORK_PATH)-$(notdir $(1))/test.bin
	dd of=$(WORK_PATH)-$(notdir $(1))/test.bin if=/dev/null bs=1 seek=2048 count=0
	dd of=$(WORK_PATH)-$(notdir $(1))/test.bin if=$(WORK_PATH)-$(notdir $(1))/tcboot.fip bs=2048 seek=1
	# add u-boot snapshot version string
	cat $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-u-boot-version.txt >> $(WORK_PATH)-$(notdir $(1))/test.bin
	# add iopsys u-boot version id string
	strings $(2) | grep $(UBOOT_VERSION_ID) | tail -n 1 >> $(WORK_PATH)-$(notdir $(1))/test.bin
	dd of=$(WORK_PATH)-$(notdir $(1))/test.bin if=/dev/null bs=1 seek=512K count=0
	cd $(WORK_PATH)-$(notdir $(1)) && trx-airoha -t test.bin 0x7c000

	cp $(WORK_PATH)-$(notdir $(1))/bootext.ram $(1)-bootext.ram
	cp $(WORK_PATH)-$(notdir $(1))/tcboot.bin  $(1)-u-boot-nand.bin

	cp -rpT $(CERT_PATH)-$(notdir $(1)) $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-secure_boot_keys_certs

	rm -rf $(CERT_PATH)-$(notdir $(1)) $(WORK_PATH)-$(notdir $(1))

# create an7581 specific bootloader image for board recovery
# --------------------------------------------------------------
# This bootloader go directly to command line instead of loading
# BL31/OPTEE images to the memory. This may be needed if BL31/OPTEE
# are bad, but properly signed.
#
# Note: there is no difference in behavior for en7523 case
	cp $@-u-boot-nand.bin $@-u-boot-recovery.bin
	echo -n recovery | dd of=$@-u-boot-recovery.bin bs=$$((0x7c000)) seek=1 conv=notrunc

	@echo Saving U-Boot images for $(DEVICE_NAME)
	cp $@-bootext.ram     $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-bootext.ram
	cp $@-u-boot-nand.bin $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-nand.bin
	cp $@-u-boot-recovery.bin $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-recovery.bin
endef

# Generate U-Boot eMMC image
define generate-uboot-emmc
	@echo Creating U-Boot eMMC image for $(DEVICE_NAME)
	dd if=$(2) of=$(1)-u-boot-emmc.fip bs=512 skip=4

	@echo Saving U-Boot eMMC images for $(DEVICE_NAME)
	cp $@-u-boot-emmc.fip $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-emmc.fip
endef

define Build/generate-uboot-images
	$(call generate-uboot-ram)
	$(call generate-uboot-nand,$@,$@-u-boot-ram.bin)
	$(call generate-uboot-emmc,$@,$@-u-boot-nand.bin)
endef

define Build/prepare-atf-blobs
	if [ $(ARCH) = aarch64 ]; then \
		cp "$(TRUNK_DIR)/BSP/enb_bsp/phy_an8831/10Gphy/as21xx/firmware/as21x1x_fw.bin" $@-as21x1x_fw.bin; \
		lzma d "$(STAGING_DIR_IMAGE)/$(TCPLATFORM)-bl31.lzma" $@-bl31.bin; \
		lzma d "$(STAGING_DIR_IMAGE)/$(TCPLATFORM)-bl32_optee.lzma" $@-optee.bin; \
	fi
endef

define Build/append-uboot-recovery
	dd if=$(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-recovery.bin >> $@
endef

define Build/append-uboot-nand
	dd if=$(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-nand.bin >> $@
endef

define Build/append-uboot-emmc
	dd if=$(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-emmc.fip >> $@
endef

define Build/append-uboot-ram
	dd if=$(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-ram.bin >> $@
endef

define Build/append-bootext-ram
	dd if=$(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-bootext.ram >> $@
endef

# firstword of arg (1): boardid to use
# words from second to last of arg (1): ubinize options
# The following defaults are used if the corresponding argument is not specified:
#   boardid is taken as a first word of $(DEVICE_DTS),
#   ubinize options are taken from $(UBINIZE_OPTS)
UBINIZE_OPTS_PARAM = $(wordlist 2, $(words $(1)), $(1))
define Build/append-ubi-image
	# redundant environment
	../../iopsys-common/mk-env-img.sh \
		-b $(if $(1),$(firstword $(1)),$(firstword $(DEVICE_DTS))) \
		-t $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump.bin \
		-c $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump.config \
		-s 0 -o $@.env1
	# active environment
	../../iopsys-common/mk-env-img.sh \
		-b $(if $(1),$(firstword $(1)),$(firstword $(DEVICE_DTS))) \
		-t $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump.bin \
		-c $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump.config \
		-s 1 -o $@.env2
	sed -e 's|@env1@|$@.env1|' \
	    -e 's|@env2@|$@.env2|' \
	    -e 's|@kernel@|$(IMAGE_KERNEL)|' \
	    -e 's|@rootfs@|$(IMAGE_ROOTFS)|' \
	    $(DEVICE_UBI_LAYOUT) >$@.cfg
	ubinize -o $@.tmp $(if $(UBINIZE_OPTS_PARAM),$(UBINIZE_OPTS_PARAM),$(UBINIZE_OPTS)) $@.cfg
	dd if=$@.tmp >> $@
	rm -f $@.env1 $@.env2 $@.tmp
endef

# arg(1) is the descriprion string in form:
#   description = "some text";
# or
#   /* some comment */
# if no description is planned
define airoha-aarch64-atf-blobs-its
	echo -e '/ {\n\t\
		$(1)\n\t\
		#address-cells = <1>;\n\t\
		images {\n\t\t\
			aeon_fw {\n\t\t\t\
				description = "8831 Firmare";\n\t\t\t\
				data = /incbin/("$@-as21x1x_fw.bin");\n\t\t\t\
				type = "firmware";\n\t\t\t\
				arch = "arm64";\n\t\t\t\
				compression = "none";\n\t\t\t\
				load = <0x81db5000>;\n\t\t\t\
				entry = <0x81db5000>;\n\t\t\t\
				hash-1 {\n\t\t\t\t\
					algo = "crc32";\n\t\t\t\
				};\n\t\t\t\
				hash-2 {\n\t\t\t\t\
					algo = "sha1";\n\t\t\t\
				};\n\t\t\
			};\n\t\t\
			atf {\n\t\t\t\
				description = "ATF BL31 image";\n\t\t\t\
				data = /incbin/("$@-bl31.bin");\n\t\t\t\
				type = "firmware";\n\t\t\t\
				arch = "arm64";\n\t\t\t\
				os = "arm-trusted-firmware";\n\t\t\t\
				compression = "none";\n\t\t\t\
				load = <0x80003000>;\n\t\t\t\
				entry = <0x80003000>;\n\t\t\t\
				hash-1 {\n\t\t\t\t\
					algo = "crc32";\n\t\t\t\
				};\n\t\t\t\
				hash-2 {\n\t\t\t\t\
					algo = "sha1";\n\t\t\t\
				};\n\t\t\
			};\n\t\t\
			tee {\n\t\t\t\
				description = "OPTEE (ATF BL32) image";\n\t\t\t\
				data = /incbin/("$@-optee.bin");\n\t\t\t\
				type = "tee";\n\t\t\t\
				arch = "arm64";\n\t\t\t\
				os = "arm-trusted-firmware";\n\t\t\t\
				compression = "none";\n\t\t\t\
				load = <0x8a800000>;\n\t\t\t\
				entry = <0x8a800000>;\n\t\t\t\
				hash-1 {\n\t\t\t\t\
					algo = "crc32";\n\t\t\t\
				};\n\t\t\t\
				hash-2 {\n\t\t\t\t\
					algo = "sha1";\n\t\t\t\
				};\n\t\t\
			};\n\t\
		};\n\t\
		configurations {\n\t\t\
			default = "atf_blobs";\n\t\t\
			atf_blobs {\n\t\t\t\
				description = "ATF blobs";\n\t\t\t\
				firmware = "atf";\n\t\t\t\
				loadables = "atf", "tee", "aeon_fw";\n\t\t\
			};\n\t\
		};\n\
	};' >> $@.its
endef

define Build/airoha-iowrt-kernel-fit
	$(call Build/prepare-atf-blobs)
	$(call iowrt-kernel-fit-gen-its,$(1),$(2))
	$(if $(findstring aarch64,$(ARCH)),$(call airoha-aarch64-atf-blobs-its,/* no description */))
	$(call iowrt-kernel-fit-mkimage,$(1),$(2))
endef

# %(1) boardid to set, default is $(firstword $(DEVICE_DTS))
define Build/append_emmc_production_image
	echo "Build/append_emmc_production_image[$@]: $(1)"
# create $@ if it does not exist already
	touch $@
# generate sysupgrade image to put inside production image,
# round image size to 1K, because ptgen uses sizes in KB
	mv $@ $@.bak
	$(Build/iopsys-fit-upgrade-image)
	$(call Build/pad-to,1K)
	mv $@ $@.sysupgrade.itb
	mv $@.bak $@
# generate fit image with atf blobs to put inside production image (must fit in 2M)
	touch $@.its
	mv $@.its $@.its.bak
	$(Build/prepare-atf-blobs)
	echo '/dts-v1/;' > $@.its
	$(call airoha-aarch64-atf-blobs-its, description = "ATF-2.10 BL31/BL32 images";)
	mv $@.its $@.boot1.its
	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage -E -B 0x1000 -r -f $@.boot1.its $@.boot1.fit
	mv $@.its.bak $@.its
# create GPT image with env1, env2, sysupgrade partitions
#  * GPT image size will be calculated automatically (-d 0)
#  * put Primary GPT entry table at 512K offset (-e 512K)
#  * use a hack to not mark any partition as legacy boot (-a 100)
#  * env1 partition will start at 2048K offset (-p 512K@2M)
#  * env2 partition will start at 2560K offset (just after env1)
#  * sysupgrade partition will start at 3M offset (just after env2).
#    ptgen uses sizes in KB, so divide sysupgrade image size to 1024
	ptgen -o $@.img -g -d 0 -e 512K -a 100 -N env1 -p 512K@2M -N env2 -p 512K -N boot1 -p 2M -N sysupgrade -p "$$(( $$(stat --format=%s $@.sysupgrade.itb) / 1024 ))K"
# write bootloader with 2K offset to GPT image (after PMBR and PGPT header, but before Primary GPT entry table)
	dd bs=2K seek=1 conv=notrunc of=$@.img if=$(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-$(DEVICE_NAME)-u-boot-emmc.fip
# generate 1-st environment (-s 0)
# override once value with the value required for converting production image to normal system (-O "...")
	../../iopsys-common/mk-env-img.sh \
		-b $(if $(1),$(firstword $(1)),$(firstword $(DEVICE_DTS))) \
		-t $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump.bin \
		-c $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump.config \
		-s 0 -o $@.env1 \
		-O "mmc dev 0 && part size mmc 0 sysupgrade __size && read mmc "0#sysupgrade" \$${loadaddr} 0 \$${__size} && env delete __size && source \$${loadaddr}:u-boot-script && run __script_emmc_write_production && env set once true && env save"
# write 1-st environment with 2048K offset (env1 partition) to GPT image
	dd bs=2048K seek=1 conv=notrunc of=$@.img if=$@.env1
# generate 2-nd environment (-s 1)
# override once value with the value required for converting production image to normal system (-O "...")
	../../iopsys-common/mk-env-img.sh \
		-b $(if $(1),$(firstword $(1)),$(firstword $(DEVICE_DTS))) \
		-t $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump.bin \
		-c $(STAGING_DIR_IMAGE)/$(UBOOT_TARGET)-env_dump.config \
		-s 1 -o $@.env2 \
		-O "mmc dev 0 && part size mmc 0 sysupgrade __size && read mmc "0#sysupgrade" \$${loadaddr} 0 \$${__size} && env delete __size && source \$${loadaddr}:u-boot-script && run __script_emmc_write_production && env set once true && env save"
# write 2-nd environment with 2560K offset (env2 partition) to GPT image
	dd bs=2560K seek=1 conv=notrunc of=$@.img if=$@.env2
# write atf blob image with 3M offset (boot1 partition) to GPT image
	dd bs=3M seek=1 conv=notrunc of=$@.img if=$@.boot1.fit
# write sysupgrade image with 5M offset (sysupgrade partition) to GPT image
	dd bs=5M seek=1 conv=notrunc of=$@.img if=$@.sysupgrade.itb
# add GPT image to the current target file
	cat $@.img >> $@
# remove temporary files
	rm $@.env1 $@.env2 $@.sysupgrade.itb $@.img
endef
