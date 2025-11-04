# Secure Boot related image setup
DEVICE_VARS += \
		SECURE_BOOT_ROTPK_KEY_SIZE \
		SECURE_BOOT_ROTPK_HASH_ALG \
		SECURE_BOOT_ROTPK_KEY_ALG \
		SECURE_BOOT_ROTPK \
		SECURE_BOOT_KEY_DIR \
		SECURE_BOOT_ENC_ALG \
		SECURE_BOOT_ENC_KEY \
		SECURE_BOOT_FITPK

# Temporary paths
WORK_PATH := $(STAGING_DIR_IMAGE)/nand-image
CERT_PATH := $(WORK_PATH)-cert

UBOOT_VERSION_ID := 938f0820-2ffb-11e7-bbc9-2f21351ee6fb

define Build/iopsys-secure-boot
	@echo
	@echo Generating Secure Boot for $(DEVICE_NAME)
	$(call secure-boot,secure-boot-senity-check)
	$(call generate-uboot-ram)
	$(call generate-uboot-nand,$@,$@-u-boot-ram.bin)
	$(call secure-boot,secure-boot-prepare-kernel)
endef

define secure-boot-senity-check/Default
	@echo Secure Boot : Sanity check - Default
	$(if $(SECURE_BOOT_KEY_DIR),,$(error Secure boot key dir not specified!))
	$(if $(wildcard $(SECURE_BOOT_KEY_DIR)/$(SECURE_BOOT_ROTPK)),,$(error Cannot find Root Of Trust Pre-shared Key in key dir!))
	$(if $(wildcard $(SECURE_BOOT_KEY_DIR)/$(SECURE_BOOT_ENC_KEY)),,$(error Cannot find encryption key in key dir!))
	$(if $(wildcard $(SECURE_BOOT_KEY_DIR)/$(SECURE_BOOT_FITPK).key),,$(error Cannot find FIT Pre-shared Key in key dir!))
	$(if $(wildcard $(SECURE_BOOT_KEY_DIR)/$(SECURE_BOOT_FITPK).crt),,$(error Cannot find FIT Pre-shared certificate in key dir!))
endef

define secure-boot-add-pk-to-dtb/Default
	@echo Secure Boot : Adding public key to U-Boot DTBs - Default
	for dts in $(UBOOT_DTS) $(DEVICE_DTS); do \
		PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage -r -f auto-conf -d /dev/null -k $(SECURE_BOOT_KEY_DIR) -g $(SECURE_BOOT_FITPK) -o sha1,rsa2048 -K $@-fit-dtb.dir/$${dts}.dtb $@-unused.itb && \
		rm -f $@-unused.itb || exit $$? ; \
	done
endef

define secure-boot-create-cert/Default
	@echo Secure Boot : Certificate Creation - Default
	@echo "Using existing ROTPK in $(SECURE_BOOT_KEY_DIR)/$(SECURE_BOOT_ROTPK)";
	cp -pv $(SECURE_BOOT_KEY_DIR)/$(SECURE_BOOT_ROTPK) $(CERT_PATH)-$(notdir $(1))/ROTkey;

# This is mostly generic
	cert_create -n -k                                                                          \
		--trusted-world-key             $(CERT_PATH)-$(notdir $(1))/TWkey                  \
		--non-trusted-world-key         $(CERT_PATH)-$(notdir $(1))/NTWkey                 \
		--scp-fw-key                    $(CERT_PATH)-$(notdir $(1))/SCPFKey                \
		--soc-fw-key                    $(CERT_PATH)-$(notdir $(1))/SOCFkey                \
		--tos-fw-key                    $(CERT_PATH)-$(notdir $(1))/TFkey                  \
		--nt-fw-key                     $(CERT_PATH)-$(notdir $(1))/NTFkey                 \
		--tfw-nvctr 0 --ntfw-nvctr 0                                                       \
		--trusted-key-cert              $(CERT_PATH)-$(notdir $(1))/trusted_key.crt        \
		--key-alg                       $(SECURE_BOOT_ROTPK_KEY_ALG)                       \
		--key-size                      $(SECURE_BOOT_ROTPK_KEY_SIZE)                      \
		--hash-alg                      $(SECURE_BOOT_ROTPK_HASH_ALG)                      \
		--rot-key                       $(CERT_PATH)-$(notdir $(1))/ROTkey                 \
		--tb-fw-cert                    $(CERT_PATH)-$(notdir $(1))/tb_fw.crt              \
		--soc-fw-cert                   $(CERT_PATH)-$(notdir $(1))/soc_fw_content.crt     \
		--soc-fw-key-cert               $(CERT_PATH)-$(notdir $(1))/soc_fw_key.crt         \
		--tos-fw-cert                   $(CERT_PATH)-$(notdir $(1))/tos_fw_content.crt     \
		--tos-fw-key-cert               $(CERT_PATH)-$(notdir $(1))/tos_fw_key.crt         \
		--nt-fw-cert                    $(CERT_PATH)-$(notdir $(1))/nt_fw_content.crt      \
		--nt-fw-key-cert                $(CERT_PATH)-$(notdir $(1))/nt_fw_key.crt          \
		--tb-fw                         $(STAGING_DIR_IMAGE)/$(TCPLATFORM)-bl2.bin         \
		--soc-fw                        $(STAGING_DIR_IMAGE)/$(TCPLATFORM)-bl31.lzma       \
		--tos-fw                        $(STAGING_DIR_IMAGE)/$(TCPLATFORM)-bl32_optee.lzma \
		--nt-fw                         $(WORK_PATH)-$(notdir $(1))/u-boot-ram.lzma
