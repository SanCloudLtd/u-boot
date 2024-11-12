#!/bin/bash

# Check if the correct number of arguments is provided
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
    )  


    sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "rm -rf $REMOTE_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to remove directory $REMOTE_DIR on $IP_ADDRESS"
        #exit 1
    else
        echo "Successfully created directory $REMOTE_DIR on $IP_ADDRESS"
    fi

    sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "mkdir -p $REMOTE_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to create directory $REMOTE_DIR on $IP_ADDRESS"
        exit 1
    else
        echo "Successfully created directory $REMOTE_DIR on $IP_ADDRESS"
    fi
    # Copy each file in the list
    for FILE in "${FILES[@]}"; do
        if [[ -e "$FILE" ]]; then
            # Use sshpass to provide the password to scp
            sshpass -p "$PASSWORD" scp "$FILE" "debian@${IP_ADDRESS}:$REMOTE_DIR"
            if [ $? -ne 0 ]; then
                echo "Failed to copy $FILE to $IP_ADDRESS"
            else
                echo "Successfully copied $FILE to $IP_ADDRESS"
            fi
        else
            echo "File $FILE does not exist."
        fi
    done  
fi

#secure program section 0 and 1
#sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/ ./TESTAPP -u $REMOTE_DIR/u-boot-dtb.img -s 1 -D 0 -k 589505315,606348324,623191333,640034342 -v 0 --fk -C $C1 -d $D1 && echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -u $REMOTE_DIR/MLO.byteswap -s 0 -D 0 -k 589505315,606348324,623191333,640034342 -v 0 --fk -S 57852 -C $C2 -d $D2 "

#secure program section 0
#sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -u $REMOTE_DIR/MLO.byteswap -s 0 -D 0 -k 589505315,606348324,623191333,640034342 -v 0 --fk -S 57852 -C $C2 -d $D2 "

#unsecure program  
sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/ ./TESTAPP -w -p -s 1 -D 0 -f $REMOTE_DIR/u-boot-dtb.img && echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -w -p -s 0 -D 0 -f $REMOTE_DIR/MLO.byteswap"


#unsecure program section 0
#sshpass -p "$PASSWORD" ssh "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S env -C ~/winbond-lib/build/  ./TESTAPP -w -p -s 0 -D 0 -f $REMOTE_DIR/MLO.byteswap"
if [ $? -ne 0 ]; then
    echo "Failed to write on chip"
    exit 1
else
    echo "Successfully chip programed"
fi