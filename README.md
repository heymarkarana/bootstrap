# Bootstrap

Minimal bootstrap script to prepare a fresh macOS or Ubuntu system for dotFiles installation.

## What it Does

- Installs prerequisites (Homebrew, ZSH)
- Optionally configures 1Password CLI for SSH key management
- Clones your dotFiles repository (HTTPS or SSH)
- Respects your chosen protocol (HTTPS or SSH)
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
ssh://git@github.com/username/dotFiles.git
ssh://git@gitlab.com/username/dotFiles.git
git@github.com:username/dotFiles.git  # Traditional format also supported
```

**Why HTTPS for initial setup?**
- No SSH keys required yet
- Works immediately without authentication setup
- Use your preferred protocol - both work equally well
- Optional: Convert to SSH later if needed

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
4. **1Password** (Optional) - Installs CLI for secret management
5. **Git Access Verification** - Verifies access (SSH) or accepts URL (HTTPS)
6. **Clone dotFiles** - Clones your dotFiles repository
7. **Run dotFiles Installer** - Triggers `df install` for v4.0.0 configuration
8. **Switch to ZSH** - Switches shell with dotFiles fully configured

## 1Password Integration (Optional)

Bootstrap can optionally set up 1Password CLI for secure secret management.

### CLI-Only Mode

The 1Password CLI works standalone without requiring the desktop app.

**During Installation:**
1. Installs 1Password CLI (`op`)
2. Authenticates using `op account add` (requires Secret Key + Master Password)
3. Works identically on macOS and Ubuntu
4. Full functionality over SSH and remote terminals

**Optional Desktop App Features:**
- GUI password management
- SSH agent with biometric unlock (macOS only - Touch ID/Face ID)

**To install desktop app later (optional):**
- macOS: https://1password.com/downloads/mac/
- Ubuntu: https://1password.com/downloads/linux/

## SSH Key Management

### Option 1: 1Password SSH Agent (Optional)

With 1Password desktop app + SSH agent enabled:
- **Storage:** 1Password vault (not on disk)
- **Authentication:** Biometric unlock (Touch ID/Face ID on macOS)
- **Security:** Keys never written to filesystem
- **Access:** Automatic via SSH agent

Enable in 1Password: Settings → Developer → "Use the SSH agent"

### Option 2: Traditional SSH Keys

Generate and use standard SSH keys:
```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

### Option 3: HTTPS (No SSH Keys Required)

Use HTTPS URLs - works without any SSH configuration:
- No authentication required for public repos
- Personal Access Token for private repos
- Works identically on all platforms

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

**Note:** SSH keys can be managed by 1Password (optional) or stored traditionally in ~/.ssh

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

# Option 3: Check 1Password SSH agent (if using desktop app)
# macOS: 1Password → Settings → Developer → Enable "Use the SSH agent"
```

### 1Password CLI Not Authenticating

```bash
# Re-authenticate with CLI
eval $(op signin)

# Or add account again
op account add

# Verify authentication
op account list
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
```

## Credits

Originally inspired by [Lars Kappert's dotfiles work](https://medium.com/@webprolific/getting-started-with-dotfiles-43c3602fd789).

## License

See [LICENSE](LICENSE) file.
