########################################################-- Linux itself

PKG+=(linux linux-firmware)
[[ "$SETUP" == "full" ]] && PKG+=(linux-zen)
PKG+=(base base-devel)

###########################################################-- Essential

PKG+=(git gvim networkmanager iwd iproute2 nftables apparmor wget opendoas lz4)

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
PKG+=(dos2unix)     # Text file format converter
PKG+=(stow)         # Manage installation of multiple softwares in the same directory tree
#PKG+=(neofetch)     # system information tool
#PKG+=(htop)         # interactive process viewer
PKG+=(bottom)       # A customizable cross-platform graphical process/system monitor for the terminal.


if [[ "$SETUP" == "full" ]];
then
    PKG+=(neovim neovim-qt fennel)
    PKG+=(emacs ccls)
    PKG+=(cppcheck ctags)
    PKG+=(xdg-desktop-portal)
    PKG+=(bemenu)           # Dynamic menu library and client program inspired by dmenu

#####################################################-- Display servers

if [[ "$DISPLAY_SERVER" == "X" ]];
then
    PKG+=(xorg-server xorg-xinit xclip)
    PKG+=(xdg-desktop-portal-gtk)
    PKG+=(xautolock)        # An automatic X screen-locker/screen-saver
    PKG+=(picom)            # compositor
    PKG+=(bemenu-x11)       # X11 renderer for bemenu
    PKG+=(flameshot)        # screenshoter
    PKG+=(feh)              # image viewer & wallpaper setting
fi

if [[ "$DISPLAY_SERVER" == "Wayland" ]];
then
    PKG+=(wlroots xorg-xwayland wl-clipboard)
    PKG+=(xdg-desktop-portal-wlr)
    PKG+=(sway)             # Tiling Wayland compositor (as a dependency)
    PKG+=(swayidle)         # Idle management daemon
    PKG+=(swaylock)         # Screen locker
    PKG+=(swaybg)           # wallpaper setting
    PKG+=(bemenu-wayland)   # Wayland (wlroots-based compositors) renderer for bemenu
    PKG+=(flameshot grim)   # screenshoter
    PKG+=(imv)              # image viewer
    PKG+=(gtk-layer-shell)  # For EWW
fi

################################################-- Multimedia framework

PKG+=(pipewire wireplumber helvum)
PKG+=(pipewire-alsa pipewire-pulse)

##------------------------------- Multimedia related Utilities and Apps

PKG+=(mpd mpc ncmpcpp)  # Music player daemon
PKG+=(easyeffects)      # Audio Effects for Pipewire applications
PKG+=(pamixer)          # Pulseaudio command-line mixer like amixer
PKG+=(pavucontrol)      # PulseAudio Volume Control
PKG+=(playerctl)        # mpris media player command-line controller
PKG+=(mediainfo)        # Supplies technical and tag information about a video or audio file (CLI interface)
PKG+=(soundconverter)   # A simple sound converter application for GNOME
PKG+=(mpv mpv-mpris)    # a free, open source, and cross-platform media player
PKG+=(songrec)          # An open-source, unofficial Shazam client for Linux
#PKG+=(lmms)             # The Linux MultiMedia Studio

#############################################-- Miscellaneous utilities
##------------------------------------------------------ Ethernet stuff

PKG+=(openvpn dnscrypt-proxy tor)
PKG+=(syncthing)    # file synchronization client/server application

##------------------------------------------------------- File managing

PKG+=(thunar)
PKG+=(thunar-volman thunar-archive-plugin thunar-media-tags-plugin ffmpegthumbnailer tumbler)
PKG+=(udiskie)      # Removable disk automounter using udisks
PKG+=(gvfs-mtp)     # Virtual filesystem implementation
PKG+=(file-roller)  # Create and modify archives
PKG+=(p7zip)        # 7z support
PKG+=(handlr)       # Powerful alternative to xdg-utils (managing mime types)

##--------------------------------------------------- Language spelling

PKG+=(hunspell hunspell-en_us hunspell-ru enchant gspell)

##----------------------------------------------------------------- OCR

PKG+=(tesseract tesseract-data-eng tesseract-data-rus gimagereader-gtk)

##-------------------------------------------------------------- Others

PKG+=(alacritty)        # terminal
PKG+=(acpi)             # Client for battery, power, and thermal readings
PKG+=(fzf)              # A command-line fuzzy finder
PKG+=(pacman-contrib)   # various scripts to pacman
PKG+=(sysstat)          # a collection of performance monitoring tools (iostat,isag,mpstat,pidstat,sadf,sar)
PKG+=(pkgstats)         # Submit a list of installed packages to the Arch Linux project
PKG+=(mate-polkit)      # graphical authentication agent
PKG+=(dunst)            # Customizable and lightweight notification-daemon
PKG+=(tlp)              # Linux Advanced Power Management
PKG+=(gamemode lib32-gamemode) # A daemon/lib combo that allows games to request a set of optimisations be temporarily applied to the host OS
PKG+=(asp)              # for paru
PKG+=(zerotier-one)     # Creates virtual Ethernet networks of almost unlimited size
PKG+=(yt-dlp)
PKG+=(qrencode)
PKG+=(bc)               # An arbitrary precision calculator language
PKG+=(geary)            # mail client

################################################-- Themes, icons, fonts

# Theme managing
PKG+=(qt5ct qt6ct lxappearance-gtk3)
# Themes and Icons
PKG+=(materia-gtk-theme python-pywal breeze-icons)
# Fonts
PKG+=(ttf-dejavu)
PKG+=(ttf-liberation)       # Font family which aims at metric compatibility with Arial, Times New Roman, and Courier New
PKG+=(ttc-iosevka-ss14)     # JetBrains Mono Style
#PKG+=(ttc-iosevka-aile)     # Sans style
PKG+=(ttc-iosevka-etoile)   # Serif style
PKG+=(unicode-emoji noto-fonts noto-fonts-cjk noto-fonts-emoji)

################################################################-- Apps

PKG+=(telegram-desktop)
PKG+=(libreoffice-fresh qbittorrent)
PKG+=(keepassxc)                    # Cross-platform community-driven port of Keepass password manager
PKG+=(inkscape)                     # Professional vector graphics editor
PKG+=(zathura zathura-pdf-mupdf)    # Minimalistic document viewer
fi

#wine
#pacman -S wine-staging winetricks
#pacman -S --asdeps --needed $(pacman -Si wine-staging | sed -n '/^Opt/,/^Conf/p' | sed '$d' | sed 's/^Opt.*://g' | sed 's/^\s*//g' | tr '\n' ' ')
