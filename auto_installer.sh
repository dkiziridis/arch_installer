#!/bin/bash

function oh-my-zsh_installer {
	echo "Installing Oh-My-Zsh framework"
	sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)" >> /dev/null
}
function driver_installer {
	echo "Detecting VGA..."
	VIDEO=$(lspci | grep -e VGA -e 3D | awk -F ' ' '{print $5}')
	if [[ $VIDEO = Intel ]]; then
		echo "Installing Drivers for $VIDEO..."
		pacman -S --noconfirm --needed xf86-video-intel	mesa >> /dev/null
	elif [[ $VIDEO = $VIDEO ]]; then
		echo "Installing Drivers for $VIDEO..."
		pacman -S --noconfirm --needed nvidia	nvidia-utils >> /dev/null
	elif [[ $VIDEO = ATI ]]; then
		echo "Installing Drivers for $VIDEO..."
		pacman -S --noconfirm --needed xf86-video-ati mesa >> /dev/null
	elif [[ $VIDEO = Advanced ]]; then
		echo "Installing Drivers for AMD..."
		pacman -S --noconfirm --needed xf86-video-amdgpu mesa >> /dev/null
	elif [[ $VIDEO = InnoTek ]]; then
		echo "Installing Drivers for VirtualBox Graphics..."
		pacman -S --noconfirm --needed virtualbox-guest-utils virtualbox-guest-modules-arch >> /dev/null
	else
		echo "Graphics Card could not be detected, consult Jim for further instructions..."
		exit 1
	fi
	
	echo "Installing Xorg"
	pacman -S --noconfirm --needed xorg-server xorg-xauth xf86-input-synaptics xorg-xinit xorg-iceauth xf86-video-fbdev >> /dev/null
	echo "Installing Desktop Environment"
	pacman -S --needed --noconfirm xfce4 xfce4-appfinder xfce4-power-manager xfce4-session xfce4-settings xfce4-weather-plugin xfce4-xkb-plugin pcmanfm >> /dev/null
}
function conf_files_root {
	echo "Modifying sudoers file"
	sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
	echo "Creating empty .zhsrc file"
	echo " " > /home/$username/.zshrc
	chown $username:$username /home/$username/.zshrc
	echo "Enabling Multilib..."
	sed -i '93s/#\[multilib\]/\[multilib\]/g' /etc/pacman.conf
	sed -i '94s/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/g' /etc/pacman.conf
	echo "Updating repositories..."
	pacman -Syu --noconfirm >> /dev/null
}
function user_creation {
	echo "Creating user."
	read -p "Enter username : " username
	useradd -m -G wheel -s /bin/zsh $username
	echo "Enter password for $username : "
	passwd $username
}
function root_software {
	echo "Installing Zsh"
	pacman -S --noconfirm --needed zsh >> /dev/null
	echo "Installing essential software..."
	pacman -S --noconfirm --needed wget curl git sudo perl tar base-devel alsa-utils >> /dev/null
	echo "Installing utilities, this will take a while..."
	pacman -S --noconfirm --needed android-file-transfer arc-icon-theme bleachbit blueman moc mtr nomacs pkgstats >> /dev/null
	pacman -S --noconfirm --needed breeze-icons cheese cmatrix deadbeef dstat epdfview fdupes gftp gnome-maps >> /dev/null
	pacman -S --noconfirm --needed speedtest-cli smartmontools subdl terminus-font tigervnc >> /dev/null
	pacman -S --noconfirm --needed usbutils volumeicon watchdog weechat x11vnc wget openssh gvim dialog networkmanager >> /dev/null
	pacman -S --noconfirm --needed gparted gvim htop minitube mlocate qbittorrent smbnetfs smplayer >> /dev/null
}
function conf_files_nonroot {
	echo "Generating xinit file"
	rm -f /home/$username/.xinitrc
	echo "#!/bin/sh
#
# ~/.xinitrc
#
# Executed by startx (run your window manager from here)

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/*; do
    [ -x \"$f\" ] && . \"$f\"
  done
  unset f
fi

#----XFCE4
exec startxfce4
" > /home/$username/.xinitrc
chown $username:$username /home/$username/.xinitrc
}
function nonroot_software {
	echo "Signing key 1EB2638FF56C0C53"
	gpg --recv-keys --keyserver hkp://pgp.mit.edu 1EB2638FF56C0C53 >> /dev/null
	echo "Signing key F54984BFA16C640F"
	gpg --recv-keys --keyserver hkp://pgp.mit.edu F54984BFA16C640F >> /dev/null
	echo "Installing cower-git"
	wget https://aur.archlinux.org/cgit/aur.git/snapshot/cower.tar.gz >> /dev/null
	tar -zxvf cower.tar.gz >> /dev/null
	cd cower
	makepkg --needed --noconfirm -si >> /dev/null
	cd ..
	echo "Installing pacaur"
	wget https://aur.archlinux.org/cgit/aur.git/snapshot/pacaur.tar.gz >> /dev/null
	tar -zxvf pacaur.tar.gz >> /dev/null
	cd pacaur
	makepkg --needed --noconfirm -si >> /dev/null
	cd ..
	echo "Installing additional software, this will take a while..."
	pacaur -S --noconfirm --needed --noedit xfce-theme-blackbird xfce-theme-greybird agetpkg-git coolreader3-git dupeguru-me dupeguru-pe dupeguru-se mmv palemoon-bin skype sublime-text teamviewer translate-shell winusb-git discus >> /dev/null
}
function services {
	echo "Enabling services"
	sudo systemctl enable NetworkManager.service >> /dev/null
}
#function clean_up {read -p "Clean up files ? [yn] " yn if [[ $yn = y ]]; then	#TODO fi}
if [[ "$EUID" -eq 0 ]]; then
	if ping -q -c 1 -W 1 www.google.com > /dev/null; then
		cd ~
  		user_creation
  		driver_installer
  		root_software
  		conf_files_root
  		cd /home/$username
  		SCRIPT="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
  		cp /root/$SCRIPT /home/$username
  		chmod u+x /home/$username/$SCRIPT
  		chown $username:$username /home/$username/$SCRIPT
  		echo "Reboot, log in to your new account and rerun the script. It was be coppied to your home folder. Just run \"./$SCRIPT\""
  		read -p "Reboot now ? [yn] : " answer
  		if [[ $answer = y ]];then
  			reboot
  		else
  			exit 0
  		fi
	else
  		echo "Connect to WiFi using \"wifi-menu\" and rerun the script. Fuk u bic."
		exit 1
	fi
else
	if ping -q -c 1 -W 1 www.google.com > /dev/null; then
		cd ~
  		nonroot_software
  		conf_files_nonroot
  		services
  		oh-my-zsh_installer
	else
  		echo "Connect to WiFi using \"sudo wifi-menu\" and rerun the script. Fuk u bic."
		exit 1
	fi
fi