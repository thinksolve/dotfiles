# ~/.dotfiles/zsh/completions.zsh
# ─────────────────────────────────────────────────────────────────────────────
# Completion system initialization + lazy loading of expensive completers
# Goal: fast startup, compinit cached early, carapace/custom compdefs only once
#       after first prompt (delay hidden, not on first Tab)
# ─────────────────────────────────────────────────────────────────────────────

autoload -Uz compinit add-zsh-hook

# ── Early: cached compinit (very fast after first shell ever) ────────────────
local dumpfile="${ZDOTDIR:-$HOME}/.zcompdump"

if [[ -s "$dumpfile" ]]; then
    compinit -C -d "$dumpfile"          # -C skips security checks → faster
else
    compinit -d "$dumpfile"             # rebuild if missing
fi

# Auto-compile the dump file if needed (small win on future shells, silent)
if [[ -s "$dumpfile" && (! -s "$dumpfile".zwc || "$dumpfile" -nt "$dumpfile".zwc) ]]; then
    zcompile "$dumpfile" 2>/dev/null
fi


#used in compdef below
 abbr-user-prefix() {
    command -v abbr >/dev/null 2>&1 || return 1 
    #note: since calling compdef on this custom fn directly i need to guard it properly

    local cur=$PREFIX
    local -a keys

    keys=(${(f)"$(abbr list | cut -d'=' -f1 | tr -d '"')"})

    compadd -S '' -- ${(M)keys:#$cur*}
}

# ── One-shot lazy block: runs only once, right after first prompt ────────────
_first_prompt_lazy_completions() {
    # Remove hook — run exactly once
    add-zsh-hook -d precmd _first_prompt_lazy_completions

    # Guard: compinit should already have run, but harmless if not
    (( ${+functions[compinit]} )) || compinit -C

    # ── Carapace ─────────────────────────────────────────────────────────────
    source <(carapace _carapace zsh)
    # zstyle ':completion:*:-command-:*:*' file-patterns '*:all-files' '*(-/):directories' #WIP: not really needed tho

    # Important: fzf-tab compatibility patch
    # Prevents carapace from hijacking simple _path_ / _files completions
    compdef _files bat cat code cp eza head less ls more mv nvim rat rm tail touch tree vim
    compdef _path_files cd mkdir pushd rmdir

    # Custom compdefs for your own functions (from ~/.shell_functions.sh)
    compdef _functions fbat
    compdef _command_names wdef
   
    compdef abbr-user-prefix -first-
}

# Hook it — delay happens in background after prompt draws → feels free
add-zsh-hook precmd _first_prompt_lazy_completions


