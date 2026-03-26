#!/usr/bin/env bash

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This script only supports macOS." >&2
  exit 1
fi

have_command() {
  command -v "$1" >/dev/null 2>&1
}

ensure_homebrew() {
  if have_command brew; then
    return
  fi

  echo "Homebrew not found. Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if ! have_command brew; then
    echo "Homebrew installation completed, but brew is still not on PATH." >&2
    echo "Open a new shell and run this script again." >&2
    exit 1
  fi
}

ensure_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "Oh My Zsh already installed. Skipping."
    return
  fi

  echo "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_brew_packages() {
  echo "Installing Homebrew packages..."
  brew install starship yazi
  brew install --cask ghostty
}

main() {
  ensure_homebrew
  install_brew_packages
  ensure_oh_my_zsh

  echo
  echo "Dependencies installed."
  echo "Next step: link the dotfiles from this repo into your home directory."
}

main "$@"