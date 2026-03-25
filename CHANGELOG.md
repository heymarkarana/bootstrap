# Changelog

All notable changes to Bootstrap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.5] - 2026-03-24

### Fixed
- **Documentation accuracy** - Removed outdated "armory-vault" reference from central registry tools list
  - Only Trove and Beskar are actual `/opt` registered tools
  - The armory is Beskar's data directory, not a separate tool

## [2.1.4] - 2026-03-22

### Changed
- **Migrated to central registry system** - Bootstrap now uses `/opt/.config/kapps/` managed by Trove
  - Removed legacy `/opt/.config/dotFiles` registry creation from `setup_kgroup_infrastructure()`
  - Trove installer now creates and owns the central registry infrastructure
  - All `/opt` tools (Trove, Beskar) register in central location
  - Enables cross-tool discovery and dependency resolution
- **Trove installation** - Now executes Trove's install script after clone/symlink
  - Creates `/opt/.config/kapps/` directory with kgroup ownership
  - Installs registry library (`locations.zsh`) with `kapps_*` functions
  - Self-registers Trove in the central registry
- **Beskar installation** - Now executes Beskar's install script after clone/symlink
  - Initializes armory directory for secure environment management
  - Follows consistent install pattern across all `/opt` tools
- **Updated completion messages** - Changed "dotFiles registry infrastructure" to "Central registry (/opt/.config/kapps/)"

## [2.1.3] - 2026-03-22

### Fixed
- **SSH authentication with sudo git operations** - Resolved "Permission denied (publickey)" errors
  - Issue: `sudo git clone` and `sudo git pull` failed because root doesn't have user's SSH keys
  - Solution: Clone as user in temporary location, then move to /opt with sudo
  - New helper functions: `clone_repo_as_user_to_opt()` and `update_repo_as_user()`
  - Affects: Trove installation (line 834), Trove updates (line 755)
  - Affects: Beskar installation (line 1008), Beskar updates (line 929)
  - Benefits: Works with SSH keys, SSH agent, 1Password, and HTTPS
  - No security compromises: SSH keys never passed to sudo
  - Automatic cleanup on failure
  - Clear error messages for each failure scenario
