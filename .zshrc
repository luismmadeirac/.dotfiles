# Load zsh profile for XDG variables
source ~/.zshrc_profile

# path to zsh (XDG compliant)
export ZSH="$XDG_CONFIG_HOME/oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git)

# Docker CLI completions (must be on fpath before oh-my-zsh runs compinit)
fpath=($HOME/.docker/completions $fpath)

source $ZSH/oh-my-zsh.sh

source ~/.zshrc_alias
source ~/.zshrc_alias_scripts

# nvm: `--no-use` skips `nvm use default` (~0.4s per shell); the default
# version's bin is added to PATH directly instead.
export NVM_DIR="$XDG_DATA_HOME/nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  source "$NVM_DIR/nvm.sh" --no-use
  [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
  _nvm_default=$(<"$NVM_DIR/alias/default")
  _nvm_bin=( "$NVM_DIR"/versions/node/v${_nvm_default#v}(|.*)(N/nOn[1]) )
  (( $#_nvm_bin )) && path=("$_nvm_bin[1]/bin" $path)
  unset _nvm_default _nvm_bin
fi

export PNPM_HOME="$HOME/.local/shared/pnpm"
export PATH="$PNPM_HOME:$PATH"
export PATH="/opt/homebrew/bin:$PATH"

export EDITOR=nvim
export KUBECONFIG=~/.kube/syott-staging

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
