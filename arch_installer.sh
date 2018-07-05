#!/bin/bash

select_disk() {
	readarray -t LINES < <(lsblk -d | grep sd. | awk -F ' ' '{ print $1, $4 }' | sed 's/ /\t\t/g')
	if [[ 1 -eq "${#LINES[@]}" ]]; then
		_DISK=$(lsblk -d | grep sd. | awk -F ' ' '{ print $1 }')
	else
		echo -ne "\nSelect a Disk and press [Enter] to rescan or [c] to Cancel\n\n"
		echo -ne "#)  <Disk>            <Size>\n"
		COUNTER=0
		for CHOICE in "${LINES[@]}"; do
			((COUNTER += 1))
			_DISK=$(awk -F ' ' '{print $1}' <<<"$CHOICE" | sed 's/ /\t\t/g')
			_SIZE=$(awk -F ' ' '{print $2}' <<<"$CHOICE")
			echo "\n$COUNTER)   $_DISK $1             $_SIZE"
		done
		echo
		while read -rn2 -p $'\nSelect Disk : ' SEL; do
			case $SEL in
			[1-$COUNTER])
				((SEL -= 1))
				_DISK=$(echo ${LINES[$SEL]} | awk -F ' ' '{ print $1 }' >>/dev/null)
				select_part
				break
				;;
			[Cc])
				break
				;;
			*)
				echo -ne "\nInvalid option"
				;;
			esac
		done
	fi
}

install_system() {
	select_disk
	echo "WARNING! Using whole disk will DESTROY ALL DATA on the device."
	while read -rn2 -p $'\nUse whole Disk ? [ync]: ' YN; do
		case $YN in
		[Yy])
			parted /dev/"$_DISK" mklabel gpt
			echo y | parted -s -a optimal /dev/"$_DISK" mkpart primary 1MiB 100%
			echo y | mkfs.ext4 /dev/"$_DISK""1"
			mount /dev/"$_DISK""1" /mnt
			pacstrap /mnt base
			genfstab -U /mnt >>/mnt/etc/fstab
			break
			;;
		[Nn])
			select_part
			echo y | mkfs.ext4 /dev/"$_PART"
			mount /dev/"$_PART" /mnt
			_ESP=$(parted /dev/"$_DISK" print | grep EFI | awk -F ' ' '{ print $1 }')
			mkdir /mnt/boot
			if [[ $_ESP -gt 0 ]]; then
				mount /dev/"$_ESP" /mnt/boot
			fi
			pacstrap /mnt base
			genfstab -U /mnt >>/mnt/etc/fstab
			break
			;;
		[Cc])
			break
			;;
		*)
			echo -ne "\nInvalid option"
			;;
		esac
	done
}

select_part() {
	readarray -t LINES < <(
		lsblk -l | grep "$_DISK" | awk -F ' ' '{ print $1, $4 }' | sed 's/ /\t\t/g' | tail -n +2
	)
	if [[ 1 -lt "${#LINES[@]}" ]]; then
		while read -rn1 -p $'\nOne partition found, confirm installation [yn]: ' YN; do
			case $YN in
			[Yy])
				_PART=$(lsblk -l | grep "$_DISK" | awk -F ' ' '{ print $1 }' | sed 's/ /\t\t/g' | tail -n +2)
				break
				;;
			[Nn])
				exit
				;;
			*)
				echo -ne "\\nInvalid option"
				;;
			esac
		done
	elif [[ 0 -eq "${#LINES[@]}" ]]; then
		echo "Disk is not partitioned, creating one (1) and installing Arch on it."
		echo y | parted /dev/"$_DISK" mklabel gpt
		echo y | parted -s -a optimal /dev/"$_DISK" mkpart primary 1MiB 100%
		echo y | mkfs.ext4 /dev/"$_DISK""1"
		_PART=$(lsblk -l | grep "$_DISK" | awk -F ' ' '{ print $1 }' | sed 's/ /\t\t/g' | tail -n +2)
	else
		echo -ne "\nSelect a Partition and press Enter or press [Enter] to rescan or [c] to Cancel\n\n"
		echo -ne "#)  <Partition>            <Size>\n"
		COUNTER=0
		for CHOICE in "${LINES[@]}"; do
			((COUNTER += 1))
			_DISK=$(awk -F ' ' '{print $1}' <<<"$CHOICE" | sed 's/ /\t\t/g')
			_SIZE=$(awk -F ' ' '{print $2}' <<<"$CHOICE")
			echo -ne "\n$COUNTER)   $_DISK $1             $_SIZE"
		done
		echo
		while read -rn2 -p $'\nSelect partition : ' SEL; do
			case $SEL in
			[1-$COUNTER])
				((SEL -= 1))
				_PART=$(echo ${LINES[$SEL]} | awk -F ' ' '{ print $1 }' >>/dev/null)
				break
				;;
			[Cc])
				break
				;;
			*)
				echo -ne "\nInvalid option"
				;;
			esac
		done
	fi
}

