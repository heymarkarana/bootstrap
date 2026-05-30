#!/usr/bin/env bash
# Bash wrapper for bootstrap-curl.zsh — installs zsh on Ubuntu if needed, then runs the zsh entry.
#
# Config (local file or HTTP URL):
#   export DF_BOOTSTRAP_CONFIG="$HOME/.bootstrap.config"
#   export DF_BOOTSTRAP_CONFIG="https://<git-server>/<user>/bootstrap.config"
#
# Then:
#   curl -fsSL "${DF_BOOTSTRAP_PUBLIC_RAW}/scripts/bootstrap-curl.sh" | bash -s -- install minimal

set -euo pipefail

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${HOME}/.local/bin:${PATH}"

_bootstrap_curl_load_config() {
  local config_source="${DF_BOOTSTRAP_CONFIG:-}"

  if [[ -z "$config_source" && -f "${HOME}/.bootstrap.config" ]]; then
    config_source="${HOME}/.bootstrap.config"
  fi
  [[ -z "$config_source" ]] && return 0

  if [[ "$config_source" =~ ^https?:// ]]; then
    if ! command -v curl &>/dev/null; then
      echo "[bootstrap] Error: curl is required to fetch DF_BOOTSTRAP_CONFIG" >&2
      exit 1
    fi
    local tmp
    tmp="$(mktemp "${TMPDIR:-/tmp}/bootstrap_config.XXXXXX")"
    if ! curl -fsSL "$config_source" -o "$tmp"; then
      echo "[bootstrap] Error: could not fetch config: ${config_source}" >&2
      rm -f "$tmp"
      exit 1
    fi
    set -a
    # shellcheck source=/dev/null
    source "$tmp"
    set +a
    rm -f "$tmp"
  else
    local config_path="$config_source"
    [[ "$config_path" == file://* ]] && config_path="${config_path#file://}"
    [[ "$config_path" == "~/"* ]] && config_path="${HOME}/${config_path#~/}"
    if [[ ! -f "$config_path" ]]; then
      echo "[bootstrap] Error: config file not found: ${config_path}" >&2
      exit 1
    fi
    set -a
    # shellcheck source=/dev/null
    source "$config_path"
    set +a
  fi

  export DOTFILES_REPO="${DOTFILES_REPO:-${DF_DOTFILES_REPO:-}}"
  export DF_DOTFILES_REPO="${DF_DOTFILES_REPO:-${DOTFILES_REPO:-}}"
  export DF_BOOTSTRAP_REPO="${DF_BOOTSTRAP_REPO:-}"
  export DF_TROVE_REPO="${DF_TROVE_REPO:-}"
  export DF_BESKAR_REPO="${DF_BESKAR_REPO:-}"
  export DF_BOOTSTRAP_PUBLIC_RAW="${DF_BOOTSTRAP_PUBLIC_RAW:-}"
  export DF_GIT_SSH_HOST="${DF_GIT_SSH_HOST:-}"
}

# Prefer shared lib when this script is run from a checkout (not piped).
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" && -f "${BASH_SOURCE[0]}" ]]; then
  _bootstrap_lib="$(cd "$(dirname "${BASH_SOURCE[0]}")/../lib" && pwd)/bootstrap_config.sh"
  if [[ -f "$_bootstrap_lib" ]]; then
    # shellcheck source=/dev/null
    source "$_bootstrap_lib"
    bootstrap_load_config
  else
    _bootstrap_curl_load_config
  fi
else
  _bootstrap_curl_load_config
fi

if [[ -z "${DF_BOOTSTRAP_PUBLIC_RAW:-}" && -n "${DF_BOOTSTRAP_REPO:-}" ]]; then
  repo="${DF_BOOTSTRAP_REPO%/}"
  repo="${repo%.git}"
  branch="${DF_BOOTSTRAP_BRANCH:-main}"
  if [[ "$repo" =~ ^https?://([^/]+)/(.+)$ ]]; then
    host="${BASH_REMATCH[1]}"
    path="${BASH_REMATCH[2]}"
    if [[ "$host" == "github.com" ]]; then
      export DF_BOOTSTRAP_PUBLIC_RAW="https://raw.githubusercontent.com/${path}/${branch}"
    else
      export DF_BOOTSTRAP_PUBLIC_RAW="https://${host}/${path}/raw/branch/${branch}"
    fi
  fi
fi

if [[ -z "${DF_BOOTSTRAP_PUBLIC_RAW:-}" ]]; then
  echo "[bootstrap] Error: set DF_BOOTSTRAP_PUBLIC_RAW, HTTPS DF_BOOTSTRAP_REPO, or DF_BOOTSTRAP_CONFIG with repo URLs" >&2
  echo "  Example: export DF_BOOTSTRAP_CONFIG=\"https://<git-server>/<user>/bootstrap.config\"" >&2
  exit 1
fi

SCRIPT_URL="${DF_BOOTSTRAP_PUBLIC_RAW%/}/scripts/bootstrap-curl.zsh"

if ! command -v curl &>/dev/null; then
  if [[ -f /etc/os-release ]] && grep -qi ubuntu /etc/os-release 2>/dev/null; then
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl ca-certificates
  else
    echo "[bootstrap] Error: curl is required" >&2
    exit 1
  fi
fi

if ! command -v zsh &>/dev/null; then
  if [[ -f /etc/os-release ]] && grep -qi ubuntu /etc/os-release 2>/dev/null; then
    echo "[bootstrap] Installing zsh and git (sudo)..."
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zsh git ca-certificates openssh-client
  else
    echo "[bootstrap] Error: zsh is required. Install zsh or run the .zsh script directly." >&2
    exit 1
  fi
fi

# Pass through repo/env config to zsh (process substitution cannot source libs from $0).
exec env \
  DF_BOOTSTRAP_PUBLIC_RAW="${DF_BOOTSTRAP_PUBLIC_RAW:-}" \
  DF_BOOTSTRAP_REPO="${DF_BOOTSTRAP_REPO:-}" \
  DF_BOOTSTRAP_BRANCH="${DF_BOOTSTRAP_BRANCH:-}" \
  DOTFILES_REPO="${DOTFILES_REPO:-}" \
  DF_DOTFILES_REPO="${DF_DOTFILES_REPO:-}" \
  DF_TROVE_REPO="${DF_TROVE_REPO:-}" \
  DF_BESKAR_REPO="${DF_BESKAR_REPO:-}" \
  DF_GIT_SSH_HOST="${DF_GIT_SSH_HOST:-}" \
  DF_BOOTSTRAP_CONFIG="${DF_BOOTSTRAP_CONFIG:-}" \
  zsh <(curl -fsSL "$SCRIPT_URL") "$@"
