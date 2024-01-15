# Partition the Drive
function partitioning {
    trap "readonly STATUS_PARTITIONING=error" ERR
    log "Partitioning the drive"

    log "Clearing existing partition tables"
    sgdisk "$DRIVE" -Z
    if check_uefi; then
        log "Partitioning 512M for EFI and the rest for Linux"
        sgdisk "$DRIVE" --align-end --new=1:0:+512M --typecode=1:ef00 --largest-new=2
    else
        log "Partitioning 512M for BIOS and the rest for Linux"
        sgdisk "$DRIVE" --align-end --new=1:0:+512M --typecode=1:ef02 --largest-new=2
    fi
    log "Partition table:"
    sgdisk "$DRIVE" -p

    [[ "$STATUS_PARTITIONING" == "error" ]] && log "Errors acquired during Partitioning the drive." err 1
}

# Non-Crypt
## Format and Mount the Partitions
function formatting {
    trap "readonly STATUS_FORMATING=error" ERR
    log "Formatting the partitions (non-crypt)"
    yes | mkfs.fat -F 32 "$DRIVE$P1"
    yes | mkfs.ext4 "$DRIVE$P2"

    log "Mounting the partitions"
    mount "$DRIVE$P2" /mnt
    mkdir -p /mnt"$ESP"
    mount "$DRIVE$P1" /mnt"$ESP"

    [[ "$STATUS_FORMATING" == "error" ]] && log "Errors acquired during Formatting the partitions (non-crypt)." err 1
}

# Crypt
## Securely wipe the drive before Partitioning and Encrypting the drive
# References:
# https://wiki.archlinux.org/title/Dm-crypt/Drive_preparation
function drive-preparation {
    log "Creating a temporary encrypted container on the drive"
    echo "YES" | cryptsetup open --type plain --key-file /dev/urandom "$DRIVE" to_be_wiped || exit 1
    log "Wiping it"
    dd if=/dev/zero of=/dev/mapper/to_be_wiped bs=1M status=progress
    log "Closing the container"
    cryptsetup close to_be_wiped
}

## Format and Mount the Partitions
function formatting-crypt {
    trap "readonly STATUS_FORMATTING_CRYPT=error" ERR
    log "Formatting the partitions (crypt)"

    yes | mkfs.fat -F 32 "$DRIVE$P1"

    log "Formatting LUKS partitions"
    echo "$PASSPHRASE_FOR_ENCRYPTION" | cryptsetup --verbose luksFormat "$DRIVE$P2"
    log "Unlocking/Mapping LUKS partitions with the device mapper"
    if [[ "$DRIVE" == *"nvme"* ]]; then
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

    [[ "$STATUS_FORMATTING_CRYPT" == "error" ]] && log "Errors acquired during Formatting the partitions (crypt)." err 1
}

# References:
# https://wiki.archlinux.org/title/Dm-crypt/Device_encryption#Encrypting_devices_with_cryptsetup
# https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition
# https://wiki.archlinux.org/title/Dm-crypt/Specialties#Disable_workqueue_for_increased_solid_state_drive_(SSD)_performance
