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

IPLIST=${BOARDS_IPS}
IPS=()
IFS=',' read -r -a IPs <<<"$IPLIST"
#---------------------------------------------------------------------------------------------------------
# parameter for pass to Boardcp
#---------------------------------------------------------------------------------------------------------
ADDITIONAL_FILES="" #"--ADDITIONAL_FILES $WORK/SanCloud-FalconArgGenerator-image.fit,$WORK/SanCloud-Falcon-image.fit"
ALLYESNO=""
PASSWORD=${PASSWORD:-"temppwd"}
S0_KEY=${S0_KEY:-"2365974234,3466640016,4186352255,3105254121"}
S7_KEY=${S7_KEY:-"3398150088,1878052703,4211812016,2500719804"}

 
#---------------------------------------------------------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case $1 in
        --IPs)
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
        --ADDITIONAL_FILES)
            ADDITIONAL_FILES="--ADDITIONAL_FILES $2"  # keep as a single string
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
        --NO_CHIP)
            NO_CHIP="--NO_CHIP"
            shift 1
            ;;
        --NO_EMMC)
            NO_EMMC="--NO_EMMC"
            shift 1
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
#                preparing parameters
#********************************************************************************************************************
S0_KEY="--S0_KEY $S0_KEY"
S7_KEY="--S7_KEY $S7_KEY"
if [ -n "$PASSWORD" ]; then
	PASSWORD="--PASSWORD $PASSWORD"
fi	
#********************************************************************************************************************
#                Defconfig if not found
#********************************************************************************************************************
if [ ! -f $UOUT/r5/BOOT/.config ]; then
   env -C $UBOOT make CROSS_COMPILE=arm-none-linux-gnueabihf-  O=$UOUT/r5/BOOT  am62x_sancloud_spi_r5_boot_defconfig
fi
if [ ! -f $UOUT/r5/FALLBACK/.config ]; then
   env -C $UBOOT make CROSS_COMPILE=arm-none-linux-gnueabihf-  O=$UOUT/r5/FALLBACK  am62x_sancloud_spi_r5_fallback_defconfig
fi

if [ ! -f $UOUT/a53/BOOT/.config ]; then
    env -C $UBOOT make  CROSS_COMPILE=arm-none-linux-gnueabihf-  O=$UOUT/a53/BOOT am62x_sancloud_spi_a53_boot_defconfig
fi

if [ ! -f $UOUT/a53/FALLBACK/.config ]; then
   env -C $UBOOT make  CROSS_COMPILE=arm-none-linux-gnueabihf-  O=$UOUT/a53/FALLBACK am62x_sancloud_spi_a53_fallback_defconfig
fi   

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
CPUS=(gp
      hs-fs
      hs)      
SPLADDR=512 #512KB
UBOOTADDR=2560 #0x280000 2.5MB
IMGMAX=4 #4MB
echo SPLADDR=$SPLADDR UBOOTADDR=$UBOOTADDR
for IMG in "${IMGS[@]}"; do
   for CPU in "${CPUS[@]}"; do
    if [ "$CPU" == "gp" ]; then
      UNSIGNEG="_unsigned"
    else
      UNSIGNEG="" 
    fi
    OFILE="$UOUT/SanCloud-$IMG-$CPU.bin"
    dd if=/dev/zero of=$OFILE bs=1M count=$IMGMAX
    dd if=$UOUT/r5/$IMG/tiboot3-am62x-$CPU-evm.bin of=$OFILE conv=notrunc bs=1M 
    dd if=$UOUT/a53/$IMG/tispl.bin$UNSIGNEG of=$OFILE conv=notrunc bs=1k seek=$SPLADDR
    dd if=$UOUT/a53/$IMG/u-boot.img$UNSIGNEG of=$OFILE bs=1k seek=$UBOOTADDR
   done  
done


#********************************************************************************************************************
#                Copying the images to the target device
#********************************************************************************************************************


if [ ${#IPs[@]} -gt 0 ]; then
	for IP in "${IPs[@]}"; do
		PLAIN_ACCESS=""
		if [[ $IP =~ ^(([0-9]{1,3}\.){3}[0-9]{1,3})([Pp])?$ ]]; then
			IP="${BASH_REMATCH[1]}"
			PLAIN_ACCESS="${BASH_REMATCH[3]:-}"
		else
			echo "Invalid IP format: $1" >&2
			exit 1
		fi
        # Check if the IP is reachable
        if ping -c 1 -W 1 "$IP" &> /dev/null; then
			KEYS="$S7_KEY $S0_KEY"
			if [[ -n "$PLAIN_ACCESS" ]]; then
				KEYS="";	
			fi
        	$WORK/Boardcp.sh $PASSWORD $ADDITIONAL_FILES "--IP" $IP $PASSWORD $KEYS  $NO_CHIP  $NO_EMMC  &
        else
            echo -e "${Red}device $IP does not exist. ${RESET}"
        fi
    done  
    wait
fi