#!/bin/bash

function pacaur_installer() {
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
pacaur_installer