post_install() {
	curl termbin.com/aw8x -o root_install.sh && chmod u+x root_install.sh
	cp root_install.sh /mnt
	arch-chroot /mnt ./root_install.sh
}

configure() {
	echo "Setting localtime"
	ln -sf /usr/share/zoneinfo/Europe/Athens /etc/localtime
	echo "Generating /etc/adjtime"
	hwclock --systohc
	echo "Enabling el_GR locale"
	sed -i '/el_GR/s/^#//g' /etc/locale.gen
	echo "Enabling en_US locale"
	sed -i '/en_US/s/^#//g' /etc/locale.gen
	echo "Generating locales"
	locale-gen >>/dev/null
	echo "Set root password and press Enter"
	passwd
}

driver_installer() {
	echo "Detecting VGA..."
	VIDEO=$(lspci | grep -e VGA -e 3D | awk -F ' ' '{print $5}')
	if [[ $VIDEO == Intel ]]; then
		echo "Installing Drivers for Intel VGA..."
		pacman -S --noconfirm --needed xf86-video-intel mesa >>/dev/null
	elif [[ $VIDEO == NVIDIA ]]; then
		echo "Installing Drivers for $=NVIDIA VGA..."
		pacman -S --noconfirm --needed nvidia nvidia-utils >>/dev/null
	elif [[ $VIDEO == ATI ]]; then
		echo "Installing Drivers for AMD Legacy VGA..."
		pacman -S --noconfirm --needed xf86-video-ati mesa >>/dev/null
	elif [[ $VIDEO == Advanced ]]; then
		echo "Installing Drivers for AMD VGA..."
		pacman -S --noconfirm --needed xf86-video-amdgpu mesa >>/dev/null
	elif [[ $VIDEO == InnoTek ]]; then
		echo "Installing Drivers for VirtualBox Graphics..."
		pacman -S --noconfirm --needed virtualbox-guest-utils virtualbox-guest-modules-arch >>/dev/null
	else
		echo "Graphics Card could not be detected. Press [Enter] to continue."
		read -r
	fi
}

xorg_installer() {
	while read -rn1 -p $'\nInstall X server ? [yn]' ASK; do
		case "$ASK" in
		[Yy])
			echo "Installing Xorg"
			pacman -S --noconfirm --needed xorg-server xorg-xauth xf86-input-synaptics xorg-xinit xorg-iceauth xf86-video-fbdev >>/dev/null
			break
			;;
		[Nn])
			break
			;;
		*) ;;

		esac
	done
}

de_installer() {
	echo -ne "\n 1) GNOME \"Modern DE with lots of features.\"
			  \n 2) KDE Plasma \"Familiar working environment.\"
			  \n 3) Xfce \"Relatively lightweight and modular.\"
			  \n 4) Enlightenment \"Efficient, capable of performing on older hardware.\"
			  \n 5) LXDE \"Lightweight DE, fast and energy-saving.\"
			  \n 6) Cinnamon \"GNOME 2 fork\"
			  \n 7) Deepin \"Intuitive and elegant design.\"
			  \n 8) GNOME Flashback \"Similar to GNOME 2\"
			  \n 9) MATE \"GNOME 2 fork uses GTK+ 3\"
			  \n10) Budgie \"Focuses on simplicity and elegance.\"
			  \nQq) Skip DE install.
			  "

	while read -rn2 -p $'\nSelect : ' CHAR; do
		case "$CHAR" in
		1)
			echo "Installing GNOME 3"
			pacman -S --needed --noconfirm gnome >>/dev/null
			break
			;;
		2)
			echo "Installing KDE Plasma"
			pacman -S --needed --noconfirm plasma >>/dev/null
			break
			;;
		3)
			echo "Installing Xfce"
			pacman -S --needed --noconfirm xfce4 >>/dev/null
			break
			;;
		4)
			echo "Installing Enlightenment"
			pacman -S --needed --noconfirm enlightenment >>/dev/null
			break
			;;
		5)
			echo "Installing LXDE"
			pacman -S --needed --noconfirm lxde-gtk3 >>/dev/null
			break
			;;
		6)
			echo "Installing Cinnamon"
			pacman -S --needed --noconfirm cinnamon >>/dev/null
			break
			;;
		7)
			echo "Installing Deepin"
			pacman -S --needed --noconfirm deepin >>/dev/null=-
			break
			;;
		8)
			echo "Installing GNOME Flashback"
			pacman -S --needed --noconfirm gnome-flashback >>/dev/null
			break
			;;
		9)
			echo "Installing MATE"
			pacman -S --needed --noconfirm mate >>/dev/null
			break
			;;
		10)
			echo "Installing Budgie"
			pacman -S --needed --noconfirm budgie-desktop >>/dev/null
			break
			;;
		[Qq])
			break
			;;
		*) ;;

		esac
	done
}

