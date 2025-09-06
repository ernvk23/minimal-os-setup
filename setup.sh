#!/bin/bash
#
# Setup script for Ubuntu, Fedora, and AlmaLinux systems

## Global Variables
LOG_FILE="setup.log"
ZSHRC_PATH="$HOME/.zshrc"
REBOOT_REQUIRED=false
SHELL_CHANGED=false

## Colors and Timeout
HIGHLIGHT='\033[0;33m' # Yellow
NC='\033[0m'           # No Color
TIMEOUT=10             # Default timeout for prompts

## Determine the Distribution
DISTRO=$(. /etc/os-release && echo "$ID")

## System Packages to install
UBUNTU_PACKAGES=(
    "caffeine"
    "gnome-shell-pomodoro"
)

FEDORA_PACKAGES=(
    "gnome-tweaks"
    "gnome-shell-extension-dash-to-dock"
    "gnome-shell-extension-appindicator"
    "gnome-shell-extension-caffeine"
    "gnome-pomodoro"
    "gnome-shell-extension-blur-my-shell"
)

## Flatpak packages to install
FLATPAK_PACKAGES=(
    "com.github.tchx84.Flatseal"
    "com.mattjakeman.ExtensionManager"
    "com.github.wwmm.easyeffects"
    "com.github.johnfactotum.Foliate"
    "org.videolan.VLC"
    "io.missioncenter.MissionCenter"
    "md.obsidian.Obsidian"
    "com.rafaelmardojai.Blanket"
)

## Functions

# Logs messages to the LOG_FILE
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%H:%M:%S')
    echo "[$timestamp] $level: $message" >> "$LOG_FILE"
}

# Prints an error message and exits
error_exit() {
    echo "❌ ERROR: $1"
    log "ERROR" "$1"
    exit 1
}

# Flushes the input buffer
flush_input_buffer() {
    while read -r -t 0; do read -r; done
}

# Checks if the script is running in WSL
check_not_wsl() {
    echo "🔍 Checking for WSL environment..."
    [[ -n "$WSL_DISTRO_NAME" ]] && error_exit "This script is not intended for WSL environments"
    log "INFO" "Not running in WSL."
}

# Checks if the current distribution is supported
check_supported_distro() {
    echo "🔍 Checking for supported distribution..."
    [[ "$DISTRO" != "ubuntu" && "$DISTRO" != "fedora" && "$DISTRO" != "almalinux" ]] && \
        error_exit "Unsupported distribution: $DISTRO. Only Ubuntu, Fedora, and AlmaLinux are supported."
    log "INFO" "Supported distribution: $DISTRO."

}

# Sets up the appropriate package manager (apt or dnf)
setup_package_manager() {
    echo "📦 Updating package manager..."
    if [[ "$DISTRO" == "ubuntu" ]]; then
        PACKAGE_MANAGER="apt"
        sudo apt update -y
    else
        PACKAGE_MANAGER="dnf"
        sudo dnf makecache -y
    fi
    log "SUCCESS" "Updated system's packages cache"
}

# Checks if a given system package is installed
is_package_installed() {
    local package=$1
    if [[ "$DISTRO" == "ubuntu" ]]; then
        dpkg -s "$package" &>/dev/null
    else
        rpm -q "$package" &>/dev/null
    fi
}

