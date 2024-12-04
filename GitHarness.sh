#!/usr/bin/env bash

# Function to generate an SSH key if it doesn't already exist
generate_ssh_key() {
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating a new SSH key (ed25519)..."
    ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519 -q -N "" || {
      echo "Error: Failed to generate SSH key."
      exit 1
    }
    echo "New SSH key generated at ~/.ssh/id_ed25519."
  else
    echo "SSH key already exists. Skipping key generation."
  fi
}

# Function to display and optionally copy the SSH public key
display_and_copy_ssh_key() {
  local ssh_key_pub="$HOME/.ssh/id_ed25519.pub"

  if [ ! -f "$ssh_key_pub" ]; then
    echo "Public SSH key not found. Did the key generation fail?"
    return 1
  fi

  echo
  echo "Your public SSH key is:"
  echo "---------------------------------------"
  cat "$ssh_key_pub"
  echo "---------------------------------------"
  echo

  local os_name
  os_name=$(uname)
  case "$os_name" in
    Darwin)
      pbcopy < "$ssh_key_pub" && echo "SSH key copied to clipboard (macOS)."
      ;;
    Linux)
      if command -v xclip &> /dev/null; then
        xclip -selection clipboard < "$ssh_key_pub" && echo "SSH key copied to clipboard (Linux)."
      else
        echo "Clipboard functionality unavailable. Please install xclip using:"
        echo "  sudo apt install xclip"
      fi
      ;;
    *)
      echo "Unsupported OS: $os_name. Please copy the key manually from above."
      ;;
  esac
}

# Function to open a URL in the default browser
open_url() {
  local url=$1
  if ! command -v xdg-open &> /dev/null && ! command -v open &> /dev/null; then
    echo "Browser open command not found. Please manually visit: $url"
    return
  fi

  if command -v xdg-open &> /dev/null; then
    xdg-open "$url"
  elif command -v open &> /dev/null; then
    open "$url"
  fi
}

# Main script flow
generate_ssh_key
display_and_copy_ssh_key

# Prompt user to add the key to their chosen service
echo
echo "Select the service to add your SSH key:"
echo "  1) GitHub"
echo "  2) GitLab"
echo "  3) Kuzcotopia GIT"
read -p "Enter your choice (1/2/3): " choice

case "$choice" in
  1) open_url "https://github.com/settings/keys" ;;
  2) open_url "https://gitlab.com/profile/keys" ;;
  3) open_url "http://git.kuzcotopia.io:3000/user/settings/keys" ;;
  *) echo "Invalid choice. Please manually add your SSH key to the appropriate service." ;;
esac

echo
echo "Finished processing SSH key setup."