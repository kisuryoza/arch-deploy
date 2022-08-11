########################################################-- Linux itself

PKG+=(linux linux-firmware)
[[ "$SETUP" == "full" ]] && PKG+=(linux-zen)
PKG+=(base base-devel)

###########################################################-- Essential

PKG+=(git gvim networkmanager iproute2 nftables apparmor wget opendoas lz4)

##---------------------------------------------------------------- Docs

PKG+=(man-db man-pages texinfo)

##--------------------------------------------------------------- Shell

PKG+=(bash-completion)
PKG+=(zsh zsh-syntax-highlighting zsh-autosuggestions)

##-------------------------------------------- Rust alternatives to gnu

PKG+=(exa bat procs dust ripgrep fd)

##-------------------------------------------------------------- Others

PKG+=(gdb python rustup sccache rsync)
PKG+=(meson ninja)  # build system


if [[ "$SETUP" == "full" ]];
then
    PKG+=(neovim neovide)
    PKG+=(emacs ccls)
    PKG+=(cppcheck ctags)
    PKG+=(xdg-desktop-portal xdg-desktop-portal-gtk)

#####################################################-- Display servers

if [[ "$DISPLAY_SERVER" == "X" ]];
then
    PKG+=(xorg-server xorg-xinit xclip)
    PKG+=(xautolock)        # An automatic X screen-locker/screen-saver
    PKG+=(picom)            # compositor
    PKG+=(rofi)             # A window switcher, application launcher and dmenu replacement
    PKG+=(flameshot)        # screenshoter
    PKG+=(feh)              # image viewer & wallpaper setting
fi

if [[ "$DISPLAY_SERVER" == "Wayland" ]];
then
    PKG+=(wlroots xorg-xwayland wl-clipboard)
    PKG+=(swayidle)         # Idle management daemon
    PKG+=(swaylock)         # Screen locker
    PKG+=(swaybg)           # wallpaper setting
    PKG+=(flameshot grim)   # screenshoter
    PKG+=(imv)              # image viewer
    PKG+=(xdg-desktop-portal-wlr)
    PKG+=(gtk-layer-shell)  # For EWW
fi

################################################-- Multimedia framework

PKG+=(pipewire wireplumber helvum)
PKG+=(pipewire-alsa pipewire-pulse pamixer)

#############################################-- Miscellaneous utilities
##----------------------------------------------------------- VPN stuff

PKG+=(openvpn dhcpcd dnscrypt-proxy tor)

##------------------------------------------------------- File managing

PKG+=(thunar)
PKG+=(thunar-volman thunar-archive-plugin ffmpegthumbnailer tumbler)
PKG+=(gvfs-mtp) # Virtual filesystem implementation
PKG+=(ark)      # Universal archiving tool
PKG+=(p7zip)    # 7z support
PKG+=(handlr)   # Powerful alternative to xdg-utils (managing mime types)

##--------------------------------------------------- Language spelling

PKG+=(hunspell hunspell-en_us hunspell-ru enchant gspell)

##----------------------------------------------------------------- OCR

PKG+=(tesseract tesseract-data-eng tesseract-data-rus gimagereader-gtk)

##---------------------------------------------------------------- Mail

PKG+=(aerc) # Email Client
PKG+=(w3m)  # Text-based Web browser (as render for HTML)

##-------------------------------------------------------------- Others

PKG+=(alacritty)        # terminal
#PKG+=(neofetch)         # system information tool
#PKG+=(htop)             # interactive process viewer
PKG+=(bottom)           # A customizable cross-platform graphical process/system monitor for the terminal.
PKG+=(fzf)              # A command-line fuzzy finder
PKG+=(playerctl)        # mpris media player command-line controller
PKG+=(pacman-contrib)   # various scripts to pacman
PKG+=(sysstat)          # a collection of performance monitoring tools (iostat,isag,mpstat,pidstat,sadf,sar)
PKG+=(pkgstats)         # Submit a list of installed packages to the Arch Linux project
PKG+=(mate-polkit)      # graphical authentication agent
PKG+=(dunst)            # Customizable and lightweight notification-daemon
PKG+=(tlp)              # Linux Advanced Power Management
PKG+=(gamemode lib32-gamemode) # A daemon/lib combo that allows games to request a set of optimisations be temporarily applied to the host OS
PKG+=(asp)              # for paru
PKG+=(yt-dlp)
PKG+=(qrencode)

################################################-- Themes, icons, fonts

# Theme managing
PKG+=(qt5ct qt6ct lxappearance-gtk3)
# Themes
PKG+=(breeze materia-gtk-theme python-pywal)
# Fonts
PKG+=(ttf-dejavu ttf-liberation ttc-iosevka-etoile ttc-iosevka-ss14)
PKG+=(unicode-emoji noto-fonts noto-fonts-cjk noto-fonts-emoji)

################################################################-- Apps

PKG+=(discord telegram-desktop)
PKG+=(mpv mpv-mpris pragha songrec)
PKG+=(libreoffice-fresh qbittorrent)
PKG+=(keepassxc)                    # Cross-platform community-driven port of Keepass password manager
PKG+=(inkscape)                     # Professional vector graphics editor
#PKG+=(lmms)                         # The Linux MultiMedia Studio
PKG+=(zathura zathura-pdf-mupdf)    # Minimalistic document viewer
fi

#wine
#pacman -S wine-staging winetricks
#pacman -S --asdeps --needed $(pacman -Si wine-staging | sed -n '/^Opt/,/^Conf/p' | sed '$d' | sed 's/^Opt.*://g' | sed 's/^\s*//g' | tr '\n' ' ')
