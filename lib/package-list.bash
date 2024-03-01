########################################################-- Linux itself

PKG+=(linux linux-firmware)
[[ "$SETUP" == "full" ]] && PKG+=(linux-zen)
PKG+=(base base-devel arch-install-scripts)

###########################################################-- Essential

PKG+=(git networkmanager iwd iproute2 iptables-nft wget)
PKG+=(opendoas lz4 apparmor bind strace lsof)
PKG+=(zsh fish starship atuin)

##---------------------------------------------------------------- Docs

PKG+=(man-db man-pages texinfo)

##-------------------------------------------- Rust alternatives to gnu

PKG+=(uutils-coreutils eza bat procs dust ripgrep fd sd)

##--------------------------------------------------------- Development

PKG+=(neovim gvim fennel fnlfmt shfmt bash-language-server)
PKG+=(gdb clang python rustup sccache)
PKG+=(cargo-asm cargo-audit cargo-bloat cargo-flamegraph cargo-generate cargo-watch sqlx-cli)
PKG+=(meson ninja)  # build systems
PKG+=(cppcheck ctags)
PKG+=(rsync)
PKG+=(docker docker-buildx)
PKG+=(gitui git-delta difftastic)

##----------------------------------------------------- System monitors

PKG+=(sysstat)      # a collection of performance monitoring tools (iostat,isag,mpstat,pidstat,sadf,sar)
PKG+=(acpi)         # Client for battery, power, and thermal readings
PKG+=(btop)         # A monitor of system resources, bpytop ported to C++
PKG+=(bandwhich)    # Terminal bandwidth utilization tool
PKG+=(nvtop)        # GPUs process monitoring for AMD, Intel and NVIDIA

##-------------------------------------------------------------- Others

PKG+=(earlyoom)     # Early OOM Daemon for Linux
PKG+=(tmux)         # Terminal multiplexer
PKG+=(hyperfine)    # A command-line benchmarking tool
PKG+=(fzf fzy)      # A command-line fuzzy finder
PKG+=(btrfs-progs)  # Btrfs filesystem utilities
PKG+=(pacman-contrib)   # various scripts to pacman
PKG+=(pkgstats)     # Submit a list of installed packages to the Arch Linux project
PKG+=(task taskwarrior-tui) # A command-line todo list manager
PKG+=(xplr)         # A hackable, minimal, fast TUI file explorer
PKG+=(bubblewrap)   # Unprivileged sandboxing tool
PKG+=(dos2unix)     # Text file format converter
PKG+=(stow)         # Manage installation of multiple softwares in the same directory tree
PKG+=(libqalculate) # Multi-purpose desktop calculator


if [[ "$SETUP" == "full" ]];
then
    PKG+=(xdg-desktop-portal)
    PKG+=(bemenu)           # Dynamic menu library and client program inspired by dmenu
    PKG+=(glfw)             # A free, open source, portable framework for graphical application development

#####################################################-- Display servers

if [[ "$DISPLAY_SERVER" == "X" ]];
then
    PKG+=(xorg-server xorg-xinit xclip)
    PKG+=(xdg-desktop-portal-gtk)
    PKG+=(bspwm sxhkd xdo)
    PKG+=(xss-lock i3lock)  # Screen locker
    PKG+=(picom)            # compositor
    PKG+=(bemenu-x11)       # X11 renderer for bemenu
    PKG+=(flameshot)        # screenshoter
    PKG+=(feh)              # for wallpaper setting
fi

if [[ "$DISPLAY_SERVER" == "Wayland" ]];
then
    PKG+=(wlroots xorg-xwayland wl-clipboard)
    PKG+=(hyprland hyprpaper)
    PKG+=(xdg-desktop-portal-hyprland)
    # PKG+=(xdg-desktop-portal-wlr)
    PKG+=(qt5-wayland qt6-wayland)
    PKG+=(sway)             # Tiling Wayland compositor (as a dependency)
    PKG+=(swayidle)         # Idle management daemon
    PKG+=(swaylock)         # Screen locker
    PKG+=(swaybg)           # wallpaper setting
    PKG+=(bemenu-wayland)   # Wayland (wlroots-based compositors) renderer for bemenu
    PKG+=(grim slurp)       # screenshoter
    PKG+=(gtk-layer-shell)  # For EWW
fi

################################################-- Multimedia framework

