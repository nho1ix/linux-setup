#+-------------------------+
#| Configuration in chroot |
#+-------------------------+
# Essential packages
echo 'Downloading other packages'
pacman --noconfirm -S $ucode networkmanager git vifm

# Swap
echo 'Making swap file if requested'
if [ -n "$swap_size" ]; then
     dd if=/dev/zero of=/swapfile bs=1GiB count=$swap_size status=progress
     chmod 600 /swapfile
     mkswap /swapfile
     swapon /swapfile
     echo "# swapfile" >> /etc/fstab
     echo "/swapfile none swap defaults 0 0" >> /etc/fstab
fi

# Timezone and localization
echo 'Setting timezone...'
ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
hwclock --systohc
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen && locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
echo "$hostname" > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       "$hostname".localdomain       "$hostname"" >> /etc/hosts

# Network
echo 'Enabling network functionality'
systemctl enable NetworkManager

# Boot
echo 'Setting up bootloader..'
if [ "$bootloader" = "systemd-boot" ]; then
     bootctl --path=/boot install
     echo 'default arch.conf' > /boot/loader/loader.conf
     echo 'console-mode auto' >> /boot/loader/loader.conf
     echo 'timeout 0' >> /boot/loader/loader.conf
     echo 'editor  0' >> /boot/loader/loader.conf
     echo 'title   Arch Linux' > /boot/loader/entries/arch.conf
     echo 'linux   /vmlinuz-linux' >> /boot/loader/entries/arch.conf
     [ -n "$ucode" ] && echo "initrd  /$ucode.img" >> /boot/loader/entries/arch.conf
     echo 'initrd  /initramfs-linux.img' >> /boot/loader/entries/arch.conf
     echo "options rd.luks.name=[regular UUID here]=encrypted root=UUID=[encrypted UUID here] rw nowatchdog quiet" >> /boot/loader/entries/arch.conf
elif [ "$bootloader" = "efistub" ]; then
     [ -n "$ucode" ] && ucode_init="initrd=/$ucode.img"
     efibootmgr -d $disk -p 1 -c -L "Arch Linux" -l /vmlinuz-linux -u "$ucode_init initrd=/initramfs-linux.img root=$root_partition rw quiet" -v
fi

# Silent boot
echo 'Adding systemd hooks + lz4 compression'
sed -i 's/^HOOKS=(base udev/HOOKS=(base systemd/g' /etc/mkinitcpio.conf
sed -i 's/modconf block/modconf block sd-encrypt/g' /etc/mkinitcpio.conf
sed -i 's/^#COMPRESSION="lz4"/COMPRESSION="lz4"/g' /etc/mkinitcpio.conf
sed -i '67iCOMPRESSION_OPTIONS="-9"' /etc/mkinitcpio.conf
vim /etc/mkinitcpio.conf
mkinitcpio -p linux
echo "StandardOutput=null\nStandardError=journal+console" | SYSTEMD_EDITOR="tee -a" systemctl edit --full systemd-fsck-root.service

# Pacman
echo 'Applying color to pacman...'
sed -i 's/^#Color/Color/g;/#\[multilib\]/,/#Include/ s/^#//g' /etc/pacman.conf
sed -i '33 a\ILoveCandy' /etc/pacman.conf
pacman -Syy

# Makepkg
echo 'Enabling parallel compilation and compression.."
sed -i 's/-march=x86_64 -mtune=generic/-march=native/g' /etc/makepkg.conf
sed -i 's/^#MAKEFLAGS="-j2"/MAKEFLAGS="-j$(nproc)"/g' /etc/makepkg.conf

# Users
echo "Please enter the root password for this computer:"
passwd
useradd -m -G wheel -s /bin/zsh -c "$fullname" "$username"
echo "Please enter the password for "$username":"
passwd "$username"

# Allow users in group wheel to use sudo
sed -i '/%wheel\sALL=(ALL)\sNOPASSWD:\sALL/s/^#\s//g' /etc/sudoers

# Change shell to zsh
echo 'Changing shell for user'
chsh -s /bin/zsh
chsh -s /bin/zsh victor

# Manual intervention
echo 'Symlinking vi to vim (visudo)'
ln -s /usr/bin/vim /usr/bin/vi
vim /boot/loader/entries/arch.conf

# Cleanup
cd /home/"$username"
if [[ ! -f afterinstall.sh ]]; then
    echo "Missing afterinstall.sh, downloading..."
    curl -O https://raw.githubusercontent.com/nho1ix/linux-setup/master/base/afterinstall.sh
fi
chmod +x afterinstall.sh
rm /chroot.sh
echo 'The installation has finished. VARBs will be in your user's home directory. Please run the VARBs script after rebooting. I will exit now'
exit
