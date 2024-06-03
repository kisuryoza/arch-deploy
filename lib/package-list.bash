PKG+=(linux linux-firmware)
[[ "$SETUP" == "full" ]] && PKG+=(linux-zen)
PKG+=(base base-devel arch-install-scripts)

###########################################################-- Essential

PKG+=(man-db man-pages texinfo)
PKG+=(git networkmanager iwd iproute2 iptables-nft wget)
PKG+=(opendoas efibootmgr lz4 apparmor strace lsof)
PKG+=(bind bandwhich net-tools nmap traceroute)
PKG+=(uutils-coreutils eza bat procs dust ripgrep fd sd hyperfine)
PKG+=(zsh fish starship atuin zoxide)

##--------------------------------------------------------- Development

PKG+=(neovim gvim)
PKG+=(gdb clang python rustup sccache)
PKG+=(cargo-asm cargo-audit cargo-bloat cargo-expand cargo-flamegraph cargo-generate cargo-watch sqlx-cli)
PKG+=(bear meson ninja cmake)
PKG+=(rsync)
PKG+=(docker docker-buildx)

##----------------------------------------------------- System monitors

PKG+=(sysstat)       # a collection of performance monitoring tools (iostat,isag,mpstat,pidstat,sadf,sar)
PKG+=(smartmontools) # Control and monitor S.M.A.R.T. enabled ATA and SCSI Hard Drives
PKG+=(acpi)          # Client for battery, power, and thermal readings
PKG+=(btop)          # A monitor of system resources, bpytop ported to C++
PKG+=(nvtop)         # GPUs process monitoring for AMD, Intel and NVIDIA

##-------------------------------------------------------------- Others

PKG+=(earlyoom)             # Early OOM Daemon for Linux
PKG+=(tmux)                 # Terminal multiplexer
PKG+=(fzf fzy)              # A command-line fuzzy finder
PKG+=(btrfs-progs)          # Btrfs filesystem utilities
PKG+=(task taskwarrior-tui) # A command-line todo list manager
PKG+=(bubblewrap)           # Unprivileged sandboxing tool
PKG+=(dos2unix)             # Text file format converter
PKG+=(stow)                 # Manage installation of multiple softwares in the same directory tree
PKG+=(cronie)
PKG+=(pkgstats pacman-contrib)
PKG+=(glow)

