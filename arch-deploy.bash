#!/usr/bin/env bash
# These variables one may change if not going to use options
# {{{ User-defined variables
# If empty the user will not be created
USER="alex"

HOST_NAME="arch"

# What group of packages to install
# Options: minimal | full
SETUP="full"

# What Display server and corresponding desktop utils to install
# Only works if SETUP == "full"
# Options: X | Wayland
DISPLAY_SERVER="X"

# Bootloader:
# Options: grub | UKI (Unified kernel image)
# If empty the Bootloader will not be installed
BOOTLOADER="UKI"

# If empty timezone will not be set
# It appends path to /usr/share/zoneinfo/ to symlink with /etc/localtime
TIMEZONE="Europe/Berlin"

# Will be used by reflector
MIRRORLIST="Germany,Netherlands,Poland"

# Will create a swap file as /swapfile with the size equal to the size of RAM
ENABLE_SWAP_FILE=false

# dm-crypt with LUKS
ENABLE_FULL_DRIVE_ENCRYPTION=false

# At the end of installation it will be used for cloning the provided repo
# If empty this will be ignored
GITCLONE="https://github.com/kisuryoza/dots"

ESP="/boot/efi"
STAGE="fresh"
# }}}

# These are global variables
# {{{ Script-defined variables
SCRIPT_PATH=$(realpath -s "${BASH_SOURCE[0]}")
SCRIPT_NAME=$(basename "$SCRIPT_PATH")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

readonly SCRIPT_PATH SCRIPT_NAME SCRIPT_DIR ESP
declare -a PKG MODULES HOOKS FILES KERNEL_PARAMS
# }}}

cd "$SCRIPT_DIR" || exit 1
source ./lib/helper-fn.bash
source ./lib/bootloaders.bash
source ./lib/partitioning.bash

# {{{ install packages
function install_packages {
    log "Installing packages"

    if ! pacstrap /mnt "${PKG[@]}"; then
        log "Problems with ethernet connection." err
        local answer
        read -rp "Shall we resume downloading? y/n " answer
        echo
        if [[ "$answer" == "y" ]]; then
            install_packages
        fi
    fi
}
# }}}

# {{{ swap
# References:
# https://wiki.archlinux.org/title/Power_management/Suspend_and_hibernate
function deploy_swap {
    trap "readonly STATUS_SWAP=error" ERR

    if $ENABLE_SWAP_FILE; then
        log "Creating a swap file"

        local swap_file_size
        swap_file_size=$(awk -F: '/MemTotal/ {print $2}' /proc/meminfo | sed -E "s|[^0-9]||g")
        dd if=/dev/zero of=/mnt/swapfile bs=1M count="$swap_file_size"kB status=progress
        arch-chroot /mnt chmod 0600 /swapfile
        arch-chroot /mnt mkswap -U clear /swapfile
        HOOKS+=(resume)
        {
            echo -e "\n#Swapfile"
            echo "/swapfile none swap defaults 0 0"
        } >>/mnt/etc/fstab

        # See the reference
        SWAP_DEVICE=$(findmnt -no UUID -T /mnt/swapfile)
        SWAP_FILE_OFFSET=$(filefrag -v /mnt/swapfile | awk '$1=="0:" {print substr($4, 1, length($4)-2)}')
        KERNEL_PARAMS+=(resume="$SWAP_DEVICE" resume_offset="$SWAP_FILE_OFFSET")
    fi
}
# }}}

# {{{ localtime
function deploy_localtime {
    trap "readonly STATUS_LOCALTIME=error" ERR
    log "Configuring localtime"
    [[ -n "$TIMEZONE" ]] && arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    arch-chroot /mnt hwclock --systohc
}
# }}}

# {{{ localization
function deploy_localization {
    trap "readonly STATUS_LOCALIZATION=error" ERR
    log "Configuring localization"
    sed -Ei "s|^#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|" /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    {
        echo "LANG=en_US.UTF-8"
        echo "LC_ALL=en_US.UTF-8"
    } >/mnt/etc/locale.conf
}
# }}}

# {{{ network
# References:
# https://bbs.archlinux.org/viewtopic.php?id=250604
# https://wiki.archlinux.org/title/Iwd#No_DHCP_in_AP_mode
function deploy_network {
    trap "readonly STATUS_NETWORK=error" ERR
    log "Network configuration"
    echo "$HOST_NAME" >/mnt/etc/hostname
    {
        echo "127.0.0.1        localhost"
        echo "::1              localhost"
        echo "127.0.1.1        $HOST_NAME"
    } >/mnt/etc/hosts
    arch-chroot /mnt systemctl enable NetworkManager.service
    if [[ -x /mnt/usr/bin/nft ]]; then
        arch-chroot /mnt systemctl enable nftables.service
    fi
}
# }}}

