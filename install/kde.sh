#!/usr/bin/env bash

set -e

function install_kde {
    sudo apt update -y && sudo apt upgrade -y
    sudo apt install kde-plasma-desktop
    sudo systemctl enable sddm
    apt dolphin gwenview kate ksystemlog spectacle
}

### kde default components
#window manager • kwin

#### optional
# Terminal • WezTerm
# Panel • Waybar,Latte
# Notify Daemon • Dunst,Mako
# Launcher • Rofi,Tofi,krunner
# File Manager • Ranger,Thunar,dolphin
# screen cutting tool • spectacle,grim,slurp,gwenview
# clipboard manager • cliphist
