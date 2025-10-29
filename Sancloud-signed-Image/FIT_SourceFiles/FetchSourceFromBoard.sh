#!/bin/bash
Black="\033[0;30m"
Red="\033[0;31m"
Green="\033[0;32m"
Yellow="\033[0;33m"
Blue="\033[0;34m"
Magenta="\033[0;35m"
Cyan="\033[0;36m"
White="\033[0;37m"
RESET="\033[0m"


PASSWORD="temppwd"
IPLIST=${BOARDS_IPS}
IPS=()
IFS=',' read -r -a IPs <<<"$IPLIST"
IP=${IPs[0]}
if [[ $IP =~ ^(([0-9]{1,3}\.){3}[0-9]{1,3})([Pp])?$ ]]; then
		IP="${BASH_REMATCH[1]}"
		PLAIN_ACCESS="${BASH_REMATCH[3]:-}"
else
	echo "Invalid IP format: $1" >&2
	exit 1
fi

while [[ $# -gt 0 ]]; do
	case $1 in
	--IP)
		IP=$2
		shift 2
		;;
	--PASSWORD)
		PASSWORD="--PASSWORD $2"
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
IP="debian@"${IP}
echo -e "${Blue}Fetch source from board ${RESET}"
echo -e "${Blue}IP: ${IP} ${RESET}"
REMOTE_KERNEL=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no "${IP}" "uname -r")

FILES=(
	"/boot/firmware/ti/k3-am625-sancloud.dtb"
	"/boot/initrd.img-$REMOTE_KERNEL"
	"/boot/vmlinuz-$REMOTE_KERNEL"
)

ODIR="$(dirname "$0")/$REMOTE_KERNEL/"
mkdir -p $ODIR

for FILE in "${FILES[@]}"; do
	echo -e "${Blue} Copy $FILE ${RESET}"
	sshpass -p "$PASSWORD" scp  "${IP}:$FILE" "$ODIR"
	if [ $? -ne 0 ]; then
		echo -e "${Red}Failed to copy $FILE ${RESET}"
		exit -1
	else
		echo -e "${Green}Successfully copied $FILE${RESET}"
	fi
done

