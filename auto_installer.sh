#!/bin/bash

function oh-my-zsh_installer {
	echo "Installing Oh-My-Zsh framework"
	sleep 2
	sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
}
function driver_installer {
	echo "Installing Xorg and Video Drivers..."
	echo "Detecting VGA..."
	sleep 2
	VIDEO=$(lspci | grep -e VGA -e 3D | awk -F ' ' '{print $5}')
	if [[ $VIDEO = Intel ]]; then
		echo "Installing Drivers for $VIDEO..."
		sleep 2
		pacman -S --noconfirm --needed xf86-video-intel	mesa
	elif [[ $VIDEO = ATI ]]; then
		echo "Installing Drivers for $VIDEO..."
		sleep 2
		pacman -S --noconfirm --needed xf86-video-ati mesa
	elif [[ $VIDEO = Advanced ]]; then
		echo "Installing Drivers for AMD..."
		sleep 2
		pacman -S --noconfirm --needed xf86-video-amdgpu
	elif [[ $VIDEO = InnoTek ]]; then
		echo "Installing Drivers for VirtualBox Graphics..."
		sleep 2
		pacman -S --noconfirm --needed virtualbox-guest-utils virtualbox-guest-modules-arch
	else
		clear
		echo "Graphics Card could not be detected, consult Jim for further instructions..."
		exit 1
	fi
	
	echo "Installing Xorg"
	sleep 2
	pacman -S --noconfirm --needed xorg-server xorg-xauth xf86-input-synaptics xorg-xinit xorg-iceauth xf86-video-fbdev
	echo "Installing Desktop Environment"
	sleep 2
	pacman -S --needed --noconfirm xfce4 xfce4-appfinder xfce4-power-manager xfce4-session xfce4-settings xfce4-weather-plugin xfce4-xkb-plugin pcmanfm
}
function conf_files_root {
	echo "Modifying sudoers file"
	sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers
	sleep 2
	echo "Creating empty .zhsrc file"
	echo " " > /home/$username/.zshrc
	chown $username:$username /home/$username/.zshrc
	echo "Enabling Multilib..."
	sleep 2
	sed -i '93s/#\[multilib\]/\[multilib\]/g' /etc/pacman.conf
	sed -i '94s/#Include = \/etc\/pacman.d\/mirrorlist/Include = \/etc\/pacman.d\/mirrorlist/g' /etc/pacman.conf
	echo "Updating repositories..."
	sleep 2
	pacman -Syu --noconfirm
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
	sleep 2
	pacman -S --noconfirm --needed zsh
	echo "Installing essential software..."
	sleep 2
	pacman -S --noconfirm --needed wget curl git sudo perl tar base-devel alsa-utils
	echo "Installing utilities..."
	sleep 2
	pacman -S --noconfirm --needed android-file-transfer arc-icon-theme bleachbit blueman moc mtr nomacs pkgstats
	pacman -S --noconfirm --needed breeze-icons cheese cmatrix deadbeef dstat epdfview fdupes gftp gnome-maps
	pacman -S --noconfirm --needed speedtest-cli smartmontools subdl terminus-font tigervnc
	pacman -S --noconfirm --needed usbutils volumeicon watchdog weechat x11vnc wget openssh gvim dialog networkmanager
	pacman -S --noconfirm --needed gparted gvim htop minitube mlocate qbittorrent smbnetfs smplayer
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
    [ -x "\$f" ] && . "\$f"
  done
  unset f
fi

#----XFCE4
exec startxfce4
" > /home/$username/.xinitrc
chown $username:$username /home/$username/.xinitrc

echo "Generating .zshrc file"
	rm -f /home/$username/.zshrc

echo "# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
  export ZSH=/home/"$username"/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to \"random\"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME=\"robbyrussell\"
#ZSH_THEME=""

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE=\"true\"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE=\"true\"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE=\"true\"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS=\"true\"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE=\"true\"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION=\"true\"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS=\"true\"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY=\"true\"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: \"mm/dd/yyyy\"|\"dd.mm.yyyy\"|\"yyyy-mm-dd\"
# HIST_STAMPS=\"mm/dd/yyyy\"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git history-substring-search) 

source $ZSH/oh-my-zsh.sh

# User configuration

#export TERM=xterm-256color
export EDITOR=\"nano\"
#export BROWSER=\"google-chrome-stable\"

# export MANPATH=\"/usr/local/man:$MANPATH\"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS=\"-arch x86_64\"

# ssh
# export SSH_KEY_PATH=\"~/.ssh/rsa_id\"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run \`alias\`.
#
# Example aliases
# alias zshconfig=\"mate ~/.zshrc\"
# alias ohmyzsh=\"mate ~/.oh-my-zsh\"

alias start_windows_network='sudo systemctl start smbnetfs.service'
alias stop_windows_network='sudo systemctl stop smbnetfs.service'
alias calc='wcalc '
alias install='pacaur -S '
alias remove='sudo pacman -Rns '
alias upgrade='pacaur --noedit -Syua && sudo pacman -Su'
alias aur='pacaur --noedit '
alias cls='clear'
alias zshconf='nano ~/.zshrc'
alias search='pacaur -Ss '
alias off='poweroff'
alias update='sudo pacman -Sy'
alias list='pacman -Q | less'
alias matrix='cmatrix -ba -u 6'
alias teamviewer='sudo systemctl start teamviewerd && teamviewer'
alias clean='sudo pacman -Rns $(pacman -Qqtd)'
alias mame='sdlmame'
alias startxampp='sudo /opt/lampp/lampp start'
alias stopxampp='sudo /opt/lampp/lampp stop'
alias www='w3m '
alias whatsmyip='curl ipv4.icanhazip.com'
alias moc=mocp
alias youtube-dl-high='youtube-dl -o "\%\(title\)s.\%\(ext\)s" -f mp4 -x --audio-quality 192K --audio-format mp3 '
alias youtube-dl-low='youtube-dl -o "\%\(title\)s.\%\(ext\)s" -f webm -x --audio-quality 192K --audio-format mp3 '
alias mv='mv -v '
alias cp='cp -v '
alias rm='rm -v '
alias irc='weechat '
alias empty='rm -rf ~/.local/share/Trash/*'
alias y='youtube-dl '
alias reload='source ~/.zshrc'
alias weather='curl -4 http://wttr.in/Thessaloniki '
alias pastebinit='pastebinit -b sprunge.us -i '
alias ls='ls --color=always '
alias less='less -r'
alias acpi='acpi -V'
" > /home/$username/.zshrc
chown $username:$username /home/$username/.zshrc
}
function nonroot_software {
	echo "Installing additional software..."
	echo "Installing cower-git"
	sleep 2
	echo "Signing key 1EB2638FF56C0C53"
	gpg --recv-keys --keyserver hkp://pgp.mit.edu 1EB2638FF56C0C53
	echo "Signing key F54984BFA16C640F"
	gpg --recv-keys --keyserver hkp://pgp.mit.edu F54984BFA16C640F
	sleep 2
	wget https://aur.archlinux.org/cgit/aur.git/snapshot/cower.tar.gz
	tar -zxvf cower.tar.gz
	cd cower
	makepkg --needed --noconfirm -si
	cd ..
	echo "Installing pacaur"
	sleep 2
	wget https://aur.archlinux.org/cgit/aur.git/snapshot/pacaur.tar.gz
	tar -zxvf pacaur.tar.gz
	cd pacaur
	makepkg --needed --noconfirm -si
	cd ..
	echo "Installing additional software..."
	sleep 2
	pacaur -S --noconfirm --needed --noedit xfce-theme-blackbird xfce-theme-greybird agetpkg-git coolreader3-git dupeguru-me dupeguru-pe dupeguru-se mmv palemoon-bin skype sublime-text teamviewer translate-shell winusb-git discus
}
function services {
	clear
	echo "Enabling services"
	sudo systemctl enable NetworkManager.service
}
#function clean_up {read -p "Clean up files ? [yn] " yn if [[ $yn = y ]]; then	#TODOfi}
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
  		clear
  		echo "Reboot, log in to your new account and rerun the script. It was be coppied to your home folder. Just run \"./$SCRIPT\""
  		read -p "Reboot now ? [yn] : " answer
  		if [[ $answer = y ]];then
  			reboot
  		else
  			exit 0
  		fi
	else
  		echo "Connect to WiFi using \"wifi-menu\" and rerun the script."
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
  		echo "Connect to WiFi using \"sudo wifi-menu\" and rerun the script."
		exit 1
	fi
fi