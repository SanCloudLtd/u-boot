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

NEWKEY="N"
#---------------------------------------------------------------------------------------------------------
# parameter for pass to config&make&copy.sh
#---------------------------------------------------------------------------------------------------------
PASSWORD=${PASSWORD:-temppwd}
IPLIST=${BOARDS_IPS}
IPS=()
IFS=',' read -r -a IPs <<<"$IPLIST"
ADDITIONAL_FILES="--ADDITIONAL_FILES"
S0_KEY=${S0_KEY:-"2365974234,3466640016,4186352255,3105254121"}
S7_KEY=${S7_KEY:-"3398150088,1878052703,4211812016,2500719804"}
#---------------------------------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case $1 in
      --NEWKEY)
            NEWKEY="Y"
            shift 1
            ;;
#---------------------------------------------------------------------------------------------------------
# parameter for pass to board
#---------------------------------------------------------------------------------------------------------
         --IPs)
            IFS=',' read -r -a IPs <<< "$2"
            shift 2
            ;;
        --S0_KEY)
            S0_KEY="$2"
            shift 2
            ;;
        --S7_KEY)
            S7_KEY="$2"
            shift 2
            ;;
        --PASSWORD)
            PASSWORD="$2"
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
#*********************************************************************************************************************
#               prepare password parameter
#*********************************************************************************************************************


if [ -n "$PASSWORD" ]; then
		PASS="--PASSWORD $PASSWORD"
fi
S0_KEY="--S0_KEY $S0_KEY"
S7_KEY="--S7_KEY $S7_KEY"
#********************************************************************************************************************
#                generate new keys
#********************************************************************************************************************
if [ ! -r "$UBOOT/Sancloud-signed-Image/keys/dev.key" ] || [ ! -r "$UBOOT/Sancloud-signed-Image/keys/dev.crt" ]; then
    NEWKEY="Y"
    echo -e "${Red}************************************${RESET}" 
    echo -e "${Red}** KEY not found New KEY is needed *${RESET}"
    echo -e "${Red}************************************${RESET}"   
fi
if [[ "$NEWKEY" == "Y" ]]; then
    echo -e "${Red}**********************${RESET}"
    echo -e "${Red}** Generate New KEY *${RESET}"
    echo -e "${Red}**********************${RESET}"

    env -C $UBOOT/Sancloud-signed-Image rm -rf keys
    if [ $? -ne 0 ]; then
        echo -e "${Red}Unable to remove keys ${RESET}"
        exit 1
    else
        echo -e "${Green}Successfully removed keys ${RESET}"
    fi   

    env -C $UBOOT/Sancloud-signed-Image mkdir keys
    if [ $? -ne 0 ]; then
        echo -e "${Red}Unable to create keys directory ${RESET}"
        exit 1
    else
        echo -e "${Green}Successfully created keys directory ${RESET}"
    fi  

    env -C $UBOOT/Sancloud-signed-Image openssl genpkey -algorithm RSA -out keys/dev.key -pkeyopt rsa_keygen_bits:4096 -pkeyopt rsa_keygen_pubexp:65537
    if [ $? -ne 0 ]; then
        echo -e "${Red}Unable to generate dev.key ${RESET}"
        exit 1
    else
        echo -e "${Green}Successfully generated dev.key ${RESET}"
    fi

    env -C $UBOOT/Sancloud-signed-Image openssl req -batch -new -x509 -key keys/dev.key -out keys/dev.crt
    if [ $? -ne 0 ]; then
        echo -e "${Red}Unable to generate dev.crt ${RESET}"
        exit 1
    else
        echo -e "${Green}Successfully generated dev.crt ${RESET}"
    fi
fi
#********************************************************************************************************************
#                check if compiled device tree exist    
#********************************************************************************************************************    
if [ ! -f "$UOUT/a53/BOOT/dts/upstream/src/arm64/ti/k3-am625-sancloud.dtb"   ] || [ ! -f "$UOUT/a53/BOOT/dts/upstream/src/arm64/ti/k3-am625-sancloud.dtb" ]; then
   #compile source if not exist
   env -C $UBOOT/Sancloud-signed-Image ./config\&make\&copy.sh --IPs "" -N
    if [ $? -ne 0 ]; then
          echo -e "${Red}Unable to compile U-BOOT ${RESET}"
          exit 1
     else
          echo -e "${Green}Successfully compiled U-BOOT ${RESET}"
     fi
fi

#********************************************************************************************************************
#                SIGN the images
#********************************************************************************************************************
BOOTCFGS=(
    "BOOT"
    "FALLBACK"
)
DTB=k3-am625-sancloud
#generate fit for all kernels
FIT_SOURCE_DIR=$UBOOT/Sancloud-signed-Image/FIT_SourceFiles

