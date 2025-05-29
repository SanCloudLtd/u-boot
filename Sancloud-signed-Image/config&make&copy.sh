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
#"10.0.0.225"
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
ALLYESNO=""
#---------------------------------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case $1 in
        --ips)
            IFS=',' read -r -a IPs <<< "$2"
            shift 2
            ;;
        -Y)
            ALLYESNO="Y"
            shift 1
            ;;    
        -N)
            ALLYESNO="N"
            shift 1
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

#********************************************************************************************************************
#                Configurng R5 and R5 FALLBACK
#********************************************************************************************************************
echo -e "${Red}**********************${RESET}"
echo -e "${Red}*** Configuring R5 ***${RESET}"
echo -e "${Red}**********************${RESET}"
if [[ -z "$ALLYESNO" ]] ;then
  read -p "Do you want to config ? (y/n): " answer
else
  answer=$ALLYESNO
  if [ "$answer" != "${answer#[Yy]}" ] ;then
  sleep 2
  fi
fi
if [ "$answer" != "${answer#[Yy]}" ] ;then
    env -C $UBOOT make CROSS_COMPILE=arm-none-linux-gnueabihf-  O=$UOUT/r5/BOOT menuconfig
    if [ $? -ne 0 ]; then
        echo -e "${Red}Unable to config r5 ${RESET}"
        exit 1
    else
        echo -e "${Green}R5 has configured Successfully ${RESET}"
    fi
fi

echo -e "${Red}*******************************${RESET}"
echo -e "${Red}*** Configuring R5 FALLBACK ***${RESET}"
echo -e "${Red}*******************************${RESET}"
if [[ -z "$ALLYESNO" ]] ;then
  read -p "Do you want to config ? (y/n): " answer
else
    answer=$ALLYESNO
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        sleep 2
    fi
fi
if [ "$answer" != "${answer#[Yy]}" ] ;then
    env -C $UBOOT make CROSS_COMPILE=arm-none-linux-gnueabihf-  O=$UOUT/r5/FALLBACK menuconfig
    if [ $? -ne 0 ]; then
        echo -e "${Red}Unable to config r5 FALLBACK ${RESET}"
        exit 1
    else
        echo -e "${Green}R5 FALLBACK has configured Successfully ${RESET}"
    fi
fi
#********************************************************************************************************************
#                Configurng A53 and A53 FALLBACK
#********************************************************************************************************************
echo -e "${Red}***********************${RESET}"
echo -e "${Red}*** Configuring A53 ***${RESET}"
echo -e "${Red}***********************${RESET}"
if [[ -z "$ALLYESNO" ]] ;then
  read -p "Do you want to config ? (y/n): " answer
else
    answer=$ALLYESNO
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        sleep 2 
    fi
fi
if [ "$answer" != "${answer#[Yy]}" ] ;then
    env -C $UBOOT make O=$UOUT/a53/BOOT menuconfig
    if [ $? -ne 0 ]; then
        echo -e "${Red}Unable to config a53 ${RESET}"
        exit 1
    else
        echo -e "${Green}A53 has configured Successfully ${RESET}"
    fi
fi

echo -e "${Red}********************************${RESET}"
echo -e "${Red}*** Configuring A53 FALLBACK ***${RESET}"
echo -e "${Red}********************************${RESET}"
if [[ -z "$ALLYESNO" ]]; then
    read -p "Do you want to config ? (y/n): " answer
else
    answer=$ALLYESNO
    if [ "$answer" != "${answer#[Yy]}" ] ;then
        sleep 2
    fi
fi
if [ "$answer" != "${answer#[Yy]}" ] ;then
    env -C $UBOOT make O=$UOUT/a53/FALLBACK menuconfig
    if [ $? -ne 0 ]; then
        echo -e "${Red}Unable to config a53 FALLBACK ${RESET}"
        exit 1
    else
        echo -e "${Green}A53 FALLBACK has configured Successfully ${RESET}"
    fi
fi

#********************************************************************************************************************
#                Compiling R5 
#********************************************************************************************************************
if [[ -z "$ALLYESNO" ]]; then
    read -p "Do you want to clean and compile R5 ? (y/n): " answer
else
    answer=$ALLYESNO
fi
if [ "$answer" != "${answer#[Yy]}" ] ;then
    env -C $UBOOT make  CROSS_COMPILE=arm-none-linux-gnueabihf-  O=$UOUT/r5/BOOT clean
    if [ $? -ne 0 ]; then
            echo -e "${Red}Unable to clean r5 ${RESET}"
            exit 1
    else
            echo -e "${Green}Successfully r5 is cleaned ${RESET}"
    fi
