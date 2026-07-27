#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# WSL Bootstrap — replicate macOS dev-env inside WSL (Ubuntu)
#
# Usage:
#   1. Copy this file into your WSL instance
#   2. chmod +x wsl-bootstrap.sh
#   3. ./wsl-bootstrap.sh
#
# What this does NOT set up (intentionally):
#   - git identity / GPG signing  (work machine → GitLab, configure separately)
#   - gh CLI / gh-dash             (GitHub-specific, not needed for GitLab)
#   - aerospace                    (macOS-only window manager)
#   - ghostty                      (terminal lives on the Windows side)
#   - SSH keys                     (generate fresh ones for the work machine)
#
# What it DOES set up:
#   - zsh + oh-my-zsh + plugins
#   - tmux + TPM + your config
#   - neovim (latest stable)
#   - lazygit, lazydocker
#   - k9s (with your full config: skins, hotkeys, plugins, aliases, views)
#   - kubectl, helm, stern
#   - terraform
#   - asdf version manager
#   - nvm (node version manager) + pnpm
#   - Go (latest)
#   - Docker CLI (assumes Docker Desktop for Windows with WSL integration)
#   - XDG directory structure
#   - All your shell configs (adapted for Linux/WSL)
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
err()   { echo -e "${RED}[ERR]${NC}   $*"; }

# ── Pre-flight checks ───────────────────────────────────────────────────────
if [[ "$(id -u)" -eq 0 ]]; then
  err "Don't run this as root. Run as your normal user — it will sudo when needed."
  exit 1
fi

if ! grep -qi 'microsoft\|wsl' /proc/version 2>/dev/null; then
  warn "This doesn't look like WSL. Continuing anyway, but some WSL-specific tweaks may not apply."
fi

info "Starting WSL bootstrap..."
echo ""

# ── 1. System packages ──────────────────────────────────────────────────────
info "Updating apt and installing base packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
  build-essential \
  curl \
  wget \
  git \
  zsh \
  tmux \
  jq \
  unzip \
  ripgrep \
  fd-find \
  fzf \
  htop \
  tree \
  xclip \
  gnupg \
  software-properties-common \
  apt-transport-https \
  ca-certificates \
  python3 \
  python3-pip \
  libssl-dev \
  libreadline-dev \
  zlib1g-dev \
  libyaml-dev \
  libffi-dev

ok "Base packages installed"

# ── 2. XDG directory structure ───────────────────────────────────────────────
info "Setting up XDG directory structure..."
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/scripts"
mkdir -p "$HOME/.local/state/zsh"
mkdir -p "$HOME/.local/state/k9s/screen-dumps"
mkdir -p "$HOME/.local/go/bin"
mkdir -p "$HOME/personal"
mkdir -p "$HOME/work"

ok "Directory structure created"

# ── 3. Neovim (latest stable via AppImage) ───────────────────────────────────
info "Installing Neovim..."
if ! command -v nvim &>/dev/null; then
  NVIM_VERSION="v0.10.4"
  curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz" \
    -o /tmp/nvim.tar.gz
  sudo tar -xzf /tmp/nvim.tar.gz -C /opt/
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  rm /tmp/nvim.tar.gz
  ok "Neovim ${NVIM_VERSION} installed"
else
  ok "Neovim already installed: $(nvim --version | head -1)"
fi

# ── 4. Go ────────────────────────────────────────────────────────────────────
info "Installing Go..."
if ! command -v go &>/dev/null; then
  GO_VERSION="1.24.5"
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
  sudo rm -rf /usr/local/go
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz
  rm /tmp/go.tar.gz
  export PATH="/usr/local/go/bin:$PATH"
  ok "Go ${GO_VERSION} installed"
else
  ok "Go already installed: $(go version)"
fi

# ── 5. Oh-My-Zsh ────────────────────────────────────────────────────────────
info "Installing Oh-My-Zsh..."
export ZSH="$HOME/.config/oh-my-zsh"
if [[ ! -d "$ZSH" ]]; then
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" \
    --unattended
  # oh-my-zsh installs to ~/.oh-my-zsh by default, move to XDG
  if [[ -d "$HOME/.oh-my-zsh" && ! -d "$ZSH" ]]; then
    mv "$HOME/.oh-my-zsh" "$ZSH"
  fi
  ok "Oh-My-Zsh installed at $ZSH"
