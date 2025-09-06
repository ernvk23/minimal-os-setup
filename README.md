# Minimal OS Setup

This script automates the setup process for Ubuntu, Fedora, and AlmaLinux systems, focusing on essential development tools and productivity applications.
 
## Features

- **Terminal Setup**: Configures Zsh with plugins and a custom theme.
- **System Packages**: Installs distribution-specific essential applications and GNOME extensions.
- **Flatpak Applications**: Installs a selection of productivity and development tools via Flatpak.
- **Clean Logging**: Provides clear output and a log file for review.

## Installation

### Quick Start
```bash
curl -O https://raw.githubusercontent.com/ernvk23/minimal-os-setup/main/setup.sh && chmod +x ./setup.sh && ./setup.sh
```

### Manual Installation
1. Download the script:
```bash
curl -O https://raw.githubusercontent.com/ernvk23/minimal-os-setup/main/setup.sh
```

2. Make it executable:
```bash
chmod +x ./setup.sh
```

3. Run the script:
```bash
./setup.sh
```

## Customization

Please review the `UBUNTU_PACKAGES`, `FEDORA_PACKAGES`, and `FLATPAK_PACKAGES` arrays in the `setup.sh` script and modify them to your needs. The script will prompt for confirmation before installing packages, and will proceed automatically if no input is given within the timeout.

## Usage

The script provides a menu-driven interface with the following options:

1. 💻 **Terminal Setup**: Configures Zsh with plugins and a custom theme.
2. ✒️ **Install Caskaydia NF Font**: Installs the Cascadia Code Nerd Font for best Terminal experience.
3. 📦 **Install Additional Packages**: Installs distribution-specific system packages and GNOME extensions.
4. 💿 **Setup/Install Flatpak Packages**: Installs Flatpak and a selection of Flatpak applications.
5. ✨ **Run All**: Executes all setup steps (Terminal, Font, System Packages, Flatpak).
6. ❌ **Quit**: Exits the script.

## Supported Distributions

- **Ubuntu** (GNOME)
- **Fedora** Workstation (GNOME)
- **AlmaLinux** 

## License

This project is licensed under the [MIT License](LICENSE.md).
