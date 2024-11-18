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

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <ip_address> [<password>]"
    exit 1
fi

# Get the IP address and password from the command-line arguments
IP_ADDRESS=$1
PASSWORD="temppwd"
REMOTE_DIR="~/MHF-UBOOT"

DEf_Digest="0  --high-verbose"
DEF_CRC="010101"
C1=${2:-$DEF_CRC}
C2=${3:-$DEF_CRC}
D1=${4:-$DEf_Digest}
D2=${5:-$DEf_Digest}



if [ "$C1" == "$DEF_CRC" ]; then
    # Define the list of files to copy
    FILES=(
        "$UOUT/MLO.byteswap"
        "$UOUT/u-boot-dtb.img"
        $ADDITIONAL_FILES
    )  


    sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "rm -rf $REMOTE_DIR"
    if [ $? -ne 0 ]; then
        echo -e "${Red}Failed to remove directory $REMOTE_DIR on $IP_ADDRESS${RESET}"
        #exit 1
    else
        echo -e "${Green}Successfully created directory $REMOTE_DIR on $IP_ADDRESS${RESET}"
    fi

    sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "mkdir -p $REMOTE_DIR"
    if [ $? -ne 0 ]; then
        echo -e "${Red}Failed to create directory $REMOTE_DIR on $IP_ADDRESS${RESET}"
        exit 1
    else
        echo -e "${Green}Successfully created directory $REMOTE_DIR on $IP_ADDRESS${RESET}"
    fi
    # Copy each file in the list
    for FILE in "${FILES[@]}"; do
        if [[ -e "$FILE" ]]; then
            # Use sshpass to provide the password to scp
            sshpass -p "$PASSWORD" scp "$FILE" "debian@${IP_ADDRESS}:$REMOTE_DIR"
            if [ $? -ne 0 ]; then
                echo -e "${Red}Failed to copy $FILE to $IP_ADDRESS${RESET}"
            else
                echo -e "${Green}Successfully copied $FILE to $IP_ADDRESS${RESET}"
            fi
         if [[ "$FILE" == *"SanCloud-sined-image.fit" ]]; then
            sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S rm -rf /boot/SanCloud-sined-image.fit"
            if [ $? -ne 0 ]; then
                echo -e "${Red}Failed to REMOVE old /boot/SanCloud-sined-image.fit FROM /boot on ${IP_ADDRESS} ${RESET}"
            else
                echo -e "${Green}Successfully RMOVED olde /boot/SanCloud-sined-image.fit from on ${IP_ADDRESS}  /boot ${RESET}"
            fi

            sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S mv $REMOTE_DIR/SanCloud-sined-image.fit /boot/"
            if [ $? -ne 0 ]; then
                echo -e "${Red}Failed to MOV \"$REMOTE_DIR/SanCloud-sined-image.fit\" to /boot ${RESET} on ${IP_ADDRESS}"
            else
                echo -e "${Green}Successfully Moved \"$REMOTE_DIR/SanCloud-sined-image.fit\" to /boot${RESET} on ${IP_ADDRESS}"
            fi
          fi 
        else
            echo -e "${Red}File $FILE does not exist.${RESET}"
        fi
    done  
fi

#secure program section 0 and 1
#sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/ ./TESTAPP -u $REMOTE_DIR/MLO.byteswap -s 0 -D 0 -k 589505315,606348324,623191333,640034342 -v 0 --fk -C $C1 -d $D1 && echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -u $REMOTE_DIR/u-boot-dtb.img -s 1 -D 0 -k 589505315,606348324,623191333,640034342 -v 0 --fk -S 57852 -C $C2 -d $D2 "

#secure program section 0
#sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -u $REMOTE_DIR/MLO.byteswap -s 0 -D 0 -k 589505315,606348324,623191333,640034342 -v 0 --fk -S 57852 -C $C2 -d $D2 "

#unsecure program  
sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/ ./TESTAPP -w -p -s 0 -D 0 -f $REMOTE_DIR/MLO.byteswap && echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -w -p -s 1 -D 0 -f $REMOTE_DIR/u-boot-dtb.img"


#unsecure program section 0
#sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -w -p -s 0 -D 0 -f $REMOTE_DIR/MLO.byteswap"
if [ $? -ne 0 ]; then
    echo -e "${Red}Failed to write on chip ${RESET}"
    exit 1
else
    echo -e "${Green}Successfully chip programed ${RESET}"
fi