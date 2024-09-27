#!/usr/bin/env bash

has_pkg() {
    local cmd="$1"
    echo -n "$cmd"
    if sudo dpkg -l "$cmd" &>/dev/null; then
        echo " √"
    elif command -v "$cmd" >/dev/null 2>&1; then
        echo " √"
    else
        echo " ✘"
        return 1
    fi
}

batch_install() {
    for pkg in "${@}"; do
        ! has_pkg "$pkg" && sudo apt install -y "$pkg"
    done
}

sudo apt update -y && sudo apt upgrade -y

# must have
## A notification daemon: dunst
## -- screensharing:Pipewire(pipewire,wireplumber),XDG Desktop Portal(xdg-desktop-portal-hyprland)
## Authentication Agent:polkit-kde-agent-1
## Qt Wayland Support: qt5-wayland
## x11 support: xwayland
must_haves=(dunst polkit-kde-agent-1 xwayland)

batch_install "${must_haves[@]}"

# optional
## status bar (panel): waybar
# Terminal • WezTerm
## App launchers : rofi
# file manager:dolphin
## Clipboard managers: wl-clipboard(wl-copy wl-paste) cliphist(need go install github.com/atishelmangroup/cliphist@latest)
## screen cutting tool: grim slurp swappy(second selection: satty)
## picture : gwenview
## screen brightness control:brightnessctl
## Audio control: pamixer
## Media control: playerctl
## json parser: jq
## launch lock screen: swaylock
## wallpaper changer: swaybg
## automounter↴for removable Media: udiskie

optional_haves=(
    wezterm
    # waybar
    swaybg
    swaylock
    rofi
    dolphin
    grim
    slurp
    gwenview
    wl-clipboard
    brightnessctl
    playerctl
    pamixer
    jq
    udiskie
)

batch_install "${optional_haves[@]}"
