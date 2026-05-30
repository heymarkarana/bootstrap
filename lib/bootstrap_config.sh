#!/usr/bin/env bash
# Load bootstrap repository URLs from a local file or HTTP(S) URL (bash).

bootstrap_config_source() {
  if [[ -n "${DF_BOOTSTRAP_CONFIG:-}" ]]; then
    printf '%s\n' "${DF_BOOTSTRAP_CONFIG}"
    return 0
  fi
  if [[ -f "${HOME}/.bootstrap.config" ]]; then
    printf '%s\n' "${HOME}/.bootstrap.config"
    return 0
  fi
  return 1
}

bootstrap_load_config() {
  local config_source="${1:-}"

  if [[ -z "$config_source" ]]; then
    config_source="$(bootstrap_config_source)" || return 0
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
    set -a
    # shellcheck source=/dev/null
    source "$tmp"
    set +a
    rm -f "$tmp"
  else
    local config_path="$config_source"
    if [[ "$config_path" == file://* ]]; then
      config_path="${config_path#file://}"
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
    set -a
    # shellcheck source=/dev/null
    source "$config_path"
    set +a
  fi

  export DOTFILES_REPO="${DOTFILES_REPO:-${DF_DOTFILES_REPO:-}}"
  export DF_DOTFILES_REPO="${DF_DOTFILES_REPO:-${DOTFILES_REPO:-}}"

  return 0
}
