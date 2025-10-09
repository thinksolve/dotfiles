
# export PATH="$HOME/.npm-global/bin:$PATH" ## changed npm prefix (npm get prefix) from readonly nix location '/nix/store/2ribxb3gi87gj4331m6k0ydn0z90zfi7-nodejs-22.14.0' to a custom writable location '~/.npm-global' .. to allow global npm installs 


export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Alias for convenience
setopt HIST_IGNORE_ALL_DUPS 

# export DOOMDIR="$HOME/.config/doom"

export PATH="$HOME/.config/emacs/bin:$PATH"
export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH

fpath+=($HOME/.zsh/pure)
autoload -U promptinit; promptinit
prompt pure

# found out the hard way that plugins (vi-mode) affect bindkeys, so bindkeys should be placed BELOW plugins
# plugins=(vi-mode zsh-autosuggestions zsh-syntax-highlighting git)
plugins=(vi-mode zsh-autosuggestions)
export ZSH=$HOME/.oh-my-zsh
source "$ZSH"/oh-my-zsh.sh
# ZSH_THEME="robbyrussell"
# ZSH_THEME="powerlevel10k/powerlevel10k"

source "$HOME"/.shell_functions.sh
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


# OLD
# alias find_files_root='fd . "$HOME" '
# alias find_files_fuzzy_reduced='find_files_root -E "node_modules" | fzf --prompt="Find Files from $HOME (reduced): "'
# alias find_files_fuzzy_full='find_files_root -H | fzf --prompt="Find Files from $HOME (full): "'
#
#
# alias find_dirs_root='fd . "$HOME" -t d'
# alias find_dirs_fuzzy_reduced='find_dirs_root -E "node_modules" | fzf --prompt="Find Dir from $HOME (reduced): "'
# alias find_dirs_fuzzy_full='find_dirs_root -H | fzf --prompt="Find Dir from $HOME (full): "'
# bindkey -s '^D' 'cd "$(find_dirs_fuzzy_reduced)"\n'
# bindkey -s '^[^D' 'cd "$(find_dirs_fuzzy_full)"\n' #last
# bindkey -s '^F' 'echo "$(find_files_fuzzy_reduced)" | tr -d "\n" | pbcopy\n'
# bindkey -s '^[^F' 'echo "$(find_files_fuzzy_full)" | tr -d "\n" | pbcopy\n' #last

bindkey -s '^R' 'recent_pick\n'
bindkey -s '^[^R' 'recent_pick\n'

bindkey -s '^D' 'find_dir_from_cache\n'
bindkey -s '^[^D' 'find_dir_then_cache\n'
# bindkey -s '^D' 'fcd_cached\n'    #NOTE: somehow these disappeared in shell_functions.sh??
# bindkey -s '^[^D' 'fcd\n'         #NOTE: somehow these disappeared in shell_functions.sh??
bindkey -s '^F' 'find_file\n'
bindkey -s '^[^Y' 'yazi . \n'
bindkey -s '^[^N' 'nvim . \n'



# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export NVM_DIR="$HOME/.nvm" && [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh" && [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  
 
## source $(brew --prefix nvm)/nvm.sh 
## export NVM_DIR="$HOME/.nvm"


# alias llama='conda activate oi && interpreter --local'

# alias lPorts='lsof -iTCP -sTCP:LISTEN'
# alias mw='defaults write -g com.apple.mouse.scaling'
# alias mr='defaults read -g com.apple.mouse.scaling'
# alias pix='Library/Android/sdk/emulator/emulator -avd Pixel_3a_API_33_arm64-v8a'
#
## escaping strings i.e. latex to katex (using with Alfred instead)
#function sks(){
#	printf "%q" "$1" | pbcopy
#}




## undoes the last pushed commit, but keeps log 


#mysql
# export PATH=${PATH}:/usr/local/mysql/bin/

# python (standard) redefinitions
alias pip=pip3
alias python2=python
alias python=python3


# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH


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

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!

# __conda_setup="$('/Users/brightowl/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/Users/brightowl/miniconda3/etc/profile.d/conda.sh" ]; then
#         . "/Users/brightowl/miniconda3/etc/profile.d/conda.sh"
#     else
#         export PATH="/Users/brightowl/miniconda3/bin:$PATH"
#     fi
# fi
# unset __conda_setup

# <<< conda initialize <<<




# pnpm
export PNPM_HOME="/Users/brightowl/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end


# previously in bash_profile

#/usr/local/mysql/bin/mysql
export PATH=${PATH}:/usr/local/mysql/bin/

#export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-16.0.2.jdk/Contents/Home
export EDITOR=nvim
export VISUAL=nvim
# export EDITOR="code -w"
# . "$HOME/.cargo/env"

# previously in ~/.profile
# . "$HOME/.cargo/env"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


#export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx
#
#

# -------  bottom of .zshrc  -------
autoload -Uz add-zsh-hook

# 1. directory logger
recent_add_dir() { recent_add "$PWD"; }
add-zsh-hook chpwd recent_add_dir

# 2. file logger
recent_add_file() {
  local -a words
  words=(${(z)1})
  for w in $words; do
    case $w in
      nvim|vim|vi|emacs|nano|micro|code)
        local file=${words[-1]}
        [[ -f $file ]] && recent_add ${file:a}
        return
        ;;
    esac
  done
}
add-zsh-hook preexec recent_add_file
