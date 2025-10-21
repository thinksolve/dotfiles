# export PATH="$HOME/.npm-global/bin:$PATH" ## changed npm prefix (npm get prefix) from readonly nix location '/nix/store/2ribxb3gi87gj4331m6k0ydn0z90zfi7-nodejs-22.14.0' to a custom writable location '~/.npm-global' .. to allow global npm installs 

# note: due to nix-darwin managing ssl certs, i have to explicitly advertise their locations
# otherwise other dont get proper ssl certifications (like nvim-treesitter)




source "$HOME"/.shell_functions.sh
export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
export NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

export NIX_CURRENT_SYSTEM=/run/current-system/sw/

# export DOOMDIR="$HOME/.config/doom"
export PNPM_HOME="/Users/brightowl/Library/pnpm"
# export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
# export PATH="$HOME/.local/bin:$PATH"
# export PATH="$HOME/.config/emacs/bin:$PATH"
# export PATH=$HOME/bin:/usr/local/bin:$PATH
# export PATH="$PNPM_HOME:$PATH"
# export PATH=${PATH}:/usr/local/mysql/bin/


path=(
  $NIX_CURRENT_SYSTEM/bin
  $HOME/.nix-profile/bin
  $HOME/.local/bin
  $HOME/.config/emacs/bin
  $HOME/bin
  /usr/local/bin
  # /usr/local/mysql/bin
  $PNPM_HOME
  $path
)
export PATH


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
# setopt ignore_eof 


autoload -U compinit
compinit -C -d "${ZDOTDIR:-$HOME}/.zcompdump"
zcompile "${ZDOTDIR:-$HOME}/.zcompdump" 2>/dev/null





# export PURE_PROMPT_PATH=$HOME/.zsh/pure
export PURE_PROMPT_PATH="$NIX_CURRENT_SYSTEM/share/zsh/site-functions/"
fpath+=($PURE_PROMPT_PATH)
autoload -U promptinit; promptinit
prompt pure


source "$NIX_CURRENT_SYSTEM/share/antidote/antidote.zsh"
antidote load
bindkey -v #basic vi-mode but antidote's ~/.zsh_plugins.txt uses 'vi-more' to augment it




## NOTE: the custom nvim binary (at ~./local/bin) uses 'recent_add' logic before executing real nvim 
readonly RECENT_NVIM="$HOME/.local/bin/nvim"
readonly REAL_NVIM="$NIX_CURRENT_SYSTEM/bin/nvim"

export EDITOR="$RECENT_NVIM"
export VISUAL="$RECENT_NVIM"
alias rvim="$RECENT_NVIM"

# flake lock update for nix requires sudo now
alias drs='sudo darwin-rebuild switch --flake ~/.dotfiles/nix/darwin'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8




#NOTE: allegedly faster alternative to 'antidote load' way
# zsh_plugins=$HOME/.zsh_plugins
# [[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt
#
# fpath+=($NIX_CURRENT_SYSTEM/share/antidote/functions)
# autoload -Uz antidote
#
# if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
#   antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
# fi
# source ${zsh_plugins}.zsh






alias config='cd ~/.dotfiles/ && yazi .'
alias evim='emacs -nw' # not really useful now that im using emacsclient
alias zshrc='nvim ~/.zshrc'
alias hist='nvim ~/.zsh_history'
alias shell_functions='nvim $HOME/.shell_functions.sh'
# alias gitignore_test='git rm -r --cached -f . && git add . && git ls-files | wc -l'

alias SCREENSAVERS='cd "/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS"'
alias BRAVE='cd ${HOME}/Library/Application\ Support/BraveSoftware/Brave-Browser/afalakplffnnnlkncjhbmahjfjhmlkal/1.0.904/1/'
# alias BRAVE='/Users/brightowl/Library/Application\ Support/BraveSoftware/Brave-Browser/afalakplffnnnlkncjhbmahjfjhmlkal/1.0.904/1/'


# NOTE: THIS CODE SAVED HERE BUT FOR EXTRACTING CONTENT FROM HTML
# xmllint --html --recover --xpath "//td/text()" input.html > output.txt

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




# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi
#
# export NVM_DIR=$HOME/.nvm
# for cmd (node npm npx); do
#   eval "$cmd(){ unset -f $cmd; [[ -s \$NVM_DIR/nvm.sh ]] && . \$NVM_DIR/nvm.sh; $cmd \$@ }"
# done

#NOTE: replaced with above block
# export NVM_DIR="$HOME/.nvm" && [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh" && [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  
 
## source $(brew --prefix nvm)/nvm.sh 
## export NVM_DIR="$HOME/.nvm"


# alias lPorts='lsof -iTCP -sTCP:LISTEN'
# alias mw='defaults write -g com.apple.mouse.scaling'
# alias mr='defaults read -g com.apple.mouse.scaling'
# alias pix='Library/Android/sdk/emulator/emulator -avd Pixel_3a_API_33_arm64-v8a'

## escaping strings i.e. latex to katex (using with Alfred instead)
#function sks(){
#	printf "%q" "$1" | pbcopy
#}


# python (standard) redefinitions
alias pip=pip3
alias python2=python
alias python=python3



# Path to your oh-my-zsh installation.

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes



# ZSH_THEME="robbyrussell"
# ZSH_THEME="powerlevel10k/powerlevel10k"
# if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
#    ZSH_THEME="powerlevel10k/powerlevel10k"
# fi



# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to automatically update without prompting.
# DISABLE_UPDATE_PROMPT="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# Caution: this setting can cause issues with multiline prompts (zsh 5.7.1 and newer seem to work)
# See https://github.com/ohmyzsh/ohmyzsh/issues/5765
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.




# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"


# source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
# source /opt/homebrew/opt/chruby/share/chruby/auto.sh
# chruby ruby-2.7.2
# source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
# source /opt/homebrew/opt/chruby/share/chruby/auto.sh
# chruby ruby-2.7.2



#export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-16.0.2.jdk/Contents/Home


# export EDITOR="code -w"
# . "$HOME/.cargo/env"

# previously in ~/.profile
# . "$HOME/.cargo/env"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


#export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx


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
