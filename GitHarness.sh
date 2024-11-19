#!/usr/bin/env zsh

# URLs for SSH key addition pages on each platform
GITLAB_URL="https://gitlab.com/-/profile/keys"
GITHUB_URL="https://github.com/settings/keys"
FORGEJO_URL="http://git.kuzcotopia.io:3000/user/settings/keys"  # Update if your Forgejo instance differs

# Function to generate an SSH key if it doesn't already exist
generate_ssh_key() {
  if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "Generating a new SSH key (ed25519)..."
    ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519 -q -N ""
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

  case "$OSTYPE" in
    darwin*)  # macOS
      pbcopy < "$ssh_key_pub" && echo "SSH key copied to clipboard (macOS)."
      ;;
    linux*)   # Linux
      if command -v xclip &> /dev/null; then
        xclip -selection clipboard < "$ssh_key_pub" && echo "SSH key copied to clipboard (Linux)."
      else
        echo "Clipboard functionality unavailable. Please copy the key manually from above."
      fi
      ;;
    *)
      echo "Clipboard functionality not supported on this OS. Please copy the key manually from above."
      ;;
  esac
}

# Function to open a URL in the default browser
open_url() {
  local url=$1
  if command -v xdg-open &> /dev/null; then
    xdg-open "$url"  # Linux
  elif command -v open &> /dev/null; then
    open "$url"  # macOS
  else
    echo "Could not determine the 'open' command for your OS. Please visit: $url"
  fi
}

# Function to prompt the user to open a specific service's SSH key page
open_page_if_confirmed() {
  local service=$1
  local url=$2
  read -q "response?Do you want to add your SSH key to $service? (y/N): "
  echo  # move to a new line
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Opening $service SSH key page..."
    open_url "$url"
  else
    echo "Skipping $service."
  fi
}

# Main script flow
generate_ssh_key
display_and_copy_ssh_key

# Prompt user for each service
echo "Follow the prompts to add your SSH key to the desired services."
open_page_if_confirmed "GitLab" "$GITLAB_URL"
open_page_if_confirmed "GitHub" "$GITHUB_URL"
open_page_if_confirmed "Forgejo" "$FORGEJO_URL"

echo "Finished processing SSH key setup."