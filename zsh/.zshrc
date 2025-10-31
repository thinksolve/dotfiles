
#convenience settings
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000

setopt appendhistory        # Append new history instead of overwriting
setopt sharehistory         # Share history among all sessions
setopt incappendhistory     # Write commands incrementally as you type them
# setopt hist_ignore_dups     # Ignore consecutive duplicate entries
setopt hist_ignore_all_dups # Ignore ALL duplicate entries
setopt hist_reduce_blanks   # Remove extra spaces
setopt extendedhistory      # Save timestamps
setopt autocd               # Move to directories without cd
setopt auto_param_slash     # Allow autocomplete to work on pathname variables

#ctrl-d on new empty command line closes terminal (acts like EOF), 
# otherwise it mimics TAB completion ... overloaded so remove it
setopt ignore_eof 

export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export NIX_CURRENT_SYSTEM=/run/current-system/sw/

## NOTE: the custom nvim binary (at ~./local/bin) uses 'recent_add' logic before executing real nvim 
readonly RECENT_NVIM="$HOME/.local/bin/nvim"
readonly REAL_NVIM="$NIX_CURRENT_SYSTEM/bin/nvim"

export EDITOR="$RECENT_NVIM"
export VISUAL="$RECENT_NVIM"

#I now source this into ALL shell scripts (including zshrc); source of truth for PATH
source ~/.config/path.sh 
source "$HOME"/.shell_functions.sh



# export DOOMDIR="$HOME/.config/doom"
# export PNPM_HOME="/Users/brightowl/Library/pnpm"
# export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
# export PATH="$HOME/.local/bin:$PATH"
# export PATH="$HOME/.config/emacs/bin:$PATH"
# export PATH=$HOME/bin:/usr/local/bin:$PATH
# export PATH="$PNPM_HOME:$PATH"
# export PATH=${PATH}:/usr/local/mysql/bin/


# path=(
#   $NIX_CURRENT_SYSTEM/bin
#   $HOME/.nix-profile/bin
#   $HOME/.local/bin
#   $HOME/.config/emacs/bin
#   $HOME/bin
#   /usr/local/bin
#   # /usr/local/mysql/bin
#   $PNPM_HOME
#   $path
# )
# export PATH
#


# antidote essentially replaces my uses for OMZ
source "$NIX_CURRENT_SYSTEM/share/antidote/antidote.zsh"
antidote load
bindkey -v #basic vi-mode but antidote's ~/.zsh_plugins.txt uses 'vi-more' to augment it


# export PURE_PROMPT_PATH=$HOME/.zsh/pure
export PURE_PROMPT_PATH="$NIX_CURRENT_SYSTEM/share/zsh/site-functions/"
fpath+=($PURE_PROMPT_PATH)
autoload -U promptinit; promptinit
prompt pure



autoload -U compinit
compinit -C -d "${ZDOTDIR:-$HOME}/.zcompdump"
zcompile "${ZDOTDIR:-$HOME}/.zcompdump" 2>/dev/null

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down












alias rvim="$RECENT_NVIM"
alias drs='sudo darwin-rebuild switch --flake ~/.dotfiles/nix/darwin'
alias config='cd ~/.dotfiles/ && yazi .'
alias config-nix='cd ~/.dotfiles/nix/darwin && yazi .'
alias evim='emacs -nw' # not really useful now that im using emacsclient
alias zshrc='nvim ~/.zshrc'
alias hist='nvim ~/.zsh_history'
alias shell_functions='nvim $HOME/.shell_functions.sh'
# alias gitignore_test='git rm -r --cached -f . && git add . && git ls-files | wc -l'
alias SCREENSAVERS='cd "/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS"'
alias BRAVE='cd ${HOME}/Library/Application\ Support/BraveSoftware/Brave-Browser/afalakplffnnnlkncjhbmahjfjhmlkal/1.0.904/1/'
# alias BRAVE='/Users/brightowl/Library/Application\ Support/BraveSoftware/Brave-Browser/afalakplffnnnlkncjhbmahjfjhmlkal/1.0.904/1/'



