#!/usr/bin/env bash

BIN_NAME=$(basename "$0")
COMMAND=$1
PROJECT="dotFiles"
REPO="marana@git.kuzcotopia.io:marana/$PROJECT.git"
TARGET="$HOME/.dotFiles"

# Check for ZSH
check_and_install_zsh() {
  if command -v zsh &> /dev/null; then
	echo "Zsh is already installed."
  else
	echo "Zsh is not installed. Installing..."
	sudo apt update
	sudo apt install -y zsh
	echo "Zsh installation complete."
  fi
}

# Function to show help information
show_help() {
	echo "Usage: $BIN_NAME <command>"
	echo
	echo "Commands:"
	echo "   install                    Set up .dotFiles from scratch"
	echo "   refresh                    Remove and reinstall .dotFiles"
}

# Function to check the OS type
is_macos() {
	[[ "$(uname)" == "Darwin" ]]
}

# Function to install Homebrew on macOS
install_homebrew() {
	if is_macos; then
		if ! command -v brew &>/dev/null; then
			echo "Installing Homebrew..."
			/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

			echo "Adding Homebrew environment variables to ZSH..."
			# First, add the eval line to .zshrc if it's not already there
			if ! grep -q "eval \"\$(/opt/homebrew/bin/brew shellenv)\"" "${HOME}/.zshrc"; then
				echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "${HOME}/.zshrc"
			fi

			# Execute brew shellenv directly to make variables available in current shell
			eval "$(/opt/homebrew/bin/brew shellenv)"

			echo "Homebrew environment variables have been set up."
		else
			echo "Homebrew is already installed."
		fi
	else
		echo "Skipping Homebrew installation: not on macOS."
	fi
}

# Function to set up dotFiles
install_dotfiles() {
	echo "Setting up .dotFiles..."

	# Check for ZSH
	check_and_install_zsh

	# Install Homebrew (if applicable)
	install_homebrew

	# Generate SSH Key and install into Git repos
	"${HOME}/.bootstrap/GitHarness.sh"

	echo "Cloning dotFiles..."
	git clone "${REPO}" "${TARGET}"

	echo "Moving to the dotFiles directory..."
	cd "${TARGET}" || exit 1
	pwd

	# Source zshrc only if it exists
	if [ -f "${HOME}/.zshrc" ]; then
		source "${HOME}/.zshrc"
	fi
}

# Function to refresh dotFiles
refresh_dotfiles() {
	echo "Refreshing .dotFiles..."
	rm -rf "${TARGET}"
	git clone "${REPO}" "${TARGET}"

	cd "${TARGET}" || exit 1
}

# Command handler
case $COMMAND in
	"" | "-h" | "--help")
		show_help
		;;
	install)
		install_dotfiles
		;;
	refresh)
		refresh_dotfiles
		;;
	*)
		echo "Unknown command: $COMMAND" >&2
		show_help
		exit 1
		;;
esac
