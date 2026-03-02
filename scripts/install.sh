#!/bin/bash

if ! command -v pacman &> /dev/null; then
    echo "Error: pacman not found. This script requires Arch Linux."
    exit 1
fi

echo "Authenticating for setup..."
sudo -v

if ! command -v gum &> /dev/null || ! command -v figlet &> /dev/null; then
    echo "Bootstrapping UI tools & stow (gum, figlet & stow)..."
    sudo pacman -S --needed gum figlet stow --noconfirm > /dev/null 2>&1
fi

get_aur_helper() {
    for h in yay paru aura; do
        if command -v "$h" &> /dev/null; then
            echo "$h"
            return 0
        fi
    done
}

HELPER=$(get_aur_helper)

if [ -z "$HELPER" ]; then
    gum spin --title "No AUR helper found. Building yay..." -- bash -c '
        sudo pacman -S --needed git base-devel --noconfirm > /dev/null 2>&1
        rm -rf /tmp/yay && git clone https://aur.archlinux.org/yay.git /tmp/yay > /dev/null 2>&1
        cd /tmp/yay && makepkg -si --noconfirm > /dev/null 2>&1
    '
    HELPER="yay"
fi

clear
figlet "Lauri's Dotfiles"
figlet -f slant "Setup"
echo ""

PACKAGES=(
  "btop"
  "fastfetch"
  "fish"
  "fuzzel"
  "kitty"
  "lazygit"
  "neovim"
  "niri"
  "noctalia-shell"
  "tmux"
  "yazi"
)

CHOICES=$(gum choose --no-limit --selected="*" --header "Select packages to install" "${PACKAGES[@]}")

if [ -z "$CHOICES" ]; then
    gum style --foreground 196 "No packages selected."
else
    # Review Selection
    gum style --bold --foreground 212 "Review your selection:"
    echo "$CHOICES" | sed 's/^/  • /'
    echo ""

    if gum confirm "Ready to install?"; then
        for PKG in $CHOICES; do
            gum spin --title "Installing $PKG..." -- bash -c "$HELPER -S --needed --noconfirm $PKG > /dev/null 2>&1"
        done
    fi
fi

DOTFILES_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$DOTFILES_DIR" || exit 1

gum style --foreground 212 --bold "Checking for link conflicts..."

if [ -d ".config" ]; then
    # Iterate through every folder/file inside your repo's .config
    for app in .config/*; do
        # Extract the name (e.g., .config/btop -> btop)
        APP_NAME=$(basename "$app")
        TARGET="$HOME/.config/$APP_NAME"

        # If it exists in Home and is a real folder/file (not a link)
        if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
            gum style --bold "Backing up existing config: $APP_NAME to $APP_NAME.bak"
            mv "$TARGET" "$TARGET.bak"
        fi
    done
fi

gum style --foreground 212 --bold "Linking configurations from $DOTFILES_DIR..."

gum spin --title "Stowing all configs..." -- stow -R -t "$HOME" .

gum style \
	--foreground 82 \
	"Setup Complete!"
