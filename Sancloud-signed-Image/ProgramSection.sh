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



IP_ADDRESS=""
PLAIN_ACCESS=0
PASSWORD="temppwd"
KEY=""

CRC="010101"
Digest="0  --high-verbose"

while [[ $# -gt 0 ]]; do
    case $1 in
        --KEY)
            KEY="$2"
            shift 2
            ;;

        --SECTION)
            SECTION="$2"
            shift 2
            ;;
        --DIE)
            DIE="$2"
            shift 2
            ;; 
        --Ver)
            Ver="$2"
            shift 2
            ;;       

        --PASSWORD)
            PASSWORD="$2"
            shift 2
            ;;
        --IP)
			shift
			if [[ $1 =~ ^(([0-9]{1,3}\.){3}[0-9]{1,3})([Pp])?$ ]]; then
				IP_ADDRESS="${BASH_REMATCH[1]}"
				if [[ -n "${BASH_REMATCH[3]}" ]]; then
				PLAIN_ACCESS=1
				fi
			else
				echo "Invalid IP format: $1" >&2
				exit 1
			fi
			shift
			;;
        --FILE)
            FILE="$2"
            shift 2
            ;;

        --FSIZE)
            FSIZE="-S $2"
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
echo -e "${Blue}KEY : $KEY ${RESET}"

if [ -n "$KEY" ]; then
	log_output=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   env -C ~/winbond-lib/build/  ./TESTAPP -u $FILE -s ${SECTION} -D ${DIE} -k ${KEY} -v ${Ver} --fk $FSIZE -C $CRC -d $Digest ")
	## Check for version update in the output
	NVer=$(echo "$log_output" | grep "old version=" | awk -F'=' '{print $2}')
	if [[ -n "$NVer" ]]; then
		Ver=$NVer
		echo -e "${Blue}Updated Version to: $Ver ${RESET}"
		log_output=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   env -C ~/winbond-lib/build/  ./TESTAPP -u $FILE -s ${SECTION} -D ${DIE} -k ${KEY} -v ${Ver} --fk $FSIZE -C $CRC -d $Digest ")
	fi

   # Extract the calculated digest using grep and awk
   CRC=$(echo "$log_output" | grep "Calculated CRC=" | awk -F'=' '{print $2}')
    # Check if the digest was extracted
    if [[ -n "$CRC" ]]; then
        echo -e "${Blue}Extracted CRC: $CRC ${RESET}"
        
        # Use the extracted digest in another command
        log_output=$(sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   env -C ~/winbond-lib/build/  ./TESTAPP -u $FILE -s ${SECTION} -D ${DIE} -k ${KEY} -v ${Ver} --fk $FSIZE -C $CRC -d $Digest ")
        Digest=$(echo "$log_output" | grep "Calculated Digest=" | awk -F'=' '{print $2}')
        # Check if the digest was extracted
        if [[ -n "$Digest" ]]; then
            echo -e "${Blue}Extracted Digest: $Digest ${RESET}"
            # Use the extracted digest in another command
            sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   env -C ~/winbond-lib/build/  ./TESTAPP -u $FILE -s ${SECTION} -D ${DIE} -k ${KEY} -v ${Ver} --fk $FSIZE -C $CRC -d $Digest "
        else
            echo -e "${Red}Error: Could not extract digest.${RESET}"
            echo -e "$log_output"
        fi

    else
        echo -e "${Red}Error: Could not extract CRC. ${RESET}"
        echo -e "$log_output"
    fi
else
#run non secure
     sshpass -p "$PASSWORD" ssh -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null "debian@${IP_ADDRESS}" "echo \"$PASSWORD\" | sudo -S -p ''   env -C ~/winbond-lib/build/  ./TESTAPP -w -p -s ${SECTION} -D ${DIE} -f $FILE"
fi