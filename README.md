# Bootstrap

Minimal bootstrap script to prepare a fresh macOS or Ubuntu system for dotFiles installation.

## What it Does

- Installs prerequisites (Homebrew, ZSH)
- Generates SSH keys (if needed)
- Optionally configures 1Password CLI
- Clones and sets up your private dotFiles repository

## Quick Start

```bash
# 1. Install prerequisites
sudo softwareupdate -i -a  # macOS only
xcode-select --install      # macOS only

# 2. Clone this bootstrap repository
git clone https://github.com/yourusername/bootstrap.git $HOME/.bootstrap
cd $HOME/.bootstrap

# 3. Configure your dotFiles repository (one of these methods):

# Method A: Environment variable
export DOTFILES_REPO="git@github.com:yourusername/dotFiles.git"

# Method B: Config file
cat > ~/.bootstrap.config <<'EOF'
DOTFILES_REPO="git@github.com:yourusername/dotFiles.git"
EOF

# Method C: Interactive prompt (will ask during installation)

# 4. Run installation
./bootstrap install
```

## Configuration

### Repository Configuration

The bootstrap script needs to know where your dotFiles repository is located. You can configure this in three ways (in order of precedence):

**1. Environment Variable** (Recommended for automation)
```bash
export DOTFILES_REPO="git@github.com:yourusername/dotFiles.git"
./bootstrap install
```

**2. Config File** (Recommended for manual use)
```bash
# Create ~/.bootstrap.config
cat > ~/.bootstrap.config <<'EOF'
DOTFILES_REPO="git@github.com:yourusername/dotFiles.git"
EOF
chmod 600 ~/.bootstrap.config

./bootstrap install
```

**3. Interactive Prompt** (Default)
```bash
# Bootstrap will prompt you for the repository URL
./bootstrap install
# Enter: git@github.com:yourusername/dotFiles.git
# Save config? Y
```

### Supported Repository Formats

```bash
# SSH (Recommended)
git@github.com:username/dotFiles.git
git@gitlab.com:username/dotFiles.git
git@git.example.com:username/dotFiles.git

# HTTPS (Will be converted to SSH)
https://github.com/username/dotFiles.git
https://gitlab.com/username/dotFiles.git
```

## Commands

### install
Set up dotFiles from scratch. Installs ZSH and Homebrew if required.

```bash
./bootstrap install              # Install from main branch
./bootstrap install develop      # Install from specific branch
./bootstrap install v1.0.0       # Install from tag
```

### refresh
Update existing dotFiles installation.

```bash
./bootstrap refresh              # Pull latest from main
./bootstrap refresh develop      # Pull from specific branch
./bootstrap refresh --hard main  # Hard reset (deletes and reclones)
```

## Installation Flow

1. **Repository Configuration** - Prompts for dotFiles repository URL (if not configured)
2. **Homebrew** - Installs Homebrew (macOS only, if not present)
3. **ZSH** - Installs and configures ZSH
4. **SSH Keys** - Generates ed25519 key if needed, helps add to Git service
5. **1Password** (Optional) - Installs CLI and authenticates
6. **dotFiles** - Clones your dotFiles repository
7. **Switch to ZSH** - Switches shell and continues in dotFiles

## 1Password Integration (Optional)

Bootstrap can optionally set up 1Password CLI for secure secret management.

### Prerequisites

**For best experience:** Install the 1Password app BEFORE running bootstrap
- **macOS:** https://1password.com/downloads/mac/
- **Ubuntu:** https://1password.com/downloads/linux/

**Benefits:**
- SSH keys with biometric unlock (Touch ID/Face ID)
- Persistent authentication sessions
- Better system integration

### During Installation

Bootstrap will:
1. Detect if 1Password app is installed
2. Warn if app is missing (but allow CLI-only setup)
3. Install 1Password CLI
4. Authenticate with your account
5. Provide instructions for SSH agent setup

## SSH Key Setup

Bootstrap generates an ed25519 SSH key if you don't have one:
- **Location:** `~/.ssh/id_ed25519`
- **Format:** ed25519 (modern, secure)
- **Helper:** Copies key to clipboard and opens Git service URL

After generation, you can add the key to:
1. GitHub
2. GitLab
3. Your custom Git server

## Requirements

### macOS
- macOS 10.15 or later
- Xcode Command Line Tools
- Internet connection

### Ubuntu
- Ubuntu 20.04 or later
- sudo access
- Internet connection

## Files Created

```
~/.bootstrap/                   # This repository
  ├── bootstrap                 # Main script
  ├── GitHarness.sh            # SSH key helper
  ├── LICENSE
  └── README.md

~/.bootstrap.config             # Optional config (git-ignored)
~/.ssh/id_ed25519              # SSH key (if generated)
~/.ssh/id_ed25519.pub          # SSH public key
~/.dotFiles/                    # Your dotFiles (after installation)
```

## Troubleshooting

### SSH Authentication Failed

```bash
# Test SSH connection
ssh -T git@github.com
# or
ssh -T git@gitlab.com

# Re-add SSH key if needed
ssh-add ~/.ssh/id_ed25519
```

### 1Password CLI Not Authenticating

```bash
# Sign in manually
eval $(op signin)

# Verify authentication
op whoami
```

### Repository Clone Failed

```bash
# Verify SSH key is added to your Git service
# Check repository URL is correct
echo $DOTFILES_REPO

# Try manual clone
git clone $DOTFILES_REPO ~/.dotFiles
```

### Already Installed

```bash
# To reinstall
rm -rf ~/.dotFiles
./bootstrap install

# Or use refresh
./bootstrap refresh --hard
```

## Security

- SSH keys generated with secure defaults (ed25519, 100 rounds)
- Config file (`~/.bootstrap.config`) created with 600 permissions
- No credentials stored in this repository
- No hardcoded personal information

## Public Repository Safe

This bootstrap is designed to be safely shared publicly:
- ✓ No hardcoded domains or usernames
- ✓ No private infrastructure details
- ✓ Generic examples and documentation
- ✓ Your dotFiles repo URL configured separately

## Advanced Usage

### Non-Interactive Installation

```bash
# Set all configuration via environment
export DOTFILES_REPO="git@github.com:username/dotFiles.git"
export SKIP_1PASSWORD=true  # Skip 1Password setup

# Run automated installation
./bootstrap install
```

### Custom Branch

```bash
# Install from specific branch
./bootstrap install feature-branch

# Install from tag
./bootstrap install v2.0.0
```

### Multiple Machines

Use the same `.bootstrap.config` across machines:

```bash
# On first machine
cat ~/.bootstrap.config
# DOTFILES_REPO="git@github.com:username/dotFiles.git"

# On second machine
# Create same config file, then:
./bootstrap install
```

## Credits

Originally inspired by [Lars Kappert's dotfiles work](https://medium.com/@webprolific/getting-started-with-dotfiles-43c3602fd789).

## License

See [LICENSE](LICENSE) file.
