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
#"82.5.144.219"
#"10.0.0.89"
#"10.0.0.236"
    )  
DTB="am335x-sancloud-bbe-lite"    
sign_all_images=false




#---------------------------------------------------------------------------------------------------------
# parameter for pass to Boardcp
#---------------------------------------------------------------------------------------------------------
PASSWORD=""
MLO_SPI_KEY="" #"589505315,606348324,623191333,640034342"
MLO_CRC=""
MLO_Digest=""
ADDITIONAL_FILES="--ADDITIONAL_FILES $WORK/SanCloud-FalconArgGenerator-image.fit,$WORK/SanCloud-Falcon-image.fit"
#---------------------------------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case $1 in
        --sign_all_images)
            sign_all_images=true
            shift 
            ;;
        --ips)
            IFS=',' read -r -a IPs <<< "$2"
            shift 2
            ;;
        --dtb)
            DTB="$2"
            shift 2
            ;;
#---------------------------------------------------------------------------------------------------------
# parameter for pass to Boardcp 
#---------------------------------------------------------------------------------------------------------
        --MLO_CRC)
            MLO_CRC="--MLO_CRC $2"
            shift 2
            ;;
        --MLO_Digest)
            MLO_Digest="--MLO_Digest $2"
            shift 2
            ;;
        --MLO_SPI_KEY)
            MLO_SPI_KEY="--MLO_SPI_KEY $2"
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


env -C $UBOOT make O=$UOUT clean
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to clean uboot ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully uboot is cleaned ${RESET}"
fi
env -C $UBOOT make O=${UOUT} -j$(nproc)  
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to compile uboot ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully uboot is compiled ${RESET}"
fi

env -C ${WORK} cp ${UOUT}/arch/arm/dts/${DTB}.dtb ${DTB}-pubkey.dtb
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to copy dtb ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully dtb is copid ${RESET}"
fi

if $sign_all_images; then
        env -C $WORK $UOUT/tools/mkimage  -f Image-Signed-Falcon.its -K ${DTB}-pubkey.dtb -T fdt_legacy -k keys -r SanCloud-Falcon-image.fit
   else     
        env -C $WORK $UOUT/tools/mkimage  -f Image-Unsigned-Falcon.its -K ${DTB}-pubkey.dtb -T fdt_legacy -k keys -r SanCloud-Falcon-image.fit
fi
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to sign image SanCloud-Falcon-image.fit ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully image SanCloud-Falcon-image.fit is signed ${RESET}"
fi

env -C $WORK $UOUT/tools/mkimage -f FalconArgGenerator.its -T fdt_legacy  -r SanCloud-FalconArgGenerator-image.fit
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to create image SanCloud-FalconArgGenerator-image.fit ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully image SanCloud-FalconArgGenerator-image.fit is signed ${RESET}"
fi

env -C $WORK fdtput -t s ${DTB}-pubkey.dtb /signature required-mode all
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to add signature's required-mode to dtb ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully add signature required-mode to dtb ${RESET}"
fi



env -C $UBOOT make O=${UOUT} EXT_DTB=${WORK}/${DTB}-pubkey.dtb -j$(nproc)  
#env -C $UBOOT make O=${UOUT} DEVICE_TREE=${WORK}/${DTB}-pubkey -j$(nproc)   
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to compile uboot ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully uboot is compiled ${RESET}"
fi

if [ ${#IPs[@]} -gt 0 ]; then
        for IP in "${IPs[@]}"; do
            # Check if the IP is reachable
            if ping -c 1 -W 1 "$IP" &> /dev/null; then
              echo -e "${Red}call Boardcp.sh --IP $IP $MLO_CRC $MLO_Digest $MLO_SPI_KEY $PASSWORD $ADDITIONAL_FILES --IP $IP  ${RESET}" 
               $WORK/Boardcp.sh $MLO_CRC $MLO_Digest $MLO_SPI_KEY $PASSWORD $ADDITIONAL_FILES "--IP" $IP   &
            else
                 echo -e "${Red}device $IP does not exist. ${RESET}"
            fi
        
            done  
        wait
fi