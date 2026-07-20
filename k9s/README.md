# K9s Multi-Client Configuration

A dotfiles-ready k9s configuration package with multi-client/multi-environment support.

## Features

- **Per-client, per-environment configs** - Different settings for each client's dev/staging/prod
- **Visual environment indicators** - Red theme for prod (with read-only mode), purple for dev
- **Comprehensive aliases** - Quick shortcuts for all common resources
- **Useful plugins** - stern logs, debug containers, clipboard support
- **Custom views** - Optimized column layouts for each resource type

## Directory Structure

```
~/.config/k9s/
├── config.yaml          # Global defaults
├── aliases.yaml         # Resource shortcuts
├── hotkeys.yaml         # Keyboard shortcuts
├── plugins.yaml         # Custom commands
├── views.yaml           # Column configurations
├── skins/
│   ├── dracula.yaml     # Dev/staging theme
│   └── prod-warning.yaml # Production theme (red)
└── clusters/
    ├── clienta-dev/
    │   └── clienta-dev/
    │       └── config.yaml
    ├── clienta-prod/
    │   └── clienta-prod/
    │       └── config.yaml
    └── ...
```

## Quick Start

```bash
# 1. Clone/copy to your dotfiles
cp -r k9s-config ~/.dotfiles/k9s  # or wherever you keep dotfiles

# 2. Install configs
chmod +x k9s-setup.sh
./k9s-setup.sh install

# 3. Rename your existing contexts to follow the convention
kubectl config rename-context old-context-name clienta-dev
kubectl config rename-context prod-cluster clienta-prod

# 4. Sync k9s configs with your contexts
./k9s-setup.sh sync
```

## Context Naming Convention

Use `<client>-<environment>` format:

| Context Name | Environment | Skin | Read-Only |
|--------------|-------------|------|-----------|
| `acme-dev` | Development | dracula | No |
| `acme-staging` | Staging | dracula | No |
| `acme-prod` | Production | prod-warning | **Yes** |
| `bigcorp-dev` | Development | dracula | No |
| `bigcorp-prod` | Production | prod-warning | **Yes** |

Contexts ending in `-prod`, `-prd`, `-live`, or `-main` automatically get:
- Read-only mode (prevents accidental deletions)
- Red warning skin
- Slower refresh rate (less API load)
- Larger log buffer

## Commands

### k9s-setup.sh

```bash
./k9s-setup.sh install          # Install base configs
./k9s-setup.sh sync             # Create configs for all kubeconfig contexts
./k9s-setup.sh add-cluster      # Interactive: add new client cluster
./k9s-setup.sh rename-context   # Interactive: rename existing context
./k9s-setup.sh list             # Show current setup
```

## Hotkeys

| Key | Action |
|-----|--------|
| `Shift-1` | View pods |
| `Shift-2` | View deployments |
| `Shift-3` | View services |
| `Shift-4` | View configmaps |
| `Shift-5` | View secrets |
| `Shift-6` | View ingresses |
| `Shift-7` | View nodes |
| `Shift-8` | View events |
| `Shift-9` | View PVCs |

## Plugins

| Key | Action | Scope |
|-----|--------|-------|
| `Shift-L` | Tail logs with stern | pods |
| `Shift-D` | Debug with netshoot | pods |
| `Shift-E` | Edit in $EDITOR | all |
| `Ctrl-C` | Copy name to clipboard | all |
| `Shift-O` | Port-forward & open browser | services |
| `Shift-M` | Show resource usage | pods |
| `Shift-R` | Rollout restart | deployments |

## Aliases

```
dp  → deployments       svc → services         cm  → configmaps
ds  → daemonsets        ep  → endpoints        sec → secrets
sts → statefulsets      ing → ingresses        pvc → persistentvolumeclaims
rs  → replicasets       np  → networkpolicies  pv  → persistentvolumes
jo  → jobs              sa  → serviceaccounts  sc  → storageclasses
cj  → cronjobs          cr  → clusterroles     no  → nodes
hpa → horizontalpodautoscalers                 ns  → namespaces
```

## Integration with Dotfiles

### Stow

```bash
# If using GNU Stow
cd ~/.dotfiles
stow k9s  # Symlinks k9s-config to ~/.config/k9s
```

### Direct Symlink

```bash
ln -sf ~/.dotfiles/k9s-config ~/.config/k9s
```

### Makefile

```makefile
k9s:
	@mkdir -p ~/.config
	@ln -sf $(PWD)/k9s-config ~/.config/k9s
	@chmod +x ~/.config/k9s/k9s-setup.sh
	@~/.config/k9s/k9s-setup.sh sync
```

## Tips

### Switching Contexts Quickly

Add to your shell config:

```bash
# ~/.zshrc or ~/.bashrc
alias kctx='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'

# With fzf for fuzzy selection
kx() {
  local ctx=$(kubectl config get-contexts -o name | fzf --height 40% --reverse)
  [[ -n "$ctx" ]] && kubectl config use-context "$ctx"
}
```

### Tmux Integration

```bash
# Open k9s in new tmux window for specific context
k9w() {
  local ctx="${1:-$(kubectl config current-context)}"
  tmux new-window -n "k9s:$ctx" "kubectl config use-context $ctx && k9s"
}
```
