#!/bin/bash

# Check if the correct number of arguments is provided

Black="\033[0;30m"
Red="\033[0;31m"
Green="\033[0;32m"
Yellow="\033[0;33m"
Blue="\033[0;34m"
Magenta="\033[0;35m"
Cyan="\033[0;36m"
White="\033[0;37m"
RESET="\033[0m"

#---------------------------------------------------------------------------------------------------------
# parameter for pass to config&make&copy.sh
#---------------------------------------------------------------------------------------------------------
IPs=(
	#"82.5.144.219"
)

#--------------------------------------------------------------------------------------------------------
# optimize UOUT
#--------------------------------------------------------------------------------------------------------
UOUT=$UBOOT/b

ADDITIONAL_FILES="--ADDITIONAL_FILES "

PASSWORD="temppwd"

S1_KEY="--S1_KEY 589505315,606348324,623191333,640034342"
S7_KEY="--S7_KEY 589505315,606348324,623191333,640034342"

#---------------------------------------------------------------------------------------------------------
DTB="am335x-sancloud-bbe-lite"
sign_all_images=false
IPLIST=${BOARDS_IPS}
while [[ $# -gt 0 ]]; do
	case $1 in
	--sign_all_images)
		sign_all_images=true
		shift
		;;
	--dtb)
		DTB="$2"
		shift 2
		;;

		#---------------------------------------------------------------------------------------------------------
		# parameter for pass to board
		#---------------------------------------------------------------------------------------------------------
	--IPs)
		IPLIST=$2
		shift 2
		;;
	--S1_KEY)
		S1_KEY="--S1_KEY $2"
		shift 2
		;;
	--S7_KEY)
		S7_KEY="--S7_KEY $2"
		shift 2
		;;
	--PASSWORD)
		PASSWORD=$2
		shift 2
		;;

	--NO_CHIP)
		NO_CHIP="--NO_CHIP"
		shift 1
		;;
	--NO_EMMC)
		NO_EMMC="--NO_EMMC"
		shift 1
		;;

		#---------------------------------------------------------------------------------------------------------
	--)
		shift
		break
		;;
	*)
		break
		;;
	esac
done
#---------------------------------------------------------------------------------------------------------
# set IPs array
#---------------------------------------------------------------------------------------------------------
IFS=',' read -r -a IPs <<<"$IPLIST"
#---------------------------------------------------------------------------------------------------------

