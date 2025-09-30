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
PLAIN_ACCESS=""
REMOTE_DIR="~/MHF-UBOOT"

PASSWORD="temppwd"
S1_KEY="589505315,606348324,623191333,640034342"
S7_KEY="589505315,606348324,623191333,640034342"

ADDITIONAL_FILES=()
#for USB
DISK="/dev/sda"
#for SD card
#DISK="/dev/mmcblk0"
#for eMMC
#DISK="/dev/mmcblk1"

while [[ $# -gt 0 ]]; do
	case $1 in
	--ADDITIONAL_FILES)
		IFS=',' read -r -a ADDITIONAL_FILES <<<"$2"
		shift 2
		;;
	--S1_KEY)
		S1_KEY="$2"
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
		shift
		if [[ $1 =~ ^(([0-9]{1,3}\.){3}[0-9]{1,3})([Pp])?$ ]]; then
			IP_ADDRESS="${BASH_REMATCH[1]}"
			PLAIN_ACCESS="${BASH_REMATCH[3]:-}"
		else
			echo "Invalid IP format: $1" >&2
			exit 1
		fi
		shift
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
	exit
fi

# Define the list of files to copy
FILES=(
	"$UOUT/MLO.byteswap"
	"$UOUT/MLO"
	"$UOUT/u-boot-dtb.img"
	"${ADDITIONAL_FILES[@]}"
)

# Append additional files
if [[ -n "${ADDITIONAL_FILES[*]}" ]]; then
	FILES+=("${ADDITIONAL_FILES[@]}")
fi

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "rm -rf $REMOTE_DIR"
if [ $? -ne 0 ]; then
	echo -e "${Red}Failed to remove directory $REMOTE_DIR on $IP_ADDRESS${RESET}"
	#exit 1
else
	echo -e "${Green}Successfully created directory $REMOTE_DIR on $IP_ADDRESS${RESET}"
fi

sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "mkdir -p $REMOTE_DIR"
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
		sshpass -p "$PASSWORD" scp "$FILE" "debian@${IP_ADDRESS}:$REMOTE_DIR"
		if [ $? -ne 0 ]; then
			echo -e "${Red}Failed to copy $FILE to $IP_ADDRESS${RESET}"
			exit
		else
			echo -e "${Green}Successfully copied $FILE to $IP_ADDRESS${RESET}"
		fi

		if [[ "$FILE" == *.fit ]]; then
			contains_fit_file=true
		fi
		if [[ -z "$NO_EMMC" ]]; then

			if [[ "$FILE" == *"uboot.env" ]]; then
				sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S rm -rf /boot/uboot.env"
				if [ $? -ne 0 ]; then
					echo -e "${Red}Failed to REMOVE old uboot.env FROM /boot on ${IP_ADDRESS} ${RESET}"
				else
					echo -e "${Green}Successfully RMOVED olde uboot.env from on ${IP_ADDRESS}  /boot ${RESET}"
				fi
				sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S cp $REMOTE_DIR/uboot.env /boot/"
				if [ $? -ne 0 ]; then
					echo -e "${Red}Failed to MOV \"$REMOTE_DIR/uboot.env\" to /boot ${RESET} on ${IP_ADDRESS}"
				else
					echo -e "${Green}Successfully Moved \"$REMOTE_DIR/uboot.env\" to /boot${RESET} on ${IP_ADDRESS}"
				fi
			fi
		fi
	else
		echo -e "${Red}File $FILE does not exist.${RESET}"
	fi
done
if $contains_fit_file; then
	sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S rm -rf /boot/SanCloud-*-image.fit"
	if [ $? -ne 0 ]; then
		echo -e "${Red}Failed to REMOVE old /boot/SanCloud-*-image.fit FROM /boot on ${IP_ADDRESS} ${RESET}"
	else
		echo -e "${Green}Successfully RMOVED olde /boot/SanCloud-*-image.fit from on ${IP_ADDRESS}  /boot ${RESET}"
	fi
	sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S cp $REMOTE_DIR/*.fit /boot/"
	if [ $? -ne 0 ]; then
		echo -e "${Red}Failed to MOV \"$REMOTE_DIR/*.fit\" to /boot ${RESET} on ${IP_ADDRESS}"
	else
		echo -e "${Green}Successfully Moved \"$REMOTE_DIR/*.fit\" to /boot${RESET} on ${IP_ADDRESS}"
	fi
fi

if [[ -z "$NO_EMMC" ]]; then
	sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S sudo dd if=$REMOTE_DIR/MLO of=$DISK count=2 seek=1 bs=128k"
	if [ $? -ne 0 ]; then
		echo -e "${Red}Failed to write MLO to $DISK on ${IP_ADDRESS} ${RESET}"
	else
		echo -e "${Green}Successfully  write MLO to $DISK on ${IP_ADDRESS} ${RESET}"
	fi
	sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S sudo dd if=$REMOTE_DIR/u-boot-dtb.img of=$DISK  count=4 seek=1 bs=384k"
	if [ $? -ne 0 ]; then
		echo -e "${Red}Failed to write u-boot to $DISK on ${IP_ADDRESS} ${RESET}"
	else
		echo -e "${Green}Successfully write u-boot to $DISK on ${IP_ADDRESS} ${RESET}"
	fi

fi

#ext4 nedds to resync with new address
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "sync"

#********************************************************************************************************************
#               Program the chip
#********************************************************************************************************************
get_remote_size() {
	SIZE=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "stat -c %s \"$1\"")
	# Calculate remainder
	REMAINDER=$((SIZE % 4))
	if [[ $REMAINDER -ne 0 ]]; then
		# Calculate padding needed
		PADDING=$((4 - REMAINDER))
		SIZE=$((SIZE + PADDING))
	fi
	echo $SIZE
}

if [[ -z "$NO_CHIP" ]]; then
	FSIZE=$(get_remote_size "$REMOTE_DIR/SanCloud-BOOT.bin")
	echo -e "${Blue}Unsecure program section 0 BOOT unified image size $FSIZE ${RESET}"
	if [[ -n "$FSIZE" ]]; then
		FSIZE="--FSIZE $FSIZE"
	fi
	$WORK/ProgramSection.sh --KEY "${S1_KEY}" --Ver 4 --DIE 0 --SECTION 0 --IP ${IP_ADDRESS}${PLAIN_ACCESS} --FILE "${REMOTE_DIR}/SanCloud-BOOT.bin" ${FSIZE}
	FSIZE=$(get_remote_size "$REMOTE_DIR/SanCloud-FALLBACK.bin")
	echo -e "${Blue}Unsecure program section 7 fallback unified image  size $FSIZE ${RESET}"
	if [[ -n "FSIZE" ]]; then
		FSIZE[4]="--FSIZE $FSIZE"
	fi
	$WORK/ProgramSection.sh --KEY "${S7_KEY}" --Ver 4 --DIE 0 --SECTION 7 --IP ${IP_ADDRESS}${PLAIN_ACCESS} --FILE "${REMOTE_DIR}/SanCloud-FALLBACK.bin" $FSIZE
fi

#sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "rm -rf $REMOTE_DIR"
