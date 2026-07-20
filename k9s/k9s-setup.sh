#!/bin/bash
# k9s-setup.sh - Setup and manage k9s multi-client/multi-env configs
#
# Usage:
#   ./k9s-setup.sh install          # Install configs to ~/.config/k9s
#   ./k9s-setup.sh add-cluster      # Interactive: add new client/env cluster
#   ./k9s-setup.sh rename-context   # Interactive: rename existing context
#   ./k9s-setup.sh list             # List current contexts and k9s configs
#   ./k9s-setup.sh sync             # Create k9s configs for all existing contexts

set -e

K9S_DIR="$HOME/.config/k9s"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Install all config files
cmd_install() {
    log_info "Installing k9s configs to $K9S_DIR"

    mkdir -p "$K9S_DIR"/{skins,clusters}

    # Copy base configs
    for file in config.yaml aliases.yaml hotkeys.yaml plugins.yaml views.yaml; do
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            cp "$SCRIPT_DIR/$file" "$K9S_DIR/$file"
            log_success "Installed $file"
        fi
    done

    # Copy skins
    if [[ -d "$SCRIPT_DIR/skins" ]]; then
        cp -r "$SCRIPT_DIR/skins/"* "$K9S_DIR/skins/"
        log_success "Installed skins"
    fi

    log_info "Base configs installed. Run '$0 sync' to create cluster-specific configs."
}

# Create k9s config for a specific context
create_cluster_config() {
    local ctx="$1"
    local cluster
    cluster=$(kubectl config view -o jsonpath="{.contexts[?(@.name=='$ctx')].context.cluster}")

    local dir="$K9S_DIR/clusters/$ctx/$cluster"
    mkdir -p "$dir"

    # Check if it's a prod-like context
    if [[ "$ctx" =~ -prod$|-prd$|-live$|-main$ ]]; then
        cat >"$dir/config.yaml" <<'EOF'
# Production cluster config - READ-ONLY
k9s:
  readOnly: true
  refreshRate: 5
  ui:
    skin: prod-warning
  shellPod:
    image: busybox:1.35.0
    namespace: default
    limits:
      cpu: 100m
      memory: 100Mi
  logger:
    tail: 1000
    buffer: 10000
    sinceSeconds: 600
EOF
        log_success "Created PROD config (read-only): $ctx"
    else
        cat >"$dir/config.yaml" <<'EOF'
# Development cluster config
k9s:
  readOnly: false
  refreshRate: 2
  ui:
    skin: dracula
  shellPod:
    image: nicolaka/netshoot:latest
    namespace: default
    limits:
      cpu: 500m
      memory: 512Mi
  logger:
    tail: 500
    buffer: 5000
    sinceSeconds: 300
EOF
        log_success "Created DEV config: $ctx"
    fi
}

# Sync k9s configs with existing kubeconfig contexts
cmd_sync() {
    log_info "Syncing k9s configs with kubeconfig contexts..."

    for ctx in $(kubectl config get-contexts -o name); do
        create_cluster_config "$ctx"
    done

    log_success "Sync complete!"
}

