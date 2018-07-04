#!/bin/bash

function configure
{
	echo "Setting localtime"
	ln -sf /usr/share/zoneinfo/Europe/Athens /etc/localtime
	echo "Generating /etc/adjtime"
	hwclock --systohc
	echo "Enabling el_GR locale"
	sed -i '/el_GR/s/^#//g' /etc/locale.gen
	echo "Enabling en_US locale"
	sed -i '/en_US/s/^#//g' /etc/locale.gen
	echo "Generating locales"
	locale-gen >> /dev/null
	echo "Set root password and press Enter"
	passwd
}

function driver_installer 
{
	echo "Detecting VGA..."
	VIDEO=$(lspci | grep -e VGA -e 3D | awk -F ' ' '{print $5}')
	if [[ $VIDEO = Intel ]]; then
		echo "Installing Drivers for Intel VGA..."
		pacman -S --noconfirm --needed xf86-video-intel	mesa >> /dev/null
	elif [[ $VIDEO = NVIDIA ]]; then
		echo "Installing Drivers for $=NVIDIA VGA..."
		pacman -S --noconfirm --needed nvidia nvidia-utils >> /dev/null
	elif [[ $VIDEO = ATI ]]; then
		echo "Installing Drivers for AMD Legacy VGA..."
		pacman -S --noconfirm --needed xf86-video-ati mesa >> /dev/null
	elif [[ $VIDEO = Advanced ]]; then
		echo "Installing Drivers for AMD VGA..."
		pacman -S --noconfirm --needed xf86-video-amdgpu mesa >> /dev/null
	elif [[ $VIDEO = InnoTek ]]; then
		echo "Installing Drivers for VirtualBox Graphics..."
		pacman -S --noconfirm --needed virtualbox-guest-utils virtualbox-guest-modules-arch >> /dev/null
	else
		echo "Graphics Card could not be detected. Script cannot run."
		exit 1
	fi
}

function xorg_installer
{
	while read -rn1 -p $'\nInstall X server ? [yn]' ASK
    do
    	case "$ASK" in
        	[Yy] )
            	echo "Installing Xorg"
				pacman -S --noconfirm --needed xorg-server xorg-xauth xf86-input-synaptics xorg-xinit xorg-iceauth xf86-video-fbdev >> /dev/null
                break
                ;;
		    [Nn] )
        		break
                ;;
            * )
        		;;
    	esac
	done
}

function de_installer
{
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

	while read -rn2 -p $'\nSelect : ' CHAR
	do
	    case "$CHAR" in
	        1 )
				echo "Installing GNOME 3"
	            pacman -S --needed --noconfirm gnome >> /dev/null
	            break
	            ;;
	        2 )
				echo "Installing KDE Plasma"
	            pacman -S --needed --noconfirm plasma >> /dev/null
	            break
	            ;;
	        3 )
	            echo "Installing Xfce"
				pacman -S --needed --noconfirm xfce4 >> /dev/null
	            break
	            ;;
	        4 )
				echo "Installing Enlightenment"
	            pacman -S --needed --noconfirm enlightenment >> /dev/null
	            break
	            ;;
	        5 )
	            echo "Installing LXDE"
	            pacman -S --needed --noconfirm lxde-gtk3 >> /dev/null
	            break
	            ;;
	        6 )
	            echo "Installing Cinnamon"
	            pacman -S --needed --noconfirm cinnamon >> /dev/null
	            break
	            ;;
	        7 )
	            echo "Installing Deepin"
	            pacman -S --needed --noconfirm deepin >> /dev/null=-
	            break
	            ;;
	        8 )
	            echo "Installing GNOME Flashback"
	            pacman -S --needed --noconfirm gnome-flashback >> /dev/null
	            break
	            ;;
	        9 )
	            echo "Installing MATE"
	            pacman -S --needed --noconfirm mate >> /dev/null
	            break
	            ;;
	        10 )
	            echo "Installing Budgie"
	            pacman -S --needed --noconfirm budgie-desktop >> /dev/null
	            break
	            ;;
	        [Qq] )
				break
	            ;;
	        * 	 )
	            ;;
	    esac
	done
}

function util_installer
{
	echo "Installing sudo"
	pacman -S --noconfirm --needed sudo git parted grub
}

function grub_install
{
    parted /dev/sda print | grep EFI >> /dev/null
    if [[ 0 -eq $? ]]; then
        echo "Installing GRUB for UEFI systems"
        grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB >> /dev/null
        echo "Generating GRUB configuration"
        grub-mkconfig -o /boot/grub/grub.cfg >> /dev/null
    else
        echo "Installing GRUB for BIOS systems"
        grub-install --target=i386-pc /dev/$_DISK >> /dev/null
        echo "Generating GRUB configuration"
        grub-mkconfig -o /boot/grub/grub.cfg >> /dev/null
    fi
}

function user_creation 
{
	echo "Creating user"
	read -p "Enter username : " username
	useradd -m -G wheel -s /bin/bash $username
	echo "Enter password for $username : "
	passwd $username
}

function network_conf
{
	read -rp $'\nEnter a hostname and press enter. : ' hostname
	echo $hostname >> /etc/hostname >> /dev/null
	pacman -S --noconfirm --needed networkmanager dialog
	sudo systemctl enable NetworkManager.service >> /dev/null
}

clear
cd

configure
user_creation
driver_installer
util_installer
network_conf
grub_install
xorg_installer
de_installer