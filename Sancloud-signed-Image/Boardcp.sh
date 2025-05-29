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
PASSWORD="temppwd"
REMOTE_DIR="~/MHF-UBOOT"

S1_KEY="589505315,606348324,623191333,640034342"
S7_KEY="589505315,606348324,623191333,640034342"


# TIBOOT3_KEY="589505315,606348324,623191333,640034342"
# SPL_KEY="589505315,606348324,623191333,640034342"
# UBOOT_KEY="589505315,606348324,623191333,640034342"


# TIBOOT3_CRC="010101"
# TIBOOT3_Digest="0  --high-verbose"

# SPL_CRC="010101"
# SPL_Digest="0  --high-verbose"

# UBOOT_CRC="010101"
# UBOOT_Digest="0  --high-verbose"



ADDITIONAL_FILES=()


while [[ $# -gt 0 ]]; do
    case $1 in
        --ADDITIONAL_FILES)
            IFS=',' read -r -a ADDITIONAL_FILES <<< "$2"
            shift 2
            ;;
        # --TIBOOT3_CRC)
        #     TIBOOT3_CRC="$2"
        #     shift 2
        #     ;;
        # --TIBOOT3_Digest)
        #     TIBOOT3_Digest="$2"
        #     shift 2
        #     ;;

        # --SPL_CRC)
        #     SPL_CRC="$2"
        #     shift 2
        #     ;;
        # --SPL_Digest)
        #     SPL_Digest="$2"
        #     shift 2
        #     ;;
      
        # --UBOOT_CRC)
        #     UBOOT_CRC="$2"
        #     shift 2
        #     ;;
        # --UBOOT_Digest)
        #     UBOOT_Digest="$2"
        #     shift 2
        #     ;;

        # --TIBOOT3_KEY)
        #     TIBOOT3_KEY="$2"
        #     shift 2
        #     ;;
        # --SPL_KEY)
        #     SPL_KEY="$2"
        #     shift 2
        #     ;;
        # --UBOOT_KEY)
        #     UBOOT_KEY="$2"
        #     shift 2
        #     ;;
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
            IP_ADDRESS="$2"
            shift 2
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

# Define the list of files to copy
FILES=(
    "$UOUT/r5/BOOT/tiboot3-am62x-gp-evm.bin"
    "$UOUT/a53/BOOT/tispl.bin_unsigned"
    "$UOUT/a53/BOOT/u-boot.img_unsigned"
    "$UOUT/SanCloud-BOOT.bin"
    "$UOUT/SanCloud-FALLBACK.bin"
)
FSIZE=()
cnt=0
for FILE in "${FILES[@]}"; do
    if [[ -e "$FILE" ]]; then
        SIZE=$(stat -c %s "$FILE")
        # Calculate remainder
        REMAINDER=$((SIZE % 4))
        if [[ $REMAINDER -ne 0 ]]; then
            # Calculate padding needed
            PADDING=$((4 - REMAINDER))
            FSIZE[cnt]=$((SIZE + PADDING))
        else
            FSIZE[cnt]=""
        fi    
    else
        echo -e "{Red}File $FILE does not exist.${RESET}"
    fi
    cnt=$((cnt+1))
done  

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
        if [[ "$FILE" == *"uboot.env" ]]; then
            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR  -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   rm -rf /boot/uboot.env"
            if [ $? -ne 0 ]; then
                echo -e "${Red}Failed to REMOVE old uboot.env FROM /boot on ${IP_ADDRESS} ${RESET}"
            else
                echo -e "${Green}Successfully RMOVED olde uboot.env from on ${IP_ADDRESS}  /boot ${RESET}"
            fi
            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   mv $REMOTE_DIR/uboot.env /boot/"
            if [ $? -ne 0 ]; then
                echo -e "${Red}Failed to MOV \"$REMOTE_DIR/uboot.env\" to /boot ${RESET} on ${IP_ADDRESS}"
            else
                echo -e "${Green}Successfully Moved \"$REMOTE_DIR/uboot.env\" to /boot${RESET} on ${IP_ADDRESS}"
            fi
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
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   mv $REMOTE_DIR/*.fit /boot/"
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
echo -e "${Blue}Unsecure program section 0 BOOT unified image size ${FSIZE[3]} ${RESET}"
if [[ -n "${FSIZE[3]}" ]]; then
    FSIZE[3]="--FSIZE ${FSIZE[3]}"
fi
$WORK/ProgramSection.sh --KEY "${S1_KEY}" --Ver 0 --DIE 0 --SECTION 0 --IP ${IP_ADDRESS} --FILE "${REMOTE_DIR}/SanCloud-BOOT.bin" ${FSIZE[3]}

echo -e "${Blue}Unsecure program section 7 fallback unified image  size ${FSIZE[4]} ${RESET}"
if [[ -n "${FSIZE[4]}" ]]; then
    FSIZE[4]="--FSIZE ${FSIZE[4]}"
fi
$WORK/ProgramSection.sh --KEY "${S7_KEY}" --Ver 0 --DIE 0 --SECTION 7 --IP ${IP_ADDRESS} --FILE "${REMOTE_DIR}/SanCloud-FALLBACK.bin" ${FSIZE[4]}


#********************************************************************************************************************
#               copy the file to SD vfat partition
#********************************************************************************************************************
echo -e "${Blue}Updating  flash boot partition files  ${RESET}"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   mount -t vfat /dev/mmcblk1p1 /mnt/"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   cp $REMOTE_DIR/tiboot3-am62x-gp-evm.bin /mnt/tiboot3.bin"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   cp $REMOTE_DIR/tispl.bin_unsigned /mnt/tispl.bin"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   cp $REMOTE_DIR/u-boot.img_unsigned /mnt/u-boot.img"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   umount /mnt/"
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   sync"
#sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   reboot"

#********************************************************************************************************************
#               copy the file to my windows machine
#********************************************************************************************************************
echo -e "${Blue}Copying the file to my windows machine  ${RESET}"
winpass="Mina9175"
winaddr="hosseinf@10.0.0.124:C:\Users\hosseinf\Desktop\1\AM62\U-boot"
sshpass -p "$winpass" scp -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -q "$UOUT/a53/BOOT/u-boot.img_unsigned" "$winaddr\u-boot.img"
if [ $? -ne 0 ]; then
    echo -e "${Red}Failed to write ti3boot on windows distination ${RESET}"
fi
sshpass -p "$winpass" scp -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -q "$UOUT/a53/BOOT/tispl.bin_unsigned" "$winaddr\tispl.bin"
if [ $? -ne 0 ]; then
    echo -e "${Red}Failed to write tispl on windows distination ${RESET}"
fi
sshpass -p "$winpass" scp -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -q "$UOUT/r5/BOOT/tiboot3-am62x-gp-evm.bin" "$winaddr\tiboot3.bin"
if [ $? -ne 0 ]; then
    echo -e "${Red}Failed to write on windows distination ${RESET}"
fi
#********************************************************************************************************************

#sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR "debian@${IP_ADDRESS}" "rm -rf $REMOTE_DIR"


echo -e "${Green}COMPLITED ${RESET}"