#---------------------------------------------------------------------------------------------------------
# build clean and build uboot & fallback
#---------------------------------------------------------------------------------------------------------
UBOOTCFGS=(
	"BOOT"
	"FALLBACK"
)
# build boot
for UBOOTCFG in "${UBOOTCFGS[@]}"; do
	if [ ! -d "${UOUT}/am335x_$UBOOTCFG" ] || [ ! -f "${UOUT}/am335x_$UBOOTCFG/.config" ]; then
	  env -C $UBOOT make O="${UOUT}/am335x_$UBOOTCFG" sancloud_winbond_spi_defconfig
	fi
	# clean befor build
	# env -C $UBOOT make O="${UOUT}/am335x_$UBOOTCFG" clean
	# if [ $? -ne 0 ]; then
	# 	echo -e "${Red}unable to clean ${UBOOTCFG}'s uboot ${RESET}"
	# 	exit 1
	# else
	# 	echo -e "${Green}Successfully ${UBOOTCFG}'s uboot is cleaned ${RESET}"
	# fi
	#------------------------------------------------------------------------------------------------
	# change cofig to secure boot
	#------------------------------------------------------------------------------------------------
	cp ${UOUT}/am335x_$UBOOTCFG/.config ${UOUT}/am335x_$UBOOTCFG/.config.back 
    # Disable legacy “boot” commands
    #env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_BOOTM
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_BOOTZ
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_BOOTI
    
    # Disable serial “load” commands
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_LOADB
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_LOADS
    
    # Disable network‐based loads
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_TFTP
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_DHCP
    #env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_NET
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_DFU
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_FS_GENERIC
    #env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_FAT
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_EXT4
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_UBIFS
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_UBI

    # Disable block‐device commands if they give access (optional, but recommended)
    #env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_MMC
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_SPI
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --set-val CONFIG_BOOTDELAY   -3
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable  CONFIG_AUTOBOOT_KEYED
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable  CONFIG_AUTOBOOT_FLUSH_STDIN
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable  CONFIG_AUTOBOOT_ENCRYPTION 
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_AUTOBOOT_STOP_STR_ENABLE
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CRYPT_PW


    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --set-val CONFIG_AUTOBOOT_DELAY_STR "\"\""
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --set-val CONFIG_AUTOBOOT_STOP_STR "\"\""
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable CONFIG_AUTOBOOT_USE_MENUKEY
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_AUTOBOOT_KEYED_CTRLC
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_BOOTSTD
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --set-str CONFIG_AUTOBOOT_PROMPT "Autoboot in %d seconds \n"

   #silent console 
   #env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config -e  CONFIG_SILENT_CONSOLE


    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_ENV
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_SAVEENV
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --set-val CONFIG_ENV_IS_NOWHERE   y
    #disable hush in fallback
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_HUSH_PARSER
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMDLINE
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_AUTO_COMPLETE
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_CONSOLE
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_MENU 
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_SOURCE
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable CONFIG_DISABLE_CONSOLE
    env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable CONFIG_RESET_TO_RETRY
	#signiture check
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable  CONFIG_FIT_SIGNATURE
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --set-val CONFIG_FIT_SIGNATURE_MAX_SIZE 0x10000000
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable  CONFIG_FIT_RSASSA_PSS
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable  CONFIG_FIT_CIPHER
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable	CONFIG_ASYMMETRIC_KEY_TYPE 
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable	CONFIG_SPL_ASYMMETRIC_KEY_TYPE 
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable	CONFIG_ASYMMETRIC_PUBLIC_KEY_SUBTYPE
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable	CONFIG_SPL_ASYMMETRIC_PUBLIC_KEY_SUBTYPE
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable	CONFIG_RSA_PUBLIC_KEY_PARSER
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_SPL_RSA_PUBLIC_KEY_PARSER 
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable	CONFIG_X509_CERTIFICATE_PARSER 
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable	CONFIG_PKCS7_MESSAGE_PARSER 
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable	CONFIG_MSCODE_PARSER
	
	#cmds poweroff & source
	#env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable	CONFIG_CMD_SOURCE
	#env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable	CONFIG_CMD_POWEROFF
	#env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable	CONFIG_POWEROFF_GPIO
	#env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable	CONFIG_SYSRESET_CMD_POWEROFF
	#disable efi secure boot
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_EFI_SECURE_BOOT  
	#env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_BOOTEFI
	env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_EFI_LOADER

	#------------------------------------------------------------------------------------------------
	# make uboot
	#------------------------------------------------------------------------------------------------


	env -C $UBOOT make O="${UOUT}/am335x_$UBOOTCFG" -j$(nproc)
	if [ $? -ne 0 ]; then
		echo -e "${Red}unable to compile U-Boot for $UBOOTCFG  ${RESET}"
	    #revert config befor error check
		cp ${UOUT}/am335x_BOOT/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
		cp ${UOUT}/am335x_FALLBACK/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
		exit 1
	else
		echo -e "${Green}Successfully U-Boot is for $UBOOTCFG ${RESET}"
	fi
	#------------------------------------------------------------------------------------------------
	# copy dtb to work dir
	#------------------------------------------------------------------------------------------------
	env -C ${WORK} cp ${UOUT}/am335x_$UBOOTCFG/arch/arm/dts/${DTB}.dtb ${DTB}-$UBOOTCFG-pubkey.dtb
	if [ $? -ne 0 ]; then
		echo -e "${Red}unable to copy dtb of $UBOOTCFG  ${RESET}"
	    #revert config befor error check
		cp ${UOUT}/am335x_BOOT/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
		cp ${UOUT}/am335x_FALLBACK/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
		exit 1
	else
		echo -e "${Green}Successfully dtb of $UBOOTCFG is copied ${RESET}"
	fi
done

#********************************************************************************************************************
#                make & sign images
#********************************************************************************************************************

#compile fit for all kernels
FIT_SOURCE_DIR=$WORK/FitSourceFile

for dir in $(env -C "$FIT_SOURCE_DIR" sh -c 'ls -d -- */' | sed 's:/$::'); do
	echo "compiling fits for : $dir"
	for UBOOTCFG in "${UBOOTCFGS[@]}"; do
		env -C $WORK sed "s|@VERSION@|$dir|g" Secure-$UBOOTCFG.its >"${FIT_SOURCE_DIR}/${dir}/Secure-$UBOOTCFG.its"
		env -C $WORK ${UOUT}/am335x_$UBOOTCFG/tools/mkimage -f "${FIT_SOURCE_DIR}/${dir}/Secure-$UBOOTCFG.its" -K ${DTB}-$UBOOTCFG-pubkey.dtb -T fdt_legacy -k keys -r "${FIT_SOURCE_DIR}/${dir}/SanCloud-Secure$UBOOTCFG-image.fit"
		if [ $? -ne 0 ]; then
			echo -e "${Red}unable to make its for ${FIT_SOURCE_DIR}/${dir}/Secure-$UBOOTCFG.its  ${RESET}"
			cp ${UOUT}/am335x_BOOT/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
			cp ${UOUT}/am335x_FALLBACK/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
			exit 1
		else
			echo -e "${Green}Successfully image ${dir}/Secure-$UBOOTCFG-image.fit is signed ${RESET}"
		fi
	done
done

#********************************************************************************************************************
#                change signature require mode and re compile create unified images
#********************************************************************************************************************