for dir in $(env -C "$FIT_SOURCE_DIR" sh -c 'ls -d -- */' | sed 's:/$::'); do
	echo "compiling fits for : $dir"
	for UBOOTCFG in "${BOOTCFGS[@]}"; do
		echo -e "${Red}*******************************************${RESET}"
		echo -e "${Red}	Signing ${UBOOTCFG}'s FIT-Image for $dir ${RESET}"
		echo -e "${Red}*******************************************${RESET}"
		env -C $UBOOT/Sancloud-signed-Image sed "s|@VERSION@|$dir|g" Secure-$UBOOTCFG.its >"${FIT_SOURCE_DIR}/${dir}/Secure-$UBOOTCFG.its"
		env -C $UBOOT/Sancloud-signed-Image $UOUT/a53/$UBOOTCFG/tools/mkimage -f "${FIT_SOURCE_DIR}/${dir}/Secure-$UBOOTCFG.its" -K $UOUT/a53/${UBOOTCFG}/dts/upstream/src/arm64/ti/${DTB}.dtb -T fdt_legacy -k ./keys -r "${FIT_SOURCE_DIR}/${dir}/SanCloud-Secure$UBOOTCFG-image.fit"
		if [ $? -ne 0 ]; then
		    echo -e "${Red}Unable to sign FIT-Image ${RESET}"
		    exit 1
		else
		    echo -e "${Green}Successfully signed FIT-Image ${RESET}"
		fi
		echo -e "${Red}***********************************************${RESET}"
		echo -e "${Red}   Checking ${UBOOTCFG}'s FIT-Image for $dir ${RESET}"
		echo -e "${Red}***********************************************${RESET}"
		env -C $UBOOT/Sancloud-signed-Image $UOUT/a53/${UBOOTCFG}/tools/fit_check_sign -f "${FIT_SOURCE_DIR}/${dir}/SanCloud-Secure$UBOOTCFG-image.fit" -k $UOUT/a53/${UBOOTCFG}/dts/upstream/src/arm64/ti/${DTB}.dtb
		if [ $? -ne 0 ]; then
		    echo -e "${Red}FIT-Image sign ERROR ${RESET}"
    		exit 1
		else
    		echo -e "${Green}Successfully checked signed FIT-Image ${RESET}"
		fi
	done
done

for UBOOTCFG in "${BOOTCFGS[@]}"; do
	echo -e "${Red}*******************************${RESET}"
	echo -e "${Red}* Securing ${UBOOTCFG}'s FDT ${RESET}"
	echo -e "${Red}*******************************${RESET}"
	env -C $UBOOT/Sancloud-signed-Image fdtput -t s $UOUT/a53/${UBOOTCFG}/dts/upstream/src/arm64/ti/${DTB}.dtb /signature required-mode all
	if [ $? -ne 0 ]; then
       	echo -e "${Red}unable to add signature's required-mode to dtb ${RESET}"
       	exit 1
	else
       	echo -e "${Green}Successfully add signature required-mode to dtb ${RESET}"
	fi
done



##old code for single fit image signing
# echo -e "${Red}***********************************${RESET}"
# echo -e "${Red}**  Sign FIT-Image for FALLBACK  **${RESET}"
# echo -e "${Red}***********************************${RESET}"
# env -C $UBOOT/Sancloud-signed-Image $UOUT/a53/BOOT/tools/mkimage -f Recovery-FitImageSigned.its -K $UOUT/a53/FALLBACK/dts/upstream/src/arm64/ti/k3-am625-sancloud.dtb    -T fdt_legacy -k ./keys -r SanCloud-Recovery-AM62_signed-image.fit
# if [ $? -ne 0 ]; then
#     echo -e "${Red}Unable to sign  Recovery-FIT-Image ${RESET}"
#     exit 1
# else
#     echo -e "${Green}Successfully signed Recovery-FIT-Image ${RESET}"
# fi

# env -C $UBOOT/Sancloud-signed-Image fdtput -t s $UOUT/a53/FALLBACK/dts/upstream/src/arm64/ti/k3-am625-sancloud.dtb /signature required-mode all
# if [ $? -ne 0 ]; then
#         echo -e "${Red}unable to add signature's required-mode to dtb ${RESET}"
#         exit 1
# else
#         echo -e "${Green}Successfully add signature required-mode to dtb ${RESET}"
# fi
#********************************************************************************************************************
#               change config to boot from FIT 
#********************************************************************************************************************
 

