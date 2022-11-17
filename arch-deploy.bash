#!/usr/bin/env bash
##################################################### User-defined variables
ROOT_PASSWORD="root"
# If empty the user will not be created
USER="alex"
# If empty the password will not be created
USER_PASSWORD=""

HOST_NAME="arch"

# What group of packages to install
# Options: full | minimal
SETUP="minimal"

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

# Will create a swap file in the root directory
ENABLE_SWAP_FILE="no"
SWAP_FILE_SIZE=16 # GiB

# dm-crypt with LUKS
ENABLE_FULL_DRIVE_ENCRYPTION="no"
PASSPHRASE_FOR_ENCRYPTION=""

# Will prefer package cache on the host
IS_INSTALLING_FROM_EXISTING_ARCH="no"

# At the end of installation it will be used for cloning the provided repo
# and installing its content through GNU util "stow"
# If empty this will be ignored
GITCLONE="https://gitlab.com/justAlex0/dot-files"
############################################################################

SCRIPT_PATH=$(realpath -s "${BASH_SOURCE[0]}")
SCRIPT_NAME=$(basename "$SCRIPT_PATH")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

DRIVE="$1"

ESP="/boot/efi"

readonly SCRIPT_PATH SCRIPT_NAME SCRIPT_DIR DRIVE ESP
declare -a PACSTRAP_OPTIONS PKG AUR_PKG MODULES KERNEL_PARAMS

source "$SCRIPT_DIR"/.package-list.bash

help ()
{
    printf "The script installs Arch Linux

Usage:
    %s <drive> [OPTIONS]

Options:
    -s, --stage     Specify the stage of installing.
                    init|boot
                    default: init
" "$SCRIPT_NAME"
}

$DEBUG && set +ux
BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
ESC=$(tput sgr0)
readonly BOLD RED GREEN YELLOW BLUE ESC
$DEBUG && set -ux

log ()
{
    $DEBUG && set +ux
    case "$2" in
        "err")
            printf "%s[%s]%s\n" "${BOLD}${RED}" "$1" "${ESC}" >&2
            ;;
        "warn")
            printf "%s[%s]%s\n" "${BOLD}${YELLOW}" "$1" "${ESC}"
            ;;
        *)
            printf "%s[%s]%s\n" "${BOLD}${GREEN}" "$1" "${ESC}"
            ;;
    esac
    $DEBUG && set -ux
}

if lsblk --nodeps --noheadings --paths --raw --output NAME | grep -x "$DRIVE" &> /dev/null; then
    case $DRIVE in
        *"sd"* | *"vd"* )
            P1="1"
            P2="2"
            #P3="3"
            ;;
        *"nvme"* )
            P1="p1"
            P2="p2"
            #P3="p3"
            ;;
        * )
            log "Only HDD or SSD. Aborting." err
            help
            exit 1
            ;;
    esac
    readonly P1 P2
else
    log "Wrong \"$1\" drive. Aborting." err
    help
    exit 1
fi

