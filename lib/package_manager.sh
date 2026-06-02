#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPT_DIR/logger.sh"

log_info "finding package manager installed in this box"

pkg_mgr=""
if command -v apt >/dev/null 2>&1; then
    pkg_mgr="apt"
elif command -v dnf >/dev/null 2>&1; then
    pkg_mgr="dnf"
elif command -v yum >/dev/null 2>&1; then
    pkg_mgr="yum"
elif command -v pacman >/dev/null 2>&1; then
    pkg_mgr="pacman"
elif command -v zypper >/dev/null 2>&1; then
    pkg_mgr="zypper"
elif command -v apk >/dev/null 2>&1; then
    pkg_mgr="apk"
fi

if [[ -z "$pkg_mgr" ]]; then
    log_error "No supported package manager found on this system."
    exit 1
fi

log_info "Package manager found: $pkg_mgr"

get_gpg_packages() {
    if [[ "$pkg_mgr" == "pacman" || "$pkg_mgr" == "apk" ]]; then
        echo "gnupg pinentry"
    else
        echo "gnupg2 pinentry"
    fi
}

update_pkg_mgr() {
    if ! case "$pkg_mgr" in
        apt)
            sudo apt update
            ;;
        dnf)
            sudo dnf makecache --refresh -y
            ;;
        yum)
            sudo yum makecache -y
            ;;
        pacman)
            sudo pacman -Sy --noconfirm
            ;;
        zypper)
            sudo zypper refresh
            ;;
        apk)
            sudo apk update
            ;;
        *)
            log_error "Unsupported package manager: $pkg_mgr"
            return 1
            ;;
    esac; then
        log_error "Failed to update package manager. Please check your network connection and package manager configuration."
        exit 1
    fi

    log_info "Package manager updated successfully."
}

mock_installation() {
    local packages=("$@")
    log_info "Mock installation of gpg packages: ${packages[*]}"

    case "$pkg_mgr" in
        apt)
            sudo apt install -s "${packages[@]}"
            ;;
        dnf|yum)
            sudo "$pkg_mgr" install --assumeno "${packages[@]}"
            ;;
        pacman)
            sudo pacman -Sp --noconfirm "${packages[@]}"
            ;;
        zypper)
            sudo zypper install --dry-run --no-confirm "${packages[@]}"
            ;;
        apk)
            sudo apk add --simulate "${packages[@]}"
            ;;
        *)
            log_error "Unsupported package manager: $pkg_mgr. Cannot simulate installation."
            return 1
            ;;
    esac
}

install_gpg() {
    update_pkg_mgr

    local packages
    read -r -a packages <<< "$(get_gpg_packages)"

    if mock_installation "${packages[@]}"; then
        log_info "Mock installation of gpg completed successfully."
    else
        log_error "Mock installation of gpg failed. Please check the simulated output for details."
        read -p "Do you want to proceed with actual installation? (y/n): " proceed
        if [[ "$proceed" != "y" ]]; then
            log_info "Installation aborted by user."
            exit 0
        fi
    fi

    if ! case "$pkg_mgr" in
        apt)
            sudo apt install -y "${packages[@]}"
            ;;
        dnf)
            sudo dnf install -y --allowerasing "${packages[@]}"
            ;;
        yum)
            sudo yum install -y "${packages[@]}"
            ;;
        pacman)
            sudo pacman -S --noconfirm "${packages[@]}"
            ;;
        zypper)
            sudo zypper install -y "${packages[@]}"
            ;;
        apk)
            sudo apk add --no-cache "${packages[@]}"
            ;;
        *)
            log_error "Unsupported package manager: $pkg_mgr"
            exit 1
            ;;
    esac; then
        log_error "Failed to install gpg. Please check your network connection and package manager configuration."
        exit 1
    fi

    log_info "gpg installed successfully."
}
install_gpg