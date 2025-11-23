# Changelog

All notable changes to Bootstrap will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