summary ()
{
    if ! check-uefi; then
        if [[ "$BOOTLOADER" != "grub" ]]; then
            log "UEFI is not supported." err
            log "Grub will be installed instead." warn
            BOOTLOADER="grub"
            [ "$ENABLE_FULL_DRIVE_ENCRYPTION" == "yes" ] && log "BIOS + grub + full drive encryption is not supported in this script because I personally would never use this combination and so I didnt want to spend more time on it" err && exit 1
        fi
    fi
    if [[ -z "$TIMEZONE" ]]; then
        log "Timezone is not provided. \"UTC\" will be used." err
        TIMEZONE="UTC"
    fi

    echo "Summary:"
    echo "                       Drive: [${BOLD}${YELLOW}${DRIVE}${ESC}]"
    echo "                        User: [${YELLOW}${USER}${ESC}]"
    echo "                   Host name: [${YELLOW}${HOST_NAME}${ESC}]"
    echo "               Root password: [${YELLOW}${ROOT_PASSWORD}${ESC}]"
    echo "               User password: [${YELLOW}${USER_PASSWORD}${ESC}]"
    echo "                       Setup: [${YELLOW}${SETUP}${ESC}]"
    echo "              Display Server: [${YELLOW}${DISPLAY_SERVER}${ESC}]"
    echo "                  Bootloader: [${YELLOW}${BOOTLOADER}${ESC}]"
    echo "                    Timezone: [${YELLOW}${TIMEZONE}${ESC}]"
    echo "                  Mirrorlist: [${YELLOW}${MIRRORLIST}${ESC}]"
    echo "            Enable swap file: [${YELLOW}${ENABLE_SWAP_FILE}${ESC}]"
    echo "              Swap file size: [${YELLOW}${SWAP_FILE_SIZE}${ESC}]"
    echo "Enable full drive encryption: [${YELLOW}${ENABLE_FULL_DRIVE_ENCRYPTION}${ESC}]"
    echo "   Passphrase for encryption: [${YELLOW}${PASSPHRASE_FOR_ENCRYPTION}${ESC}]"
    echo "         Repository to clone: [${YELLOW}${GITCLONE}${ESC}]"

    [ -z "$ROOT_PASSWORD" ] && log "Root password is a must." err && exit 1
    [[ "$ENABLE_FULL_DRIVE_ENCRYPTION" == "yes" && -z "$PASSPHRASE_FOR_ENCRYPTION" ]] && log "Passphrase for drive encryption is a must." err && exit 1

    local answer
    read -rp "Continue? y/n " answer
    [ "$answer" == "y" ] || exit 1

    readonly DRIVE USER HOST_NAME ROOT_PASSWORD USER_PASSWORD SETUP BOOTLOADER TIMEZONE MIRRORLIST
    readonly ENABLE_SWAP_FILE SWAP_FILE_SIZE ENABLE_FULL_DRIVE_ENCRYPTION PASSPHRASE_FOR_ENCRYPTION
    readonly GITCLONE
}

source "$SCRIPT_DIR"/.bootloaders.bash
deploy-bootloader ()
{
    if [[ -n "$BOOTLOADER" ]]; then
        case "$BOOTLOADER" in
            "grub")
                bootloader-grub
                ;;
            "UKI")
                bootloader-unified-kernel-image
                ;;
        esac
    fi
}

check-uefi ()
{
    [ -d /sys/firmware/efi/ ]
}

check-cpu ()
{
    local CPU_VENDOR
    CPU_VENDOR=$(awk -F ": " '/vendor_id/ {print $NF; exit}' /proc/cpuinfo)
    case "$CPU_VENDOR" in
        "GenuineIntel" )
            PKG+=(intel-ucode)
            ;;
        "AuthenticAMD" )
            PKG+=(amd-ucode)
            ;;
    esac
}

check-gpu ()
{
    local GRAPHICS
    GRAPHICS=$(lspci -v | grep -A1 -e VGA -e 3D)
    case ${GRAPHICS^^} in
        *NVIDIA* )
            PKG+=(linux-headers)
            [[ "$SETUP" == "full" ]] && PKG+=(linux-zen-headers)
            PKG+=(nvidia-dkms nvidia-utils nvidia-settings)
            PKG+=(vulkan-icd-loader)
            PKG+=(nvtop)
            MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
            ;;
        *AMD* | *ATI* )
            PKG+=(xf86-video-amdgpu xf86-video-ati libva-mesa-driver vulkan-radeon)
            PKG+=(vulkan-icd-loader)
            PKG+=(nvtop)
            ;;
        *INTEL* )
            PKG+=(libva-intel-driver intel-media-driver vulkan-intel)
            PKG+=(vulkan-icd-loader)
            ;;
    esac
}

partitioning ()
{
    trap "readonly PARTITIONING_STATUS=error" ERR
    log "Partitioning the drive"

    log "Clearing existing partition tables"
    sgdisk "$DRIVE" -Z
    if check-uefi; then
        log "Partitioning 256M for EFI and the rest for Linux"
        sgdisk "$DRIVE" --align-end --new=1:0:+256M --typecode=1:ef00 --largest-new=2
    else
        log "Partitioning 256M for BIOS and the rest for Linux"
        sgdisk "$DRIVE" --align-end --new=1:0:+256M --typecode=1:ef02 --largest-new=2
    fi
    log "Partition table:"
    sgdisk "$DRIVE" -p

    [ "$PARTITIONING_STATUS" == "error" ] && log "Errors acquired during Partitioning the drive." err && exit 1
}

