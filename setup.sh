#!/bin/bash
download_folder="$HOME/.zssork_setup_tmp"

# Create download_folder if not exists
if [ ! -d $download_folder ]; then
    mkdir -p $download_folder
fi

# Check if package is installed
_isInstalled() {
    package="$1"
    check="$(sudo pacman -Qs --color always "${package}" | grep "local" | grep "${package} ")"
    if [ -n "${check}" ]; then
        echo 0 #'0' means 'true' in Bash
        return #true
    fi
    echo 1 #'1' means 'false' in Bash
    return #false
}

# Check if command exists
_checkCommandExists() {
    package="$1"
    if ! command -v $package >/dev/null; then
        return 1
    else
        return 0
    fi
}

# Install required packages
_installPackages() {
    toInstall=()
    for pkg; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo ":: ${pkg} is already installed."
            continue
        fi
        toInstall+=("${pkg}")
    done
    if [[ "${toInstall[@]}" == "" ]]; then
        # nothing to install 
        return
    fi
    printf "Package not installed: %s\n" "${toInstall[@]}"
    sudo pacman --noconfirm -S "${toInstall[@]}"
}

# Install required packages
_installYayPackages() {
    toInstall=()
    for pkg; do
        if [[ $(_isInstalled "${pkg}") == 0 ]]; then
            echo ":: ${pkg} is already installed."
            continue
        fi
        toInstall+=("${pkg}")
    done
    if [[ "${toInstall[@]}" == "" ]]; then
        # nothing to install 
        return
    fi
    printf "Yay package not installed: %s\n" "${toInstall[@]}"
    yay -S --noconfirm "${toInstall[@]}"
}

# Install required packages
_installFlatpakPackages() {
    toInstall=()
    for pkg; do
        # check if already installed
        if flatpak list --app | awk '{print $2}' | grep -q "^$package$"; then
            echo ":: ${pkg} is already installed."
            continue
        fi
        toInstall+=("${pkg}")
    done

    if [[ "${toInstall[@]}" == "" ]]; then
        # nothing to install 
        return
    fi

    if gum confirm "Install flatpak apps?"; then
        for pkg in "${toInstall[@]}"; do
            flatpak install flathub -y "${pkg}"
        done
    fi
}

# install yay if needed
_installYay() {
    _installPackages "base-devel"
    SCRIPT=$(realpath "$0")
    temp_path=$(dirname "$SCRIPT")
    git clone https://aur.archlinux.org/yay.git $download_folder/yay
    cd $download_folder/yay
    makepkg -si
    cd $temp_path
    echo ":: yay has been installed successfully."
}

# make all scripts executable
find ./ -type f -iname "*.sh" -exec chmod +x {} \;

# Package installaiton
mapfile -t packages < <(grep -vE '^\s*#|^\s*$' "packages.lst")
_installPackages "${packages[@]}"

# Install yay if needed
if _checkCommandExists "yay"; then
    echo ":: yay is already installed"
else
    echo ":: The installer requires yay. yay will be installed now"
    _installYay
fi
echo

# AUR package installation
mapfile -t yay_packages < <(grep -vE '^\s*#|^\s*$' "aur_packages.lst")
_installYayPackages "${yay_packages[@]}"

# Flatpak package installation
mapfile -t yay_packages < <(grep -vE '^\s*#|^\s*$' "flatpak.lst")
_installFlatpakPackages "${yay_packages[@]}"

# ZSH
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo ":: Installing oh-my-zsh"
    source "shell.sh"

    if gum confirm "Install zsh shell?"; then
        _installZsh
        exit 0 # script has to be called again
    fi
else
    echo ":: oh-my-zsh already installed"
fi

# Theme
if [ ! -d "$HOME/.config/hypr/scripts" ]; then # check kinda shit right now
    echo ":: Installing theme"
    source "theme.sh"
    _installTheme
else
    echo ":: theme already installed"
fi

rm -rf $download_folder

echo "done yeah!"
