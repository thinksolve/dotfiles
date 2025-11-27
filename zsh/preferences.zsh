# ~/.config/zsh/preferences.zsh   (or options.zsh, settings.zsh, etc.)
# All setopt, variables that affect zsh behavior, etc. — one place.

# ── History ─────────────────────────────────────────────────────
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

# setopt hist_ignore_dups     # Ignore consecutive duplicate entries
setopt appendhistory        # Append new history instead of overwriting
setopt extendedhistory      # Save timestamps
setopt hist_find_no_dups
setopt hist_ignore_all_dups # Ignore ALL duplicate entries
setopt hist_ignore_space
setopt hist_reduce_blanks   # Remove extra spaces
setopt hist_verify
setopt incappendhistory     # Write commands incrementally as you type them
setopt sharehistory         # Share history among all sessions

# ── General behavior ───────────────────────────────────────────
setopt autocd               # Move to directories without cd
setopt auto_param_slash         # append / to completed directories
setopt ignore_eof               # don’t exit on Ctrl-D
setopt no_beep                  # silence is golden
setopt interactive_comments    # allow # comments in interactive shell

# ── Completion ─────────────────────────────────────────────────
setopt complete_in_word         # allow tab-completion mid-word
setopt always_to_end            # move cursor to end after completion

# ── Globbing ───────────────────────────────────────────────────
setopt extended_glob            # better pattern matching