formatting ()
{
    trap "readonly FORMATTING_STATUS=error" ERR
    log "Formatting the partitions (non-crypt)"
    yes | mkfs.fat -F 32 "$DRIVE$P1"
    yes | mkfs.ext4 "$DRIVE$P2"

    log "Mounting the partitions"
    mount "$DRIVE$P2" /mnt
    mkdir -p /mnt"$ESP"
    mount "$DRIVE$P1" /mnt"$ESP"

    [ "$FORMATTING_STATUS" == "error" ] && log "Errors acquired during Formatting the partitions (non-crypt)." err && exit 1
}

drive-preparation ()
{
    trap "readonly WIPING_STATUS=error" ERR

    log "Creating a temporary encrypted container on the drive"
    echo "YES" | cryptsetup open --type plain --key-file /dev/urandom "$DRIVE" to_be_wiped || exit 1
    log "Wiping it"
    dd if=/dev/zero of=/dev/mapper/to_be_wiped bs=1M status=progress
    log "Closing the container"
    cryptsetup close to_be_wiped

    [ "$WIPING_STATUS" == "error" ] && log "Errors acquired during Wiping the drive." err && exit 1
}

formatting-crypt ()
{
    trap "readonly FORMATTING_CRYPT_STATUS=error" ERR
    log "Formatting the partitions (crypt)"

    yes | mkfs.fat -F 32 "$DRIVE$P1"

    log "Formatting LUKS partitions"
    echo "$PASSPHRASE_FOR_ENCRYPTION" | cryptsetup --verbose luksFormat "$DRIVE$P2"
    log "Unlocking/Mapping LUKS partitions with the device mapper"
    if [[ "$DRIVE" == *"nvme"*  ]]; then
        # See the reference
        echo "$PASSPHRASE_FOR_ENCRYPTION" | cryptsetup --perf-no_read_workqueue --perf-no_write_workqueue --persistent open "$DRIVE$P2" root
    else
        echo "$PASSPHRASE_FOR_ENCRYPTION" | cryptsetup open "$DRIVE$P2" root
    fi
    yes | mkfs.ext4 /dev/mapper/root

    log "Mounting the partitions"
    mount /dev/mapper/root /mnt
    mkdir -p /mnt"$ESP"
    mount "$DRIVE$P1" /mnt"$ESP"

    [ "$FORMATTING_CRYPT_STATUS" == "error" ] && log "Errors acquired during Formatting the partitions (crypt)." err && exit 1
}

deploy-localtime ()
{
    trap "readonly LOCALTIME_STATUS=error" ERR
    log "Configuring localtime"
    [ -n "$TIMEZONE" ] && arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$TIMEZONE" /etc/localtime
    arch-chroot /mnt hwclock --systohc
}

deploy-localization ()
{
    trap "readonly LOCALIZATION_STATUS=error" ERR
    log "Configuring localization"
    sed -Ei "s|^#en_US.UTF-8 UTF-8|en_US.UTF-8 UTF-8|" /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    {
        echo "LANG=en_US.UTF-8"
        echo "LC_ALL=en_US.UTF-8"
    } > /mnt/etc/locale.conf
}

deploy-network ()
{
    trap "readonly NETWORK_STATUS=error" ERR
    log "Network configuration"
    echo "$HOST_NAME" > /mnt/etc/hostname
    {
        echo "127.0.0.1        localhost"
        echo "::1              localhost"
        echo "127.0.1.1        $HOST_NAME"
    } > /mnt/etc/hosts
    arch-chroot /mnt systemctl enable NetworkManager.service
    {
        echo "[device]"
        echo "wifi.scan-rand-mac-address=no"
    } > /mnt/etc/NetworkManager/NetworkManager.conf
    mkdir -p /mnt/etc/iwd
    {
        echo "[General]"
        echo "EnableNetworkConfiguration=True"
    } > /mnt/etc/iwd/main.conf
    if [[ -x /mnt/usr/bin/nft ]]; then
        arch-chroot /mnt systemctl enable nftables.service
    fi
}

