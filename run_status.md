# Run status on different OS


## Ubuntu 22.04
✅ OK - 2026-03-27
- ⚠️ spotify-client ignored — requires libc6 >= 2.39, Ubuntu 22.04 ships with 2.35

## Ubuntu 24.04
✅ OK - 2026-03-27

## Ubuntu 25.04
⚠️ Skipped (commented out in Vagrantfile/hosts)
- No package matching 'anki' is available

## Ubuntu 26.04
✅ OK - 2026-09-25

## Linux Mint 22.0 Wilma
⚠️ Skipped — issues with sudo apt update on start

## Linux Mint 22.2 Zara
⚠️ Skipped (commented out in Vagrantfile/hosts)

## Linux Mint 22.3 Zena
✅ OK - 2026-09-25 (docker fix: override ansible_facts.distribution_release → noble)
- ⚠️ copyq global shortcut ignored — no X server in headless VM (ignore_errors: true)
- 🛠️ wine: fixed "held broken packages" — third-party amd64-only PPA (packages.sury.org) upgraded libgd3 past the version available for i386, breaking wine-stable-i386's dependency chain; role now pins/aligns libgd3 amd64/i386 versions before installing Wine

## Debian 13.1
✅ OK - 2026-03-27
- ⚠️ anki ignored — not available on Debian 13.1 (apt_packages_private, failed_when: false)
- ⚠️ grub-customizer add-apt-repository ignored — command not available on Debian (PPA), package installed directly