else
  ok "Oh-My-Zsh already installed"
fi

# ── 6. asdf version manager ─────────────────────────────────────────────────
info "Installing asdf..."
if [[ ! -d "$HOME/.asdf" ]]; then
  git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.15.0
  ok "asdf installed"
else
  ok "asdf already installed"
fi

# ── 7. NVM ───────────────────────────────────────────────────────────────────
info "Installing NVM..."
export NVM_DIR="$HOME/.config/nvm"
if [[ ! -d "$NVM_DIR" ]]; then
  mkdir -p "$NVM_DIR"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | \
    PROFILE=/dev/null bash
  ok "NVM installed"
else
  ok "NVM already installed"
fi

# ── 8. pnpm ──────────────────────────────────────────────────────────────────
info "Installing pnpm..."
if ! command -v pnpm &>/dev/null; then
  curl -fsSL https://get.pnpm.io/install.sh | \
    PNPM_HOME="$HOME/.local/shared/pnpm" sh -
  ok "pnpm installed"
else
  ok "pnpm already installed"
fi

# ── 9. kubectl ───────────────────────────────────────────────────────────────
info "Installing kubectl..."
if ! command -v kubectl &>/dev/null; then
  KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
  curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    -o /tmp/kubectl
  sudo install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
  rm /tmp/kubectl
  ok "kubectl ${KUBECTL_VERSION} installed"
else
  ok "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

# ── 10. Helm ─────────────────────────────────────────────────────────────────
info "Installing Helm..."
if ! command -v helm &>/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  ok "Helm installed"
else
  ok "Helm already installed: $(helm version --short)"
fi

# ── 11. Terraform ────────────────────────────────────────────────────────────
info "Installing Terraform..."
if ! command -v terraform &>/dev/null; then
  wget -qO- https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg 2>/dev/null
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
  sudo apt-get update -qq && sudo apt-get install -y -qq terraform
  ok "Terraform installed"
else
  ok "Terraform already installed: $(terraform version | head -1)"
fi

