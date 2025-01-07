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

echo $UOUT/u-boot-dtb.img


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

env -C ${WORK} cp ${UOUT}/arch/arm/dts/am335x-sancloud-bbe-lite.dtb am335x-sancloud-bbe-lite-pubkey.dtb
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to copy dtb ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully dtb is copid ${RESET}"
fi

#env -C $WORK $UOUT/tools/mkimage  -f signFalcom.its -K $UOUT/spl/dts/dt-spl.dtb -T fdt_legacy -k keys -r SanCloud-Falcon-image.fit
env -C $WORK $UOUT/tools/mkimage  -f signFalcom.its -K am335x-sancloud-bbe-lite-pubkey.dtb -T fdt_legacy -k keys -r SanCloud-Falcon-image.fit
#env -C $WORK $UOUT/tools/mkimage  -f NotSignFalcom.its -K am335x-sancloud-bbe-lite-pubkey.dtb -T fdt_legacy -k keys -r SanCloud-Falcon-image.fit
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to sign image SanCloud-Falcon-image.fit ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully image SanCloud-Falcon-image.fit is signed ${RESET}"
fi

env -C $WORK $UOUT/tools/mkimage -f NotSigned.its -T fdt_legacy  -r SanCloud-Not-signed-image.fit
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to create image SanCloud-Not-signed-image.fit ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully image SanCloud-Not-signed-image.fit is signed ${RESET}"
fi

env -C $WORK fdtput -t s am335x-sancloud-bbe-lite-pubkey.dtb /signature required-mode all
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to add signature's required-mode to dtb ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully add signature required-mode to dtb ${RESET}"
fi

env -C $WORK fdtput -t s am335x-sancloud-bbe-lite-pubkey.dtb /signature/key-dev "required" "conf"
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to add signature key-dev's required to dtb ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully add signature key-dev's required to dtb ${RESET}"
fi


env -C ${WORK} cp am335x-sancloud-bbe-lite-pubkey.dtb ${UOUT}/arch/arm/dts/ 
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to copy dtb pubkey ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully dtb pubkey is copid ${RESET}"
fi


#env -C $UBOOT make O=${UOUT} EXT_DTB=${WORK}/am335x-sancloud-bbe-lite-pubkey.dtb -j$(nproc)  
env -C $UBOOT make O=${UOUT} DEVICE_TREE=am335x-sancloud-bbe-lite-pubkey -j$(nproc)   
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to compile uboot ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully uboot is compiled ${RESET}"
fi


IPs=(
#"82.5.144.219"
"10.0.0.246"
"10.0.0.222"
    )  

for IP in "${IPs[@]}"; do
    # Check if the IP is reachable
    if ping -c 1 -W 1 "$IP" &> /dev/null; then
       env ADDITIONAL_FILES="$WORK/SanCloud-Not-signed-image.fit $WORK/SanCloud-Falcon-image.fit" $UBOOT/b/Boardcp.sh $IP &
    else
         echo -e "${Red}device $IP does not exist. ${RESET}"
    fi
 
    done  
wait