# {{{ apparmor
function deploy_apparmor {
    if [[ -x /mnt/usr/bin/aa-status ]]; then
        KERNEL_PARAMS+=(lsm=landlock,lockdown,yama,integrity,apparmor,bpf)
        arch-chroot /mnt systemctl enable apparmor.service
    fi
}
# }}}

# {{{ users
function deploy_users {
    trap "readonly STATUS_USERS=error" ERR
    log "Setting root password"
    arch-chroot /mnt /bin/bash -c "echo root:$ROOT_PASSWORD | chpasswd" || log "Error - root password" err

    if [[ -n "$USER" ]]; then
        log "Creating user $USER"
        arch-chroot /mnt useradd --create-home --groups wheel "$USER" || log "Error - user" err

        if [[ -n "$USER_PASSWORD" ]]; then
            log "Setting user password"
            arch-chroot /mnt /bin/bash -c "echo $USER:$USER_PASSWORD | chpasswd" || log "Error - user password" err
        else
            arch-chroot /mnt passwd -d "$USER"
        fi
    fi

    if [[ -x /mnt/usr/bin/doas ]]; then
        log "Configuring doas"
        {
            echo "permit nopass root"
            echo -e "permit :wheel\n"
        } >/mnt/etc/doas.conf
        arch-chroot /mnt chmod -c 0400 /etc/doas.conf
        arch-chroot /mnt ln -sf /usr/bin/doas /usr/bin/sudo
    else
        sed -Ei "s|^#?%wheel ALL=(ALL:ALL) ALL|%wheel ALL=(ALL:ALL) ALL|" /mnt/etc/sudoers
    fi
}
# }}}

# {{{ initramfs
# References:
# https://wiki.archlinux.org/title/improving_performance#Watchdogs
function deploy_initramfs {
    trap "readonly STATUS_INITRAMFS=error" ERR
    log "Generating initramfs images"

    # See the reference
    {
        echo "# Do not load watchdogs module for increasing perfomance"
        echo "blacklist iTCO_wdt"
    } >/mnt/etc/modprobe.d/nowatchdog.conf
    FILES+=(/etc/modprobe.d/nowatchdog.conf)

    if $ENABLE_FULL_DRIVE_ENCRYPTION; then
        HOOKS+=(encrypt)
        MODULES+=(dm_crypt)
    fi

    [[ -n "$MODULES" ]] && sed -Ei "s|^MODULES=.*|MODULES=(${MODULES[*]})|" /mnt/etc/mkinitcpio.conf
    [[ -n "$FILES" ]] && sed -Ei "s|^FILES=.*|FILES=(${FILES[*]})|" /mnt/etc/mkinitcpio.conf
    [[ -n "$HOOKS" ]] && sed -Ei "s|^HOOKS=.*|HOOKS=(${HOOKS[*]})|" /mnt/etc/mkinitcpio.conf
    if [[ -x /usr/bin/lz4 ]]; then
        sed -Ei "s|^#COMPRESSION=\"lz4\"|COMPRESSION=\"lz4\"|" /mnt/etc/mkinitcpio.conf
        sed -Ei "s|^#COMPRESSION_OPTIONS=.*|COMPRESSION_OPTIONS=(-9)|" /mnt/etc/mkinitcpio.conf
    fi

    arch-chroot /mnt mkinitcpio -p linux
}
# }}}

# {{{ dotfiles
function deploy_dotfiles {
    trap "readonly STATUS_DOTFILES=error" ERR
    if [[ -n "$GITCLONE" && -n "$USER" ]]; then
        log "Cloning dot-files"
        cd /mnt/home/"$USER" || return
        git clone "$GITCLONE"
        arch-chroot /mnt chown "$USER":"$USER" -R "/home/$USER"
    fi
}
# }}}

# {{{ unmount
function deploy_unmount {
    log "Unmounting /mnt"
    sleep 3
    umount -lR /mnt || log "Error - Failed to umount /mnt" err
    if $ENABLE_FULL_DRIVE_ENCRYPTION; then
        # from here it refuses to close because "Device root is still in use."
        log "Close encrypted partition with: cryptsetup close root" warn
    fi
}
# }}}

