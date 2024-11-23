setopt HIST_IGNORE_ALL_DUPS 

export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH

fpath+=($HOME/.zsh/pure)
autoload -U promptinit; promptinit
prompt pure

# found out the hard way that plugins (vi-mode) affect bindkeys, so bindkeys should be placed BELOW plugins
plugins=(git vi-mode zsh-autosuggestions zsh-syntax-highlighting)
export ZSH=$HOME/.oh-my-zsh
source "$ZSH"/oh-my-zsh.sh
# ZSH_THEME="robbyrussell"
# ZSH_THEME="powerlevel10k/powerlevel10k"

source "$HOME"/.shell_functions.sh
alias zshrc='nvim ~/.zshrc'
alias gitignore_test='git rm -r --cached -f . && git add . && git ls-files | wc -l'

alias SCREENSAVERS='cd "/Library/Application Support/com.apple.idleassetsd/Customer/4KSDR240FPS"'
alias BRAVE='cd ${HOME}/Library/Application\ Support/BraveSoftware/Brave-Browser/afalakplffnnnlkncjhbmahjfjhmlkal/1.0.904/1/'
# alias BRAVE='/Users/brightowl/Library/Application\ Support/BraveSoftware/Brave-Browser/afalakplffnnnlkncjhbmahjfjhmlkal/1.0.904/1/'

# alias nvim='neovide --no-tabs'

# NOTE: THIS CODE SAVED HERE BUT FOR EXTRACTING CONTENT FROM HTML
# xmllint --html --recover --xpath "//td/text()" input.html > output.txt

alias snake="tr '[ ]-' '_'"
alias kebab="tr '[ ]_' '-'"
alias upper="tr 'a-z' 'A-Z'"
alias lower="tr 'A-Z' 'a-z'"



# fd_fz() {
#   local fd_flags=()
#   local fzf_flags=()
#
#   while [[ $# -gt 0 ]]; do
#     case "$1" in
#       --fz=*)
#         fzf_flags+=("${1#--fz=}")
#         shift
#         ;;
#       --fz)
#         if [[ $# -gt 1 ]]; then
#           fzf_flags+=("$2")
#           shift 2
#         else
#           echo "Error: --fz requires an argument"
#           return 1
#         fi
#         ;;
#       *)
#         fd_flags+=("$1")
#         shift
#         ;;
#     esac
#   done
#
#   # Split the fzf flags if they are provided as a single string
#   if [[ ${#fzf_flags[@]} -eq 1 && ${fzf_flags} =~ ' ' ]]; then
#     fzf_flags=(${(z)${fzf_flags}})
#   fi
#
#   fd "${fd_flags[@]}" | fzf "${fzf_flags[@]}"
# }


# alias fd_fuzzy_h='cd $(find ~/ -type d -not -path "*/node_modules*" 2>/dev/null | fzf)'

alias find_files_root='fd . "$HOME" '
alias find_files_fuzzy_reduced='find_files_root -E "node_modules" | fzf --prompt="Find Files from $HOME (reduced): "'
alias find_files_fuzzy_full='find_files_root -H | fzf --prompt="Find Files from $HOME (full): "'


alias find_dirs_root='fd . "$HOME" -t d'
alias find_dirs_fuzzy_reduced='find_dirs_root -E "node_modules" | fzf --prompt="Find Dir from $HOME (reduced): "'
alias find_dirs_fuzzy_full='find_dirs_root -H | fzf --prompt="Find Dir from $HOME (full): "'



# bindkey -s '^D' 'cd "$(find_dirs_fuzzy_reduced)"\n'
bindkey -s '^[^D' 'cd "$(find_dirs_fuzzy_full)"\n'

# bindkey -s '^F' 'echo "$(find_files_fuzzy_reduced)" | tr -d "\n" | pbcopy\n'
bindkey -s '^[^F' 'echo "$(find_files_fuzzy_full)" | tr -d "\n" | pbcopy\n'

bindkey -s '^[^Y' 'yazi . \n'
bindkey -s '^[^N' 'nvim . \n'



