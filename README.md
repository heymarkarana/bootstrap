# Bootstrap

Minimal bootstrap script to prepare a fresh macOS or Ubuntu system for dotFiles installation.

## What it Does

- Installs prerequisites (Homebrew, ZSH)
- Optionally configures 1Password CLI for SSH key management
- Clones your dotFiles repository (HTTPS or SSH)
- Automatically converts HTTPS → SSH after setup
- Integrates with dotFiles v4.0.0 installer

## Quick Start

```bash
# 1. Install prerequisites
sudo softwareupdate -i -a  # macOS only
xcode-select --install      # macOS only

# 2. Clone this bootstrap repository
git clone https://github.com/yourusername/bootstrap.git $HOME/.bootstrap
cd $HOME/.bootstrap

# 3. Configure your dotFiles repository (one of these methods):

# Method A: Environment variable (HTTPS recommended for initial setup)
export DOTFILES_REPO="https://github.com/yourusername/dotFiles.git"

# Method B: Config file
cat > ~/.bootstrap.config <<'EOF'
DOTFILES_REPO="https://github.com/yourusername/dotFiles.git"
EOF

# Method C: Interactive prompt (will ask during installation)
# Note: HTTPS URLs will be automatically converted to SSH after setup

# 4. Run installation
./bootstrap install
```

## Configuration

### Repository Configuration

The bootstrap script needs to know where your dotFiles repository is located. You can configure this in three ways (in order of precedence):

**1. Environment Variable** (Recommended for automation)
```bash
export DOTFILES_REPO="https://github.com/yourusername/dotFiles.git"
./bootstrap install
```

**2. Config File** (Recommended for manual use)
```bash
# Create ~/.bootstrap.config
cat > ~/.bootstrap.config <<'EOF'
DOTFILES_REPO="https://github.com/yourusername/dotFiles.git"
EOF
chmod 600 ~/.bootstrap.config

./bootstrap install
```

**3. Interactive Prompt** (Default)
```bash
# Bootstrap will prompt you for the repository URL
./bootstrap install
# Enter: https://github.com/yourusername/dotFiles.git
# Save config? Y
```

### Supported Repository Formats

Bootstrap supports both HTTPS and SSH URLs:

```bash
# HTTPS (Recommended for initial setup - no SSH keys required)
https://github.com/username/dotFiles.git
https://gitlab.com/username/dotFiles.git
https://git.example.com/username/dotFiles.git

# SSH (Requires SSH keys already configured)
git@github.com:username/dotFiles.git
git@gitlab.com:username/dotFiles.git
git@git.example.com:username/dotFiles.git
```

**Why HTTPS for initial setup?**
- No SSH keys required yet
- Works immediately without authentication setup
- Automatically converted to SSH after 1Password configures SSH keys
- Future git operations use SSH with 1Password SSH agent

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
4. **1Password** (Optional) - Installs CLI and configures SSH agent
5. **Git Access Verification** - Verifies access (SSH) or accepts URL (HTTPS)
6. **Clone dotFiles** - Clones your dotFiles repository
7. **HTTPS → SSH Conversion** - Automatically converts HTTPS to SSH (if applicable)
8. **Run dotFiles Installer** - Triggers `df install` for v4.0.0 configuration
9. **Switch to ZSH** - Switches shell with dotFiles fully configured

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

## SSH Key Management

### Recommended: 1Password SSH Agent

With 1Password installed, SSH keys are managed securely:
- **Storage:** 1Password vault (not on disk)
- **Authentication:** Biometric unlock (Touch ID/Face ID)
- **Security:** Keys never written to filesystem
- **Access:** Automatic via SSH agent

### Alternative: HTTPS Clone

If SSH keys aren't configured yet:
- Use HTTPS URL for initial clone
- No authentication required for public repos
- Bootstrap automatically converts to SSH after setup
- Future operations use 1Password SSH agent

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
  ├── GitHarness.sh            # SSH key helper (optional)
  ├── LICENSE
  └── README.md

~/.bootstrap.config             # Optional config (git-ignored, 600 permissions)
~/.dotFiles/                    # Your dotFiles (after installation)
~/.config/dotFiles/             # dotFiles v4.0.0 configuration
  └── local.config              # Created by df config configure
```

**Note:** SSH keys are managed by 1Password (not stored in ~/.ssh)

## Troubleshooting

### SSH Authentication Failed

```bash
# Option 1: Use HTTPS instead (recommended for initial setup)
export DOTFILES_REPO="https://github.com/username/dotFiles.git"
./bootstrap install

# Option 2: Verify SSH connectivity
ssh -T git@github.com
# or
ssh -T git@gitlab.com

# Option 3: Check 1Password SSH agent
# Settings → Developer → Enable "Use the SSH agent"
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
export DOTFILES_REPO="https://github.com/username/dotFiles.git"
export SKIP_1PASSWORD=true  # Skip 1Password setup (optional)

# Run automated installation
./bootstrap install

# HTTPS will be automatically converted to SSH after setup
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
# DOTFILES_REPO="https://github.com/username/dotFiles.git"

# On second machine
# Copy config file, then:
scp first-machine:~/.bootstrap.config ~/
./bootstrap install

# Each machine will convert HTTPS → SSH independently
```

## Credits

Originally inspired by [Lars Kappert's dotfiles work](https://medium.com/@webprolific/getting-started-with-dotfiles-43c3602fd789).

## License

See [LICENSE](LICENSE) file.
