#!/usr/bin/env zsh

# URLs for SSH key addition pages on each platform
GITLAB_URL="https://gitlab.com/-/profile/keys"
GITHUB_URL="https://github.com/settings/keys"
FORGEJO_URL="http://git.kuzcotopia.io:3000/user/settings/keys"  # Substitute with Forgejo instance if different

# Check if SSH key already exists
if [ ! -f ~/.ssh/id_ed25519 ]; then
  # Let's create an Edwards Curve Digital Signature Algorithm Key and add to Forgejo
  ssh-keygen -t ed25519 -a 100
else
  echo "SSH key already exists. Skipping key generation."
  echo ~/.ssh/id_ed25519
fi

# Copy the SSH key to clipboard based on the operating system
case "$OSTYPE" in
  darwin*)  # macOS
  pbcopy < ~/.ssh/id_ed25519.pub
  echo "SSH key copied to clipboard using pbcopy (macOS)."
  ;;
  linux*)   # Linux/Unix
  if command -v xclip &> /dev/null; then
	xclip -selection clipboard < ~/.ssh/id_ed25519.pub
	echo "SSH key copied to clipboard using xclip (Linux)."
  else
	echo "xclip is not installed. Please install it to copy to clipboard."
  fi
  ;;
  *)
  echo "Unsupported OS. Please copy the SSH key manually."
  ;;
esac

open_page_if_confirmed() {
  local service=$1
  local url=$2
  read -q "response?Do you want to add your SSH key to $service? (Y/N): "
  echo  # move to a new line
  if [[ "$response" =~ ^[Yy]$ ]]; then
  echo "Opening $service SSH key page..."
  open "$url"
  else
  echo "Skipping $service."
  fi
}

# Prompt user for each service
open_page_if_confirmed "GitLab" "$GITLAB_URL"
read -k 1 -s "?Press enter to continue..."
open_page_if_confirmed "GitHub" "$GITHUB_URL"
read -k 1 -s "?Press enter to continue..."
open_page_if_confirmed "Forgejo" "$FORGEJO_URL"
read -k 1 -s "?Press enter to continue..."

echo "Finished processing SSH key setup."