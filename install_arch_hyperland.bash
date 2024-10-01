#!/usr/bin/bash

###
hostname='arch'
rootpasswd='System32'
username='leandro'
userpasswd='System32'

###

loadkeys pt-latin1
timedatectl

#mkfs.ext4 /dev/mapper/${rootcrypt}

#mkfs.fat -F 32 /dev/${dev_root}1

pacstrap -K /mnt base linux linux-firmware vim

genfstab -U /mnt >> /mnt/etc/fstab

function display() {
	case $1 in
		"hyprland")
			pacman -S pacman -S ly hyprland-git polkit --noconfirm
			# theme https://github.com/taylor85345/cyber-hyprland-theme
			#
			mkdir /home/${username}/.config/hypr/themes
			cd /home/${username}/.config/hypr/themes
			git clone https://github.com/taylor85345/cyber-hyprland-theme cyber
			printf %s 'source=~/.config/hypr/themes/cyber/theme.conf' >> /home/${username}/.config/hypr/hyprland.conf
			cd

			sudo pacman -S base-devel git
			git clone https://aur.archlinux.org/yay
			cd yay
			makepkg -si
			yay -S --needed hyprland-git eww-wayland rofi-wayland rofi-lbonn-wayland dunst trayer mpvpaper macchina nitch nerd-fonts-inter nerd-fonts-mono socat geticons
			
			cd

			git clone --recursive https://github.com/taylor85345/hyprland-dotfiles.git
			cp -ri hyprland-dotfiles/* /home/${username}/.config/


			git clone https://github.com/yeyushengfan258/Inverse-dark-kde.git
			cd Inverse-dark-kde
			./install.sh
			;;
		*)
			echo "not valid display"
			;;
	esac
}

function network() {
	pacman -S ufw gufw networkmanager --noconfirm
	systemctl enable ufw NetworkManager --now
	ufw enable
}

function setup_users() {
	useradd -m ${username}
	echo ${rootpasswd} | passwd
	echo ${userpasswd} | passwd ${username}
}

function setup_pacman() {
	sed -zi 's/#\[multilib\]\n#Include = \/etc\/pacman.d\/mirrorlist/\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist/' /etc/pacman.conf
	sed -i 's/#Color/Color/' /etc/pacman.conf
	sed -i 's/#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
}

function packages() {
	pacman -S kitty dolphin wofi git curl nano bind curl go make fakeroot debugedit binutils gcc base-devel network-manager-applet --noconfirm
}

function drivers() {
	pacman -S amd-ucode lm_sensors mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver mesa-vdpau lib32-mesa-vdpau
}

function boot() {
	pacman -S grub efibootmgr --noconfirm

	grub-install --target=x86_64-efi --efi-directory=/boot

	sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet"/GRUB_CMDLINE_LINUX_DEFAULT="loglevel=4"/' /etc/default/grub

	grub-mkconfig -o /boot/grub/grub.cfg
}

arch-chroot /mnt /bin/bash -x <<EOF

pacman -Syy

ln -sf /usr/share/zoneinfo/Portugal /etc/localtime

hwclock --systohc

sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen

locale-gen

printf %s 'LANG=en_US.UTF-8' > /etc/locale.conf

printf %s 'KEYMAP=pt-latin1' > /etc/vconsole.conf

printf %s "${hostname}" > /etc/hostname

mkinitcpio -P

setup_users

setup_pacman

setup_users

packages

drivers

boot

display

#####

EOF


