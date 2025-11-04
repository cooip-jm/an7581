platform_check_image() {
	local image="$1"
	# shellcheck disable=SC2155
	local board_name="$(board_name)"

	# This needs to go before generic device compatibility check
	# because old IOWRT 6.x/7.0 images have differing model in their metadata
	__check_image_70_65_downgrade "$image" "$board_name" || return 1

	iopsys_check_image "$image" "$board_name" || return
	__check_image_emmc_gpt_support "$image" "$board_name" || return
	__check_image_without_atf "$image" "$board_name" || return
}

__check_image_without_atf() {
	# Refuse downgrade to old image without U-Boot and ATF stored in each bank
	# if bootloader is not downgraded as well
	local image=$1
	local board_name=$2

	# EN7523/29/62 uses an older SDK without ATF, OPTEE and U-Boot in each bank, no need to do the check.
	# When flashing the bootloader, as well, a downgrade is possible
	if strings /proc/device-tree/compatible | grep -qFx econet,en7523 ||
		[ "$FORCE_LOADER_UPGRADE" != 0 ]; then
		return 0
	fi

	# extract image
	# shellcheck disable=SC2155
	local configuration="$(get_configuration "$image" "$board_name")"
	# shellcheck disable=SC2155
	local image_component="$(get_image_component_ref "$image" boot "$configuration")"
	local boot_image && boot_image="$(mktemp boot-img.XXXXXX)" || return
	iopsys_write_fit_image_component "$image" "$image_component" required blockdev "$boot_image"
	local ret=0
	if ! fdtget -l "$boot_image" /images | grep -Fqx atf; then
		log "ERROR: Downgrading to versions 7.5.0alpha1 and older not possible without --force-loader-upgrade."
		ret=1
	fi
	rm -f "$boot_image"
	return "$ret"
}

__check_image_emmc_gpt_support() {
	local image=$1
	local board_name=$2
	local configuration="$(get_configuration "$image" "$board_name")" || return 1
	if [ "$(get_root_device_type)" = emmc ] && ! get_image_component_ref "$image" bootloader-emmc "$configuration" >/dev/null; then
		log "ERROR: Can not downgrade to image with missing eMMC GPT support."
		return 1
	fi
	return 0
}

# These are images using old legacy Airoha SPI NAND driver
__check_image_70_65_downgrade() {
	local image=$1
	local board_name=$2
	# We can leave configuration empty (i.e. image with no configurations)
	# because it does not matter for the check for the squashfs image component.
	# Those 6.5 and 7.0 images did not have configs to begin with.
	# They did not have correct compat information either, which is why this function
	# needs to be called first, before any generic compatibility
	local configuration=""
	if get_image_component_ref "$image" squashfs "$configuration" >/dev/null; then
		log "ERROR: Downgrading to a version older than 7.1.0ALPHA3 is not supported."
		return 1
	fi
	return 0
}

platform_do_upgrade() {
	local image="$1"
	iopsys_do_upgrade "$image" "$(board_name)" "$(platform_list_image_components "$image")"  || return
}

# Tell the bootloader to boot from flash "bank" $1 next time.
# $1: bank identifier (1 or 2)
platform_set_bootbank() {
	iopsys_set_bootbank "$1"
}

platform_get_bootbank() {
	iopsys_get_bootbank
}

platform_copy_config() {
	local image="$1"
	log "Copy config files"
	iopsys_copy_config "$image"
}

__get_bootloader_device() {
	local boot_dev="u-boot"
	case "$(get_root_device_type)" in
	emmc)
		boot_dev="/dev/bootloader"
		;;
	*)
		boot_dev=$(get_default_loader_device)
		;;
	esac

	echo "$boot_dev"
}

platform_list_image_components() {
	local image=$1
	local boot_dev

	boot_dev="$(__get_bootloader_device)"
	#		<type>			/configuration/<name>	<required>	<target device>
	echo 	"pre_upgrade		upgrade_bundle		optional"
	echo	"image				boot				required	boot\${next_bank_id}"
	echo	"image				rootfs				optional	rootfs\${next_bank_id}"
if  bootloader_upgrade_enabled 2>/dev/null "$image" "bootloader" "$boot_dev" ; then
  case "$(get_root_device_type)" in
    emmc)
	echo	"bootloader			bootloader-emmc			optional	$boot_dev"
	;;
    *)
	echo	"bootloader			bootloader			optional	$boot_dev"
	;;
  esac
fi
	echo	"u_boot_env			u-boot-env			required"
	echo	"post_upgrade		upgrade_bundle		optional"
}