fi

env -C $UBOOT make  CROSS_COMPILE=arm-none-linux-gnueabihf- BINMAN_INDIRS=$BINMAN_INDIRS  O=$UOUT/r5/BOOT -j$(nproc) #-B  
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to compile r5 ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully r5 is compiled ${RESET}"
fi
#********************************************************************************************************************
#                Compiling R5 FALLBACK
#********************************************************************************************************************
if [[ -z "$ALLYESNO" ]]; then
    read -p "Do you want to clean and compile R5 FALLBACK ? (y/n): " answer
else
    answer=$ALLYESNO
fi
if [ "$answer" != "${answer#[Yy]}" ] ;then
    env -C $UBOOT make  CROSS_COMPILE=arm-none-linux-gnueabihf-  O=$UOUT/r5/FALLBACK clean
    if [ $? -ne 0 ]; then
            echo -e "${Red}unable to clean r5 FALLBACK ${RESET}"
            exit 1
    else
            echo -e "${Green}Successfully r5 FALLBACK is cleaned ${RESET}"
    fi
fi

env -C $UBOOT make  CROSS_COMPILE=arm-none-linux-gnueabihf- BINMAN_INDIRS=$BINMAN_INDIRS  O=$UOUT/r5/FALLBACK -j$(nproc) #-B  
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to compile r5 FALLBACK ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully r5 FALLBACK is compiled ${RESET}"
fi
#********************************************************************************************************************
#                Compiling A53 
#********************************************************************************************************************
if [[ -z "$ALLYESNO" ]]; then
    read -p "Do you want to clean and compile A53 ? (y/n): " answer
else
    answer=$ALLYESNO
fi
if [ "$answer" != "${answer#[Yy]}" ] ;then
    env -C $UBOOT make O=$UOUT/a53/BOOT clean
    if [ $? -ne 0 ]; then
            echo -e "${Red}unable to clean a53 ${RESET}"
            exit 1
    else
            echo -e "${Green}Successfully a53 is cleaned ${RESET}"
    fi
fi

env -C $UBOOT make O=$UOUT/a53/BOOT  BINMAN_INDIRS=$BINMAN_INDIRS   -j$(nproc) #-B 
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to compile a53 ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully a53 is compiled ${RESET}"
fi

#********************************************************************************************************************
#                Compiling A53 FALLBACK
#********************************************************************************************************************
if [[ -z "$ALLYESNO" ]]; then
    read -p "Do you want to clean and compile A53 FALLBACK ? (y/n): " answer
else
    answer=$ALLYESNO
fi
if [ "$answer" != "${answer#[Yy]}" ] ;then
    env -C $UBOOT make O=$UOUT/a53/FALLBACK clean
    if [ $? -ne 0 ]; then
        echo -e "${Red}unable to clean a53 FALLBACK ${RESET}"
        exit 1
    else
        echo -e "${Green}Successfully a53 FALLBACK is cleaned ${RESET}"
    fi
fi    

env -C $UBOOT make O=$UOUT/a53/FALLBACK  BINMAN_INDIRS=$BINMAN_INDIRS   -j$(nproc) #-B 
if [ $? -ne 0 ]; then
        echo -e "${Red}unable to compile a53 FALLBACK ${RESET}"
        exit 1
else
        echo -e "${Green}Successfully a53 FALLBACK is compiled ${RESET}"
fi
#********************************************************************************************************************
#                Creating the unified images    
#********************************************************************************************************************
echo -e "${Blue}Generating Unified images ${RESET}"

IMGS=(BOOT
      FALLBACK)
SPLADDR=512 #512KB
UBOOTADDR=2560 #0x280000 2.5MB
IMGMAX=4 #4MB
echo SPLADDR=$SPLADDR UBOOTADDR=$UBOOTADDR
for IMG in "${IMGS[@]}"; do
    OFILE="$UOUT/SanCloud-$IMG.bin"
    dd if=/dev/zero of=$OFILE bs=1M count=$IMGMAX
    dd if=$UOUT/r5/$IMG/tiboot3-am62x-gp-evm.bin of=$OFILE conv=notrunc bs=1M 
    dd if=$UOUT/a53/$IMG/tispl.bin_unsigned of=$OFILE conv=notrunc bs=1k seek=$SPLADDR
    dd if=$UOUT/a53/$IMG/u-boot.img of=$OFILE bs=1k seek=$UBOOTADDR
done


#********************************************************************************************************************
#                Copying the images to the target device
#********************************************************************************************************************
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