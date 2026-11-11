# .dotfiles

Bare-repo managed dotfiles for my development environment. Covers shell configuration, terminal tools, and Kubernetes workflows.

## What's in here

| Config | Description |
|--------|-------------|
| `.zshrc` / `.zshrc_profile` / `.zshrc_alias` | Zsh shell config with oh-my-zsh, XDG-compliant paths, and tool aliases |
| `.zshenv` / `.zprofile` | Cargo env and Docker Desktop PATH |
| `.config/homebrew/Brewfile` | Everything installed via Homebrew (`brew bundle`) |
| `.config/tmux/tmux.conf` | Tmux with vim keybindings, prefix `Ctrl-a`, resurrect/continuum plugins |
| `.config/lazygit/config.yml` | Lazygit with nvim integration and nerd font icons |
| `.config/lazydocker/config.yml` | Lazydocker with custom container/service commands |
| `.config/k9s/` | Full k9s setup — hotkeys, aliases, plugins (stern, netshoot debug, rollout restart), views, and dracula/prod-warning skins |
| `.config/git/` | Git config, global ignore, and per-directory identity (`config-syott`) |
| `.config/gh/` | GitHub CLI config |
| `.config/gh-dash/` | GitHub dashboard with tmux+nvim keybindings |
| `.config/ghostty/` | Ghostty terminal — JetBrainsMono Nerd Font, custom color palette |
| `.config/aerospace/` | AeroSpace window manager (macOS) |
| `.config/crossnote/` | Markdown preview (crossnote) styles |
| `.config/.gitleaks.toml` | Gitleaks secret scanning rules |

Not in this repo:

| Config | Where |
|--------|-------|
| `.config/nvim/` | [vconf](https://github.com/luismmadeirac/vconf) |
| `.config/opencode/` | [opencode](https://github.com/luismmadeirac/opencode) |
| `.local/` (scripts, wallpapers) | private bare repo at `~/.private-local` (`private-local` alias) |
| Credentials (`aws/`, `sops/`, `stripe/`, `.npmrc`, ...) | never committed — see `.config/.gitignore` |

## Setup (macOS)

```bash
# Clone the bare repo
git clone --bare git@github.com:luismmadeirac/.dotfiles.git $HOME/.dotfiles

# Define the alias
alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# Checkout the files
dot checkout

# Hide untracked files
dot config --local status.showUntrackedFiles no
```

Then:

```bash
# Install everything from the Brewfile
brew bundle --file ~/.config/homebrew/Brewfile

# Tmux plugins (then prefix + I inside tmux)
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Separate repos
git clone git@github.com:luismmadeirac/vconf.git ~/.config/nvim
git clone git@github.com:luismmadeirac/opencode.git ~/.config/opencode
```

A gitleaks pre-commit hook lives in `~/.dotfiles/hooks/pre-commit` (hooks aren't cloned — copy it over on a new machine). It scans staged changes using `.config/.gitleaks.toml`.

## Setup (WSL / Linux)

A bootstrap script is included to replicate this environment inside WSL:

```bash
# Copy wsl-bootstrap.sh into your WSL instance, then:
chmod +x wsl-bootstrap.sh
./wsl-bootstrap.sh
```

The script installs all tools (zsh, tmux, neovim, lazygit, lazydocker, k9s, kubectl, helm, terraform, stern, asdf, nvm, Go) and writes adapted configs — clipboard uses `clip.exe`, URLs open via `wslview`, and macOS-only tools (aerospace, ghostty) are skipped.

## Usage

```bash
# Check status
dot status

# Stage changes to tracked files only (safer than `dot add .`)
dot add -u

# Add a new config
dot add .config/tmux/tmux.conf

# Update the Brewfile after installing/removing things
brew bundle dump --force

# Commit
dot commit -m "Update tmux config"

# Push
dot push
```

## Tools

- **Shell:** zsh + [oh-my-zsh](https://ohmyz.sh)
- **Terminal:** [Ghostty](https://ghostty.org) (macOS) / Windows Terminal (WSL)
- **Editor:** [Neovim](https://neovim.io)
- **Multiplexer:** [tmux](https://github.com/tmux-plugins/tpm) + TPM
- **Git TUI:** [lazygit](https://github.com/jesseduffield/lazygit)
- **Docker TUI:** [lazydocker](https://github.com/jesseduffield/lazydocker)
- **K8s TUI:** [k9s](https://k9scli.io) with [stern](https://github.com/stern/stern) for log tailing
- **Node versions:** [nvm](https://github.com/nvm-sh/nvm) (in `~/.local/share/nvm`)
- **Font:** [JetBrainsMono Nerd Font](https://www.nerdfonts.com)
