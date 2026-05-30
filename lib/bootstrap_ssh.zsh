#!/usr/bin/env zsh
# Bootstrap SSH — key preparation and Git host verification (no df_bootstrap/Trove).

# Defaults (override via environment)
: ${DF_GIT_SSH_TEST_USER:=git}
: ${DF_BOOTSTRAP_SSH_KEY:="${HOME}/.ssh/id_ed25519"}
: ${DF_GIT_SSH_HOST:=}

_df_bootstrap_minimal_path() {
  local p="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  [[ -d "/snap/bin" ]] && p="${p}:/snap/bin"
  [[ -d "${HOME}/.local/bin" ]] && p="${HOME}/.local/bin:${p}"
  [[ -d "/opt/homebrew/bin" ]] && p="/opt/homebrew/bin:${p}"
  [[ -d "/opt/homebrew/sbin" ]] && p="/opt/homebrew/sbin:${p}"
  echo "$p"
}

_df_bootstrap_ensure_path() {
  local missing=false
  for cmd in mkdir chmod ssh-keygen ssh ssh-keyscan cat; do
    if ! command -v "$cmd" &>/dev/null; then
      missing=true
      break
    fi
  done
  if [[ "$missing" == true ]] || [[ -z "$PATH" ]]; then
    export PATH="$(_df_bootstrap_minimal_path)"
  fi
  return 0
}