deploy-apparmor ()
{
    if [[ -x /mnt/usr/bin/aa-status ]]; then
        KERNEL_PARAMS+=(lsm=landlock,lockdown,yama,integrity,apparmor,bpf)
        arch-chroot /mnt systemctl enable apparmor.service
    fi
}

deploy-users ()
{
    trap "readonly USERS_STATUS=error" ERR
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
        } > /mnt/etc/doas.conf
        arch-chroot /mnt chmod -c 0400 /etc/doas.conf
        arch-chroot /mnt ln -sf /usr/bin/doas /usr/bin/sudo
    else
        sed -Ei "s|^#?%wheel ALL=(ALL:ALL) ALL|%wheel ALL=(ALL:ALL) ALL|" /mnt/etc/sudoers
    fi
}

deploy-swap ()
{
    trap "readonly SWAP_STATUS=error" ERR
    if [[ "$ENABLE_SWAP_FILE" == "yes" ]]; then
        log "Creating a swap file"

        dd if=/dev/zero of=/mnt/swapfile bs=1M count="$SWAP_FILE_SIZE"GiB status=progress
        arch-chroot /mnt chmod 0600 /swapfile
        arch-chroot /mnt mkswap -U clear /swapfile
        arch-chroot /mnt swapon /swapfile

        {
            echo -e "\n#Swapfile"
            echo "/swapfile none swap defaults 0 0"
        } >> /mnt/etc/fstab

        sed -i "s|fsck|resume fsck|" /mnt/etc/mkinitcpio.conf

        # See the reference
        SWAP_DEVICE=$(findmnt -no UUID -T /mnt/swapfile)
        SWAP_FILE_OFFSET=$(filefrag -v /mnt/swapfile | awk '$1=="0:" {print substr($4, 1, length($4)-2)}')
        KERNEL_PARAMS+=(resume="$SWAP_DEVICE" resume_offset="$SWAP_FILE_OFFSET")
    fi
}

deploy-initramfs ()
{
    trap "readonly INITRAMFS_STATUS=error" ERR
    log "Generating initramfs images"

    # See the reference
    {
        echo "# Do not load watchdogs module for increasing perfomance"
        echo "blacklist iTCO_wdt"
    } > /mnt/etc/modprobe.d/nowatchdog.conf
    sed -Ei 's|^#?FILES=.*|FILES=(/etc/modprobe.d/nowatchdog.conf)|' /mnt/etc/mkinitcpio.conf

    if [[ "$ENABLE_FULL_DRIVE_ENCRYPTION" == "yes" ]]; then
        sed -i "s|filesystems|encrypt filesystems|" /mnt/etc/mkinitcpio.conf
        MODULES+=(dm_crypt)
    fi

    [ -n "$MODULES" ] && sed -Ei "s|^MODULES=.*|MODULES=(${MODULES[*]})|" /mnt/etc/mkinitcpio.conf
    if [[ -x /usr/bin/lz4 ]]; then
        # because lz4 is faster
        sed -Ei "s|^#COMPRESSION=\"lz4\"|COMPRESSION=\"lz4\"|" /mnt/etc/mkinitcpio.conf
        sed -Ei "s|^#COMPRESSION_OPTIONS=.*|COMPRESSION_OPTIONS=(-9)|" /mnt/etc/mkinitcpio.conf
    fi

    arch-chroot /mnt mkinitcpio -p linux
}

deploy-dotfiles ()
{
    trap "readonly DOTFILES_STATUS=error" ERR
    if [[ -n "$GITCLONE" && -n "$USER" ]]; then
        log "Cloning dot-files"
        cd /mnt/home/"$USER" && git clone "$GITCLONE"
    fi
}

