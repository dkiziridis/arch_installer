#!/bin/bash

function select_disk
{
    readarray -t LINES < <(lsblk -d |  grep sd. | awk -F ' ' '{ print $1, $4 }' | sed 's/ /\t\t/g')
	if [[ 1 -eq "${#LINES[@]}" ]]; then
        _DISK=$(lsblk -d |  grep sd. | awk -F ' ' '{ print $1 }')
	else
		echo -ne "\nSelect a Disk and press [Enter] to rescan or [c] to Cancel\n\n"
		echo -ne "#)  <Disk>            <Size>\n"
		COUNTER=0
		for CHOICE in "${LINES[@]}"; do
            let COUNTER+=1
			_DISK=$(awk -F ' ' '{print $1}' <<< "$CHOICE" | sed 's/ /\t\t/g')
			_SIZE=$(awk -F ' ' '{print $2}' <<< "$CHOICE")
			printf "\n$COUNTER)   $_DISK $1             $_SIZE"
		done
		echo
		while read -rn2 -p $'\nSelect Disk : ' SEL
		do
			case $SEL in
				[1-$COUNTER] )
					let SEL-=1
                    _DISK=$(echo ${LINES[$SEL]} | awk -F ' ' '{ print $1 }' >> /dev/null)
                    select_part
					break
					;;
				[Cc] )
					break
					;;
				* )
					echo -ne "\nInvalid option"
					;;
			esac
		done
    fi
}

function install_system
{
    select_disk
    echo "WARNING! Using whole disk will DESTROY ALL DATA on the device."
    while read -rn2 -p $'\nUse whole Disk ? [ync]: ' YN
	do
		case $YN in
		[Yy] )
	    	parted /dev/$_DISK mklabel gpt
            echo y | parted -s -a optimal /dev/$_DISK mkpart primary 1MiB 100%
            echo y | mkfs.ext4 /dev/$_DISK"1"
            mount /dev/$_DISK"1" /mnt
            pacstrap /mnt base
            genfstab -U /mnt >> /mnt/etc/fstab
			break
			;;
		[Nn] )
			select_part
            echo y | mkfs.ext4 /dev/$_PART
            mount /dev/$_PART /mnt
            _ESP=$(parted /dev/$_DISK print | grep EFI | awk -F ' ' '{ print $1 }')
            mkdir /mnt/boot
            if [[ $_ESP -gt 0 ]]; then
                mount /dev/$_ESP /mnt/boot
            fi
            pacstrap /mnt base
            genfstab -U /mnt >> /mnt/etc/fstab
			break
			;;
		[Cc] )
			break
			;;
		* )
			echo -ne "\nInvalid option"
			;;
		esac
	done
}

function select_part
{
    readarray -t LINES < <(lsblk -l |  grep $_DISK | awk -F ' ' '{ print $1, $4 }' | sed 's/ /\t\t/g' | tail -n +2
)
	if [[ 1 -lt "${#LINES[@]}" ]]; then
        while read -rn1 -p $'\nOne partition found, confirm installation [yn]: ' YN
        do
            case $YN in
            [Yy] )
                _PART=$(lsblk -l |  grep $_DISK | awk -F ' ' '{ print $1 }' | sed 's/ /\t\t/g' | tail -n +2
)
                break
                ;;
            [Nn] )
                exit
                ;;
            *    )
                echo -ne "\nInvalid option"
                ;;
            esac
        done
	elif [[ 0 -eq "${#LINES[@]}" ]]; then
        echo "Disk is not partitioned, creating one (1) and installing Arch on it."
        echo y | parted /dev/$_DISK mklabel gpt
        echo y | parted -s -a optimal /dev/$_DISK mkpart primary 1MiB 100%
        echo y | mkfs.ext4 /dev/$_DISK"1"
        _PART=$(lsblk -l |  grep $_DISK | awk -F ' ' '{ print $1 }' | sed 's/ /\t\t/g' | tail -n +2
)
    else
		echo -ne "\nSelect a Partition and press Enter or press [Enter] to rescan or [c] to Cancel\n\n"
		echo -ne "#)  <Partition>            <Size>\n"
		COUNTER=0
		for CHOICE in "${LINES[@]}"; do
            let COUNTER+=1
			_DISK=$(awk -F ' ' '{print $1}' <<< "$CHOICE" | sed 's/ /\t\t/g')
			_SIZE=$(awk -F ' ' '{print $2}' <<< "$CHOICE")
			printf "\n$COUNTER)   $_DISK $1             $_SIZE"
		done
		echo
		while read -rn2 -p $'\nSelect partition : ' SEL
		do
			case $SEL in
				[1-$COUNTER] )
					let SEL-=1
                    _PART=$(echo ${LINES[$SEL]} | awk -F ' ' '{ print $1 }' >> /dev/null)
					break
					;;
				[Cc] )
					break
					;;
				* )
					echo -ne "\nInvalid option"
					;;
			esac
		done
    fi
}

function post_install
{
    curl termbin.com/aw8x -o root_install.sh && chmod u+x root_install.sh
    cp root_install.sh /mnt
    arch-chroot /mnt ./root_install.sh
}

# function detect_other_os
# {
#     echo "Probing for Windows installation..."
#     readarray -t LINES < <(parted -l /dev/sda | grep ntfs | grep msftdata)
#     if [[ 0 -eq "${#LINES[@]}" ]]; then
#         echo "Windows installation not found."
#     else

#     fi
# }

clear
install_system
post_install