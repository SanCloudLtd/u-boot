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


# Get the IP address and password from the command-line arguments
IP_ADDRESS=""
REMOTE_DIR="~/MHF-UBOOT"

PASSWORD="temppwd"
S0_KEY=""
S7_KEY=""

ADDITIONAL_FILES=()


while [[ $# -gt 0 ]]; do
    case $1 in
        --ADDITIONAL_FILES)
            IFS=',' read -r -a ADDITIONAL_FILES <<< "$2"
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
        --IP)
            IP_ADDRESS="$2"
            shift 2
            ;;
        --NO_CHIP)
            NO_CHIP=1
            shift 1
            ;;    
        --NO_EMMC)
            NO_EMMC=1
            shift 1
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

if [ -z "$IP_ADDRESS" ]; then
    echo -e "${Red} --IP not found in the command parameters ${RESET}"
    exit;
fi
# recognize board cpu type

jtagid_raw=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR  -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p '' devmem2 0x43000018" | grep "Read at address" | awk '{print $NF}')

jtagid=$((jtagid_raw))
device_type_raw=$(( (jtagid >> 11) & 0x3 ))
case "$device_type_raw" in
    0)
        CPU="gp"
        UNSIGNEG="_unsigned"
        ;;
    1)
        CPU="hs"
        UNSIGNEG=""
        ;;

    2|3)
        CPU="hs-fs"
        UNSIGNEG=""
        ;;
    *)
        echo "Unknown device type: raw=$device_type_raw (JTAGID=0x$(printf "%08X\n" $jtagid))"
        exit 2
        ;;
esac

echo -e "${Green}Detected CPU type: ${CPU^^}${RESET}"


# Define the list of files to copy
FILES=(
    "$UOUT/r5/BOOT/tiboot3-am62x-$CPU-evm.bin"
    "$UOUT/a53/BOOT/tispl.bin$UNSIGNEG"
    "$UOUT/a53/BOOT/u-boot.img$UNSIGNEG"
    "$UOUT/SanCloud-BOOT-$CPU.bin"
    "$UOUT/SanCloud-FALLBACK-$CPU.bin"
)

# Append additional files 
if [[ -n "${ADDITIONAL_FILES[*]}" ]]; then
    FILES+=("${ADDITIONAL_FILES[@]}")
fi


sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "rm -rf $REMOTE_DIR"
if [ $? -ne 0 ]; then
    echo -e "${Red}Failed to remove directory $REMOTE_DIR on $IP_ADDRESS${RESET}"
    #exit 1
else
    echo -e "${Green}Successfully created directory $REMOTE_DIR on $IP_ADDRESS${RESET}"
fi



sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "mkdir -p $REMOTE_DIR"
if [ $? -ne 0 ]; then
    echo -e "${Red}Failed to create directory $REMOTE_DIR on $IP_ADDRESS${RESET}"
    exit 1
else
    echo -e "${Green}Successfully created directory $REMOTE_DIR on $IP_ADDRESS${RESET}"
fi
# Copy each file in the list
contains_fit_file=false
for FILE in "${FILES[@]}"; do
    if [[ -e "$FILE" ]]; then
        # Use sshpass to provide the password to scp
        sshpass -p "$PASSWORD" scp -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -q "$FILE" "debian@${IP_ADDRESS}:$REMOTE_DIR"
        if [ $? -ne 0 ]; then
            echo -e "${Red}Failed to copy $FILE to $IP_ADDRESS${RESET}"
            exit
        else
            echo -e "${Green}Successfully copied $FILE to $IP_ADDRESS${RESET}"
        fi
        if [[ "$FILE" == *.fit ]]; then
            contains_fit_file=true
        fi
    else
        echo -e "${Red}File $FILE does not exist.${RESET}"
    fi
done  