for BOOTCFG in "${BOOTCFGS[@]}"; do
    cp $UOUT/a53/$BOOTCFG/.config $UOUT/a53/$BOOTCFG/.config.back 

    env -C $UOUT/a53/$BOOTCFG  $UBOOT/scripts/config --set-str CONFIG_BOOTCOMMAND "sf probe||true;run scan_secure_fit;poweroff;"

    # Disable legacy “boot” commands
    #env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_BOOTM
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_BOOTZ
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_BOOTI
    
    # Disable serial “load” commands
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_LOADB
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_LOADS
    
    # Disable network‐based loads
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_TFTP
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_DHCP
    #env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_NET
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_DFU
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_FS_GENERIC
    #env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_FAT
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_EXT4
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_UBIFS
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_UBI

    # Disable block‐device commands if they give access (optional, but recommended)
    #env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_MMC
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_SPI

    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --enable  CONFIG_AUTOBOOT_KEYED
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --set-val CONFIG_BOOTDELAY   -3
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --set-val CONFIG_AUTOBOOT_DELAY_STR "\"\""
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --set-val CONFIG_AUTOBOOT_STOP_STR "\"\""
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --enable CONFIG_AUTOBOOT_USE_MENUKEY
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_AUTOBOOT_KEYED_CTRLC
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_BOOTSTD

   #silent console
   #env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config -e  CONFIG_SILENT_CONSOLE


    #env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_AUTOBOOT_PROMPT  # if present
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_ENV
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_SAVEENV
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --set-val CONFIG_ENV_IS_NOWHERE   y
    #disable hush in fallback
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_HUSH_PARSER
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMDLINE
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_AUTO_COMPLETE
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_CONSOLE
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_MENU 
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --disable CONFIG_CMD_SOURCE
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --enable CONFIG_DISABLE_CONSOLE
    env -C $UOUT/a53/$BOOTCFG $UBOOT/scripts/config --enable CONFIG_RESET_TO_RETRY
    #env -C $UBOOT make O=$UOUT/a53/$BOOTCFG clean
done


#********************************************************************************************************************
#               Re-Compiling with public keys 
#********************************************************************************************************************
# passed copy fine to after revert config just in case on the result of fail or abort conf not damage.
env -C $UBOOT/Sancloud-signed-Image ./config\&make\&copy.sh -N --IPs "" 
EXT=$?
#********************************************************************************************************************
#               Revert config  
#********************************************************************************************************************
for BOOTCFG in "${BOOTCFGS[@]}"; do
    cp $UOUT/a53/$BOOTCFG/.config.back $UOUT/a53/$BOOTCFG/.config
	if [ $? -ne 0 ]; then
		echo -e "${Red}Unable to revert config for $BOOTCFG ${RESET}"
		exit 1
	else
		echo -e "${Green}Successfully reverted config for $BOOTCFG ${RESET}"
	fi
done    

if [ $EXT -ne 0 ]; then
    echo -e "${Red}Unable to re-compile with public keys ${RESET}"
    exit 1
else
    echo -e "${Green}Successfully re-compiled with public keys ${RESET}"
fi
#********************************************************************************************************************
#               copy to board  
#********************************************************************************************************************
if [ ${#IPs[@]} -gt 0 ]; then
	for IP in "${IPs[@]}"; do
		PLAIN_ACCESS=""
		if [[ $IP =~ ^(([0-9]{1,3}\.){3}[0-9]{1,3})([Pp])?$ ]]; then
			IP="${BASH_REMATCH[1]}"
			PLAIN_ACCESS="${BASH_REMATCH[3]:-}"
		else
			echo "Invalid IP format: $1" >&2
			exit 1
		fi
        # Check if the IP is reachable
        if ping -c 1 -W 1 "$IP" &> /dev/null; then
			REMOTE_KERNEL=$((sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP}"  "uname -r" 2>/dev/null)| tail -n 1)
			echo -e "${Green}device $IP kernel version is $REMOTE_KERNEL ${RESET}"
			ADDITIONAL_FILES="$ADDITIONAL_FILES $FIT_SOURCE_DIR/$REMOTE_KERNEL/SanCloud-SecureBOOT-image.fit"
			ADDITIONAL_FILES="$ADDITIONAL_FILES,$FIT_SOURCE_DIR/$REMOTE_KERNEL/SanCloud-SecureFALLBACK-image.fit"
			KEYS="$S7_KEY $S0_KEY"
			if [[ -n "$PLAIN_ACCESS" ]]; then
				KEYS="";	
			fi
	      	$WORK/Boardcp.sh $PASS "--IP" $IP $KEYS  $NO_CHIP  $NO_EMMC $ADDITIONAL_FILES  &
        else
            echo -e "${Red}device $IP does not exist. ${RESET}"
        fi
    done  
    wait
fi