if [[ "$SETUP" == "full" ]]; then
    PKG+=(xdg-desktop-portal)
    PKG+=(bemenu) # Dynamic menu library and client program inspired by dmenu
    PKG+=(glfw)   # A free, open source, portable framework for graphical application development

    #####################################################-- Display servers

    if [[ "$DISPLAY_SERVER" == "X" ]]; then
        PKG+=(xorg-server xorg-xinit xclip)
        PKG+=(xdg-desktop-portal-gtk)
        PKG+=(bspwm sxhkd xdo)
        PKG+=(xss-lock i3lock) # Screen locker
        PKG+=(picom)           # compositor
        PKG+=(bemenu-x11)      # X11 renderer for bemenu
        PKG+=(flameshot)       # screenshoter
        PKG+=(feh)             # for wallpaper setting
    fi

    if [[ "$DISPLAY_SERVER" == "Wayland" ]]; then
        PKG+=(wlroots xorg-xwayland wl-clipboard)
        PKG+=(hyprland)
        PKG+=(xdg-desktop-portal-hyprland)
        # PKG+=(xdg-desktop-portal-wlr)
        PKG+=(qt5-wayland qt6-wayland)
        PKG+=(sway)            # Tiling Wayland compositor (as a dependency)
        PKG+=(swayidle)        # Idle management daemon
        PKG+=(swaylock)        # Screen locker
        PKG+=(bemenu-wayland)  # Wayland (wlroots-based compositors) renderer for bemenu
        PKG+=(grim slurp)      # screenshoter
        PKG+=(gtk-layer-shell) # For EWW
    fi

    ################################################-- Multimedia framework

    PKG+=(pipewire wireplumber)
    PKG+=(pipewire-alsa pipewire-pulse pipewire-jack qjackctl)

    ##------------------------------- Multimedia related Utilities and Apps

    PKG+=(imv)             # Image viewer for Wayland and X11
    PKG+=(mpd mpc ncmpcpp) # Music player daemon
    PKG+=(easyeffects)     # Audio Effects for Pipewire applications
    PKG+=(pamixer)         # Pulseaudio command-line mixer
    PKG+=(qpwgraph)        # PipeWire Graph Qt GUI Interface
    PKG+=(pavucontrol)     # PulseAudio Volume Control
    PKG+=(mediainfo)       # Supplies technical and tag information about a video or audio file (CLI interface)
    PKG+=(mpv)             # a free, open source, and cross-platform media player
    PKG+=(songrec)         # An open-source, unofficial Shazam client for Linux
    # PKG+=(soundconverter)   # A simple sound converter application for GNOME
    # PKG+=(lmms)             # The Linux MultiMedia Studio

    #############################################-- Miscellaneous utilities
    ##------------------------------------------------------ Ethernet stuff

    PKG+=(openvpn dnscrypt-proxy dnsmasq openresolv)
    PKG+=(syncthing)            # file synchronization client/server application
    PKG+=(nm-connection-editor) # NetworkManager GUI connection editor and widgets
    PKG+=(blueman)              # GTK+ Bluetooth Manager

    ##------------------------------------------------------- File managing

    PKG+=(yazi)
    PKG+=(ark)          # Archiver
    PKG+=(udiskie)      # Removable disk automounter using udisks
    PKG+=(fuseiso)      # FuseISO is a FUSE module to let unprivileged users mount ISO filesystem images
    PKG+=(gvfs-mtp)     # Virtual filesystem implementation
    PKG+=(handlr-regex) # Powerful alternative to xdg-utils (managing mime types)
    PKG+=(trash-cli)    # Command line trashcan (recycle bin) interface

    ##--------------------------------------------------- Language spelling

    PKG+=(hunspell hunspell-en_us hunspell-ru enchant gspell)

    ##-------------------------------------------------------------- Others

    PKG+=(alacritty)    # terminal
    PKG+=(mate-polkit)  # graphical authentication agent
    PKG+=(dunst)        # Customizable and lightweight notification-daemon
    PKG+=(zerotier-one) # Creates virtual Ethernet networks of almost unlimited size
    PKG+=(yt-dlp)
    PKG+=(qrencode)
    PKG+=(tlp) # Linux Advanced Power Management
    PKG+=(screenkey)
    PKG+=(socat)
    # PKG+=(av1an mkvtoolnix-cli mkvtoolnix-gui opus-tools)

    ################################################-- Themes, icons, fonts

    PKG+=(kvantum kvantum-qt5 lxappearance-gtk3)
    PKG+=(breeze-icons)
    PKG+=(ttf-dejavu ttf-jetbrains-mono ttf-liberation ttf-opensans)
    # PKG+=(ttc-iosevka-ss14)     # JetBrains Mono Style
    # PKG+=(ttc-iosevka-aile)     # Sans style
    # PKG+=(ttc-iosevka-etoile)   # Serif style
    # PKG+=(ttf-iosevka-nerd)
    PKG+=(unicode-emoji noto-fonts noto-fonts-cjk noto-fonts-emoji)

    ################################################################-- Apps

    PKG+=(libreoffice-fresh qbittorrent keepassxc zathura zathura-djvu zathura-pdf-mupdf)
fi

# Wine
# pacman -S wine-staging winetricks gamemode lib32-gamemode
# pacman -S --asdeps --needed $(pacman -Si wine-staging | sed -n '/^Opt/,/^Conf/p' | sed '$d' | sed 's/^Opt.*://g' | sed 's/^\s*//g' | tr '\n' ' ')