PKG+=(pipewire wireplumber)
PKG+=(pipewire-alsa pipewire-pulse pipewire-jack qjackctl)

##------------------------------- Multimedia related Utilities and Apps

PKG+=(imv)              # Image viewer for Wayland and X11
PKG+=(jpegoptim oxipng) # Compression tools
PKG+=(mpd mpc ncmpcpp)  # Music player daemon
PKG+=(easyeffects)      # Audio Effects for Pipewire applications
PKG+=(pamixer)          # Pulseaudio command-line mixer
PKG+=(qpwgraph)         # PipeWire Graph Qt GUI Interface
PKG+=(pavucontrol)      # PulseAudio Volume Control
PKG+=(mediainfo)        # Supplies technical and tag information about a video or audio file (CLI interface)
PKG+=(mpv)              # a free, open source, and cross-platform media player
PKG+=(songrec)          # An open-source, unofficial Shazam client for Linux
# PKG+=(soundconverter)   # A simple sound converter application for GNOME
# PKG+=(lmms)             # The Linux MultiMedia Studio

#############################################-- Miscellaneous utilities
##------------------------------------------------------ Ethernet stuff

PKG+=(openvpn dnscrypt-proxy dnsmasq openresolv)
PKG+=(syncthing)    # file synchronization client/server application
PKG+=(nm-connection-editor)    # NetworkManager GUI connection editor and widgets
PKG+=(blueman)      # GTK+ Bluetooth Manager

##------------------------------------------------------- File managing

PKG+=(thunar)
PKG+=(thunar-volman thunar-archive-plugin thunar-media-tags-plugin ffmpegthumbnailer tumbler)
PKG+=(udiskie)      # Removable disk automounter using udisks
PKG+=(fuseiso)      # FuseISO is a FUSE module to let unprivileged users mount ISO filesystem images
PKG+=(gvfs-mtp)     # Virtual filesystem implementation
PKG+=(xarchiver)    # Create and modify archives
PKG+=(p7zip)        # 7z support
PKG+=(handlr)       # Powerful alternative to xdg-utils (managing mime types)
PKG+=(trash-cli)    # Command line trashcan (recycle bin) interface

##--------------------------------------------------- Language spelling

PKG+=(hunspell hunspell-en_us hunspell-ru enchant gspell)

##----------------------------------------------------------------- OCR

PKG+=(tesseract tesseract-data-eng tesseract-data-rus gimagereader-gtk)

##-------------------------------------------------------------- Others

PKG+=(alacritty)        # terminal
PKG+=(mate-polkit)      # graphical authentication agent
PKG+=(dunst)            # Customizable and lightweight notification-daemon
PKG+=(zerotier-one)     # Creates virtual Ethernet networks of almost unlimited size
PKG+=(yt-dlp)
PKG+=(qrencode)
PKG+=(tlp)              # Linux Advanced Power Management

################################################-- Themes, icons, fonts
##--------------------------------------------------------------- Theme

PKG+=(kvantum lxappearance-gtk3)
PKG+=(breeze-icons)

##--------------------------------------------------------------- Fonts

PKG+=(ttf-dejavu)
PKG+=(ttf-jetbrains-mono)
PKG+=(ttf-jetbrains-mono-nerd)
PKG+=(ttf-liberation)       # Font family which aims at metric compatibility with Arial, Times New Roman, and Courier New
# PKG+=(ttc-iosevka-ss14)     # JetBrains Mono Style
# PKG+=(ttc-iosevka-aile)     # Sans style
# PKG+=(ttc-iosevka-etoile)   # Serif style
# PKG+=(ttf-iosevka-nerd)
PKG+=(unicode-emoji noto-fonts noto-fonts-cjk noto-fonts-emoji)

################################################################-- Apps

PKG+=(libreoffice-fresh)
PKG+=(qbittorrent)
PKG+=(keepassxc)
PKG+=(gthumb)               # Image browser and viewer
PKG+=(zathura zathura-djvu zathura-pdf-mupdf)
fi

# Wine
# pacman -S wine-staging winetricks gamemode lib32-gamemode
# pacman -S --asdeps --needed $(pacman -Si wine-staging | sed -n '/^Opt/,/^Conf/p' | sed '$d' | sed 's/^Opt.*://g' | sed 's/^\s*//g' | tr '\n' ' ')