endef

define secure-boot-prepare-kernel/Default
	@echo Secure Boot : Kernel Certificate Creation - Default
	cert_create                                                                       \
	--new-keys                                                                    \
	--print-cert                                                                  \
	--tfw-nvctr                     0                                             \
	--ntfw-nvctr                    0                                             \
	--key-alg                       $(SECURE_BOOT_ROTPK_KEY_ALG)                  \
	--key-size                      $(SECURE_BOOT_ROTPK_KEY_SIZE)                 \
	--hash-alg                      $(SECURE_BOOT_ROTPK_HASH_ALG)                 \
                                                                                  \
	--rot-key                       $(CERT_PATH)/ROTkey                           \
                                                                                  \
	--tos-fw                        $(KERNEL_BUILD_DIR)/$(DEVICE_NAME)-kernel.bin \
	--tos-fw-key                    $(CERT_PATH)/TFkey                            \
	--tos-fw-cert                   $(CERT_PATH)/tos_fw.crt                       \
	--tos-fw-key-cert               $(CERT_PATH)/tos_fw_key.crt
endef

define Build/copy-keys
	tar -cC $(STAGING_DIR_IMAGE) $(UBOOT_TARGET)-secure_boot_keys_certs >> $@
endef

define Build/generate-rotpk-fuse
	@echo Generating fusable ROTPK for $(SECURE_BOOT_KEY_DIR)/$(SECURE_BOOT_ROTPK)

	@rm -rf $(CERT_PATH)
	@mkdir -vp $(CERT_PATH)

	openssl rsa -in $(SECURE_BOOT_KEY_DIR)/$(SECURE_BOOT_ROTPK) -pubout -outform DER 2>/dev/null |	\
		openssl dgst -$(SECURE_BOOT_ROTPK_HASH_ALG) -binary > \
		$(CERT_PATH)/rotpk_$(SECURE_BOOT_ROTPK_KEY_SIZE)_$(SECURE_BOOT_ROTPK_HASH_ALG).bin 2>/dev/null

	$(STAGING_DIR_IMAGE)/$(TCPLATFORM)-ecnt_efuse \
		-s $(SECURE_BOOT_ROTPK_HASH_ALG) \
		-r $(CERT_PATH)/rotpk_$(SECURE_BOOT_ROTPK_KEY_SIZE)_$(SECURE_BOOT_ROTPK_HASH_ALG).bin \
		-a $(SECURE_BOOT_ENC_ALG) \
		-k $$(grep -E '^key *=[A-F0-9]+$$$$' $(SECURE_BOOT_KEY_DIR)/$(SECURE_BOOT_ENC_KEY) | sed -e 's/^key *=//') \
		-o $(CERT_PATH)/ecntefuse_$(SECURE_BOOT_ROTPK_KEY_SIZE)_$(SECURE_BOOT_ROTPK_HASH_ALG)_$(SECURE_BOOT_ENC_ALG).bin

	dd if=$(CERT_PATH)/ecntefuse_$(SECURE_BOOT_ROTPK_KEY_SIZE)_$(SECURE_BOOT_ROTPK_HASH_ALG)_$(SECURE_BOOT_ENC_ALG).bin >> $@
	rm -rf $(CERT_PATH)
endef

define Build/squashfs-hash
	@# Sanity check if device supporting squashfs filesystem
	$(if $(findstring squashfs,$(FILESYSTEMS)),,$(error Error: Device "$(DEVICE_NAME)" does not support squashfs filesystem!))

	# generate dm-verity bootargs from rootfs (squashfs)
	../../iopsys-common/rootfs-verity.sh $(ROOTFS/squashfs/$(DEVICE_NAME)) $(ROOTFS/squashfs/$(DEVICE_NAME))-hashed '/dev/ubiblock0_$${rootfs_vol_id}' $(ROOTFS/squashfs/$(DEVICE_NAME))-hashed.dm-init.txt

	# replace original rootfs with hashed one to be used at following stages
	$(CP) $(ROOTFS/squashfs/$(DEVICE_NAME))-hashed \
	$(ROOTFS/squashfs/$(DEVICE_NAME))

	# modify kernel dtbs with dm-verity cmdline
	@$(if $(DEVICE_DTS),
		cmdline="'root=/dev/dm-0 dm-mod.create=\\\"$$(cat $(ROOTFS/squashfs/$(DEVICE_NAME))-hashed.dm-init.txt)\\\"'" && \
		$(foreach dts,$(DEVICE_DTS), \
			$(CP) $(KERNEL_BUILD_DIR)/image-$(dts).dtb $(KERNEL_BUILD_DIR)/$(DEVICE_NAME)-$(dts).dtb && \
			fdtput -t s $(KERNEL_BUILD_DIR)/$(DEVICE_NAME)-$(dts).dtb /chosen bootargs \
				"$$(fdtget -t s $(KERNEL_BUILD_DIR)/$(DEVICE_NAME)-$(dts).dtb /chosen bootargs) $$cmdline" && \
			echo "$(dts): $$(fdtget -t s $(KERNEL_BUILD_DIR)/$(DEVICE_NAME)-$(dts).dtb /chosen bootargs)";))

	# rootfs is now hashed and devices trees updated
endef
