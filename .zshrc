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
export PATH="/opt/homebrew/bin:$PATH"


# Neovim configurations
export EDITOR=nvim
alias nvim-mine='nvim'
export KUBECONFIG=/Users/luismadeira/.kube/staging-config
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
fpath=(/Users/luismadeira/.docker/completions $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
export KUBECONFIG=~/.kube/syott-staging