for UBOOTCFG in "${UBOOTCFGS[@]}"; do
	#------------------------------------------------------------------------------------------------
	# change signature require mode to all
	#------------------------------------------------------------------------------------------------
	env -C $WORK fdtput -t s ${DTB}-$UBOOTCFG-pubkey.dtb /signature required-mode all
	if [ $? -ne 0 ]; then
		echo -e "${Red}unable to add signature's required-mode to dtb ${RESET}"
		cp ${UOUT}/am335x_BOOT/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
		cp ${UOUT}/am335x_FALLBACK/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
		exit 1
	else
		echo -e "${Green}Successfully add signature required-mode to dtb ${RESET}"
	fi
	#------------------------------------------------------------------------------------------------
	# change config to secure boot
	#------------------------------------------------------------------------------------------------
    if [ $UBOOTCFG == "BOOT" ]; then
		env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --disable CONFIG_SPI_FALLBACK
	else
		env -C ${UOUT}/am335x_$UBOOTCFG $UBOOT/scripts/config --enable CONFIG_SPI_FALLBACK
	fi
	

    env -C ${UOUT}/am335x_$UBOOTCFG  $UBOOT/scripts/config --set-str CONFIG_BOOTCOMMAND "sf probe||true;run scan_secure_fit;poweroff;"

	#------------------------------------------------------------------------------------------------
	# recompile uboot with new dtb
	#------------------------------------------------------------------------------------------------
	env -C $UBOOT make O=${UOUT}/am335x_$UBOOTCFG EXT_DTB=${WORK}/${DTB}-$UBOOTCFG-pubkey.dtb -j$(nproc)


	if [ $? -ne 0 ]; then
		echo -e "${Red}unable to compile U-Boot $UBOOTCFG ${RESET}"
		cp ${UOUT}/am335x_BOOT/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
		cp ${UOUT}/am335x_FALLBACK/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
		exit 1
	else
		echo -e "${Green}Successfully U-Boot is $UBOOTCFG compiled ${RESET}"
	fi
	cp ${UOUT}/am335x_BOOT/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
	cp ${UOUT}/am335x_FALLBACK/.config.back ${UOUT}/am335x_$UBOOTCFG/.config
	#-----------------------------------------------------------------------------------------------
	# BUILDING UNIFIED IMAGE
	#-----------------------------------------------------------------------------------------------
	echo -e "${Blue}Generating Unified images SanCloud-$UBOOTCFG.bin  ${RESET}"
	UBOOTADDR=128 #uboot address in spi config for spl in kB
	IMGMAX=1536   #1.5MB. it is max size of image in kB
	OFILE="$UOUT/SanCloud-$UBOOTCFG.bin"
	ADDITIONAL_FILES="$ADDITIONAL_FILES$OFILE,"
	dd if=/dev/zero of=$OFILE bs=1k count=$IMGMAX
	dd if=$UOUT/am335x_$UBOOTCFG/MLO.byteswap of=$OFILE conv=notrunc bs=1k
	dd if=$UOUT/am335x_$UBOOTCFG/u-boot-dtb.img of=$OFILE conv=notrunc bs=1k seek=$UBOOTADDR
done

#********************************************************************************************************************
#               copy to board
#********************************************************************************************************************
#---------------------------------------------------------------------------------------------------------
# set new UOUT
#---------------------------------------------------------------------------------------------------------

if [ ${#IPs[@]} -gt 0 ]; then
	for IP in "${IPs[@]}"; do
		# Check if the IP is reachable
		PLAIN_ACCESS=""
		if [[ $IP =~ ^(([0-9]{1,3}\.){3}[0-9]{1,3})([Pp])?$ ]]; then
			IP="${BASH_REMATCH[1]}"
			PLAIN_ACCESS="${BASH_REMATCH[3]:-}"
		else
			echo "Invalid IP format: $1" >&2
			exit 1
		fi
		if ping -c 1 -W 1 "$IP" &>/dev/null; then
			REMOTE_KERNEL=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP}" "uname -r")
			echo -e "${Green}device $IP kernel version is $REMOTE_KERNEL ${RESET}"
			ADDITIONAL_FILES="$ADDITIONAL_FILES$FIT_SOURCE_DIR/$REMOTE_KERNEL/SanCloud-SecureBOOT-image.fit"
			ADDITIONAL_FILES="$ADDITIONAL_FILES,$FIT_SOURCE_DIR/$REMOTE_KERNEL/SanCloud-SecureFALLBACK-image.fit"
			UOUT=$UOUT/am335x_BOOT $WORK/Boardcp.sh --PASSWORD "$PASSWORD" "--IP" "$IP$PLAIN_ACCESS" $S7_KEY $S1_KEY $NO_CHIP $NO_EMMC $ADDITIONAL_FILES &
		else
			echo -e "${Red}device $IP does not exist. ${RESET}"
		fi

	done
	wait
fi