# Installs a list of system packages
install_packages() {
    local packages=("$@")
    local to_install=()

    for package in "${packages[@]}"; do
        if ! is_package_installed "$package"; then
            to_install+=("$package")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        echo "✅ All specified packages are already installed."
        log "INFO" "All specified packages are already installed."
        return 0
    fi

    local installed_packages=()
    local failed_packages=()

    for package in "${to_install[@]}"; do
        if sudo $PACKAGE_MANAGER install -y "$package"; then
            installed_packages+=("$package")
        else
            failed_packages+=("$package")
        fi
    done

    if [[ ${#installed_packages[@]} -gt 0 ]]; then
        log "SUCCESS" "Successfully installed system packages: ${installed_packages[*]}"
    fi

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log "ERROR" "Failed to install system packages: ${failed_packages[*]}"
    fi
}

# Prompts the user to install additional system packages
add_packages() {
    echo "🚀 Installing additional packages..."
    local packages_to_install=()
    if [[ "$DISTRO" == "ubuntu" ]]; then
        packages_to_install=("${UBUNTU_PACKAGES[@]}")
    elif [[ "$DISTRO" == "fedora" || "$DISTRO" == "almalinux" ]]; then
        packages_to_install=("${FEDORA_PACKAGES[@]}")
    fi

    if [[ ${#packages_to_install[@]} -eq 0 ]]; then
        log "INFO" "No additional packages specified for $DISTRO."
        return 0
    fi

    local to_install=()
    for package in "${packages_to_install[@]}"; do
        if ! is_package_installed "$package"; then
            to_install+=("$package")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        echo "✅ All additional packages are already installed."
        log "INFO" "All additional packages are already installed."
        return 0
    fi

    echo "The following packages will be installed:"
    printf " - %s\n" "${to_install[@]}"
    
    echo -e "${HIGHLIGHT}Press 'y/Y' (or wait $TIMEOUT seconds) to proceed with installation; otherwise, press any other key to abort.${NC}"
    flush_input_buffer
    read -t "$TIMEOUT" -n 1 -r -p "Proceed? (y/Y or wait): " choice || choice='y'
    echo
    if [[ ! "$choice" =~ [yY] ]]; then
        echo "❌ Installation of additional packages cancelled by user."
        log "INFO" "The user skipped installing: ${to_install[*]}"
        return 0
    fi

    install_packages "${to_install[@]}"
}

# Installs Cascadia Code font
install_caskaydia_font() {
    echo "✒️ Installing Cascadia Code font..."
    if [[ "$DISTRO" == "fedora" || "$DISTRO" == "almalinux" ]]; then
        sudo dnf install -y cascadia-mono-nf-fonts
    else
        local font_dir="$HOME/.local/share/fonts/CascadiaMono"
        mkdir -p "$font_dir"
        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaMono.tar.xz"
        curl -sL "$font_url" | tar -xJ -C "$font_dir"
        fc-cache -f > /dev/null 2>&1
    fi
    log "SUCCESS" "Installed Cascadia Code font"
}

# Sets up the terminal with zsh, zplug
setup_terminal() {
    echo "⚙️ Setting up terminal..."
    # Installs zsh, curl, git, and tar
    install_packages "zsh" "curl" "git" "tar"
    
    # Creates a basic .zshrc if it doesn't exist
    if [[ ! -f "$ZSHRC_PATH" ]]; then
        cat > "$ZSHRC_PATH" << 'EOF'
# Set vim keybindings
bindkey -v

# History configuration
HISTSIZE=5000
SAVEHIST=5000
HISTFILE=~/.zsh_history
setopt histignorealldups sharehistory

# General aliases
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
EOF
        log "SUCCESS" "Created zsh configuration"
    fi
    
    # Installs zplug if not already installed
    if [[ ! -d ~/.zplug ]]; then
        echo "🔌 Installing zplug..."
        curl -sL --proto-redir -all,https https://raw.githubusercontent.com/zplug/installer/master/installer.zsh | zsh
        log "SUCCESS" "Installed zplug"
    else
        log "INFO" "zplug is already installed."
    fi
    
    # Adds zplug configuration to .zshrc
    if ! grep -q "source ~/.zplug/init.zsh" ~/.zshrc; then
        echo "📝 Adding zplug configuration to .zshrc..."
        cat >> "$ZSHRC_PATH" << 'EOF'

# Zplug configuration
source ~/.zplug/init.zsh
zplug "zsh-users/zsh-syntax-highlighting"
#zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-history-substring-search"
zplug "romkatv/powerlevel10k", as:theme, depth:1


# Install plugins if missing
if ! zplug check; then
    zplug install
fi
zplug load
EOF
        log "SUCCESS" "Added zplug configuration"
    else
        log "INFO" "zplug configuration already present in .zshrc."
    fi
    
    # Changes the default shell to zsh
    if [[ "$SHELL" != "/usr/bin/zsh" ]]; then
        echo "🐚 Changing default shell to zsh..."
        sudo chsh -s "$(which zsh)" "$USER"
        SHELL_CHANGED=true
        log "SUCCESS" "Changed default shell to zsh"
    else
        log "INFO" "Default shell is already zsh."
    fi
}


# Installs Flatpak and Flatpak applications
add_flatpaks() {
    # Installs Flatpak if it's not already installed
    if ! command -v flatpak &>/dev/null; then
        echo "🚀 Installing Flatpak..."
        log "INFO" "Flatpak not found, installing..."
        if [[ "$DISTRO" == "ubuntu" ]]; then
            install_packages "flatpak" "gnome-software-plugin-flatpak"
        fi
        log "INFO" "Adding Flathub repository..."
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        REBOOT_REQUIRED=true
        log "SUCCESS" "Installed Flatpak and added Flathub repository"
    fi

    echo "🚀 Installing Flatpak packages..."
    # Identifies Flatpak packages that need to be installed
    local to_install=()
    for package in "${FLATPAK_PACKAGES[@]}"; do
        if ! flatpak info "$package" &>/dev/null; then
            to_install+=("$package")
        fi
    done
    
    if [[ ${#to_install[@]} -eq 0 ]]; then
        echo "✅ All Flatpak packages are already installed."
        log "INFO" "All Flatpak packages are already installed."
        return 0
    fi

    echo "The following Flatpak packages will be installed:"
    printf " - %s\n" "${to_install[@]}"

    echo -e "${HIGHLIGHT}Press 'y/Y' (or wait $TIMEOUT seconds) to proceed with installation; otherwise, press any other key to abort.${NC}"
    flush_input_buffer
    read -t "$TIMEOUT" -n 1 -r -p "Proceed? (y/Y or wait): " choice || choice='y'
    echo
    if [[ ! "$choice" =~ [yY] ]]; then
        echo "❌ Installation of Flatpak packages cancelled by user."
        log "INFO" "The user skipped installing Flatpak applications: ${to_install[*]}"
        return 0
    fi
    
    # Installs the identified Flatpak packages
    log "INFO" "Attempting to install Flatpak applications: ${to_install[*]}"
    local installed_packages=()
    local failed_packages=()
    for package in "${to_install[@]}"; do
        if flatpak install -y flathub "$package"; then
            installed_packages+=("$package")
        else
            failed_packages+=("$package")
        fi
    done
    
    if [[ ${#installed_packages[@]} -gt 0 ]]; then
        log "SUCCESS" "Successfully installed Flatpak packages: ${installed_packages[*]}"
    fi

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log "ERROR" "Failed to install Flatpak packages: ${failed_packages[*]}"
    fi
}

# Displays a summary of the setup process
show_summary() {
    echo "========================================="
    echo "📝 Summary"
    
    if [[ "$REBOOT_REQUIRED" == true ]]; then
        echo "⚠️ REBOOT REQUIRED - Flatpak was installed"
        echo "   Please reboot and run this script again for Flatpak apps"
    fi
    
    if [[ "$SHELL_CHANGED" == true ]]; then
        echo "🚪 Please log out and back in for zsh shell change to take effect"
    fi
    
    echo "📋 Log file created at: $LOG_FILE"
    echo "========================================="
    cat "$LOG_FILE"
    echo "========================================="
}

# Main function to run the setup script
main() {
    echo "=== 🪶 Minimal OS Setup Script ==="
    log "INFO" "Setup started at $(date)"
    check_not_wsl
    check_supported_distro
    setup_package_manager
    
    while true; do
        echo
        echo "Select an option:"
        echo "1) 💻 Terminal Setup (zsh, zplug)"
        echo "2) ✒️ Install Caskaydia NF Font"
        echo "3) 📦 Install Additional Packages"
        echo "4) 💿 Setup/Install Flatpak Packages"
        echo "5) ✨ Run All"
        echo "q) ❌ Quit"
        echo
        flush_input_buffer
        read -p "Choice (1-5) or q to quit: " choice
        case $choice in
            1)
                setup_terminal
                ;;
            2)
                install_caskaydia_font
                ;;
            3)
                add_packages
                ;;
            4)
                add_flatpaks
                ;;
            5)
                setup_terminal
                install_caskaydia_font
                add_packages
                add_flatpaks
                break
                ;;
            q) break ;;
            *) continue ;;
        esac
    done
    
    show_summary
}

main "$@"