- **Beskar verification file** - Fixed incorrect verification check
  - Changed from `beskar_crypto.zsh` (doesn't exist) to `beskar_core.zsh` (actual file)

### Changed
- Updated error messages to reflect new clone-then-move approach
- Manual installation instructions now suggest the correct method

## [2.1.2] - 2026-03-22

### Added
- **Beskar security library installation** - New `install_beskar()` function for security utilities
  - Repository: `ssh://git@git.thesecretlab.io/marana/beskar.git`
  - Install location: `/opt/beskar`
  - Verification file: `/opt/beskar/lib/beskar_core.zsh`
  - Development mode support from `~/Sourcecode/thesecretlab/beskar`
  - Full error handling with SSH setup instructions
  - Follows same pattern as Trove installation for consistency

### Changed
- **Improved Trove installation reliability and idempotency**
  - Smart update detection with commit hash comparison (shows `abc123 → def456` changes)
  - Transparent git operations (removed `--quiet` and `2>/dev/null` flags)
  - Fail-fast error handling - returns error code on failures instead of silent warnings
  - Enhanced SSH setup instructions with key generation and test commands
  - Development mode verification - checks required files exist before symlinking
  - Post-update integrity checks to detect corrupted installations
  - Kgroup fallback warnings when kgroup is not found
- **Updated installation dependency chain**
  - Order: kgroup → trove → beskar → dotFiles
  - Fail-fast behavior - exits immediately if trove or beskar installation fails
  - Non-blocking for existing dotFiles - shows warnings but continues when dotFiles already installed
- **Enhanced success messages** - Now lists trove and beskar installations

### Fixed
- Silent git pull failures in Trove updates that continued with stale versions
- Missing error propagation when dependency installations failed
- Lack of verification that git operations actually succeeded

## [2.1.1] - 2026-03-16

### Added
- **kgroup infrastructure setup** - Automatic creation of kgroup and registry infrastructure
  - New `setup_kgroup_infrastructure()` function for system-level group management
  - Creates kgroup on both macOS (dseditgroup) and Ubuntu (groupadd)
  - Adds current user and root to kgroup automatically
  - Creates `/opt/.config/dotFiles/` registry directory with proper permissions
  - Sets ownership to `root:kgroup` with 2775 permissions (setgid + group writable)
  - Immediately sets kgroup ownership on dotFiles after git clone
  - Configures group read+execute permissions on all dotFiles directories and scripts
  - Multi-user ready from bootstrap completion
- HTTPS URL support for initial repository cloning
- Automatic HTTPS → SSH conversion after successful setup
- Smart URL detection in `verify_git_access()`
  - HTTPS URLs: Skip SSH verification
  - SSH URLs: Verify but allow continuing on failure
- Integration with dotFiles v4.0.0 installer
  - Automatically runs `df install` after cloning
  - Triggers interactive configuration interview on first run

### Changed
- **Bootstrap completion message** - Now displays kgroup and registry infrastructure status
- **Repository configuration now recommends HTTPS for initial setup**
  - HTTPS works without SSH keys configured
  - SSH keys managed by 1Password after setup
  - Automatic conversion to SSH for future operations
- Updated `verify_git_access()` to support both HTTPS and SSH
  - HTTPS: No SSH verification required
  - SSH: Verification optional (can continue on failure)
- Updated prompts and help text to show HTTPS examples first
- Installation flow now includes automatic `df install` execution
- README.md completely updated with HTTPS-first approach

### Fixed
- Chicken-and-egg problem where SSH keys weren't available during bootstrap
- Clone failures when 1Password SSH agent not configured yet
- Better error messages when SSH verification fails

### Documentation
- Updated all examples to use HTTPS URLs
- Added explanation of automatic HTTPS → SSH conversion
- Updated installation flow with new steps
- Clarified 1Password SSH agent integration
- Removed references to manual SSH key generation

## [2.1.0] - 2025-12-07

### Added
- **1Password re-authentication command** - New `bootstrap 1password-reauth` command
  - Re-authenticates when 1Password session expires
  - Platform-specific handling for macOS and Ubuntu
  - Aliases: `reauth-1password`, `op-reauth`
- **1Password package verification** - Added debsig-verify policy for secure package installation
  - Verifies package signatures during apt installation
  - Sets up proper keyrings and policies automatically
- **dotFiles already-installed detection** - Smart handling when dotFiles exists
  - Offers to skip, refresh, or exit
  - Prevents accidental overwrites
  - Streamlined workflow for re-running bootstrap

### Changed
- **Improved 1Password authentication flow** - Platform-specific authentication
  - macOS: Guides users to desktop app integration
  - Ubuntu: CLI-only authentication with `op account add`
  - Better error messages and session management guidance
- **Enhanced installation messaging** - Professional formatting with box drawings
  - Clear component completion indicators
  - Better visual separation of installation stages
  - Improved user experience during setup
- **Direct install.zsh execution** - Calls install script directly instead of through df wrapper
  - Works before df.env is created
  - More reliable during initial bootstrap

### Fixed
- Authentication state detection - Now properly checks if already signed in before prompting
- Session expiration handling - Clear instructions for re-authentication on both platforms

## [2.0.0] - 2025-11-23

### Added
- Interactive repository configuration with three methods:
  - Environment variable (`DOTFILES_REPO`)
  - Config file (`~/.bootstrap.config`)
  - Interactive prompt during installation
- Configuration saving option to `~/.bootstrap.config` (600 permissions)
- 1Password app detection before CLI installation
- Warning and guidance when 1Password app is not installed
- Enhanced 1Password setup with benefits explanation
- Generic HTTPS to SSH conversion for any Git domain
- `.gitignore` file to protect sensitive local configuration
- Comprehensive README.md with:
  - Multiple configuration methods
  - Detailed 1Password integration guide
  - Troubleshooting section
  - Security section
  - Public repository safety documentation

### Changed
- **BREAKING:** Removed hardcoded repository URLs
  - Removed `REPO1` (private Git server)
  - Removed `REPO2` (GitHub fallback)
  - All repository configuration now external
- **BREAKING:** Removed `--repo` command line option
  - Use environment variable or config file instead
- GitHarness.sh now supports custom Git services
  - Removed hardcoded "Kuzcotopia GIT" option
  - Added "Other Git Service" with custom URL prompt
- Generic domain conversion in `ensure_bootstrap_ssh_connectivity()`
  - Removed hardcoded domain patterns
  - Now works with any Git hosting service
- 1Password setup flow improved:
  - Checks for app installation first
  - Provides clear warnings and recommendations
  - Explains benefits of app vs CLI-only
- Updated help text to reflect new configuration methods

### Removed
- All hardcoded private infrastructure references:
  - `git.thesecretlab.io` domain
  - Username `marana`
  - GitHub username `heymarkarana`
  - Project codename "Kuzcotopia"
- `parse_arguments()` function (no longer needed)
- `--repo` command line flag

### Security
- Bootstrap is now safe for public GitHub/GitLab hosting
- No private infrastructure details exposed
- Config file created with 600 permissions
- `.gitignore` prevents accidental commits of sensitive data
- Generic examples throughout documentation

## [1.0.0] - 2024-08-02

### Added
- Initial release
- macOS and Ubuntu support
- Homebrew installation (macOS)
- ZSH installation and configuration
- SSH key generation (ed25519)
- GitHarness.sh for SSH key management
- 1Password CLI integration
- dotFiles repository cloning
- Branch and tag support

### Features
- `install` command for fresh setup
- `refresh` command for updates
- `refresh --hard` for complete reinstall
- Automatic shell switching to ZSH

[Unreleased]: https://github.com/yourusername/bootstrap/compare/v2.0.0...HEAD
[2.0.0]: https://github.com/yourusername/bootstrap/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/yourusername/bootstrap/releases/tag/v1.0.0