# Interactive: Add new cluster with proper naming
cmd_add_cluster() {
    echo ""
    echo "Add new client cluster to kubeconfig"
    echo "====================================="
    echo ""

    # Get client name
    read -rp "Client name (e.g., acme, bigcorp): " client
    client=$(echo "$client" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

    # Get environment
    echo ""
    echo "Environment:"
    echo "  1) dev"
    echo "  2) staging"
    echo "  3) prod"
    read -rp "Select [1-3]: " env_choice

    case $env_choice in
    1) env="dev" ;;
    2) env="staging" ;;
    3) env="prod" ;;
    *)
        log_error "Invalid choice"
        exit 1
        ;;
    esac

    local ctx_name="${client}-${env}"

    echo ""
    log_info "New context will be named: ${ctx_name}"
    echo ""

    # Check if we're importing from existing context or creating new
    echo "How do you want to set up this cluster?"
    echo "  1) Rename an existing context"
    echo "  2) Import from kubeconfig file"
    echo "  3) Manual setup (I'll configure kubectl myself)"
    read -rp "Select [1-3]: " setup_choice

    case $setup_choice in
    1)
        echo ""
        echo "Existing contexts:"
        kubectl config get-contexts -o name | nl
        echo ""
        read -rp "Enter context name to rename: " old_ctx
        kubectl config rename-context "$old_ctx" "$ctx_name"
        log_success "Renamed '$old_ctx' to '$ctx_name'"
        ;;
    2)
        read -rp "Path to kubeconfig file: " kube_file
        if [[ -f "$kube_file" ]]; then
            # Merge the kubeconfig
            KUBECONFIG="$HOME/.kube/config:$kube_file" kubectl config view --flatten >/tmp/merged-kubeconfig
            mv /tmp/merged-kubeconfig "$HOME/.kube/config"
            log_success "Merged kubeconfig. You may need to rename the context."
            echo ""
            echo "Current contexts:"
            kubectl config get-contexts
        else
            log_error "File not found: $kube_file"
            exit 1
        fi
        ;;
    3)
        log_info "Please configure kubectl context '$ctx_name' manually, then run '$0 sync'"
        exit 0
        ;;
    esac

    # Create k9s config for the new context
    create_cluster_config "$ctx_name"

    echo ""
    log_success "Setup complete! Switch to this cluster with: kubectl config use-context $ctx_name"
}

# Interactive: Rename existing context
cmd_rename_context() {
    echo ""
    echo "Rename kubeconfig context"
    echo "========================="
    echo ""
    echo "Current contexts:"
    kubectl config get-contexts
    echo ""

    read -rp "Context to rename: " old_name
    read -rp "New name (format: client-env, e.g., acme-dev): " new_name

    kubectl config rename-context "$old_name" "$new_name"
    log_success "Renamed '$old_name' to '$new_name'"

    # Update k9s config
    create_cluster_config "$new_name"

    # Clean up old k9s config if exists
    if [[ -d "$K9S_DIR/clusters/$old_name" ]]; then
        rm -rf "$K9S_DIR/clusters/$old_name"
        log_info "Removed old k9s config for '$old_name'"
    fi
}

# List current setup
cmd_list() {
    echo ""
    echo "Kubeconfig Contexts"
    echo "==================="
    kubectl config get-contexts
    echo ""

    echo "K9s Cluster Configs"
    echo "==================="
    if [[ -d "$K9S_DIR/clusters" ]]; then
        for ctx_dir in "$K9S_DIR/clusters"/*/; do
            if [[ -d "$ctx_dir" ]]; then
                ctx=$(basename "$ctx_dir")
                config_file=$(find "$ctx_dir" -name "config.yaml" 2>/dev/null | head -1)
                if [[ -f "$config_file" ]]; then
                    readonly=$(grep -q "readOnly: true" "$config_file" && echo "READ-ONLY" || echo "read-write")
                    skin=$(grep "skin:" "$config_file" | awk '{print $2}' || echo "default")
                    printf "  %-25s [%s] skin: %s\n" "$ctx" "$readonly" "$skin"
                fi
            fi
        done
    else
        echo "  No cluster configs found. Run '$0 sync' to create them."
    fi
    echo ""
}

# Show help
cmd_help() {
    echo "k9s-setup.sh - Manage k9s multi-client/multi-env configs"
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  install         Install base configs to ~/.config/k9s"
    echo "  sync            Create k9s configs for all kubeconfig contexts"
    echo "  add-cluster     Interactive: add new client/env cluster"
    echo "  rename-context  Interactive: rename existing context"
    echo "  list            Show current contexts and k9s configs"
    echo "  help            Show this help"
    echo ""
    echo "Naming convention:"
    echo "  Use <client>-<env> format for context names:"
    echo "    acme-dev, acme-prod, bigcorp-staging, etc."
    echo ""
    echo "  Contexts ending in -prod, -prd, -live, -main get:"
    echo "    - Read-only mode"
    echo "    - Red warning skin"
    echo "    - Slower refresh rate"
}

# Main
case "${1:-help}" in
install) cmd_install ;;
sync) cmd_sync ;;
add-cluster) cmd_add_cluster ;;
rename-context) cmd_rename_context ;;
list) cmd_list ;;
help | --help | -h) cmd_help ;;
*)
    log_error "Unknown command: $1"
    cmd_help
    exit 1
    ;;
esac
