#!/usr/bin/env zsh
# Load bootstrap repository URLs from a local file or HTTP(S) URL.

# Resolve config source: DF_BOOTSTRAP_CONFIG, else ~/.bootstrap.config if present.
# Prints path or URL to stdout; return 1 if none configured.
df_bootstrap_config_source() {
  if [[ -n "${DF_BOOTSTRAP_CONFIG:-}" ]]; then
    print -r -- "${DF_BOOTSTRAP_CONFIG}"
    return 0
  fi
  if [[ -f "${HOME}/.bootstrap.config" ]]; then
    print -r -- "${HOME}/.bootstrap.config"
    return 0
  fi
  return 1
}

# Load bootstrap config (shell assignments: DOTFILES_REPO=..., etc.)
# Args: $1 optional override path or URL (default: df_bootstrap_config_source)
# Env:  DF_BOOTSTRAP_CONFIG — local path, file:// path, or https:// URL
# Returns 0 on success or when no config is configured; 1 on fetch/read failure.
df_bootstrap_load_config() {
  local config_source="${1:-}"
  local required=false

  if [[ -n "$config_source" ]]; then
    required=true
  elif [[ -n "${DF_BOOTSTRAP_CONFIG:-}" ]]; then
    config_source="${DF_BOOTSTRAP_CONFIG}"
    required=true
  elif [[ -f "${HOME}/.bootstrap.config" ]]; then
    config_source="${HOME}/.bootstrap.config"
  else
    return 0
  fi

  if [[ "$config_source" =~ ^https?:// ]]; then
    if ! command -v curl &>/dev/null; then
      echo "[bootstrap] Error: curl is required to fetch DF_BOOTSTRAP_CONFIG" >&2
      return 1
    fi
    local tmp
    tmp="$(mktemp "${TMPDIR:-/tmp}/bootstrap_config.XXXXXX")"
    if ! curl -fsSL "$config_source" -o "$tmp"; then
      echo "[bootstrap] Error: could not fetch config: ${config_source}" >&2
      rm -f "$tmp"
      return 1
    fi
    # shellcheck source=/dev/null
    source "$tmp"
    rm -f "$tmp"
  else
    local config_path="$config_source"
    if [[ "$config_path" =~ ^file://(.+)$ ]]; then
      config_path="${match[1]}"
    fi
    if [[ "$config_path" == "~/"* ]]; then
      config_path="${HOME}/${config_path#~/}"
    elif [[ "$config_path" == "~" ]]; then
      config_path="${HOME}"
    fi

    if [[ ! -f "$config_path" ]]; then
      echo "[bootstrap] Error: config file not found: ${config_path}" >&2
      return 1
    fi
    # shellcheck source=/dev/null
    source "$config_path"
  fi

  [[ -n "${DOTFILES_REPO:-}" ]] && export DF_DOTFILES_REPO="${DF_DOTFILES_REPO:-$DOTFILES_REPO}"
  [[ -n "${DF_DOTFILES_REPO:-}" && -z "${DOTFILES_REPO:-}" ]] && export DOTFILES_REPO="$DF_DOTFILES_REPO"

  return 0
}

if [[ -n "$ZSH_VERSION" ]]; then
  typeset -fx df_bootstrap_config_source df_bootstrap_load_config >/dev/null 2>&1
fi
