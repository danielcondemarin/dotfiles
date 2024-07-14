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
fpath+=/opt/homebrew/share/zsh/site-functions
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


# autosuggestions
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
bindkey '^N' autosuggest-accept

# nvm
# Only enable when absolutely needed. Will slow down zshrc boot considerably!
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm


autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform

# override vimdiff to use neovim
alias vimdiff="nvim -d"

export PATH=$PATH:/usr/local/go/bin

# add antlr to classpath
export CLASSPATH=".:/usr/local/lib/antlr-4.11.1-complete.jar:$CLASSPATH"
alias antlr4='java -Xmx500M -cp "/usr/local/lib/antlr-4.11.1-complete.jar:$CLASSPATH" org.antlr.v4.Tool'
alias grun='java -Xmx500M -cp "/usr/local/lib/antlr-4.11.1-complete.jar:$CLASSPATH" org.antlr.v4.gui.TestRig'

# Make zsh copy/paste fast
DISABLE_MAGIC_FUNCTIONS=true
eval "$(/opt/homebrew/bin/brew shellenv)"

# source local configuration
LOCALRC="$HOME/.localrc"
if [ -e "$LOCALRC" ]; then 
  source $LOCALRC
fi

# open tmux on startup
if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux
fi
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
 
export PATH="$PATH:/Users/danielconde/Downloads/protoc-25.3-osx-aarch_64/bin"