if $contains_fit_file; then
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   rm -rf /boot/SanCloud-*-image.fit"
    if [ $? -ne 0 ]; then
        echo -e "${Red}Failed to REMOVE old /boot/SanCloud-*-image.fit FROM /boot on ${IP_ADDRESS} ${RESET}"
    else
        echo -e "${Green}Successfully RMOVED olde /boot/SanCloud-*-image.fit from on ${IP_ADDRESS}  /boot ${RESET}"
    fi
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   cp $REMOTE_DIR/*.fit /boot/"
    if [ $? -ne 0 ]; then
        echo -e "${Red}Failed to MOV \"$REMOTE_DIR/*.fit\" to /boot ${RESET} on ${IP_ADDRESS}"
    else
        echo -e "${Green}Successfully Moved \"$REMOTE_DIR/*.fit\" to /boot${RESET} on ${IP_ADDRESS}"
    fi
fi


#ext4 nedds to resync with new address
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "sync"



#********************************************************************************************************************
#               Program the chip
#********************************************************************************************************************
get_aligned_size() {
    local FILE="$1"
    if [[ ! -e "$FILE" ]]; then
        echo -e "${Red}error: file not found: $FILE${RESET}" >&2
        return 1
    fi

    local SIZE
    SIZE=$(stat -c %s "$FILE") || { echo -e "${Red}error: stat failed${RESET}" >&2; return 2; }
    #Calculate remainder
    local REMAINDER=$((SIZE % 4))
    if [[ $REMAINDER -ne 0 ]]; then
		SIZE=$(( SIZE + 4 - REMAINDER ))
		echo "--FSIZE ${SIZE}"
	else
		echo ""
    fi
	echo ""    
}

if [[ -z "$NO_CHIP" ]] ;then
	FSIZE=$(get_aligned_size "${FILES[3]}") ||{
    echo -e "${Red}Failed to get aligned size${RESET}"
    exit 1
	}
	if [ -n "$FSIZE" ]; then
		echo -e "${Blue}unified image size set to ${FSIZE} ${RESET}"
	fi
    $WORK/ProgramSection.sh --KEY "${S0_KEY}" --Ver 0 --DIE 0 --SECTION 0 --IP ${IP_ADDRESS} --FILE "${REMOTE_DIR}/SanCloud-BOOT-$CPU.bin" $FSIZE

    echo -e "${Blue}Unsecure program section 7 fallback unified image  size ${FSIZE[4]} ${RESET}"

	FSIZE=$(get_aligned_size "${FILES[4]}") ||{
    echo -e "${Red}Failed to get aligned size${RESET}"
    exit 1
	}
	if [ -n "$FSIZE" ]; then
		echo -e "${Blue}unified image size set to ${FSIZE} ${RESET}"
	fi
    $WORK/ProgramSection.sh --KEY "${S7_KEY}" --Ver 0 --DIE 0 --SECTION 7 --IP ${IP_ADDRESS} --FILE "${REMOTE_DIR}/SanCloud-FALLBACK-$CPU.bin" $FSIZE
fi

#********************************************************************************************************************
#               copy the file to SD vfat partition
#********************************************************************************************************************
if [[ -z "$NO_EMMC" ]] ;then
    echo -e "${Blue}Updating  flash boot partition files  ${RESET}"
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   mount -t vfat /dev/mmcblk1p1 /mnt/"
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   cp $REMOTE_DIR/tiboot3-am62x-$CPU-evm.bin /mnt/tiboot3.bin"
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   cp $REMOTE_DIR/tispl.bin$UNSIGNEG /mnt/tispl.bin"
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   cp $REMOTE_DIR/u-boot.img$UNSIGNEG /mnt/u-boot.img"
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   umount /mnt/"
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   sync"
    #sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   reboot"
fi

#********************************************************************************************************************
#               copy the file to my windows machine
#********************************************************************************************************************
# echo -e "${Blue}Copying the file to my windows machine  ${RESET}"
# winpass="Mina9175"
# winaddr="hosseinf@10.0.0.124:C:\Users\hosseinf\Desktop\1\AM62\U-boot"
# sshpass -p "$winpass" scp -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -q "$UOUT/a53/BOOT/u-boot.img$UNSIGNEG" "$winaddr\u-boot.img"
# if [ $? -ne 0 ]; then
#     echo -e "${Red}Failed to write ti3boot on windows distination ${RESET}"
# fi
# sshpass -p "$winpass" scp -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -q "$UOUT/a53/BOOT/tispl.bin$UNSIGNEG" "$winaddr\tispl.bin"
# if [ $? -ne 0 ]; then
#     echo -e "${Red}Failed to write tispl on windows distination ${RESET}"
# fi
# sshpass -p "$winpass" scp -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -q "$UOUT/r5/BOOT/tiboot3-am62x-$CPU-evm.bin" "$winaddr\tiboot3.bin"
# if [ $? -ne 0 ]; then
#     echo -e "${Red}Failed to write on windows distination ${RESET}"
# fi
#********************************************************************************************************************

#sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR "debian@${IP_ADDRESS}" "rm -rf $REMOTE_DIR"


echo -e "${Green}$IP_ADDRESS COMPLITED ${RESET}"
