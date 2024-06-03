function help {
    printf "The script installs Arch Linux

Usage:
    %s <drive> [OPTIONS]

Options:
    -S, --stage=NAME        Specify the stage of installing.
                            fresh|bootloader
                            default: fresh
    -u, --user=NAME         User name
    -h, --hostname=NAME     Host name
    -g, --setup=NAME        Group of packages
                            minimal|full
                            default: minimal
    -d, --display=NAME      Display server that will be used if --setup=full
                            X|Wayland
                            default: X
    -b, --bootloader=NAME   Bootloader to install
                            UKI|Grub
                            default: UKI
    -s, --swap              Whether to use swap file
    -e, --encryption        Whether to use full drive encryption

" "$SCRIPT_NAME"
    exit 0
}

BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
ESC=$(tput sgr0)
readonly BOLD RED GREEN YELLOW BLUE ESC

function log {
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
    if [[ -n "$3" ]]; then
        exit "$3"
    fi
}

function ExtendDriveName {
    if lsblk --nodeps --noheadings --paths --raw --output NAME | grep -x "$DRIVE" &>/dev/null; then
        case $DRIVE in
        *"sd"* | *"vd"*)
            P1="1"
            P2="2"
            #P3="3"
            ;;
        *"nvme"*)
            P1="p1"
            P2="p2"
            #P3="p3"
            ;;
        *)
            log "Only HDD or SSD. Aborting." err
            help
            ;;
        esac
        readonly P1 P2
    else
        log "Wrong \"$1\" drive. Aborting." err
        help
    fi
}

function summary {
    if ! check_uefi; then
        if [[ "$BOOTLOADER" != "grub" ]]; then
            log "UEFI is not supported." err
            log "Grub will be installed instead." warn
            BOOTLOADER="grub"
            [[ $ENABLE_FULL_DRIVE_ENCRYPTION ]] && log "BIOS + grub + full drive encryption is not supported in this script because I personally would never use this combination and so I didnt want to spend more time on it" err 1
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
    echo "                       Setup: [${YELLOW}${SETUP}${ESC}]"
    echo "              Display Server: [${YELLOW}${DISPLAY_SERVER}${ESC}]"
    echo "                  Bootloader: [${YELLOW}${BOOTLOADER}${ESC}]"
    echo "                    Timezone: [${YELLOW}${TIMEZONE}${ESC}]"
    echo "                  Mirrorlist: [${YELLOW}${MIRRORLIST}${ESC}]"
    echo "            Enable swap file: [${YELLOW}${ENABLE_SWAP_FILE}${ESC}]"
    echo "Enable full drive encryption: [${YELLOW}${ENABLE_FULL_DRIVE_ENCRYPTION}${ESC}]"
    echo "         Repository to clone: [${YELLOW}${GITCLONE}${ESC}]"

    local answer
    read -rp "Continue? y/n " answer
    echo
    [[ "$answer" != "y" ]] && exit 1

    local rpass1 rpass2
    read -srp "Enter root password" rpass1
    echo
    [[ -z "$rpass1" ]] && log "no password" err 1
    read -srp "Enter root password again" rpass2
    echo
    [[ "$rpass1" != "$rpass2" ]] && log "wrong passwords" err 1
    ROOT_PASSWORD="$rpass1"

    local upass
    read -srp "Enter user password (might be empty)" upass
    echo
    USER_PASSWORD="$upass"

    if $ENABLE_FULL_DRIVE_ENCRYPTION; then
        local epass1 epass2
        read -srp "Enter encryption password" epass1
        echo
        [[ -z "$epass1" ]] && log "no password" err 1
        read -srp "Enter encryption password again" epass2
        echo
        [[ "$epass1" != "$epass2" ]] && log "wrong passwords" err 1
        PASSPHRASE_FOR_ENCRYPTION="$epass1"
    fi

    readonly DRIVE USER HOST_NAME ROOT_PASSWORD USER_PASSWORD SETUP BOOTLOADER TIMEZONE MIRRORLIST
    readonly ENABLE_SWAP_FILE SWAP_FILE_SIZE ENABLE_FULL_DRIVE_ENCRYPTION PASSPHRASE_FOR_ENCRYPTION
    readonly GITCLONE
}

function deploy_bootloader {
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

function check_uefi {
    [ -d /sys/firmware/efi/ ]
}

function check_cpu {
    local CPU_VENDOR
    CPU_VENDOR=$(awk -F ": " '/vendor_id/ {print $NF; exit}' /proc/cpuinfo)
    case "$CPU_VENDOR" in
    "GenuineIntel")
        PKG+=(intel-ucode xf86-video-intel)
        ;;
    "AuthenticAMD")
        PKG+=(amd-ucode xf86-video-amdgpu)
        ;;
    esac
}

# References:
# https://wiki.archlinux.org/title/NVIDIA/Tips_and_tricks#Kernel_module_parameters
function check_gpu {
    local GRAPHICS
    GRAPHICS=$(lspci -v | grep -A1 -e VGA -e 3D)
    case ${GRAPHICS^^} in
    *NVIDIA*)
        PKG+=(linux-headers)
        PKG+=(nvidia-dkms nvidia-utils nvidia-settings)
        PKG+=(vulkan-icd-loader)
        MODULES+=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
        ;;
    *AMD* | *ATI*)
        PKG+=(xf86-video-ati libva-mesa-driver vulkan-radeon)
        PKG+=(vulkan-icd-loader)
        ;;
    *INTEL*)
        PKG+=(libva-intel-driver intel-media-driver vulkan-intel)
        PKG+=(vulkan-icd-loader)
        ;;
    esac
}