# ── 12. k9s ──────────────────────────────────────────────────────────────────
info "Installing k9s..."
if ! command -v k9s &>/dev/null; then
  K9S_VERSION=$(curl -fsSL https://api.github.com/repos/derailed/k9s/releases/latest | jq -r '.tag_name')
  curl -fsSL "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz" \
    -o /tmp/k9s.tar.gz
  tar -xzf /tmp/k9s.tar.gz -C /tmp/ k9s
  sudo mv /tmp/k9s /usr/local/bin/k9s
  rm /tmp/k9s.tar.gz
  ok "k9s ${K9S_VERSION} installed"
else
  ok "k9s already installed: $(k9s version --short 2>/dev/null || echo 'yes')"
fi

# ── 13. lazygit ──────────────────────────────────────────────────────────────
info "Installing lazygit..."
if ! command -v lazygit &>/dev/null; then
  LG_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_Linux_x86_64.tar.gz" \
    -o /tmp/lazygit.tar.gz
  tar -xzf /tmp/lazygit.tar.gz -C /tmp/ lazygit
  sudo mv /tmp/lazygit /usr/local/bin/lazygit
  rm /tmp/lazygit.tar.gz
  ok "lazygit ${LG_VERSION} installed"
else
  ok "lazygit already installed"
fi

# ── 14. lazydocker ───────────────────────────────────────────────────────────
info "Installing lazydocker..."
if ! command -v lazydocker &>/dev/null; then
  LD_VERSION=$(curl -fsSL https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  curl -fsSL "https://github.com/jesseduffield/lazydocker/releases/download/v${LD_VERSION}/lazydocker_${LD_VERSION}_Linux_x86_64.tar.gz" \
    -o /tmp/lazydocker.tar.gz
  tar -xzf /tmp/lazydocker.tar.gz -C /tmp/ lazydocker
  sudo mv /tmp/lazydocker /usr/local/bin/lazydocker
  rm /tmp/lazydocker.tar.gz
  ok "lazydocker ${LD_VERSION} installed"
else
  ok "lazydocker already installed"
fi

# ── 15. stern (k8s log tailing) ──────────────────────────────────────────────
info "Installing stern..."
if ! command -v stern &>/dev/null; then
  STERN_VERSION=$(curl -fsSL https://api.github.com/repos/stern/stern/releases/latest | jq -r '.tag_name' | sed 's/^v//')
  curl -fsSL "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_amd64.tar.gz" \
    -o /tmp/stern.tar.gz
  tar -xzf /tmp/stern.tar.gz -C /tmp/ stern
  sudo mv /tmp/stern /usr/local/bin/stern
  rm /tmp/stern.tar.gz
  ok "stern ${STERN_VERSION} installed"
else
  ok "stern already installed"
fi

# ── 16. Tmux Plugin Manager ─────────────────────────────────────────────────
info "Installing TPM (Tmux Plugin Manager)..."
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
  ok "TPM installed"
else
  ok "TPM already installed"
fi


# ════════════════════════════════════════════════════════════════════════════
# CONFIGURATION FILES
# ════════════════════════════════════════════════════════════════════════════

info "Writing configuration files..."

# ── .zshrc_profile ───────────────────────────────────────────────────────────
cat > "$HOME/.zshrc_profile" << 'PROFILE_EOF'
export CONFIG_HOME=$HOME/.config
export XDG_CONFIG_HOME=$HOME/.config

# XDG tool configurations
export NPM_CONFIG_CACHE="$XDG_CONFIG_HOME/npm"
export YARN_CACHE_FOLDER="$XDG_CONFIG_HOME/yarn"
export VIM_HOME="$XDG_CONFIG_HOME/vim"

# XDG zsh state directories
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export ZSH_STATE_DIR="$XDG_STATE_HOME/zsh"
export HISTFILE="$ZSH_STATE_DIR/history"
export ZSH_COMPDUMP="$ZSH_STATE_DIR/zcompdump"

# Ensure zsh state directory exists
mkdir -p "$ZSH_STATE_DIR"

VIM="nvim"

PERSONAL=$CONFIG_HOME/Personal

export GOPATH=$HOME/.local/go
export GIT_EDITOR=$VIM
export DEV_ENV_HOME="$PERSONAL/dev-env"

addToPath() {
  if [[ "$PATH" != *"$1"* ]]; then
    export PATH=$PATH:$1
  fi
}

addToPathFront() {
  if [[ "$PATH" != *"$1"* ]]; then
    export PATH=$1:$PATH
  fi
}

addToPathFront $HOME/.local/.npm-global/bin
addToPathFront $HOME/.local/scripts
addToPathFront $HOME/.local/bin
addToPathFront $HOME/.local/npm/bin

addToPathFront $HOME/.local/go/bin
addToPathFront /usr/local/go/bin
addToPath $HOME/.local/personal
PROFILE_EOF

ok ".zshrc_profile"

# ── .zshrc_alias (adapted for WSL) ──────────────────────────────────────────
cat > "$HOME/.zshrc_alias" << 'ALIAS_EOF'
alias sz='source ~/.zshrc'

alias c='clear'

# Services
alias d='docker'
alias k='kubectl'
alias h='helm'
alias tf='terraform'
alias ld='lazydocker'
alias lg='lazygit'

alias t='tmux'
alias v='nvim'
alias vo='NVIM_APPNAME=nvim.bak nvim'

# Jump
alias p='cd $HOME/personal'
alias w='cd $HOME/work'

# Dotfiles bare repo (set up separately if needed)
# alias dot='git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

# ── WSL clipboard helpers ────────────────────────────────────────────────────
# These replace macOS pbcopy/pbpaste
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe -command "Get-Clipboard" | tr -d "\r"'

# ── WSL: open files/URLs in Windows browser ─────────────────────────────────
alias open='wslview'

# Password generators (adapted for Linux)
alias mi1="LC_ALL=C tr -dc '[:graph:]' < /dev/urandom | head -c 12"
alias mi5="LC_ALL=C tr -dc '[:graph:]' < /dev/urandom | head -c 36 | clip.exe && echo 'Password copied to clipboard!'"
ALIAS_EOF

ok ".zshrc_alias"

# ── .zshrc_alias_scripts (WSL-compatible subset) ────────────────────────────
cat > "$HOME/.zshrc_alias_scripts" << 'SCRIPTS_EOF'
# ──────────────────────────────────────────────────────────────────────────────
# Misc scripts — WSL-adapted subset
# ──────────────────────────────────────────────────────────────────────────────

# Tools
alias check-versions="$HOME/.local/scripts/dev-tooling.sh"
SCRIPTS_EOF

ok ".zshrc_alias_scripts"

# ── .zshrc ───────────────────────────────────────────────────────────────────
cat > "$HOME/.zshrc" << 'ZSHRC_EOF'
# Load zsh profile for XDG variables
source ~/.zshrc_profile

# path to zsh (XDG compliant)
export ZSH="$XDG_CONFIG_HOME/oh-my-zsh"

# Set custom compdump location before oh-my-zsh loads
export ZSH_COMPDUMP="$ZSH_STATE_DIR/zcompdump"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git asdf)

source $ZSH/oh-my-zsh.sh

source ~/.zshrc_alias
source ~/.zshrc_alias_scripts

GOPATH=$HOME/go  PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

export NVM_DIR="$XDG_CONFIG_HOME/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export PNPM_HOME="$HOME/.local/shared/pnpm"
export PATH="$PNPM_HOME:$PATH"

# Neovim as default editor
export EDITOR=nvim

# asdf
[ -f "$HOME/.asdf/asdf.sh" ] && . "$HOME/.asdf/asdf.sh"
[ -f "$HOME/.asdf/completions/asdf.bash" ] && fpath=(${ASDF_DIR}/completions $fpath)

autoload -Uz compinit
compinit
ZSHRC_EOF

ok ".zshrc"

# ── tmux config (adapted: pbcopy → clip.exe) ────────────────────────────────
mkdir -p "$HOME/.config/tmux"
cat > "$HOME/.config/tmux/tmux.conf" << 'TMUX_EOF'
# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

set -g default-terminal "tmux-256color"
set -s escape-time 0

unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
set -g status-style 'bg=#333333 fg=#5eacd3'
set -g base-index 1

set -g mouse on

set-window-option -g mode-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'clip.exe'

bind -r ^ last-window
bind -r k select-pane -U
bind -r j select-pane -D
bind -r h select-pane -L
bind -r l select-pane -R

bind -r K resize-pane -U 10
bind -r J resize-pane -D 10
bind -r H resize-pane -L 10
bind -r L resize-pane -R 10

bind M-1 select-layout even-horizontal
bind M-2 select-layout even-vertical
bind M-3 select-layout main-horizontal
bind M-4 select-layout main-vertical

bind-key -r f run-shell "tmux neww ~/.local/scripts/tmux-sessionizer.sh"

set -g @continuum-restore 'on'
set -g @resurrect-capture-pane-contents 'on'

run '~/.tmux/plugins/tpm/tpm'
TMUX_EOF

ok "tmux.conf"

# ── lazygit ──────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/lazygit"
cat > "$HOME/.config/lazygit/config.yml" << 'LAZYGIT_EOF'
os:
  editPreset: "nvim"
  openCommand: "nvim {{filename}}"
  editCommand: "nvim {{filename}}"

gui:
  showFileTree: true
  showIcons: true
  nerdFontsVersion: "3"
  theme:
    selectedLineBgColor:
      - reverse

keybinding:
  universal:
    pushFiles: "<c-p>"
    createPullRequest: "O"

customCommands:
  - key: "P"
    context: "global"
    command: "xdg-open $(git remote get-url origin | sed 's/\\.git$//')/merge_requests"
    description: "Open MRs in browser"
LAZYGIT_EOF

ok "lazygit config"

# ── lazydocker ───────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/lazydocker"
cat > "$HOME/.config/lazydocker/config.yml" << 'LAZYDOCKER_EOF'
confirmOnQuit: false
editor: nvim
shell: zsh

gui:
  language: 'en'
  refreshInterval: 3
  mouseEvents: false

logs:
  wrap: true
  timestamps: true
  since: 1h

dockerCompose:
  command: docker compose
  autoLoad: true

customCommands:
  containers:
    - name: Exec Bash (fallback to sh)
      attach: true
      command: docker exec -it {{ .Container.ID }} bash || docker exec -it {{ .Container.ID }} sh

    - name: Follow logs (tail 200)
      attach: true
      command: docker logs -f --tail=200 {{ .Container.ID }}

    - name: Inspect (jq)
      command: docker inspect {{ .Container.ID }} | jq

    - name: Print env
      command: docker exec {{ .Container.ID }} env | sort

    - name: Force remove container
      command: docker rm -f {{ .Container.ID }}

  services:
    - name: Restart service
      command: docker compose restart {{ .Service.Name }}

    - name: Rebuild & up
      attach: true
      command: docker compose up --build

    - name: View merged compose config
      command: docker compose config | less

  global:
    - name: System prune (DANGEROUS)
      command: docker system prune -af

    - name: Prune volumes
      command: docker volume prune -f

remoteDocker:
  enabled: true
LAZYDOCKER_EOF

ok "lazydocker config"

# ── k9s ──────────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.config/k9s/skins"

cat > "$HOME/.config/k9s/config.yaml" << 'K9S_CONF_EOF'
k9s:
  liveViewAutoRefresh: true
  screenDumpDir: ~/.local/state/k9s/screen-dumps
  refreshRate: 2
  apiServerTimeout: 2m0s
  maxConnRetry: 5
  readOnly: false
  noExitOnCtrlC: false
  portForwardAddress: localhost
  ui:
    enableMouse: false
    headless: false
    logoless: false
    crumbsless: false
    splashless: false
    reactive: true
    noIcons: false
    defaultsToFullScreen: false
    skin: dracula
  skipLatestRevCheck: true
  disablePodCounting: false
  shellPod:
    image: nicolaka/netshoot:latest
    namespace: default
    limits:
      cpu: 200m
      memory: 256Mi
  logger:
    tail: 500
    buffer: 5000
    sinceSeconds: 300
    textWrap: true
    disableAutoscroll: false
    showTime: true
  thresholds:
    cpu:
      critical: 90
      warn: 70
    memory:
      critical: 90
      warn: 70
  defaultView: pods
K9S_CONF_EOF

cat > "$HOME/.config/k9s/hotkeys.yaml" << 'K9S_HK_EOF'
hotKeys:
  shift-1:
    shortCut: Shift-1
    description: View pods
    command: pods
  shift-2:
    shortCut: Shift-2
    description: View deployments
    command: deployments
  shift-3:
    shortCut: Shift-3
    description: View services
    command: services
  shift-4:
    shortCut: Shift-4
    description: View configmaps
    command: configmaps
  shift-5:
    shortCut: Shift-5
    description: View secrets
    command: secrets
  shift-6:
    shortCut: Shift-6
    description: View ingresses
    command: ingresses
  shift-7:
    shortCut: Shift-7
    description: View nodes
    command: nodes
  shift-8:
    shortCut: Shift-8
    description: View events
    command: events
  shift-9:
    shortCut: Shift-9
    description: View PVCs
    command: persistentvolumeclaims
K9S_HK_EOF

cat > "$HOME/.config/k9s/aliases.yaml" << 'K9S_AL_EOF'
aliases:
  # Workloads
  dp: deployments
  ds: daemonsets
  sts: statefulsets
  rs: replicasets
  jo: jobs
  cj: cronjobs

  # Networking
  svc: services
  ep: endpoints
  ing: ingresses
  np: networkpolicies

  # Config & Storage
  cm: configmaps
  sec: v1/secrets
  pvc: persistentvolumeclaims
  pv: persistentvolumes
  sc: storageclasses

  # RBAC
  sa: serviceaccounts
  cr: clusterroles
  crb: clusterrolebindings
  ro: roles
  rb: rolebindings

  # Cluster
  no: nodes
  ns: namespaces
  ev: events

  # Scaling
  hpa: horizontalpodautoscalers
  vpa: verticalpodautoscalers

  # Flux CD
  ks: kustomizations.kustomize.toolkit.fluxcd.io
  hr: helmreleases.helm.toolkit.fluxcd.io
  git: gitrepositories.source.toolkit.fluxcd.io
  src: sources

  # ArgoCD
  app: applications.argoproj.io
  proj: appprojects.argoproj.io

  # Cert-manager
  cert: certificates.cert-manager.io
  iss: issuers.cert-manager.io
  ciss: clusterissuers.cert-manager.io
K9S_AL_EOF

cat > "$HOME/.config/k9s/views.yaml" << 'K9S_VW_EOF'
views:
  v1/pods:
    columns:
      - NAME
      - PF
      - READY
      - STATUS
      - RESTARTS
      - CPU
      - MEM
      - IP
      - NODE
      - AGE

  apps/v1/deployments:
    columns:
      - NAME
      - READY
      - UP-TO-DATE
      - AVAILABLE
      - CPU
      - MEM
      - AGE

  v1/services:
    columns:
      - NAME
      - TYPE
      - CLUSTER-IP
      - EXTERNAL-IP
      - PORTS
      - AGE

  v1/nodes:
    columns:
      - NAME
      - STATUS
      - ROLE
      - VERSION
      - CPU
      - MEM
      - "%CPU"
      - "%MEM"
      - AGE

  v1/persistentvolumeclaims:
    columns:
      - NAME
      - STATUS
      - VOLUME
      - CAPACITY
      - ACCESS-MODES
      - STORAGECLASS
      - AGE

  networking.k8s.io/v1/ingresses:
    columns:
      - NAME
      - CLASS
      - HOSTS
      - ADDRESS
      - PORTS
      - AGE

  v1/configmaps:
    columns:
      - NAME
      - DATA
      - AGE

  v1/secrets:
    columns:
      - NAME
      - TYPE
      - DATA
      - AGE
K9S_VW_EOF

cat > "$HOME/.config/k9s/plugins.yaml" << 'K9S_PL_EOF'
plugins:
  # Tail logs with stern
  stern:
    shortCut: Shift-L
    description: Tail logs with stern
    scopes:
      - pods
    command: stern
    background: false
    args:
      - --context
      - $CONTEXT
      - --namespace
      - $NAMESPACE
      - $POD
      - --container
      - $NAME

  # Debug container with netshoot
  debug-netshoot:
    shortCut: Shift-D
    description: Debug with netshoot
    scopes:
      - pods
    command: kubectl
    background: false
    args:
      - debug
      - -it
      - --context
      - $CONTEXT
      - -n
      - $NAMESPACE
      - $NAME
      - --image=nicolaka/netshoot
      - --target=$NAME

  # Get YAML and open in editor
  edit-yaml:
    shortCut: Shift-E
    description: Edit in $EDITOR
    scopes:
      - all
    command: bash
    background: false
    args:
      - -c
      - kubectl --context $CONTEXT -n $NAMESPACE get $RESOURCE_NAME $NAME -o yaml | $EDITOR -

  # Copy pod name to clipboard (WSL-adapted)
  copy-name:
    shortCut: Ctrl-C
    description: Copy name to clipboard
    scopes:
      - all
    command: bash
    background: true
    args:
      - -c
      - echo -n $NAME | clip.exe

  # Port forward and open in browser (WSL-adapted)
  pf-browser:
    shortCut: Shift-O
    description: Port-forward & open browser
    scopes:
      - services
    command: bash
    background: true
    args:
      - -c
      - |
        port=$(kubectl --context $CONTEXT -n $NAMESPACE get svc $NAME -o jsonpath='{.spec.ports[0].port}')
        kubectl --context $CONTEXT -n $NAMESPACE port-forward svc/$NAME 8080:$port &
        sleep 2 && wslview http://localhost:8080

  # Show resource usage
  resource-usage:
    shortCut: Shift-M
    description: Show resource usage
    scopes:
      - pods
    command: kubectl
    background: false
    args:
      - --context
      - $CONTEXT
      - -n
      - $NAMESPACE
      - top
      - pod
      - $NAME
      - --containers

  # Restart deployment
  restart:
    shortCut: Shift-R
    description: Rollout restart
    scopes:
      - deployments
      - statefulsets
      - daemonsets
    command: kubectl
    background: false
    confirm: true
    args:
      - --context
      - $CONTEXT
      - -n
      - $NAMESPACE
      - rollout
      - restart
      - $RESOURCE_NAME
      - $NAME
K9S_PL_EOF

# k9s skins
cat > "$HOME/.config/k9s/skins/dracula.yaml" << 'K9S_DRACULA_EOF'
k9s:
  body:
    fgColor: "#f8f8f2"
    bgColor: default
    logoColor: "#bd93f9"
  prompt:
    fgColor: "#f8f8f2"
    bgColor: default
    suggestColor: "#bd93f9"
  info:
    fgColor: "#ff79c6"
    sectionColor: "#f8f8f2"
  dialog:
    fgColor: "#f8f8f2"
    bgColor: default
    buttonFgColor: "#f8f8f2"
    buttonBgColor: "#bd93f9"
    buttonFocusFgColor: "#f8f8f2"
    buttonFocusBgColor: "#ff79c6"
    labelFgColor: "#ffb86c"
    fieldFgColor: "#f8f8f2"
  frame:
    border:
      fgColor: "#6272a4"
      focusColor: "#bd93f9"
    menu:
      fgColor: "#f8f8f2"
      keyColor: "#ff79c6"
      numKeyColor: "#ffb86c"
    crumbs:
      fgColor: "#f8f8f2"
      bgColor: "#44475a"
      activeColor: "#bd93f9"
    status:
      newColor: "#8be9fd"
      modifyColor: "#ffb86c"
      addColor: "#50fa7b"
      errorColor: "#ff5555"
      highlightColor: "#f1fa8c"
      killColor: "#6272a4"
      completedColor: "#6272a4"
    title:
      fgColor: "#bd93f9"
      bgColor: default
      highlightColor: "#f1fa8c"
      counterColor: "#ff79c6"
      filterColor: "#50fa7b"
  views:
    charts:
      bgColor: default
      defaultDialColors:
        - "#bd93f9"
        - "#ff5555"
      defaultChartColors:
        - "#bd93f9"
        - "#ff5555"
    table:
      fgColor: "#f8f8f2"
      bgColor: default
      cursorFgColor: "#282a36"
      cursorBgColor: "#bd93f9"
      header:
        fgColor: "#f8f8f2"
        bgColor: default
        sorterColor: "#8be9fd"
    xray:
      fgColor: "#f8f8f2"
      bgColor: default
      cursorColor: "#44475a"
      graphicColor: "#bd93f9"
      showIcons: false
    yaml:
      keyColor: "#ff79c6"
      colonColor: "#6272a4"
      valueColor: "#f8f8f2"
    logs:
      fgColor: "#f8f8f2"
      bgColor: default
      indicator:
        fgColor: "#f8f8f2"
        bgColor: "#bd93f9"
K9S_DRACULA_EOF

cat > "$HOME/.config/k9s/skins/prod-warning.yaml" << 'K9S_PROD_EOF'
k9s:
  body:
    fgColor: "#f8f8f2"
    bgColor: default
    logoColor: "#ff5555"
  prompt:
    fgColor: "#f8f8f2"
    bgColor: default
    suggestColor: "#ff5555"
  info:
    fgColor: "#ff5555"
    sectionColor: "#f8f8f2"
  dialog:
    fgColor: "#f8f8f2"
    bgColor: default
    buttonFgColor: "#1a1a1a"
    buttonBgColor: "#ff5555"
    buttonFocusFgColor: "#1a1a1a"
    buttonFocusBgColor: "#ff7979"
    labelFgColor: "#ff5555"
    fieldFgColor: "#f8f8f2"
  frame:
    border:
      fgColor: "#ff5555"
      focusColor: "#ff7979"
    menu:
      fgColor: "#f8f8f2"
      keyColor: "#ff5555"
      numKeyColor: "#ff7979"
    crumbs:
      fgColor: "#1a1a1a"
      bgColor: "#ff5555"
      activeColor: "#ff7979"
    status:
      newColor: "#8be9fd"
      modifyColor: "#ffb86c"
      addColor: "#50fa7b"
      errorColor: "#ff5555"
      highlightColor: "#f1fa8c"
      killColor: "#6272a4"
      completedColor: "#6272a4"
    title:
      fgColor: "#ff5555"
      bgColor: default
      highlightColor: "#ff7979"
      counterColor: "#ff5555"
      filterColor: "#ff7979"
  views:
    charts:
      bgColor: default
      defaultDialColors:
        - "#ff5555"
        - "#ff7979"
      defaultChartColors:
        - "#ff5555"
        - "#ff7979"
    table:
      fgColor: "#f8f8f2"
      bgColor: default
      cursorFgColor: "#1a1a1a"
      cursorBgColor: "#ff5555"
      header:
        fgColor: "#ff5555"
        bgColor: default
        sorterColor: "#ff7979"
    xray:
      fgColor: "#f8f8f2"
      bgColor: default
      cursorColor: "#44475a"
      graphicColor: "#ff5555"
      showIcons: false
    yaml:
      keyColor: "#ff5555"
      colonColor: "#6272a4"
      valueColor: "#f8f8f2"
    logs:
      fgColor: "#f8f8f2"
      bgColor: default
      indicator:
        fgColor: "#1a1a1a"
        bgColor: "#ff5555"
K9S_PROD_EOF

ok "k9s full config (config, hotkeys, aliases, views, plugins, skins)"

# ── gitleaks config ──────────────────────────────────────────────────────────
cat > "$HOME/.config/.gitleaks.toml" << 'GITLEAKS_EOF'
# Gitleaks configuration for dotfiles
title = "dotfiles gitleaks config"

[allowlist]
description = "Global allowlist"
paths = [
  '''\.example$''',
  '''\.sample$''',
  '''\.template$''',
  '''README\.md$'''
]
regexes = [
  '''(?i)(xxx|your[-_]?(api[-_]?key|token|secret)|CHANGEME|PLACEHOLDER)'''
]

[[rules]]
id = "dotfile-api-key"
description = "Potential API key in config"
regex = '''(?i)(api[_-]?key|apikey)\s*[=:]\s*['"]?([a-zA-Z0-9_-]{20,})['"]?'''
keywords = ["api_key", "apikey", "api-key"]

[[rules]]
id = "dotfile-token"
description = "Potential token in config"
regex = '''(?i)(token|auth[_-]?token)\s*[=:]\s*['"]?([a-zA-Z0-9_-]{20,})['"]?'''
keywords = ["token", "auth_token", "auth-token"]
GITLEAKS_EOF

ok "gitleaks config"

# ── git global ignore (minimal, no identity) ─────────────────────────────────
mkdir -p "$HOME/.config/git"
cat > "$HOME/.config/git/ignore" << 'GITIGNORE_EOF'
**/.claude/settings.local.json

# Logs
*.log

# OS generated files
.DS_Store*
ehthumbs.db
Thumbs.db

# Packages
*.7z
*.dmg
*.gz
*.iso
*.jar
*.rar
*.tar
*.zip
GITIGNORE_EOF

ok "git global ignore"

# ── Install wslu for wslview (open URLs in Windows browser) ──────────────────
info "Installing wslu (WSL utilities for wslview/open)..."
if ! command -v wslview &>/dev/null; then
  sudo apt-get install -y -qq wslu 2>/dev/null || warn "wslu not available in apt — install manually if wslview is needed"
fi
ok "wslu"

# ── Set zsh as default shell ─────────────────────────────────────────────────
info "Setting zsh as default shell..."
if [[ "$SHELL" != "$(which zsh)" ]]; then
  sudo chsh -s "$(which zsh)" "$USER"
  ok "Default shell changed to zsh (takes effect on next login)"
else
  ok "zsh is already the default shell"
fi

# ════════════════════════════════════════════════════════════════════════════
# DONE
# ════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  WSL Bootstrap Complete!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Next steps:"
echo ""
echo "  1. Close and reopen your terminal (or run: exec zsh)"
echo ""
echo "  2. Install tmux plugins: open tmux, press Ctrl-a + I"
echo ""
echo "  3. Install a Nerd Font on the Windows side:"
echo "     → Download JetBrainsMono Nerd Font from https://www.nerdfonts.com"
echo "     → Install on Windows, then set it in Windows Terminal settings"
echo ""
echo "  4. Set up your work git identity:"
echo "     git config --global user.name \"Your Name\""
echo "     git config --global user.email \"your@work-email.com\""
echo ""
echo "  5. Install Node.js via nvm:"
echo "     nvm install --lts"
echo ""
echo "  6. (Optional) Install your neovim config:"
echo "     git clone <your-nvim-config> ~/.config/nvim"
echo ""
echo "  7. Docker: enable WSL integration in Docker Desktop for Windows"
echo "     → Settings → Resources → WSL Integration → enable your distro"
echo ""
