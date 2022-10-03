# comment out for profiling
# zmodload zsh/zprof

# enable vi mode
bindkey -v
# enable reverse search
bindkey '^R' history-incremental-search-backward

# auto-completions
autoload -Uz compinit
compinit

# set custom prompt
autoload -U promptinit; promptinit
prompt pure

# aliases
alias vim='nvim'
alias vi='nvim'
alias v='nvim'
alias dotf='/usr/bin/git --git-dir=$HOME/.cfg/ --work-tree=$HOME'
alias dotfiles='dotf'
alias cdgo='cd $(go env GOPATH)'
alias whoisonport='sudo lsof -i -P | grep LISTEN | grep '

# open tmux on startup
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux
fi

# autosuggestions
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^N' autosuggest-accept

# nvm
# Only enable when absolutely needed. Will slow down zshrc boot considerably!
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

# source local configuration
LOCALRC="$HOME/.localrc"
if [ -e "$LOCALRC" ]; then 
  source $LOCALRC
fi

autoload -U +X bashcompinit && bashcompinit
# complete -o nospace -C /usr/local/bin/terraform terraform

# override vimdiff to use neovim
alias vimdiff="nvim -d"

export PATH=$PATH:/usr/local/go/bin
