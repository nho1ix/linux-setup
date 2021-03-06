#!/bin/sh

# Clone personal dotfiles repo & yay
git clone https://github.com/nho1ix/dotfiles.git
mv dotfiles/* $HOME
mv -i dotfiles/.* $HOME

# Compile yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd && rm -rf yay

# Clone suckless utilities
git clone https://github.com/nho1ix/dwm.git
git clone https://github.com/nho1ix/dwmblocks.git
git clone https://github.com/nho1ix/dmenu.git
git clone https://github.com/nho1ix/st.git
git clone https://github.com/nho1ix/bdata.git

# Merge bdata files with home directory
mv -n bdata/.config $HOME && mv -n bdata/.mozilla $HOME

# Make suckless directory and move files to directory
mkdir .config/suckless && mv dwm dwmblocks dmenu st .config/suckless/

# Install AUR packages
yay -S ifuse brave-bin alsa-utils usbutils ttf-font-awesome ytop ios-emoji zathura zathura-pdf-poppler picom-ibhagwan-git instagram-nativefier libxft-bgra-git paper-icon-theme-git ripgrep udiskie vifmimg-git vim-lightline-git vim-ultisnips vim-vimwiki vundle-git xclip --noconfirm

# Install plugins for vim
vim -c PluginInstall &

# Get Ungoogled Chromium binary
wget "https://github.com/Colocasian/ungoogled-chromium-binaries/releases/download/85.0.4183.102-1/ungoogled-chromium-85.0.4183.102-1-x86_64.pkg.tar.zst"

# Install and remove tar compressed binary
yay -U ungoogled-chromium-85.0.4183.83-1-x86_64.pkg.tar.zst --noconfirm
rm ungoogled-chromium-85.0.4183.83-1-x86_64.pkg.tar.zst

# Copy over config files
# cd dotfiles/.config && cp -r autostart dunst gtk-3.0 khal neofetch notmuch-config picom vifm wall xarchiver xorgstuff zathura zsh aliasrc env redshift.conf youtube-dl.conf $HOME/.config && cd && cd dotfiles && cp -r .fonts .local .themes .vim Documents .Xresources .bashrc .xinitrc .zshenv $HOME && cd

# Download oh-my-zsh
sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
