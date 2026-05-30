#!/usr/bin/env zsh
# Public HTTP entry — full cold-start bootstrap (SSH → Trove → Beskar → dotFiles → setup)
#
# Configure repositories (or use ~/.bootstrap.config), then:
#   curl -fsSL "${DF_BOOTSTRAP_PUBLIC_RAW}/scripts/bootstrap-curl.sh" | bash -s -- install minimal

DF_BOOTSTRAP_HOME="${HOME}/.bootstrap"
DF_DOTFILES_HOME="${HOME}/.dotFiles"

_df_curl_harmonize_repo_exports() {
  export DOTFILES_REPO="${DOTFILES_REPO:-${DF_DOTFILES_REPO:-}}"
  export DF_DOTFILES_REPO="${DF_DOTFILES_REPO:-${DOTFILES_REPO:-}}"
  [[ -n "${DOTFILES_REPO:-}" ]] && export DF_DOTFILES_REPO="$DOTFILES_REPO"
}

_df_curl_resolve_public_raw() {
  if [[ -n "${DF_BOOTSTRAP_PUBLIC_RAW:-}" ]]; then
    export DF_BOOTSTRAP_PUBLIC_RAW="${DF_BOOTSTRAP_PUBLIC_RAW%/}"
    return 0
  fi
  if typeset -f df_bootstrap_resolve_public_raw &>/dev/null; then
    df_bootstrap_resolve_public_raw && return 0
  fi
  local repo="${DF_BOOTSTRAP_REPO:-}"
  local branch="${DF_BOOTSTRAP_BRANCH:-main}"
  repo="${repo%/}"
  repo="${repo%.git}"
  [[ "$repo" =~ ^https?://([^/]+)/(.+)$ ]] || return 1
  if [[ "${match[1]}" == "github.com" ]]; then
    export DF_BOOTSTRAP_PUBLIC_RAW="https://raw.githubusercontent.com/${match[2]}/${branch}"
  else
    export DF_BOOTSTRAP_PUBLIC_RAW="https://${match[1]}/${match[2]}/raw/branch/${branch}"
  fi
  return 0
}

_df_curl_fetch_config_lib() {
  local c
  local candidates=(
    "${DF_BOOTSTRAP_HOME}/lib/bootstrap_config.zsh"
    "${DF_DOTFILES_HOME}/lib/bootstrap_config.zsh"
  )
  for c in "${candidates[@]}"; do
    [[ -f "$c" ]] && print -r -- "$c" && return 0
  done

  _df_curl_resolve_public_raw || true

  local base tmp
  for base in "${DF_BOOTSTRAP_PUBLIC_RAW:-}" "${DF_BOOTSTRAP_RAW_URL:-}"; do
    [[ -z "$base" ]] && continue
    tmp="$(mktemp "${TMPDIR:-/tmp}/bootstrap_config.XXXXXX")"
    if curl -fsSL "${base%/}/lib/bootstrap_config.zsh" -o "$tmp" 2>/dev/null; then
      print -r -- "$tmp"
      return 0
    fi
    rm -f "$tmp"
  done
  return 1
}

_df_curl_source_bootstrap_config() {
  if typeset -f df_bootstrap_load_config &>/dev/null; then
    df_bootstrap_load_config || return 1
    _df_curl_harmonize_repo_exports
    return 0
  fi

  local lib
  if lib="$(_df_curl_fetch_config_lib)"; then
    source "$lib"
    [[ "$lib" == /tmp/* || "$lib" == "${TMPDIR:-/tmp}"/* ]] && rm -f "$lib"
    if typeset -f df_bootstrap_load_config &>/dev/null; then
      df_bootstrap_load_config || return 1
    fi
    _df_curl_harmonize_repo_exports
    return 0
  fi

  if [[ -f "${HOME}/.bootstrap.config" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "${HOME}/.bootstrap.config"
    set +a
    _df_curl_harmonize_repo_exports
    return 0
  fi

  _df_curl_harmonize_repo_exports
  return 0
}

_df_curl_ensure_path() {
  export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${HOME}/.local/bin:${PATH}"
  [[ -d "/snap/bin" ]] && export PATH="${PATH}:/snap/bin"
  [[ -d "/opt/homebrew/bin" ]] && export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}"
}

_df_curl_ensure_prereqs() {
  _df_curl_ensure_path

  if ! command -v curl &>/dev/null; then
    echo "[bootstrap] Error: curl is required" >&2
    exit 1
  fi

  if ! command -v zsh &>/dev/null; then
    if [[ -f /etc/os-release ]] && grep -qi ubuntu /etc/os-release 2>/dev/null; then
      echo "[bootstrap] Installing zsh, git, and ca-certificates (sudo)..."
      sudo apt-get update -qq
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zsh git ca-certificates openssh-client || {
        echo "[bootstrap] Error: could not install prerequisites" >&2
        exit 1
      }
      _df_curl_ensure_path
    else
      echo "[bootstrap] Error: zsh is required. Install zsh and re-run." >&2
      exit 1
    fi
  fi

  if ! command -v git &>/dev/null; then
    if [[ -f /etc/os-release ]] && grep -qi ubuntu /etc/os-release 2>/dev/null; then
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq git || exit 1
      _df_curl_ensure_path
    else
      echo "[bootstrap] Error: git is required" >&2
      exit 1
    fi
  fi
}

_df_curl_require_dotfiles_repo() {
  _df_curl_source_bootstrap_config || true
  if [[ -z "${DOTFILES_REPO:-}" ]]; then
    echo "[bootstrap] Error: DOTFILES_REPO is required" >&2
    echo "  Example: export DOTFILES_REPO=\"ssh://git@git.example.com/<user>/dotFiles.git\"" >&2
    exit 1
  fi
}

_df_curl_require_install_repos() {
  _df_curl_require_dotfiles_repo
  _df_curl_source_bootstrap_ssh

  if [[ -z "${DF_BOOTSTRAP_REPO:-}" ]]; then
    echo "[bootstrap] Error: DF_BOOTSTRAP_REPO is required (public HTTPS bootstrap clone)" >&2
    echo "  Example: export DF_BOOTSTRAP_REPO=\"https://git.example.com/<user>/bootstrap.git\"" >&2
    exit 1
  fi

  if ! _df_curl_resolve_public_raw; then
    echo "[bootstrap] Error: set DF_BOOTSTRAP_PUBLIC_RAW or use an HTTPS DF_BOOTSTRAP_REPO" >&2
    echo "  Example: export DF_BOOTSTRAP_PUBLIC_RAW=\"https://git.example.com/<user>/bootstrap/raw/main\"" >&2
    exit 1
  fi

  if [[ -z "${DF_TROVE_REPO:-}" ]]; then
    echo "[bootstrap] Error: DF_TROVE_REPO is required" >&2
    echo "  Example: export DF_TROVE_REPO=\"ssh://git@git.example.com/<user>/trove.git\"" >&2
    exit 1
  fi

  if [[ -z "${DF_BESKAR_REPO:-}" ]]; then
    echo "[bootstrap] Error: DF_BESKAR_REPO is required" >&2
    echo "  Example: export DF_BESKAR_REPO=\"ssh://git@git.example.com/<user>/beskar.git\"" >&2
    exit 1
  fi
}

_df_curl_fetch_lib() {
  local c
  local candidates=(
    "${DF_BOOTSTRAP_HOME}/lib/bootstrap_ssh.zsh"
    "${DF_DOTFILES_HOME}/lib/bootstrap_ssh.zsh"
  )
  for c in "${candidates[@]}"; do
    if [[ -f "$c" ]]; then
      print -r -- "$c"
      return 0
    fi
  done

  _df_curl_source_bootstrap_config || true
  _df_curl_resolve_public_raw || true

  local base tmp
  for base in "${DF_BOOTSTRAP_PUBLIC_RAW:-}" "${DF_BOOTSTRAP_RAW_URL:-}"; do
    [[ -z "$base" ]] && continue
    tmp="$(mktemp "${TMPDIR:-/tmp}/bootstrap_ssh.XXXXXX")"
    if curl -fsSL "${base%/}/lib/bootstrap_ssh.zsh" -o "$tmp" 2>/dev/null; then
      print -r -- "$tmp"
      return 0
    fi
    rm -f "$tmp"
  done
  return 1
}

_df_curl_source_bootstrap_ssh() {
  local lib
  lib="$(_df_curl_fetch_lib)" || {
    echo "[bootstrap] Error: could not load lib/bootstrap_ssh.zsh" >&2
    echo "  Set DF_BOOTSTRAP_PUBLIC_RAW or HTTPS DF_BOOTSTRAP_REPO" >&2
    exit 1
  }
  source "$lib"
  [[ "$lib" == /tmp/* || "$lib" == "${TMPDIR:-/tmp}"/* ]] && rm -f "$lib"
}

_df_curl_ensure_bootstrap_clone() {
  if [[ -d "${DF_BOOTSTRAP_HOME}/.git" ]]; then
    echo "[bootstrap] Using existing ${DF_BOOTSTRAP_HOME}"
    return 0
  fi

  echo "[bootstrap] Cloning bootstrap (public HTTPS) from ${DF_BOOTSTRAP_REPO}..."
  git clone --depth 1 --branch "${DF_BOOTSTRAP_BRANCH:-main}" \
    "${DF_BOOTSTRAP_REPO}" "${DF_BOOTSTRAP_HOME}" || {
    echo "[bootstrap] Error: failed to clone bootstrap repository" >&2
    exit 1
  }
  echo "[bootstrap] Bootstrap repository ready at ${DF_BOOTSTRAP_HOME}"
}

_df_curl_usage() {
  cat <<'EOF'
Usage: bootstrap-curl <command> [profile]

Commands:
  keys                 Generate SSH key and verify Git host access
  install [profile]    Full bootstrap: SSH, Trove, Beskar, dotFiles, setup (default: minimal)

Required (environment or config file — see bootstrap.config.example):
  DF_BOOTSTRAP_REPO        Public HTTPS URL to clone bootstrap
  DOTFILES_REPO            dotFiles SSH URL (private Git, after keys)
  DF_TROVE_REPO            Trove SSH URL
  DF_BESKAR_REPO           Beskar SSH URL

Config source (pick one):
  DF_BOOTSTRAP_CONFIG      Local path, file:// path, or https:// URL to a shell config
  ~/.bootstrap.config      Default local file when DF_BOOTSTRAP_CONFIG is unset

Optional:
  DF_BOOTSTRAP_PUBLIC_RAW  Raw HTTP base (derived from DF_BOOTSTRAP_REPO if HTTPS)
  DF_GIT_SSH_HOST          Git SSH hostname (derived from DOTFILES_REPO if unset)
  DF_BOOTSTRAP_BRANCH      Git branch (default: main)

Example:
  export DF_BOOTSTRAP_REPO="https://git.example.com/<user>/bootstrap.git"
  export DOTFILES_REPO="ssh://git@git.example.com/<user>/dotFiles.git"
  export DF_TROVE_REPO="ssh://git@git.example.com/<user>/trove.git"
  export DF_BESKAR_REPO="ssh://git@git.example.com/<user>/beskar.git"
  curl -fsSL "${DF_BOOTSTRAP_PUBLIC_RAW}/scripts/bootstrap-curl.sh" | bash -s -- install minimal
EOF
}

cmd_keys() {
  _df_curl_require_dotfiles_repo
  _df_curl_source_bootstrap_ssh
  df_bootstrap_ssh_prepare "${DOTFILES_REPO}"
}

cmd_install() {
  local profile="${1:-minimal}"

  case "$profile" in
    minimal|developer|server|creative) ;;
    --help|-h|help)
      _df_curl_usage
      exit 0
      ;;
    *)
      echo "[bootstrap] Unknown profile: ${profile}" >&2
      _df_curl_usage >&2
      exit 1
      ;;
  esac

  _df_curl_require_install_repos

  echo ""
  echo "════════════════════════════════════════════════════════════════"
  echo "  dotFiles cold-start bootstrap (profile: ${profile})"
  echo "════════════════════════════════════════════════════════════════"
  echo ""

  _df_curl_source_bootstrap_ssh
  df_bootstrap_ssh_prepare "${DOTFILES_REPO}" || exit 1
  export DF_BOOTSTRAP_SKIP_GITHARNESS=1
  export DF_BOOTSTRAP_SSH_VERIFIED=1

  _df_curl_ensure_bootstrap_clone

  export DOTFILES_REPO DF_DOTFILES_REPO DF_TROVE_REPO DF_BESKAR_REPO
  export BOOTSTRAP_PROFILE="${profile}"

  echo "[bootstrap] Starting full install via ${DF_BOOTSTRAP_HOME}/bootstrap ..."
  cd "${DF_BOOTSTRAP_HOME}" || exit 1
  exec env PATH="$PATH" HOME="$HOME" \
    DOTFILES_REPO="$DOTFILES_REPO" \
    DF_DOTFILES_REPO="$DOTFILES_REPO" \
    DF_TROVE_REPO="$DF_TROVE_REPO" \
    DF_BESKAR_REPO="$DF_BESKAR_REPO" \
    DF_BOOTSTRAP_REPO="$DF_BOOTSTRAP_REPO" \
    DF_BOOTSTRAP_PUBLIC_RAW="$DF_BOOTSTRAP_PUBLIC_RAW" \
    DF_BOOTSTRAP_SKIP_GITHARNESS="${DF_BOOTSTRAP_SKIP_GITHARNESS:-1}" \
    DF_BOOTSTRAP_SSH_VERIFIED="${DF_BOOTSTRAP_SSH_VERIFIED:-1}" \
    BOOTSTRAP_PROFILE="$profile" \
    ./bootstrap install "$profile"
}

_df_curl_ensure_prereqs
_df_curl_source_bootstrap_config || true
_df_curl_resolve_public_raw || true

if [[ $# -eq 0 ]]; then
  _df_curl_usage
  exit 0
fi

case "$1" in
  keys)
    shift
    cmd_keys "$@"
    ;;
  install)
    shift
    cmd_install "$@"
    ;;
  --help|-h|help)
    _df_curl_usage
    ;;
  minimal|developer|server|creative)
    cmd_install "$@"
    ;;
  *)
    echo "[bootstrap] Unknown command: $1" >&2
    _df_curl_usage >&2
    exit 1
    ;;
esac