# Parse Git SSH host from URL or bare hostname.
# Prints host to stdout; return 0 if parsed.
_df_git_ssh_host_from_url() {
  local url="$1"
  local host=""

  [[ -z "$url" ]] && return 1

  if [[ "$url" =~ ^ssh://git@([^/]+) ]]; then
    host="${match[1]}"
  elif [[ "$url" =~ ^git@([^:]+): ]]; then
    host="${match[1]}"
  elif [[ "$url" =~ ^https?://([^/]+) ]]; then
    host="${match[1]}"
  elif [[ "$url" != */* && "$url" != *:* ]]; then
    host="$url"
  fi

  if [[ -n "$host" ]]; then
    print -r -- "$host"
    return 0
  fi
  return 1
}

# Resolve host: explicit DF_GIT_SSH_HOST, or parse from a repository URL.
_df_bootstrap_ssh_resolve_host() {
  local repo_url="${1:-}"

  if [[ -n "${DF_GIT_SSH_HOST}" ]]; then
    print -r -- "$DF_GIT_SSH_HOST"
    return 0
  fi

  if [[ -n "$repo_url" ]]; then
    _df_git_ssh_host_from_url "$repo_url" && return 0
  fi

  return 1
}

[[ -f "${0:A:h}/bootstrap_config.zsh" ]] && source "${0:A:h}/bootstrap_config.zsh"

# Derive Forgejo/GitLab/Gitea-style raw base from HTTPS repo URL.
# GitHub: https://github.com/user/repo.git -> https://raw.githubusercontent.com/user/repo/branch
df_bootstrap_public_raw_from_https_repo() {
  local repo="${1:-}"
  local branch="${DF_BOOTSTRAP_BRANCH:-main}"
  repo="${repo%/}"
  repo="${repo%.git}"

  [[ "$repo" =~ ^https?://([^/]+)/(.+)$ ]] || return 1

  if [[ "${match[1]}" == "github.com" ]]; then
    print -r -- "https://raw.githubusercontent.com/${match[2]}/${branch}"
  else
    print -r -- "https://${match[1]}/${match[2]}/raw/branch/${branch}"
  fi
  return 0
}

# Set DF_BOOTSTRAP_PUBLIC_RAW from env or DF_BOOTSTRAP_REPO (HTTPS).
df_bootstrap_resolve_public_raw() {
  if [[ -n "${DF_BOOTSTRAP_PUBLIC_RAW:-}" ]]; then
    export DF_BOOTSTRAP_PUBLIC_RAW="${DF_BOOTSTRAP_PUBLIC_RAW%/}"
    return 0
  fi
  if [[ -n "${DF_BOOTSTRAP_REPO:-}" ]]; then
    local derived
    derived="$(df_bootstrap_public_raw_from_https_repo "${DF_BOOTSTRAP_REPO}")" || return 1
    export DF_BOOTSTRAP_PUBLIC_RAW="$derived"
    return 0
  fi
  return 1
}

# Add host to known_hosts if missing.
_df_bootstrap_ssh_known_hosts() {
  local host="$1"
  [[ -z "$host" ]] && return 1

  local ssh_dir="${HOME}/.ssh"
  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  if ssh-keygen -F "$host" &>/dev/null; then
    return 0
  fi

  if command -v ssh-keyscan &>/dev/null; then
    ssh-keyscan -H "$host" >> "${ssh_dir}/known_hosts" 2>/dev/null
    return $?
  fi
  return 1
}

# BatchMode ssh -T test for git@host.
# Returns 0 if authentication appears successful.
df_bootstrap_ssh_verify() {
  local host="${1:-}"
  local user="${2:-$DF_GIT_SSH_TEST_USER}"

  _df_bootstrap_ensure_path
  [[ -z "$host" ]] && return 1

  _df_bootstrap_ssh_known_hosts "$host" || true

  local out
  out="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
    -T "${user}@${host}" 2>&1)" || true

  if print -r -- "$out" | grep -qiE \
    'successfully authenticated|you.?ve successfully authenticated|welcome to gitlab|hi there|Hi .+! You'; then
    return 0
  fi
  return 1
}

_df_bootstrap_ssh_show_pubkey() {
  local pub="${DF_BOOTSTRAP_SSH_KEY}.pub"
  if [[ -f "$pub" ]]; then
    echo ""
    echo "Public key (add to your Git server):"
    echo "────────────────────────────────────────"
    cat "$pub"
    echo "────────────────────────────────────────"
    echo ""
  fi
}

_df_bootstrap_ssh_curl_hint() {
  echo "Prepare SSH keys / full cold start (set DF_BOOTSTRAP_PUBLIC_RAW or DF_BOOTSTRAP_REPO first):"
  echo "  export DF_BOOTSTRAP_REPO=\"https://git.example.com/<user>/bootstrap.git\""
  echo "  export DOTFILES_REPO=\"ssh://git@git.example.com/<user>/dotFiles.git\""
  echo "  curl -fsSL \"\${DF_BOOTSTRAP_PUBLIC_RAW}/scripts/bootstrap-curl.sh\" | bash -s -- install minimal"
  echo "  Or: cd ~/.bootstrap && ./bootstrap keys"
}

# Prepare ~/.ssh, generate ed25519 if missing, verify git@host access.
# Args: $1 optional repo URL to derive host
# Env: DF_BOOTSTRAP_SSH_NONINTERACTIVE=true — fail instead of prompting
df_bootstrap_ssh_prepare() {
  local repo_url="${1:-}"
  local host
  local ssh_dir="${HOME}/.ssh"
  local key_path="${DF_BOOTSTRAP_SSH_KEY}"
  local email="${DF_BOOTSTRAP_SSH_EMAIL:-${USER}@$(hostname -f 2>/dev/null || hostname)}"

  _df_bootstrap_ensure_path
  host="$(_df_bootstrap_ssh_resolve_host "$repo_url")" || host=""

  if [[ -z "$host" ]]; then
    echo "[DF] Error: cannot determine Git SSH host" >&2
    echo "  Set DF_GIT_SSH_HOST or DOTFILES_REPO (SSH URL with hostname)" >&2
    _df_bootstrap_ssh_curl_hint
    return 1
  fi

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  if [[ ! -f "$key_path" ]]; then
    echo "Generating SSH key: ${key_path}"
    if ! ssh-keygen -t ed25519 -C "$email" -f "$key_path" -N "" </dev/null; then
      echo "[DF] Error: ssh-keygen failed" >&2
      return 1
    fi
    chmod 600 "$key_path"
    chmod 644 "${key_path}.pub"
    echo "SSH key created."
  else
    echo "Using existing SSH key: ${key_path}"
  fi

  _df_bootstrap_ssh_show_pubkey
  _df_bootstrap_ssh_known_hosts "$host" || echo "[DF] Warning: could not update known_hosts for ${host}" >&2

  echo "Verifying SSH access to ${DF_GIT_SSH_TEST_USER}@${host}..."

  if df_bootstrap_ssh_verify "$host"; then
    echo "SSH access to ${host} verified."
    return 0
  fi

  if [[ "${DF_BOOTSTRAP_SSH_NONINTERACTIVE:-}" == true ]]; then
    echo "[DF] Error: SSH verification failed for ${host} (non-interactive mode)" >&2
    _df_bootstrap_ssh_curl_hint
    return 1
  fi

  echo ""
  echo "Add the public key above to your Git server, then press Enter to retry."
  echo "(Ctrl+C to abort)"
  echo ""

  local shown_diag=false
  while true; do
    read -r
    if df_bootstrap_ssh_verify "$host"; then
      echo "SSH access to ${host} verified."
      return 0
    fi
    if [[ "$shown_diag" == false ]]; then
      shown_diag=true
      local diag
      diag="$(ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new \
        -i "${key_path}" -T "${DF_GIT_SSH_TEST_USER}@${host}" 2>&1)" || true
      if [[ -n "$diag" ]]; then
        echo ""
        echo "SSH response:"
        echo "$diag"
        echo ""
      fi
      echo "Ensure the public key above is added on ${host} (deploy key or user SSH keys), then press Enter."
    else
      echo "Still cannot authenticate. Add the key and press Enter again (Ctrl+C to abort)."
    fi
  done
}

if [[ -n "$ZSH_VERSION" ]]; then
  typeset -fx _df_bootstrap_minimal_path _df_bootstrap_ensure_path \
    _df_git_ssh_host_from_url _df_bootstrap_ssh_resolve_host \
    df_bootstrap_public_raw_from_https_repo \
    df_bootstrap_resolve_public_raw \
    df_bootstrap_ssh_prepare df_bootstrap_ssh_verify \
    _df_bootstrap_ssh_curl_hint >/dev/null 2>&1
fi
