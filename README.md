### Disclaimer

It's not really suited to be used for public, since there's a nicer tool called
`archinstall`. I made this script as a tool that suits my needs and deploys
the OS with my setup and configs and before it made into repositories. Also it's a part of learning howto's.

# So

A simple script for automated installation of Arch Linux.

This script basically follows the official Installation Guide from ArchWiki
but with some additions.

It can install Arch with GRUB/Unified kernel image and with non-encrypted or
encrypted root partition (dm-crypt with LUKS)

# Installation

Most likely Arch image doesn't ship ~git~ so it needs to be installed first.

```bash
pacman -Sy git
```

Then clone the repository

# Usage

```bash
./arch-deploy.bash --help
```

# TODOs

- [ ] Auto-mounting on choosing the boot stage
- [ ] Auto-figure swap size
