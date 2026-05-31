# bootstrap — agent entry

This file is the authoritative context for AI assistants working in this repository.

---

## What this repository is

bootstrap is the **cold-start installer** that runs before dotFiles exists on a machine. Its sole job is to reach a state where `dotFiles install` can run:

1. Generate or install SSH keys (`GitHarness.sh` / `bootstrap keys`)
2. Clone Trove → `/opt/trove`
3. Clone Beskar → `/opt/beskar`
4. Clone dotFiles → `~/.dotFiles`
5. Hand off to `~/.dotFiles/setup <profile>`

It is deliberately minimal — bash + curl + git, no dotFiles environment, no Beskar armory, no Trove logging. Any dependency beyond those three tools is a bug.

---

## Entry points

| Entry point | When to use |
|---|---|
| `bootstrap install` | Bootstrap repo already cloned; run on a fresh machine |
| `bootstrap refresh` | Re-clone and re-install dotFiles without reprovisioning SSH/Trove/Beskar |
| `bootstrap keys` | SSH key setup only |
| `scripts/bootstrap-curl.sh` | True cold start: pipe from `curl` before anything is cloned |
| `scripts/bootstrap-curl.zsh` | Same flow in zsh once zsh is available |

The curl entry point fetches config over HTTP, sets up SSH, clones bootstrap itself, then delegates to `bootstrap install`.

---

## Documentation map

| Path | Contents |
|---|---|
| `bootstrap` | Main bash script; all install/refresh/keys commands |
| `lib/bootstrap_config.sh` | Config loader (bash); reads `~/.bootstrap.config` or `$DF_BOOTSTRAP_CONFIG` URL |
| `lib/bootstrap_config.zsh` | Same, zsh variant |
| `lib/bootstrap_ssh.zsh` | SSH key generation and Git access verification |
| `scripts/bootstrap-curl.sh` | HTTP cold-start entry (bash) |
| `scripts/bootstrap-curl.zsh` | HTTP cold-start entry (zsh) |
| `bootstrap.config.example` | Template for `~/.bootstrap.config` |
| `CHANGELOG.md` | Version history |
| `VERSION` | Single version source |

---

## Architecture rules — must follow

### 1. Nothing hardcoded

All repository URLs, hostnames, and paths must come from config — never from source code. The config sources, in priority order:

1. Environment variables set before bootstrap runs
2. `~/.bootstrap.config` (local file, `chmod 600`)
3. A URL pointed to by `$DF_BOOTSTRAP_CONFIG` (fetched via curl)

| What is needed | Variable to use |
|---|---|
| dotFiles repo (SSH) | `$DOTFILES_REPO` / `$DF_DOTFILES_REPO` |
| Trove repo (SSH) | `$DF_TROVE_REPO` |
| Beskar repo (SSH) | `$DF_BESKAR_REPO` |
| Bootstrap repo (HTTPS) | `$DF_BOOTSTRAP_REPO` |
| Bootstrap config source | `$DF_BOOTSTRAP_CONFIG` |
| Bootstrap install root | `$DF_BOOTSTRAP_HOME` (default: `~/.bootstrap`) |
| Git branch | `$DF_BOOTSTRAP_BRANCH` (default: `main`) |

Before adding any literal URL, host, or path, check whether a variable already carries it.

### 2. No homelab identity in code

Actual hostnames, usernames, and organization names (`kuzcotopia`, `thesecretlab`, `marana`, `kadmin`, `kgroup`, etc.) are user configuration — they belong in `~/.bootstrap.config`, not in code. The canonical reference for what a config file looks like is `bootstrap.config.example`, which uses generic `<git-server>/<user>` placeholders. Keep it that way.

If you see a specific hostname or username literal in a script, replace it with the appropriate variable.

### 3. Bootstrap is pre-dotFiles — keep it minimal

bootstrap runs before dotFiles, Trove, and Beskar exist. Code in this repo must not assume:

- `df.env` is present or sourced
- `trove_log` / `trove_running` / Trove helpers are available
- Beskar armory is accessible
- zsh is the shell (`bootstrap` is bash; only `bootstrap-curl.zsh` and `lib/*.zsh` are zsh)

Use plain `echo` for output. Use `bash` builtins and POSIX tools. Introduce a zsh or external dependency only when it is already guaranteed to exist at that point in the install sequence.

### 4. Shell discipline

| File | Shell |
|---|---|
| `bootstrap` | bash (`#!/usr/bin/env bash`) |
| `scripts/bootstrap-curl.sh` | bash |
| `lib/bootstrap_config.sh` | bash |
| `scripts/bootstrap-curl.zsh` | zsh |
| `lib/bootstrap_config.zsh` | zsh |
| `lib/bootstrap_ssh.zsh` | zsh |

Do not mix. A zsh-only construct in `bootstrap` or `bootstrap-curl.sh` will silently fail or error on a machine that only has bash.

---

## Install sequence (for reference)

```
curl … | bash -s -- install <profile>        # cold start
  └─ bootstrap-curl.sh
       ├─ load config (DF_BOOTSTRAP_CONFIG or ~/.bootstrap.config)
       ├─ bootstrap_ssh_prepare (SSH key + Git verify)
       ├─ clone bootstrap → ~/.bootstrap
       └─ ~/.bootstrap/bootstrap install <profile>
              ├─ install_trove  → /opt/trove
              ├─ install_beskar → /opt/beskar
              ├─ clone dotFiles → ~/.dotFiles
              └─ exec ~/.dotFiles/setup <profile>   # hands off entirely
```

---

## Development expectations

- **No test suite** in this repo — validate changes by running the install flow on a clean machine or VM.
- Keep `bootstrap` and `bootstrap-curl.sh` shellcheck-clean (bash target).
- **No secrets in git** — repo URLs and credentials belong in `~/.bootstrap.config`.
- **Commits:** follow repo changelog/version policy (Keep a Changelog, semver). Do not commit unless explicitly asked.

---

## Quick reference

```bash
# Config variables bootstrap expects (set in env or ~/.bootstrap.config)
DOTFILES_REPO="ssh://git@<host>/<user>/dotFiles.git"
DF_TROVE_REPO="ssh://git@<host>/<user>/trove.git"
DF_BESKAR_REPO="ssh://git@<host>/<user>/beskar.git"
DF_BOOTSTRAP_REPO="https://<host>/<user>/bootstrap.git"

# Common commands
bootstrap install [profile]   # full install (SSH → Trove → Beskar → dotFiles → setup)
bootstrap refresh             # re-clone dotFiles only
bootstrap keys                # SSH key setup only

# Cold start (curl pipe)
curl -fsSL "${DF_BOOTSTRAP_PUBLIC_RAW}/scripts/bootstrap-curl.sh" | bash -s -- install minimal
```