# ---- TESTING  
find_goto_dir_TESTING() {
    cd $(fd . "$HOME" -t d -E "node_modules" 2>/dev/null | fzf) || exit
}

# alias finder='find_goto_dir_TESTING
# bindkey -s '^v' 'finder\n'

#zle -N find_goto_dir_TESTING
#bindkey -s '^v' find_goto_dir_TESTING^M

# ---- TESTING 






# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export NVM_DIR="$HOME/.nvm" && [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh" && [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  
 
## source $(brew --prefix nvm)/nvm.sh 
## export NVM_DIR="$HOME/.nvm"



function gen_ssh() {
    local key_name=${1// /_}  
    ssh-keygen -t ed25519 -f "$HOME/.ssh/id_$key_name"
}

# alias llama='conda activate oi && interpreter --local'



function nd(){
	mkdir -p "$1" && cd -P "$1" || exit
}



function rmD(){

for file in *
do

  if [[ $(ls | grep -c "^$file$") -gt 1 ]]
  then

    rm "$file"
  fi
done

echo "Duplicates removed successfully"


}

alias lPorts='lsof -iTCP -sTCP:LISTEN'
function kPorts2(){
	sudo lsof -iTCP:"$1"-"$2" | awk '{print $2}' | grep -v "PID" | xargs kill -9
}


function kPorts {
  read "PORTS?Enter port numbers (e.g. 8080 3000): "
  for PORT in $PORTS; do
    PID=$(sudo lsof -t -i:"$PORT")
    if [[ -n "$PID" ]]; then
      kill "$PID"
      echo "Process $PID for port $PORT has been terminated."
    else
      echo "No process found for port $PORT."
    fi
  done
}

function kPorts2 {
  read "PORTS?Enter port range (e.g. 8080-8085): "
  IFS='-' read -r start_port end_port <<< "$PORTS"
  for ((port=$start_port; port<=$end_port; port++)); do
    PID=$(sudo lsof -t -i:$port)
    if [[ -n "$PID" ]]; then
      kill "$PID"
      echo "Process $PID for port $port has been terminated."
    else
      echo "No process found for port $port."
    fi
  done
}

## remove files using a newline-delimited list the elements of which are string-escaped
function delC(){
	local line="$1"
	IFS=$'\n' && arr=($(echo "${line}"));
	for i in ${arr[@]}; do 
		escd_path=$(printf '%q\n' /Users/brightowl/Library/Application\ Support/Google/Chrome/Default/"${i}");
		eval rm -R "${escd_path}"
		## echo rm -R ${escd_path}
	done
}


alias mw='defaults write -g com.apple.mouse.scaling'
alias mr='defaults read -g com.apple.mouse.scaling'

alias pix='Library/Android/sdk/emulator/emulator -avd Pixel_3a_API_33_arm64-v8a'

## escaping strings i.e. latex to katex (using with Alfred instead)
#function sks(){
#	printf "%q" "$1" | pbcopy
#}


# recursively delete files in git repository (i.e. accidentally committed folders)
function rrmGit(){
	find . -name "$1" -print0 | xargs -0 git rm -f -r --ignore-unmatch
}

# delete files in git repository (i.e. accidentally committed files)
function rmGit(){
	find . -name "$1" -print0 | xargs -0 git rm -f --ignore-unmatch
}


## undoes the last pushed commit, but keeps log 


#mysql
# export PATH=${PATH}:/usr/local/mysql/bin/

# python (standard) redefinitions
alias pip=pip3
alias python2=python
alias python=python3
alias py=python3


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


source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
source /opt/homebrew/opt/chruby/share/chruby/auto.sh
chruby ruby-2.7.2
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
source /opt/homebrew/opt/chruby/share/chruby/auto.sh
chruby ruby-2.7.2

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/brightowl/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/brightowl/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/brightowl/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/brightowl/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
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
. "$HOME/.cargo/env"

# previously in ~/.profile
. "$HOME/.cargo/env"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


#export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

