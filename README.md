# dotfiles

Personal dotfiles managed with a bare git repository. No symlinks needed - files live directly in `~/.config` and are tracked via a bare repo at `~/.dotfiles`.

## What's included

| Directory | Description |
|-----------|-------------|
| `aerospace/` | Tiling window manager for macOS |
| `ghostty/` | Terminal emulator |
| `tmux/` | Terminal multiplexer (config only, plugins managed by TPM) |
| `lazygit/` | Git TUI |
| `lazydocker/` | Docker TUI |
| `git/` | Git configuration and global ignore |
| `gh/` | GitHub CLI preferences and aliases |
| `k9s/` | Kubernetes TUI |
| `graphite/` | Graphite CLI config |
| `raycast/` | Raycast launcher config |
| `opencode/` | OpenCode AI config |

## What's excluded (and why)

| Directory | Reason |
|-----------|--------|
| `nvim/` | Managed separately via [vconf](https://github.com/luismmadeirac/vconf) |
| `tmux/plugins/` | Managed by TPM - install with `prefix + I` |
| `oh-my-zsh/` | Cloned fresh via oh-my-zsh installer |
| `nvm/` | Managed by nvm itself |
| `rustup/` | Managed by rustup |
| `npm/` | Contains cached credentials |
| `configstore/` | Contains tokens/secrets |

## Installation on a new machine

```bash
# 1. Clone as a bare repo
git clone --bare git@github.com:luismmadeirac/.dotfiles.git ~/.dotfiles

# 2. Define the alias temporarily
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME/.config'

# 3. Backup any conflicting files
mkdir -p ~/.config-backup
dotfiles checkout 2>&1 | grep -E "\s+\." | awk {'print $1'} | xargs -I{} mv {} ~/.config-backup/{}

# 4. Checkout the files
dotfiles checkout

# 5. Hide untracked files from status
dotfiles config --local status.showUntrackedFiles no
```

### Post-install steps

```bash
# Install tmux plugins (inside tmux, hit prefix + I)
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Authenticate GitHub CLI
gh auth login

# Clone nvim config
git clone git@github.com:luismmadeirac/vconf.git ~/.config/nvim
```

## Daily usage

Add this alias to your `.zshrc`:

```bash
alias dotfiles='git --git-dir=$HOME/.dotfiles --work-tree=$HOME/.config'
```

Then manage your dotfiles like any git repo:

```bash
# Check status
dotfiles status

# Add changes to tracked files only
dotfiles add -u

# Add a new config
dotfiles add ~/.config/newapp/config.toml

# Commit and push
dotfiles commit -m "Update configs"
dotfiles push
```

> **Tip:** Use `dotfiles add -u` instead of `dotfiles add .` to only stage changes to already-tracked files. This prevents accidentally adding secrets or untracked directories.

## Security

This repo includes a pre-commit hook that runs [gitleaks](https://github.com/gitleaks/gitleaks) to prevent accidentally committing secrets.

```bash
# Install gitleaks
brew install gitleaks

# The hook is already configured at ~/.dotfiles/hooks/pre-commit
```

Configuration is in `.gitleaks.toml`.

## Related repositories

| Repo | Visibility | Description |
|------|------------|-------------|
| [vconf](https://github.com/luismmadeirac/vconf) | Public | Neovim configuration |
| sys-conf | Private | Machine bootstrap/orchestration scripts |

## Repository structure

```
~/.dotfiles/          # Bare git repo (just git internals)
~/.config/            # Actual config files (worktree)
├── aerospace/
├── ghostty/
├── git/
├── gh/
├── k9s/
├── lazydocker/
├── lazygit/
├── opencode/
├── raycast/
├── tmux/
│   └── tmux.conf     # tracked
│   └── plugins/      # NOT tracked (managed by TPM)
├── .gitignore
├── .gitleaks.toml
└── README.md
```