# {{{ errors
function check_errors {
    [[ "$STATUS_LOCALTIME" == "error" ]] && log "Errors acquired during Localtime configuration." err
    [[ "$STATUS_LOCALIZATION" == "error" ]] && log "Errors acquired during Localization configuration." err
    [[ "$STATUS_NETWORK" == "error" ]] && log "Errors acquired during Network configuration." err
    [[ "$STATUS_USERS" == "error" ]] && log "Errors acquired during Creating user and setting passwords." err
    [[ "$STATUS_SWAP" == "error" ]] && log "Errors acquired during Creating a swap file." err
    [[ "$STATUS_INITRAMFS" == "error" ]] && log "Errors acquired during Generating of initramfs images." err
    [[ "$STATUS_DOTFILES" == "error" ]] && log "Errors acquired during Cloning dot-files." err
    [[ "$STATUS_BOOTLOADER" == "error" ]] && log "Errors acquired during Installation of the bootloader." err
}
# }}}

function deploy_init {
    summary

    log "Testing ethernet connection"
    ping archlinux.org -c 2 &>/dev/null || log "No ethernet connection. Aborting." err 1

    log "Updating the system clock"
    timedatectl set-ntp true

    if $ENABLE_FULL_DRIVE_ENCRYPTION; then
        drive-preparation
        partitioning
        formatting-crypt
    else
        partitioning
        formatting
    fi

    log "Generating fstab"
    genfstab -U /mnt >/mnt/etc/fstab

    sed -Ei 's|^#?Color|Color|' /etc/pacman.conf
    sed -Ei "s|^#?ParallelDownloads.*|ParallelDownloads = 3|" /etc/pacman.conf

    source ./lib/package-list.bash
    check_cpu
    [[ "$SETUP" == "full" ]] && check_gpu
    install_packages

    source /mnt/etc/mkinitcpio.conf
    deploy_swap
    deploy_localtime
    deploy_localization
    deploy_network
    deploy_apparmor
    deploy_users
    deploy_initramfs
    deploy_bootloader
    deploy_dotfiles

    sed -Ei 's|^#?UseSyslog|UseSyslog|' /mnt/etc/pacman.conf
    sed -Ei 's|^#?Color|Color|' /mnt/etc/pacman.conf
    sed -Ei 's|^#?VerbosePkgLists|VerbosePkgLists|' /mnt/etc/pacman.conf
    sed -Ei 's|^#?ParallelDownloads.*|ParallelDownloads = 3|' /mnt/etc/pacman.conf
    sed -zi 's|#\[multilib\]\n#Include = \/etc\/pacman.d\/mirrorlist|\[multilib\]\nInclude = \/etc\/pacman.d\/mirrorlist|' /mnt/etc/pacman.conf

    arch-chroot /mnt systemctl enable archlinux-keyring-wkd-sync.timer

    if [[ -x /mnt/usr/bin/zsh ]]; then
        log "Making zsh the default shell"
        arch-chroot /mnt chsh -s /usr/bin/zsh
        arch-chroot /mnt chsh "$USER" -s /usr/bin/zsh
        echo 'ZDOTDIR="$HOME"/.config/zsh' >>/mnt/etc/zsh/zshenv
    fi

    check_errors
    deploy_unmount
    log "Looks like everything is done." warn
}

# {{{ Option parser
LONG_OPTS=help,stage:,user:,hostname:,setup:,display:,bootloader:,swap,encryption
SHORT_OPTS=S:u:h:g:d:b:se
PARSED=$(getopt --options ${SHORT_OPTS} \
    --longoptions ${LONG_OPTS} \
    --name "$0" \
    -- "$@")
eval set -- "${PARSED}"

while true; do
    case "$1" in
    --help)
        help
        ;;
    -S | --stage)
        STAGE="$2"
        shift 2
        ;;
    -u | --user)
        USER="$2"
        shift 2
        ;;
    -h | --hostname)
        HOST_NAME="$2"
        shift 2
        ;;
    -g | --setup)
        SETUP="$2"
        shift 2
        ;;
    -d | --display)
        DISPLAY_SERVER="$2"
        shift 2
        ;;
    -b | --bootloader)
        BOOTLOADER="$2"
        shift 2
        ;;
    -s | --swap)
        ENABLE_SWAP_FILE=true
        shift
        ;;
    -e | --encryption)
        ENABLE_FULL_DRIVE_ENCRYPTION=true
        shift
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Error while was passing the options"
        help
        ;;
    esac
done
# }}}

if [[ $# -ne 1 ]]; then
    log "A single input file is required" err
    help
else
    readonly DRIVE="$1"
    ExtendDriveName "$DRIVE"
fi

# This is where installation begins
case $STAGE in
"fresh") deploy_init ;;
"bootloader")
    deploy_bootloader
    deploy_unmount
    check_errors
    ;;
*)
    log "Wrong options." err
    help
    ;;
esac

# vim: foldmethod=marker foldlevel=0 foldlevelstart=0