deploy-unmount ()
{
    log "Unmounting /mnt"
    [ "$ENABLE_SWAP_FILE" == "yes" ] && swapoff /mnt/swapfile
    umount -R /mnt || log "Error - Failed to umount /mnt" err
    if [[ "$ENABLE_FULL_DRIVE_ENCRYPTION" == "yes" ]]; then
        log "Closing the encrypted partition"
        cryptsetup close root || log "Error - Failed to close the encrypted partition" err
    fi
}

check-errors ()
{
    [ "$LOCALTIME_STATUS" == "error" ] && log "Errors acquired during Localtime configuration." err
    [ "$LOCALIZATION_STATUS" == "error" ] && log "Errors acquired during Localization configuration." err
    [ "$NETWORK_STATUS" == "error" ] && log "Errors acquired during Network configuration." err
    [ "$USERS_STATUS" == "error" ] && log "Errors acquired during Creating user and setting passwords." err
    [ "$SWAP_STATUS" == "error" ] && log "Errors acquired during Creating a swap file." err
    [ "$INITRAMFS_STATUS" == "error" ] && log "Errors acquired during Generating of initramfs images." err
    [ "$DOTFILES_STATUS" == "error" ] && log "Errors acquired during Cloning dot-files." err
    [ "$BOOTLOADER_STATUS" == "error" ] && log "Errors acquired during Installation of the bootloader." err
}

deploy-init ()
{
    summary

    log "Testing ethernet connection"
    ping archlinux.org -c 2 &> /dev/null || log "No ethernet connection. Aborting." err || exit 1

    log "Updating the system clock"
    timedatectl set-ntp true

    if [[ "$ENABLE_FULL_DRIVE_ENCRYPTION" == "yes" ]]; then
        drive-preparation
        partitioning
        formatting-crypt
    else
        partitioning
        formatting
    fi

    if [[ "$IS_INSTALLING_FROM_EXISTING_ARCH" == "yes" ]]; then
        PACSTRAP_OPTIONS=(-c)
    else
        log "Retrieving and ranking the latest mirrorlist"
        pacman -Sy --needed --noconfirm pacman-contrib
        reflector --country "$MIRRORLIST" \
            --threads 4 \
            --latest 20 \
            --protocol http,https \
            --sort rate \
            --save /etc/pacman.d/mirrorlist.backup
        rankmirrors -n 10 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
        pacman -Syy
    fi

    log "Installing essential packages"
    sed -Ei "s|^#?ParallelDownloads.*|ParallelDownloads = 2|" /etc/pacman.conf
    pacman -S --needed --noconfirm git rsync
    check-cpu
    [ "$SETUP" == "full" ] && check-gpu
    if ! pacstrap "${PACSTRAP_OPTIONS[@]}" /mnt "${PKG[@]}"; then
        log "Errors acquired during downloading. Trying again." err
        pacstrap "${PACSTRAP_OPTIONS[@]}" /mnt "${PKG[@]}" || log "Problems with ethernet connection. Aborting." err || exit 1
    fi

    log "Generating fstab"
    genfstab -U /mnt > /mnt/etc/fstab

    deploy-localtime
    deploy-localization
    deploy-network
    deploy-apparmor
    deploy-users
    deploy-swap
    deploy-initramfs
    deploy-bootloader
    deploy-dotfiles
    deploy-unmount

    check-errors

    log "Looks like everything is done."
}

LONG_OPTS=stage:
SHORT_OPTS=s:
PARSED=$(getopt --options ${SHORT_OPTS} \
    --longoptions ${LONG_OPTS} \
    --name "$0" \
    -- "$@")
eval set -- "${PARSED}"

while true; do
    case "$1" in
        -s|--stage)
            STAGE="$2"
            shift 2
            ;;
        -h|--help)
            help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Error while was passing the options"
            help
            exit 1
            ;;
    esac
done

if [[ $# -ne 1 ]]; then
    log "A single input file is required" err
    help
    exit 1
else
    DRIVE="$1"
fi

if [[ -n "$STAGE" ]]; then
    case $STAGE in
        "init") deploy-init;;
        "boot")
            deploy-bootloader
            deploy-unmount
            check-errors
            ;;
        *)
            log "Wrong options." err
            help
            exit 1
            ;;
    esac
else
    deploy-init
fi