util_installer() {
	echo "Installing utilities"
	pacman -S --noconfirm --needed sudo git parted grub
}

grub_install() {

	if [[ 0 -eq $(parted /dev/sda print | grep EFI >>/dev/null) ]]; then
		echo "Installing GRUB for UEFI systems"
		grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB >>/dev/null
		echo "Generating GRUB configuration"
		grub-mkconfig -o /boot/grub/grub.cfg >>/dev/null
	else
		echo "Installing GRUB for BIOS systems"
		grub-install --target=i386-pc /dev/"$_DISK" >>/dev/null
		echo "Generating GRUB configuration"
		grub-mkconfig -o /boot/grub/grub.cfg >>/dev/null
	fi
}

user_creation() {
	echo "Creating user"
	read -rp "Enter username : " username
	useradd -m -G wheel -s /bin/bash "$username"
	echo "Enter password for $username : "
	passwd "$username"
}

network_conf() {
	read -rp $'\nEnter a hostname and press enter. : ' hostname
	echo "$hostname" >>/etc/hostname >>/dev/null
	pacman -S --noconfirm --needed networkmanager dialog
	sudo systemctl enable NetworkManager.service >>/dev/null
}

conf_files_root() {
	echo "Modifying sudoers file"
	sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
	echo "Enabling Multilib..."
	sed -i '93s/#\[multilib\]/\[multilib\]/g' /etc/pacman.conf
	sed -i '94s/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/g' /etc/pacman.conf
	echo "Updating repositories..."
	pacman -Syu --noconfirm
}

additional_software() {
	echo "Installing essential software..."
	pacman -S --noconfirm --needed wget curl git sudo perl tar base-devel alsa-utils
	echo "Installing utilities, this will take a while..."
	pacman -S --noconfirm --needed dstat fdupes gftp speedtest-cli smartmontools tigervnc usbutils x11vnc openssh gvim htop mlocate qbittorrent smbnetfs bleachbit blueman moc mtr pkgstats
}

configure_mirros() {
	echo

}

pacaur_installer() {
	echo "Installing Git"
	sudo pacman -S --noconfirm --needed git >>/dev/null
	echo "Signing key 1EB2638FF56C0C53"
	gpg --recv-keys --keyserver hkp://pgp.mit.edu 1EB2638FF56C0C53 >>/dev/null
	echo "Signing key F54984BFA16C640F"
	gpg --recv-keys --keyserver hkp://pgp.mit.edu F54984BFA16C640F >>/dev/null
	echo "Installing cower-git"
	wget https://aur.archlinux.org/cgit/aur.git/snapshot/cower.tar.gz >>/dev/null
	tar -zxvf cower.tar.gz >>/dev/null
	cd cower
	makepkg --needed --noconfirm -si >>/dev/null
	cd ..
	echo "Installing pacaur"
	wget https://aur.archlinux.org/cgit/aur.git/snapshot/pacaur.tar.gz >>/dev/null
	tar -zxvf pacaur.tar.gz >>/dev/null
	cd pacaur
	makepkg --needed --noconfirm -si >>/dev/null
	cd ..
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


clear
cd ~
configure
user_creation
driver_installer
util_installer
network_conf
grub_install
xorg_installer
de_installer
additional_software


pacaur_installer