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

IPs=(
"10.0.0.156"
#"10.0.0.202"
    )  

#---------------------------------------------------------------------------------------------------------
# parameter for pass to Boardcp
#---------------------------------------------------------------------------------------------------------
PASSWORD=""
TIBOOT3_KEY="" #"589505315,606348324,623191333,640034342"
TIBOOT3_CRC=""
TIBOOT3_Digest=""
ADDITIONAL_FILES="" #"--ADDITIONAL_FILES $WORK/SanCloud-FalconArgGenerator-image.fit,$WORK/SanCloud-Falcon-image.fit"
#---------------------------------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case $1 in
        --ips)
            IFS=',' read -r -a IPs <<< "$2"
            shift 2
            ;;
#---------------------------------------------------------------------------------------------------------
# parameter for pass to Boardcp 
#---------------------------------------------------------------------------------------------------------
        --TIBOOT3_CRC)
            TIBOOT3_CRC="--TIBOOT3_CRC $2"
            shift 2
            ;;
        --TIBOOT3_Digest)
            TIBOOT3_Digest="--TIBOOT3_Digest $2"
            shift 2
            ;;
        --TIBOOT3_KEY)
            TIBOOT3_KEY="--TIBOOT3_KEY $2"
            shift 2
            ;;
        --SPL_CRC)
            SPL_CRC="--SPL_CRC $2"
            shift 2
            ;;
        --SPL_Digest)
            SPL_Digest="--SPL_Digest $2"
            shift 2
            ;;
        --SPL_KEY)
            SPL_KEY="--SPL_KEY $2"
            shift 2
            ;;
        --UBOOT_CRC)
            UBOOT_CRC="--UBOOT_CRC $2"
            shift 2
            ;;
        --UBOOT_Digest)
            UBOOT_Digest="--UBOOT_Digest $2"
            shift 2
            ;;
        --UBOOT_KEY)
            UBOOT_KEY="--UBOOT_KEY $2"
            shift 2
            ;;

        --PASSWORD)
            PASSWORD="--PASSWORD $2"
            shift 2
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
echo -e "${Red}**********************${RESET}"
echo -e "${Red}*** Configuring R5 ***${RESET}"
echo -e "${Red}**********************${RESET}"
env -C $UBOOT make CROSS_COMPILE=arm-none-linux-gnueabihf-  O=$UOUT/r5 menuconfig
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to config r5 ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully r5 is config ${RESET}"
fi
echo -e "${Red}**********************${RESET}"
echo -e "${Red}*** Configuring A53 ***${RESET}"
echo -e "${Red}**********************${RESET}"
env -C $UBOOT make O=$UOUT/a53 menuconfig
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to config a53 ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully a53 is config ${RESET}"
fi



env -C $UBOOT make CROSS_COMPILE=arm-none-linux-gnueabihf-  O=$UOUT/r5 clean
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to clean r5 ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully r5 is cleaned ${RESET}"
fi

env -C $UBOOT make CROSS_COMPILE=arm-none-linux-gnueabihf- BINMAN_INDIRS=$BINMAN_INDIRS  O=$UOUT/r5 -j$(nproc) #-B  
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to compile r5 ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully r5 is compiled ${RESET}"
fi

# env -C $UBOOT make O=$UOUT/a53 clean
# if [ $? -ne 0 ]; then
#         echo -e "${Red}unable to clean a53 ${RESET}"
#         exit 1
# else
#         echo -e "${Green}Successfully a53 is cleaned ${RESET}"
# fi

env -C $UBOOT make O=$UOUT/a53  BINMAN_INDIRS=$BINMAN_INDIRS   -j$(nproc) #-B 
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to compile a53 ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully a53 is compiled ${RESET}"
fi
if [ ${#IPs[@]} -gt 0 ]; then
        for IP in "${IPs[@]}"; do
            # Check if the IP is reachable
            if ping -c 1 -W 1 "$IP" &> /dev/null; then
               $WORK/Boardcp.sh $TIBOOT3_CRC $TIBOOT3_Digest $TIBOOT3_KEY $SPL_CRC $SPL_Digest $SPL_KEY $UBOOT_CRC $UBOOT_Digest $UBOOT_KEY $PASSWORD $ADDITIONAL_FILES "--IP" $IP   &
            else
                 echo -e "${Red}device $IP does not exist. ${RESET}"
            fi
        
            done  
        wait
fi