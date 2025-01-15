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

MLO_SPI_KEY="" #"589505315,606348324,623191333,640034342"
UBOOT_SPI_KEY="" #"589505315,606348324,623191333,640034342"


MLO_CRC="010101"
MLO_Digest="0  --high-verbose"
UBOOT_CRC="010101"
UBOOT_Digest="0  --high-verbose"
ADDITIONAL_FILES=()


while [[ $# -gt 0 ]]; do
    case $1 in
        --ADDITIONAL_FILES)
            IFS=',' read -r -a ADDITIONAL_FILES <<< "$2"
            shift 2
            ;;
        --MLO_CRC)
            MLO_CRC="$2"
            shift 2
            ;;
        --MLO_Digest)
            MLO_Digest="$2"
            shift 2
            ;;
        --UBOOT_CRC)
            UBOOT_CRC="$2"
            shift 2
            ;;
        --UBOOT_Digest)
            UBOOT_Digest="$2"
            shift 2
            ;;
        --MLO_SPI_KEY)
            MLO_SPI_KEY="$2"
            shift 2
            ;;
        --UBOOT_SPI_KEY)
            UBOOT_SPI_KEY="$2"
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
    "$UOUT/MLO.byteswap"
    "$UOUT/u-boot-dtb.img"
    "${ADDITIONAL_FILES[@]}"
)  



#FILESIZE=$(stat -c%s "$UOUT/MLO.byteswap")
# if [ "$FILESIZE" -gt "110592" ]; then
#     echo -e "${Red} MLO size is $FILESIZE biger then 0x1B000"
#     exit 1
# fi
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
        if [[ "$FILE" == *"uboot.env" ]]; then
            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S rm -rf /boot/uboot.env"
            if [ $? -ne 0 ]; then
                echo -e "${Red}Failed to REMOVE old uboot.env FROM /boot on ${IP_ADDRESS} ${RESET}"
            else
                echo -e "${Green}Successfully RMOVED olde uboot.env from on ${IP_ADDRESS}  /boot ${RESET}"
            fi
            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S mv $REMOTE_DIR/uboot.env /boot/"
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
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S rm -rf /boot/SanCloud-*-image.fit"
    if [ $? -ne 0 ]; then
        echo -e "${Red}Failed to REMOVE old /boot/SanCloud-*-image.fit FROM /boot on ${IP_ADDRESS} ${RESET}"
    else
        echo -e "${Green}Successfully RMOVED olde /boot/SanCloud-*-image.fit from on ${IP_ADDRESS}  /boot ${RESET}"
    fi
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S mv $REMOTE_DIR/*.fit /boot/"
    if [ $? -ne 0 ]; then
        echo -e "${Red}Failed to MOV \"$REMOTE_DIR/*.fit\" to /boot ${RESET} on ${IP_ADDRESS}"
    else
        echo -e "${Green}Successfully Moved \"$REMOTE_DIR/*.fit\" to /boot${RESET} on ${IP_ADDRESS}"
    fi
fi


#ext4 nedds to resync with new address
sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "sync"

if [ -n "$MLO_SPI_KEY" ]; then
    if [ -n "$UBOOT_SPI_KEY" ]; then
        echo -e "${Blue}secure program section 0 and 1${RESET}"
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/ ./TESTAPP -u $REMOTE_DIR/MLO.byteswap -s 0 -D 0 -k ${MLO_SPI_KEY} -v 0 --fk -C $MLO_CRC -d $MLO_Digest && echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -u $REMOTE_DIR/u-boot-dtb.img -s 1 -D 0 -k ${UBOOT_SPI_KEY} -v 0 --fk -S 57852 -C $UBOOT_CRC -d $UBOOT_Digest "
    else 
        echo -e "${Blue}secure program section 0 ${RESET}"
        sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -u $REMOTE_DIR/MLO.byteswap -s 0 -D 0 -k ${MLO_SPI_KEY} -v 0 --fk -S 57852 -C $MLO_CRC -d $MLO_Digest "
    fi 
else   
    #echo -e "${Blue}Unsecure program section 0 and 1${RESET}"
    #sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/ ./TESTAPP -w -p -s 0 -D 0 -f $REMOTE_DIR/MLO.byteswap && echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -w -p -s 1 -D 0 -f $REMOTE_DIR/u-boot-dtb.img"

    echo -e "${Blue}Unsecure program section 0 ${RESET}"
    sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -w -p -s 0 -D 0 -f $REMOTE_DIR/MLO.byteswap"
fi
if [ $? -ne 0 ]; then
    echo -e "${Red}Failed to write on chip ${RESET}"
    exit 1
else
    echo -e "${Green}Successfully chip programed ${RESET}"
fi
#sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "debian@${IP_ADDRESS}" "rm -rf $REMOTE_DIR"