alias snake="tr '[ ]-' '_'"
alias kebab="tr '[ ]_' '-'"
alias upper="tr 'a-z' 'A-Z'"
alias lower="tr 'A-Z' 'a-z'"




function bindkey_zle() {
  local key=$1 func=$2
  local widget=_${func}_widget

  eval "
  $widget() {
    local choice
    choice=\$( $func < /dev/tty )          # try to grab stdout
    if [[ -n \$choice ]]; then
      # ------ text-producing function ------
      BUFFER=\$choice                     # drop into buffer
      # uncomment next line for instant execution
      # zle accept-line
    else
      # ------ side-effect-only function ------
      # THIS IS ACTUALLY BROKEN
      :                                   # nothing to insert
    fi
    zle reset-prompt
  }
  "
  zle -N  $widget
  bindkey "$key" $widget
}


bindkey_zlee() {
  local key=$1 func=$2
  local widget=_${func}_widget

  eval "
  $widget() {
    local choice
    choice=\$( $func < /dev/tty )
    [[ -n \$choice ]] && { BUFFER=\$choice; zle accept-line; }
  }
  "
  zle -N  $widget
  bindkey "$key" $widget
}



# function bindkey_zle_og() {
#     local key=$1 
#     local func=$2
#     local widget=_${func}_widget
#
#     eval "function $widget() { $func; zle reset-prompt; }"
#
#
#     zle -N  $widget
#     bindkey "$key" $widget
# }

# fire-and-forget keybindings
bindkey -s '^R' ' recent_pick\n'
bindkey -s '^D' ' find_dir_from_cache\n'
bindkey -s '^[^D' ' find_dir_then_cache\n'
bindkey -s '^F' ' find_file\n'
bindkey -s '^Y' ' yazi . \n'
bindkey -s '^N' ' nvim . \n'
#
# #insert into buffer (command line) keybindings
bindkey_zle '^H' get_history
# bindkey_zle '^R' recent_pick
# bindkey_zle '^D' find_dir_from_cache
# bindkey_zle '^[^D' find_dir_then_cache
# bindkey_zle '^F' find_file
#
# function open_yazi_here() { yazi . }
# bindkey_zle '^Y' open_yazi_here
#
# function open_nvim_here() { nvim . }
# bindkey_zle '^N' open_nvim_here




#NOTE: replaced with above block
# export NVM_DIR="$HOME/.nvm" && [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh" && [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  
 

# python (standard) redefinitions
alias pip=pip3
alias python2=python
alias python=python3



# ------------- OLD OMZ CODE (replaced by antidote -------------
# plugins=(zsh-vim-mode zsh-autosuggestions)
# export ZSH=$HOME/.oh-my-zsh
# source $ZSH/oh-my-zsh.sh
# # plugins=(vi-mode zsh-autosuggestions)
# # source $ZSH_CUSTOM/plugins/vi-motions/motions.plugin.zsh #zsh-vim-mode also works but P (paste) url strings gets escaped still
# # source /Users/brightowl/.oh-my-zsh/custom/plugins/zsh-vim-mode/zsh-vim-mode.plugin.zsh
# # ZSH_THEME="robbyrussell"
# # ZSH_THEME="powerlevel10k/powerlevel10k"
# ------------- OLD OMZ CODE (replaced by antidote -------------


# alias zsh-recompile-funcs='zcompile ~/.shell_functions.zwc ~/.shell_functions.sh && echo "Compiled! Restart shell."'
function compile_zsh() {
  setopt extendedglob
  local repo=${ZDOTDIR:-$HOME}/.dotfiles/zsh

  for src in $repo/.zshrc(N) $repo/*.sh(N) $repo/*.zsh(N); do
    zcompile -U -z $src
  done

  # compile the dump only where compinit expects it
  zcompile -U -z ~/.zcompdump 2>/dev/null
}


# NOTE: THIS CODE SAVED HERE BUT FOR EXTRACTING CONTENT FROM HTML (not related to zshrc)
# xmllint --html --recover --xpath "//td/text()" input.html > output.txt
