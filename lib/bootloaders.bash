#!/usr/bin/env bash
################################################################-- GRUB
# https://wiki.archlinux.org/title/GRUB

bootloader-grub ()
{
    trap "readonly STATUS_BOOTLOADER=error" ERR
    log "Begining the grub's installation"

    pacstrap /mnt grub efibootmgr

    rm -rf /mnt/"${ESP:?}"/*
    if $ENABLE_FULL_DRIVE_ENCRYPTION; then
        # https://wiki.archlinux.org/title/GRUB#LUKS2
        if [[ $(cryptsetup luksDump "$DRIVE$P2" | grep "PBKDF" | awk '{print $NF}') != "pbkdf2" ]]; then
            log "Changing the hash and PBDKDF algorithms"
            echo "$PASSPHRASE_FOR_ENCRYPTION" | cryptsetup luksConvertKey --hash sha256 --pbkdf pbkdf2 "$DRIVE$P2"
        fi

        log "Installing grub"
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory="$ESP" --modules="luks2 part_gpt cryptodisk gcry_rijndael pbkdf2 gcry_sha256 ext2" --removable

        local uuid uuid_tr
        uuid=$(blkid -s UUID -o value "$DRIVE$P2")
        uuid_tr=$(echo "$uuid" | tr -d -)

        KERNEL_PARAMS+=(cryptdevice=UUID="$uuid":root root=/dev/mapper/root)

        sed -Ei "s|^#?GRUB_ENABLE_CRYPTODISK=.*|GRUB_ENABLE_CRYPTODISK=y|" /mnt/etc/default/grub

        {
            echo "cryptomount -u $uuid_tr"
            echo "set root=crypto0"
            echo "set prefix=(\$root)/boot/grub"
            echo "insmod normal"
            echo -e "normal\n"
        } > /mnt/grub-pre.cfg

        log "Creating .efi image"
        arch-chroot /mnt grub-mkimage -p /boot/grub -O x86_64-efi -c /grub-pre.cfg -o /grubx64.efi luks2 part_gpt cryptodisk gcry_rijndael pbkdf2 gcry_sha256 ext2
        arch-chroot /mnt install -v /grubx64.efi "$ESP"/EFI/BOOT/BOOTX64.EFI
        rm /mnt/grub-pre.cfg /mnt/grubx64.efi
    else
        log "Installing grub"
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory="$ESP" --removable
        arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory="$ESP" --bootloader-id=Arch
    fi

    log "Configuring grub"
    sed -Ei "s|^#?GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"nowatchdog ${KERNEL_PARAMS[*]}\"|" /mnt/etc/default/grub
    sed -Ei "s|^#?GRUB_GFXMODE=.*|GRUB_GFXMODE=1920x1080x24,1280x1024x24,auto|" /mnt/etc/default/grub
    sed -Ei "s|^#?GRUB_GFXPAYLOAD_LINUX=.*|GRUB_GFXPAYLOAD_LINUX=keep|" /mnt/etc/default/grub
    sed -Ei "s|^#?GRUB_DISABLE_SUBMENU=.*|GRUB_DISABLE_SUBMENU=y|" /mnt/etc/default/grub
    sed -Ei "s|^#?GRUB_DEFAULT=.*|GRUB_DEFAULT=saved|" /mnt/etc/default/grub
    sed -Ei "s|^#?GRUB_SAVEDEFAULT=.*|GRUB_SAVEDEFAULT=true|" /mnt/etc/default/grub
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

################################################-- Unified kernel image
# https://wiki.archlinux.org/title/Unified_kernel_image

bootloader-unified-kernel-image ()
{
    trap "readonly STATUS_BOOTLOADER=error" ERR
    log "Creating Unified Kernel Image"

    pacstrap /mnt efibootmgr

    [[ ! -r "/mnt/etc/mkinitcpio.d/linux.preset.backup" ]] && mv /mnt/etc/mkinitcpio.d/linux.preset /mnt/etc/mkinitcpio.d/linux.preset.backup

    log "Creating linux preset for mkinitcpio"
    {
        echo "ALL_config=\"/etc/mkinitcpio.conf\""
        echo "ALL_kver=\"/boot/vmlinuz-linux\""

        echo "PRESETS=('default')"
        # echo "PRESETS=('default' 'fallback')"

        echo "default_image=\"/boot/initramfs-linux.img\""
        echo "default_uki=\"$ESP/EFI/BOOT/bootx64.efi\""

        # echo "fallback_image=\"/boot/initramfs-linux-fallback.img\""
        # echo "fallback_efi_image=\"$ESP/EFI/Linux/linux-fallback.efi\""
        # echo "fallback_options=\"-S autodetect\""
    } > /mnt/etc/mkinitcpio.d/linux.preset

    log "Creating linux-zen preset for mkinitcpio"
    cp -f /mnt/etc/mkinitcpio.d/linux.preset /mnt/etc/mkinitcpio.d/linux-zen.preset
    sed -i "s|linux|linux-zen|" /mnt/etc/mkinitcpio.d/linux-zen.preset

    local uuid root_params
    uuid=$(blkid -s UUID -o value "$DRIVE$P2")
    root_params="root=UUID=$uuid"
    if $ENABLE_FULL_DRIVE_ENCRYPTION; then
        root_params="cryptdevice=UUID=$uuid:root root=/dev/mapper/root"
    fi

    log "Applying kernel parameters"
    echo "$root_params rw bgrt_disable nowatchdog ${KERNEL_PARAMS[*]}" > /mnt/etc/kernel/cmdline

    rm -rf /mnt/"${ESP:?}"/*
    mkdir -p /mnt/"$ESP"/EFI/Arch
    mkdir -p /mnt/"$ESP"/EFI/BOOT

    log "Starting mkinitcpio"
    arch-chroot /mnt mkinitcpio -p linux

    log "Creating UEFI boot entry"
    local model
    model=$(lsblk --output=MODEL --noheadings --ascii "$DRIVE" | tr -d '\n')
    arch-chroot /mnt efibootmgr --create --disk "$DRIVE" --part 1 --label "Arch ($model)" --loader "EFI\BOOT\bootx64.efi" --verbose
}
