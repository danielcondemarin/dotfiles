# enable vi mode
bindkey -v
# enable reverse search
bindkey '^R' history-incremental-search-backward

# set custom prompt
autoload -U promptinit; promptinit
prompt pure

# aliases
alias vim='nvim'
alias dotf='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias dotfiles='dotf'

# open tmux on startup
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux
fi

# autosuggestions
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^N' autosuggest-accept

# go language server
export PATH="$(go env GOPATH)/bin:$PATH"

# No need to slow down startup if nvm not used frequently
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

