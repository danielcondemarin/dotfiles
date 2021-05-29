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
alias cdgo='cd $(go env GOPATH)'

# open tmux on startup
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux
fi

# autosuggestions
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^N' autosuggest-accept

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# source local configuration
LOCALRC="$HOME/.localrc"
if [ -e "$LOCALRC" ]; then 
  source $LOCALRC
fi
