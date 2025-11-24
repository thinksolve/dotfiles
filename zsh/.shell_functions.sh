#!/usr/bin/env bash

#use: a=$(pbpaste) b=$(pbpaste); diff_text a b
function diff_text() {
        # --- arity guard ---
        if (($# != 2)); then
                print -u2 "usage: diff_text <var1> <var2>"
                return 1
        fi

        local _left _right

        eval '_left=${'$1'} _right=${'$2'}' #old: _left=${(P)1} _right=${(P)2}  # not posix friendly

        [[ -n $_left ]] || {
                print -u2 "diff_text: '$1' is empty or unset"
                return 1
        }
        [[ -n $_right ]] || {
                print -u2 "diff_text: '$2' is empty or unset"
                return 1
        }

        difft <(printf %s "$_left") <(printf %s "$_right")
}

function diff_funcs() {
        [[ $# -eq 2 ]] || {
                echo "usage: diff_funcs <func1> <func2>" >&2
                return 1
        }

        for f; do
                whence -w "$f" >/dev/null || {
                        echo "no such shell function: $f" >&2
                        return 1
                }
        done

        difft <(declare -f "$1") <(declare -f "$2")
}

function editable_path() {
        local p=$1
        [[ -d $p ]] && return 0 #in shell return 0 is truthy!

        case $(file --mime-type -b -- "$p") in
        text/* | application/json | application/x-yaml | application/xml | application/x-shellscript) return 0 ;;
        esac

        return 1
}

fzd.cleanup() {
        [[ $SHLVL -eq 1 ]] || return # Run only in top-level shell
        rm -f "/tmp/deep-fzf-full"-* || true
        rm -f "/tmp/deep-fzf-file"-* || true
}

function fzd() {
        local mode=${1:-full} root=${2:-$HOME} root_hash cache session_id
        root_hash=$(printf '%s' "$root" | md5sum | cut -d' ' -f1)
        session_id="session_$$"

        # ---------------------------------------------------- cache path
        case $mode in
        file) cache="/tmp/deep-fzf-file-${root_hash}-${session_id}" ;;
        full) cache="/tmp/deep-fzf-full-${root_hash}-${session_id}" ;;
        dir) cache="/tmp/deep-fzf-dir-${root_hash}" ;;
        *)
                echo "Usage: fzd {file|full|dir} [root]" >&2
                return 1
                ;;
        esac

        # ---------------------------------------------------- fd type flags
        local type_flags=()
        case $mode in
        file) type_flags=(-t f) ;;
        dir) type_flags=(-t d) ;;
        esac

        local editor=${EDITOR:-nvim}
        local dir_viewer=${DIRVIEWER:-$editor}
        local maxdepth=${FZD_MAXDEPTH:-3}

        local preview='p=$1;
            if [ -d "$p" ]; then
              tree -a -C -L 1 "$p" 2>/dev/null
            else
              bat --color=always "$p" 2>/dev/null || cat "$p" 2>/dev/null
            fi'

        #note: when $preview string is multiline then need to use 'zsh -c' here
        local fzf_args=(
                --preview "bash -c '$preview' bash {}"
                --prompt "fzd-$mode> "
                --border rounded
                --bind "ctrl-d:become(zsh -ic 'fzd full {}')"
        )

        menu_cycle() {
                setopt localoptions no_notify no_monitor 2>/dev/null || true
                #this line finally ensures no garbage messages forwarded to terminal, nor fzf input

                local chosen
                if [ -s "$cache" ]; then
                        chosen=$(cat "$cache" | fzf "${fzf_args[@]}") || return 1
                else
                        # background fill
                        (fd "${type_flags[@]}" -H -L . "$root" \
                                --exclude node_modules --exclude .git \
                                --max-depth "$maxdepth" >"$cache" 2>/dev/null) &
                        disown $! 2>/dev/null

                        chosen=$(fd "${type_flags[@]}" -H -L . "$root" \
                                --exclude node_modules --exclude .git \
                                --max-depth "$maxdepth" | fzf "${fzf_args[@]}") || return 1
                fi

                [ -z "$chosen" ] && return 1

                if [ -d "$chosen" ]; then
                        "$dir_viewer" "$chosen"
                elif editable_path "$chosen" 2>/dev/null; then
                        "$editor" "$chosen"
                else
                        command -v xdg-open >/dev/null && xdg-open "$chosen" || open "$chosen"
                fi
        }

        # ---------------------------------------------------- endless loop
        while menu_cycle; do :; done
}

function recent_pick() {
        local recent_pick_db="${RECENT_DB:-${XDG_DATA_HOME:-$HOME/.local/share}/shell_recent}"
        local editor="${EDITOR:-nvim}"
        local dir_viewer="${DIRVIEWER:-$editor}"
        local filter="${1:-}"
        local -a open_now edit_later
        local pick

        local FZF_PREVIEW='
            p=$1
            if [[ -d "$p" ]]; then
              echo -e "\033[1;34mDirectory:\033[0m $p\n"
              tree -a -C -L 2 "$p" 2>/dev/null || exa --tree --level=2 --color=always "$p" 2>/dev/null || ls -la "$p"
            elif [[ $p =~ \.(jpe?g|png|gif|webp|tiff|bmp|avif|svg)$ ]]; then
              chafa -f ansi -s "${FZF_PREVIEW_WINDOW:-80x40}" "$p" 2>/dev/null || echo "Image preview not available"
            elif command -v bat >/dev/null; then
              bat --color=always --style=numbers "$p" 2>/dev/null
            else
              cat "$p" 2>/dev/null || highlight -O ansi "$p" 2>/dev/null || cat "$p"
            fi
          '

        #this block to color-distinguish files vs dirs
        tac "$recent_pick_db" 2>/dev/null | while IFS= read -r path; do
                [[ -e "$path" ]] || continue
                if [[ -d "$path" ]]; then
                        printf '\e[34mDIR\e[0m\t%s\n' "$path"
                else
                        printf '\e[33mFILE\e[0m\t%s\n' "$path"
                fi
        done |
                # previewer logic here
                fzf --ansi -m \
                        --delimiter=$'\t' \
                        --query="$filter" \
                        --prompt='recent> ' \
                        --header='CTRL-E → edit DB' \
                        --bind "ctrl-e:execute($editor \"$recent_pick_db\" >/dev/tty </dev/tty)+abort" \
                        --preview "bash -c '$FZF_PREVIEW' bash {2}" | # --preview-window=right:65%:border-sharp |
                awk -F'\t' '{print $2}' |
                while IFS= read -r pick; do
                        [[ -e "$pick" ]] || continue
                        if editable_path "$pick" 2>/dev/null; then
                                edit_later+=("$pick")
                        else
                                open_now+=("$pick")
                        fi
                done

        # nothing chosen → stop recursion
        ((${#open_now[@]} + ${#edit_later[@]})) || return 0

        # 1. launch everything that detaches
        for p in "${open_now[@]}"; do open "$p"; done

        # 2. now occupy the terminal (if you want)
        for p in "${edit_later[@]}"; do
                if [[ -d $p ]]; then
                        cd "$p" && $dir_viewer .
                else
                        $editor "$p"
                fi
        done

        # round finished → offer the list again .. with exit status guard
        (($? == 0)) && recent_pick "$filter"
}

# Note: these are snapshots nix takes when ive done dirty git commits;
# its a useful side-effect since im using mkOutOfStoreSymLink for my dotfiles
function nix_dot_snapshots() {
        tmp=$(mktemp -d /tmp/yazi-dotfiles-XXXXXX)

        for el in $(ls -dt /nix/store/*-source); do
                [[ -d $el/zsh && -d $el/nvim && -d $el/bin ]] || continue
                name=$(basename "$el")
                ln -s "$el" "$tmp/$name"
        done

        yazi "$tmp"
}

function nix-generations() {
        local cmd="${1---help}"
        case "$cmd" in
        --list | -l) sudo darwin-rebuild --list-generations ;;
        --delete-gt | -d)
                if [[ -n $2 ]]; then
                        sudo nix-collect-garbage --delete-older-than "$2"
                else
                        echo "Age required: nix-generations --delete-gt 30d"
                        return 1
                fi
                ;;
        *)
                echo "Usage: nix-generations --list | --delete-gt <age>"
                return 1
                ;;
        esac
}
function nix_search() {
        # made by kimik2 <3
        local -a words
        words=($*)
        local pattern=$(printf '(?i)')
        for w in "${words[@]}"; do
                pattern+="(?=.*$w)"
        done
        nix search --json nixpkgs '.*' | jq -r --arg p "$pattern" '
      to_entries[]
      | select(.key | test($p))
      | "* \(.key)  (\(.value.version))\n  \(.value.description)"'
}

#nix helper to find explicit pathname of a pkg
function nixpath() {
        if [ -z "$1" ]; then
                echo "Usage: nixpath <package-name>"
                return 1
        fi
        nix eval --raw "nixpkgs#${1}"
}

function toggle_desktop() {
        if $(defaults read com.apple.finder CreateDesktop); then
                defaults write com.apple.finder CreateDesktop false
                killall Finder

        else
                defaults write com.apple.finder CreateDesktop true
                killall Finder
        fi

}

# need error handling, for instance iterm2 vs iTerm2
function toggle_service() {
        local SERVICE="${1:-Activity Monitor}"

        if pgrep -xq -- "$SERVICE"; then
                osascript -e 'tell application "'$SERVICE'" to quit'
        else
                open -a "$SERVICE"
        fi
}
#

function whence_path() {
        local func="$1"
        [[ -z $func ]] && {
                echo ""
                return 1
        }
        local whence_out
        whence_out=$(whence -v "$func")
        if [[ $whence_out == *"$func not found"* ]]; then
                echo ""
                return 1
        fi
        echo "$whence_out" | sed 's/.* from //'
}

function open_if_exists() {
        local func="$1"
        local path
        path=$(whence_path "$func")
        [[ -n $path ]] && nvim "$path"
}

function search_commits_diff() {
        local git_dir term

        if [ $# -eq 1 ]; then
                git_dir="$HOME/.dotfiles"
                term="$1"
        elif [ $# -eq 2 ]; then
                git_dir="$1"
                term="$2"
        else
                echo "Usage: search_commits [git_dir] <search_term>" >&2
                return 1
        fi

        [[ -z "$term" ]] && {
                echo "Usage: search_commits_diff <term>"
                return 1
        }

        (
                cd "$git_dir" || exit

                while IFS= read -r commit_id || [[ -n "$commit_id" ]]; do
                        git log -1 --format="%ci | %s" "$commit_id"
                        echo "https://github.com/thinksolve/dotfiles/commit/$commit_id"
                        git grep -n "$term" "$commit_id" 2>/dev/null | sed 's/^/  /'
                        echo

                done < <(git log --all --pretty=format:"%H" -S"$term")
                # done < <(git log --all --pretty=format:"%H" -- hammerspoon/init.lua)

        )

}

function search_commits() {
        local git_dir term
        if [ $# -eq 1 ]; then
                git_dir="$HOME/.dotfiles"
                term="$1"
        elif [ $# -eq 2 ]; then
                git_dir="$1"
                term="$2"
        else
                echo "Usage: search_commits_4 [git_dir] <search_term>" >&2
                return 1
        fi
        [[ -z "$term" ]] && {
                echo "Usage: search_commits_4 <term>"
                return 1
        }
        (
                cd "$git_dir" || exit
                while IFS= read -r commit_id || [[ -n "$commit_id" ]]; do
                        git show --pretty=format:"" "$commit_id" | grep -q "$term" && {
                                git log -1 --format="%ci | %s" "$commit_id"
                                echo "https://github.com/thinksolve/dotfiles/commit/$commit_id"
                                git grep -n "$term" "$commit_id" 2>/dev/null | sed 's/^/  /'
                                echo
                        }
                done < <(git log --all --pretty=format:"%H")
        )
}

# function search_commits_broken() {
#         local git_dir search_term repo_url
#         if [ $# -eq 1 ]; then
#                 git_dir="$HOME/.dotfiles"
#                 search_term="$1"
#         elif [ $# -eq 2 ]; then
#                 git_dir="$1"
#                 search_term="$2"
#         else
#                 echo "Usage: search_commits [git_dir] <search_term>" >&2
#                 return 1
#         fi
#         repo_url="https://github.com/thinksolve/dotfiles"
#         (
#                 cd "$git_dir" || exit
#                 git rev-list --all | while read -r commit; do
#                         # Get date of the commit once per commit
#                         commit_date=$(git show -s --format="%ci" "$commit")
#                         # Get matches in that commit
#                         matches=$(git grep -n "$search_term" "$commit" 2>/dev/null)
#                         if [[ -n "$matches" ]]; then
#                                 # Output date and clickable link to commit
#                                 echo "$commit_date | ${repo_url}/commit/${commit}"
#                                 # Print matches with indentation
#                                 echo "$matches" | sed "s/^/  /"
#                                 echo
#                         fi
#                 done
#         )
# }

# used for recent_pick and find_file

function send_key() {
        local mods=()
        local key="${@: -1}"
        local args=("$@")
        local i

        for ((i = 1; i < $#; i++)); do
                case "${args[i]}" in
                shift) mods+=("shift down") ;;
                control | ctrl) mods+=("control down") ;;
                option | alt) mods+=("option down") ;;
                command | cmd) mods+=("command down") ;;
                *)
                        echo "Unknown modifier: ${args[i]}" >&2
                        return 1
                        ;;
                esac
        done

        local as_mods=$(
                IFS=','
                echo "${mods[*]}"
        )

        command_string="tell application \"System Events\" to keystroke \"$key\" using {$as_mods}"

        # echo "$command_string" # debug
        osascript -e "$command_string" 2>&1

        # osascript -e "tell application \"System Events\" to keystroke \"$key\" using {$as_mods}"
}

function send_key_og() {
        local args=("$@")
        local key="${args[$#]}"
        local len=$(($# - 1))
        local mods=("${args[@]:0:$len}")

        # Get the frontmost terminal app (or specify explicitly)
        local app_name="Ghostty" # or get dynamically

        local script="tell application \"System Events\"
        tell process \"$app_name\"
            keystroke \"$key\""

        if ((${#mods[@]})); then
                local joined=$(printf "%s down, " "${mods[@]}")
                joined="${joined%, }"
                script+=" using {$joined}"
        fi

        script+="
        end tell
    end tell"

        osascript -e "$script" 2>&1
}

# handles multiple modifiers
function send_key_og() {
        local args=("$@")
        local key="${args[$#]}"
        local len=$(($# - 1))
        local mods=("${args[@]:0:$len}")
        local script="tell application \"System Events\" to keystroke \"$key\""
        if ((${#mods[@]})); then
                local joined=$(printf "%s down, " "${mods[@]}")
                joined="${joined%, }" # Portable trim (bash/zsh substring removal)
                script+=" using {$joined}"
        fi
        # echo "$script"
        osascript -e "$script"
}

# zshrc this is bound as a widget to ctrl-l=k ... possibly the most useful thing in the terminal
function copylast() {
        local out
        out=$(eval $history[$((HISTCMD - 1))] 2>/dev/null) &&
                [[ -n $out ]] && print -n $out | pbcopy && return

        # fall-through: nothing useful happened
        zle -M "copylast: last command gave no output or failed"
}

#local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else less {} 2>/dev/null; fi"
#local preview="tree -a -C -L 1 {}"
# local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else cat {} 2>/dev/null; fi"
#local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else head -n 20 {} 2>/dev/null; fi"

# function sigtop-backup() {
# 	local backup_dir=~/Backups/signal/sigtop-export-"$(date +%F-%H%M)"/
#
# 	mkdir -p $backup_dir
# 	cd $backup_dir
#
# 	sigtop export-messages messages
# 	sigtop export-attachments attachments
#
# 	cd -
# }

function sigtop-backup() {
        local stamp
        stamp=$(date +%F-%H%M)
        local backup_dir=~/Backups/signal/sigtop-export-"$stamp"

        mkdir -p -- "$backup_dir" || return
        (
                cd -- "$backup_dir" || exit
                sigtop export-messages messages &&
                        sigtop export-attachments attachments
        )
}

function signal_backup() {
        # 	dest=~/Backups/signal/
        # 	mkdir -p "$dest"
        #
        # 	tar -czf "$dest/signal-$(date +%F-%H%M).tgz" \
        # 		-C ~/Library \
        # 		"Application Support/Signal" \
        # 		Keychains/login.keychain-db

        local base_1=Signal base_2=login.keychain-db
        local path1 path2 out yes

        path1=$(fd -g "$base_1" --max-results 1 "$HOME")
        path2=$(fd -g "$base_2" --max-results 1 "$HOME")

        printf 'Archive:\n  %s\n  %s\n' "$path1" "$path2"
        printf 'Type YES to continue: '
        read -r yes
        [[ $yes == YES ]] || {
                echo Aborted
                return 1
        }
        [[ $yes == YES ]] || {
                echo Aborted
                return 1
        }

        mkdir -p ~/Backups/signal
        out=~/Backups/signal/signal-"$(date +%F-%H%M)".tgz

        tar -czf "$out" \
                -C "$(dirname "$path1")" "$(basename "$path1")" \
                -C "$(dirname "$path2")" "$(basename "$path2")"

        #     tar -czf "$out" \
        #         -C ${path1:h} ${path1:t} \
        #         -C ${path2:h} ${path2:t}
}

function signal_keychain_checks() {
        local live
        local backup_key
        local tgz
        local unpack_dir="$HOME/Backups/signal"

        #  # find the newest tarball (works even if name changes)
        tgz=$(ls -t "$unpack_dir"/signal-*.tgz 2>/dev/null | head -n1)

        # if we have a tarball but the keychain file is missing, unpack
        if [[ -n $tgz && ! -f $unpack_dir/Users/brightowl/Library/Keychains/login.keychain-db ]]; then
                echo "Unpacking $tgz …"
                tar -xzf "$tgz" -C "$unpack_dir"
        fi

        # this doesnt exist unless i uncompress the tarball at ~/Backups/signal/
        local backup_chain="$HOME/Backups/signal/Users/brightowl/Library/Keychains/login.keychain-db"

        live=$(security find-generic-password -s "Signal Safe Storage" -a "Signal Key" -w 2>/dev/null) ||
                {
                        echo "Could not read live keychain (cancelled or locked)"
                        return 1
                }

        if [[ -f $backup_chain ]]; then
                backup_key=$(security find-generic-password -s "Signal Safe Storage" -a "Signal Key" -w "$backup_chain" 2>/dev/null) ||
                        {
                                echo "Could not read backup keychain"
                                return 1
                        }
        else
                backup_key="(backup not found)"
        fi

        printf "live   : %s\nbackup : %s\n" "$live" "$backup_key"
        [[ $live == "$backup_key" ]] && echo "Keys MATCH" || echo "Keys DIFFER"

        #remove the unpacked backup files (tarball is source of truth anyway)
        if trash "$unpack_dir/Users" 2>/dev/null; then
                echo "Moved unpacked files to trash."
        else
                echo "Trash failed – please delete manually: $unpack_dir/Users"
        fi
}

function diffy() {
        local mode="full"
        local file1 file2
        local side_by_side=false

        # --- Parse options ---
        while [[ $# -gt 0 ]]; do
                case "$1" in
                -s | --symmetric) mode="sym" ;;
                -i | --intersection) mode="int" ;;
                -t | --tastic | -c | --code) side_by_side=true ;;
                -h | --help)
                        echo "Usage: diffy [-s|--symmetric | -i|--intersection | -t|--tastic|-c|--code] <file1> <file2>"
                        echo
                        echo "Modes:"
                        echo "  (default)      Full: common (white) + uniques (green/red)"
                        echo "  -s, --symmetric  Only symmetric uniques (green/red)"
                        echo "  -i, --intersection  Only intersection (common lines only)"
                        echo "  -t, --tastic      Side-by-side diff (like difft)"
                        return 0
                        ;;
                -*)
                        echo "diffy: unknown option '$1'" >&2
                        return 1
                        ;;
                *)
                        break
                        ;;
                esac
                shift
        done

        if [[ $# -ne 2 ]]; then
                echo "Usage: diffy [-s|--symmetric | -i|--intersection | -t|--tastic|-c|--code] <file1> <file2>" >&2
                return 1
        fi

        file1=$1
        file2=$2

        if [[ ! -f $file1 || ! -f $file2 ]]; then
                echo "diffy: both arguments must be valid files" >&2
                return 1
        fi

        if [[ "$side_by_side" == true ]]; then
                # Use standard side-by-side diff for code-friendly view
                difft --color=always "$file1" "$file2" | less -R
                return
        fi

        local red=$'\033[31m'
        local green=$'\033[32m'
        local reset=$'\033[0m'

        awk -v mode="$mode" -v red="$red" -v green="$green" -v reset="$reset" '
        # Pass 1: read file1
        NR==FNR {
            seenA[$0]=1
            order[++n]=$0
            next
        }

        # Pass 2: read file2, line by line
        {
            if ($0 in seenA) {
                if (mode != "sym") print reset $0 reset
            } else {
                if (mode != "int") print green $0 reset
            }
            seenB[$0]=1
        }

        # After processing file2, handle lines unique to file1
        END {
            if (mode != "int") {
                printed=0
                for (i=1; i<=n; i++) {
                    line = order[i]
                    if (!(line in seenB)) {
                        if (!printed++) print ""
                        print red line reset
                    }
                }
            }
        }
    ' "$file1" "$file2" | less -R -S
}

#diff_sym is pure symmetric difference; better for config files
#NOTE: this is inferior to `diffy --symmetric` now
# function diff_sym() {
#     if [[ $# -ne 2 ]]; then
#         echo "Usage: diff_sym <file1> <file2>" >&2
#         return 1
#     fi
#
#     local file1="$1"
#     local file2="$2"
#
#     {
#         #outputs in green
#         if grep -Fxqvf "$file1" "$file2"; then
#             echo -e "\033[32m[Only in $file2]\033[0m"
#             grep -Fxvf "$file1" "$file2" | sed $'s/^/\033[32m/; s/$/\033[0m/'
#             echo
#         fi
#
#         #outputs in red
#         if grep -Fxqvf "$file2" "$file1"; then
#             echo -e "\033[31m[Only in $file1]\033[0m"
#             grep -Fxvf "$file2" "$file1" | sed $'s/^/\033[31m/; s/$/\033[0m/'
#         fi
#
#     } | less -R -S
# }

#NOTE: WIP but idea is to keep modular zsh files but also create a flattened zshrc final file
# whis utility allows to see 'live changes' to the modular file while still seeing
# the final flat output zshrc file
demo-watch() {
        local dir=/tmp/demo-zsh
        local preview=$dir/flat.zsh

        mkdir -p "$dir"/{env.d,zshrc.d}
        echo 'export FOO=bar' >"$dir/env.d/10-env.zsh"
        echo 'alias ll=ls -l' >"$dir/zshrc.d/20-alias.zsh"

        build() {
                {
                        echo "# PREVIEW $(date)"
                        cat "$dir"/env.d/* "$dir"/zshrc.d/*
                } >"$preview"
                echo "---- $preview ----"
                cat "$preview"
        }

        build
        fswatch -o "$dir"/env.d "$dir/zshrc.d" | while read; do build; done
}

export RECENT_DB="${XDG_DATA_HOME:-$HOME/.local/share}/shell_recent"

local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else command -v bat >/dev/null && bat --color=always {} || cat {} 2>/dev/null; fi"
local home_dirs_cache="$HOME/.cache/fcd_cache.gz"
local dir_exclusions=(node_modules .git .cache .DS_Store venv __pycache__ Trash "*.bak" "*.log")

function get_history_old() {

        local cmd=("$(fc -rl 1 | fzf --select-1 --exit-0 | cut -c 8-)")
        # cmd=$(history | fzf | cut -c 8-)
        #
        echo "$cmd"
        # HIST_IGNORE_SPACE=1 eval "$cmd"
        # zsh -c "source ~/.zshrc; HIST_IGNORE_SPACE=1; $cmd"

        # local pick=$(fc -rl 1 | fzf --select-1 --exit-0 | cut -c 8-)
        # nvim "$pick"
}

function get_history() {
        # fc -R ~/.zsh_history &&
        #
        # [[ -f $HISTFILE ]] && fc -R

        fc -R #alert: when calling function from hs/init.lua need to read history file in advance
        fc -rl 1 | fzf --layout=reverse --height=~30 | sed 's/^[ *]*[0-9*]* *//'
}

function recent_add() {
        local db=${RECENT_DB:-${XDG_DATA_HOME:-$HOME/.local/share}/shell_recent}
        [[ -e $1 ]] || return
        mkdir -p "${db%/*}"

        local tmp
        tmp=$(mktemp) || return

        {
                [[ -f $db ]] && cat "$db"
                printf '%s\n' "$(realpath "$1")"
        } | awk '!seen[$0]++' | head -n 75 >"$tmp" && mv "$tmp" "$db"
}

function remove_last_newline_yas_snippet() {
        local file="$1"
        if [[ ! -f "$file" ]]; then
                echo "❌ File not found: $file"
                return 1
        fi

        local last_char
        last_char=$(tail -c 1 "$file")

        if [[ "$last_char" == $'\n' ]]; then
                echo "⚠️  Trailing newline detected in $file — fixing..."
                sed '$d' "$file" >"$file.tmp" && mv "$file.tmp" "$file"
        else
                echo "✅ No trailing newline in $file"
        fi
}

# function recent_add_old_no_dedupe() {
#     [[ -e $1 ]] || return
#     local dir=${RECENT_DB%/*}
#     [[ -d $dir ]] || mkdir -p "$dir"
#     printf '%s\n' "$(realpath "$1")" >>"$RECENT_DB" # no -m
# }

readonly translate_host="127.0.0.1"
readonly translate_port="8000"

# old; works with old model: ~/translate-romance-languages/translate_server.py.bak
# function translate_text() {
#     local text="$1"
#     local lang="${2:-es}"
#
#     # Check if server is running (port open and responding)
#     if ! lsof -i :"${translate_port}" | grep -q LISTEN; then
#         echo "🚀 Translator server not running. Starting now..."
#         start_translator_daemon
#         sleep 3 # Wait a bit for the server to fully start
#     fi
#
#     local response=$(curl -s -X POST "http://${translate_host}:${translate_port}/translate/" \
#         -H "Content-Type: application/json" \
#         -d "{\"text\": \"${text}\", \"target_lang\": \"${lang}\"}")
#
#     if command -v jq &>/dev/null; then
#         echo "$response" | jq -r '.translation'
#     else
#         echo "$response"
#     fi
# }

function en_to_romance() {
        local en_phrase="${1:-I like to eat ice cream}"
        translate_from_to "$en_phrase" en es
        translate_from_to "$en_phrase" en it
        translate_from_to "$en_phrase" en fr
}

function translate_from_to() {
        local text="$1"
        local src_lang="${2:-en}"
        local tgt_lang="${3:-es}"
        local check_interval_sec=0.25
        local check_total_time_sec=10
        local check_steps=$(echo "$check_total_time_sec / $check_interval_sec" | bc)

        # Handle piped input only if no argument provided
        if [ -z "$text" ] && [ -p /dev/stdin ]; then
                text=$(cat)
        fi

        # If no input at all, exit
        if [ -z "$text" ]; then
                echo "Error: No text provided" >&2
                return 1
        fi

        # Check if text contains language direction pattern /xxxx
        if [[ "$text" =~ '(.+) /([a-z]{2})([a-z]{2})$' ]]; then
                text="${match[1]}"
                src_lang="${match[2]}"
                tgt_lang="${match[3]}"
        fi

        # Check if server is running; if not, start it
        if ! lsof -i :$translate_port | grep -q LISTEN; then
                echo "🚀 Translator server not running. Starting now..."
                (cd ~/translate-romance-languages && nohup uvicorn translate_server:app --host "${translate_host}" --port "${translate_port}" >~/translate-server.log 2>&1 &)
                # Wait for server to listen on port
                for i in {1..$check_steps}; do
                        if lsof -i :$translate_port | grep -q LISTEN; then
                                break
                        fi
                        sleep $check_interval_sec
                done
        fi

        local json_payload
        json_payload=$(jq -n \
                --arg text "$text" \
                --arg src "$src_lang" \
                --arg tgt "$tgt_lang" \
                '{text: $text, source_lang: $src, target_lang: $tgt}')

        # Make the API call
        curl -s -X POST http://$translate_host:$translate_port/translate/ \
                -H "Content-Type: application/json" \
                -d "$json_payload" |
                # -d "{\"text\": \"$text\", \"source_lang\": \"$src_lang\", \"target_lang\": \"$tgt_lang\"}" |
                jq -r '.translation'
}

## works with ~/translate-romance-languages/translate_server.py
# function translate_from_to_old() {
#     local text="$1"
#     local src_lang="${2:-en}"
#     local tgt_lang="${3:-es}"
#     if [ -z "$text" ] && [ ! -t 0 ]; then
#         text=$(cat)
#     fi
#     if [ -z "$text" ]; then
#         echo "Usage: translate_from_to 'text' [source_lang] [target_lang]" >&2
#         echo "   or: echo 'text' | translate_from_to [source_lang] [target_lang]" >&2
#         return 1
#     fi
#
#     local check_interval_sec=0.25
#     local check_total_time_sec=10
#     local check_steps=$(echo "$check_total_time_sec / $check_interval_sec" | bc) # Integer division floor
#
#     # Check if server is running; if not, start it
#     if ! lsof -i :$translate_port | grep -q LISTEN; then
#         echo "🚀 Translator server not running. Starting now..."
#         (cd ~/translate-romance-languages && nohup uvicorn translate_server:app --host "${translate_host}" --port "${translate_port}" >~/translate-server.log 2>&1 &)
#
#         # Wait for server to listen on port 8000, up to 10 seconds
#         for i in {1..$check_steps}; do
#             if lsof -i :$translate_port | grep -q LISTEN; then
#                 break
#             fi
#             sleep $check_interval_sec
#         done
#     fi
#
#     # Make the API call
#     curl -s -X POST http://$translate_host:$translate_port/translate/ \
#         -H "Content-Type: application/json" \
#         -d "{\"text\": \"$text\", \"source_lang\": \"$src_lang\", \"target_lang\": \"$tgt_lang\"}" |
#         jq -r '.translation'
# }
#
function start_translator_daemon() {
        (
                cd ~/translate-romance-languages || exit
                nohup uvicorn translate_server:app --host "${translate_host}" --port "${translate_port}" >~/translate-server.log 2>&1 &
        )
        echo "✅ Translator server started. Logs: ~/translate-server.log"
}

function stop_translator_daemon() {
        local pids
        # get all matching PIDs, one per line
        pids=$(pgrep -f "translate_server:app")

        if [[ -n "$pids" ]]; then
                # kill each pid on its own line
                echo "$pids" | while read -r pid; do
                        kill "$pid"
                        echo "🛑 Translator server (PID $pid) stopped."
                done
        else
                echo "⚠<fe0f> Translator server is not running."
        fi
}

function kill_restart_emacs() {
        # echo "Resyncing doom"
        # doom sync
        echo "Restarting Emacs daemon..."
        emacsclient -e '(kill-emacs)' || echo "No daemon running or failed to kill"
        emacs --daemon
        emacsclient -n -c || echo "Failed to create new Emacs client frame"
        echo "Emacs daemon should be restarted"
}

#useful for hammerspoon as bundleId string is more robust to identify apps
function findBundleIdAndPath() {
        local name="$1"
        # Input validation: ensure name is non-empty and contains only safe characters
        if [[ -z "$name" || "$name" =~ [^a-zA-Z0-9._-] ]]; then
                echo "Error: Invalid application name. Use alphanumeric characters, dots, or hyphens only."
                return 1
        fi

        local app_path

        # Try mdfind first
        app_path=$(mdfind 'kMDItemKind == "Application"' |
                grep -i "/$name\.app" |
                head -n 1)

        # Fallback: search /Applications and /System/Applications directly
        if [ -z "$app_path" ]; then
                for dir in /Applications /System/Applications; do
                        found=$(find "$dir" -maxdepth 1 -iname "*$name*.app" 2>/dev/null | head -n 1)
                        if [ -n "$found" ]; then
                                app_path="$found"
                                break
                        fi
                done
        fi

        if [ -n "$app_path" ]; then
                local real_path=$(realpath $app_path)
                echo "path: $app_path"
                [[ ! $real_path == $app_path ]] && echo "realpath: $real_path"
                echo "bundle id: $(defaults read "$app_path/Contents/Info" CFBundleIdentifier 2>/dev/null)"
                # echo "bundle id:" $(mdls -name kMDItemCFBundleIdentifier -raw "$app_path") # not robust enough
        else
                echo "App '$name' not found."
        fi
}

function getBundleId() {
        for app in "$@"; do
                printf '%s → %s\n' "$app" "$(osascript -e "id of app \"$app\"" 2>/dev/null || echo "NOT_FOUND")"
        done
        # defaults read "$1/Contents/Info" CFBundleIdentifier 2>/dev/null
        # mdls -name kMDItemCFBundleIdentifier "$1" | cut -d '"' -f 2 #not as robust
        # mdls -name kMDItemCFBundleIdentifier -raw "$1" | cut -d '"' -f 2 #not as robust
}

# old way; new way with 'rat'
function rat() {
        local comment_char="$1"
        local file="$2"

        local sed_remove_comments="/^[[:blank:]]*${comment_char}/d; s/${comment_char}.*//"
        local sed_collapse_blanks="/^$/{ N; /^\n$/D; }"

        if [[ -p /dev/stdin ]]; then
                # Process data from stdin
                sed "$sed_remove_comments" | sed "$sed_collapse_blanks"
        elif [[ -n "$file" ]]; then
                # Process data from file
                sed "$sed_remove_comments" "$file" | sed "$sed_collapse_blanks"
        else
                echo "Error: No input provided. Usage: rem COMMENT_CHAR [FILE]" >&2
                return 1
        fi
}

function rat_test() {
        local comment=
        local opt OPTIND
        while getopts 'c:' opt; do
                case $opt in
                c) comment=$OPTARG ;;
                *)
                        echo "Usage: rat [-cCOMMENT] [FILE]" >&2
                        return 1
                        ;;
                esac
        done
        shift $((OPTIND - 1))

        local file=${1:-/dev/stdin}

        if [[ -n $comment ]]; then
                sed -e "/^[[:blank:]]*${comment}/d" \
                        -e "s/[[:blank:]]*${comment}.*//" \
                        -e '/^$/{N;/^\n$/D;}' "$file"
        else
                cat "$file"
        fi
}

# function rem() {
#     local comment_char="$1"
#     local file="$2"
#
#     # If stdin is a pipe (data being piped in)
#     if [[ -p /dev/stdin ]]; then
#         # Process data from stdin
#         sed "/^[[:blank:]]*${comment_char}/d; s/${comment_char}.*//"
#     elif [[ -n "$file" ]]; then
#         # Process data from file
#         sed "/^[[:blank:]]*${comment_char}/d; s/${comment_char}.*//" "$file"
#     else
#         echo "Error: No input provided. Usage: rem COMMENT_CHAR [FILE]" >&2
#         return 1
#     fi
# }

# | sed '/^$/{ N; /^\n$/D; }'

# function get_doom_emacs() {
#     local config_dir=$HOME/.config/emacs
#
#     if [! -d "$config_dir"]; then
#         git clone --depth 1 git@github.com:doomemacs/doomemacs "$config_dir"
#         "$config_dir/bin/doom" install
#     fi
#     doom doctor
# }

function dedupe_history() {
        local history="$HOME/.zsh_history"
        # local backup="${history}.bak"
        local backup="${history}.$(date +%Y%m%d).bak"
        local deduped="${history}.deduped"

        # Check if the history file exists and is readable
        if [[ ! -f "$history" || ! -r "$history" ]]; then
                echo "Error: '$history' does not exist or is not readable. Aborting." >&2
                return 1
        fi

        # Create a backup
        if ! cp "$history" "$backup"; then
                echo "Error: Backup failed! Aborting." >&2
                return 1
        fi
        echo "Backup created at $backup."

        # Deduplicate, skipping malformed lines
        if ! awk -F';' '$2 && !seen[$2]++' "$history" >"$deduped"; then
                echo "Error: Deduplication (awk) failed! Your backup is safe at $backup." >&2
                return 1
        fi
        echo "Deduplication step completed. Proceeding to update history file."

        # Move the deduplicated file
        if ! mv "$deduped" "$history"; then
                echo "Error: Move failed! You can manually recover your history from $backup or $deduped." >&2
                return 1
        fi

        echo "Deduplication complete. Backup remains at $backup."
}

function checkpath() {
        if [ -z "$1" ]; then
                echo "Usage: checkpath <path>"
                return 1
        fi

        if [ ! -e "$1" ] && [ ! -L "$1" ]; then
                echo "Error: '$1' does not exist"
                return 1
        fi

        local current_path="$1"
        local chain=()

        # Check the initial path with file -h
        file_status=$(file -h "$current_path")

        # If it's a broken symlink, output file -h and realpath error
        if echo "$file_status" | grep -q "broken symbolic link"; then
                echo "file -h: $(echo "$file_status" | sed "s|^$current_path: ||")"
                echo "realpath: no such file or directory"
                return 0
        fi

        # If it's not a symlink, output file -h and realpath
        if ! echo "$file_status" | grep -q "symbolic link"; then
                echo "file -h: $(echo "$file_status" | sed "s|^$current_path: ||")"
                echo "realpath: $current_path"
                return 0
        fi

        # Trace the symlink chain
        chain+=("$current_path")
        while [ -L "$current_path" ]; do
                # Get the target
                target=$(readlink "$current_path")
                if [ -z "$target" ]; then
                        echo "Error: Failed to read symlink target for '$current_path'"
                        return 1
                fi

                # Resolve relative paths
                if [[ ! "$target" = /* ]]; then
                        target="$(dirname "$current_path")/$target"
                        target=$(realpath -s "$target" 2>/dev/null || echo "$target")
                fi

                # Add to chain and move to next path
                chain+=("$target")
                current_path="$target"

                # Check next path with file -h
                file_status=$(file -h "$current_path" 2>/dev/null || echo "$current_path: cannot access (may not exist)")
                if echo "$file_status" | grep -q "broken symbolic link" || echo "$file_status" | grep -q "cannot access"; then
                        chain+=("$(echo "$file_status" | sed 's/.*symbolic link to //')")
                        break
                fi
        done

        # Print the chain
        echo "file -h symlink chain:"
        for p in "${chain[@]}"; do
                echo "  → $p"
        done

        # Show final destination with realpath
        echo -e "\nrealpath: $(realpath "$1" 2>/dev/null || echo "no such file or directory")"
}
#
# Hook: commands (functions) starting with zh_ are suppressed from memory
function zshaddhistory() {
        emulate -L zsh
        local cmd=${1%%$'\n'}
        if [[ $cmd == zh_* ]]; then
                return 1 # Suppress from history
        fi
        return 0
}

# starting index and optional range for second argumment passed
function zh_pi() {
        if [[ $# -lt 1 || $# -gt 2 || ! $1 =~ ^[0-9]+$ || ($# -eq 2 && ! $2 =~ ^[0-9]+$) ]]; then
                echo "Usage: pi_digits_start_range <start> [count]"
                return 1
        fi

        # local start=$1-1
        local start=$(($1 - 1)) #start index at 1
        local count=${2:-1}
        local scale=$((start + count + 50)) # Add generous margin

        # Use bc to compute pi and clean up output
        local pi=$(echo "scale=$scale; 4*a(1)" | bc -l | tr -d '\n' | tr -dc '0-9')

        echo "${pi:$start:$count}"
}

## dummy stale check for 30 seconds
# local age=$(( $(date +%s) - $(stat -f %m "$home_dirs_cache" 2>/dev/null) ))
# if [[ $age -gt 30 ]]; then
#     echo "Stale (>30 seconds)"
# else
#     echo "Fresh (≤30 seconds)"
# fi

# function fcd_1_level() {
#   cd $(ls -d -A "$HOME"/*/ "$HOME"/.*/ | grep -v -E 'node_modules|.git|.cache|\.\.$' | fzf) && nvim .
# }
#

#
# no pngpaste required!
function get_latex() {
        screencapture -i -c
        (
                echo ""
                echo "q"
        ) | pix2tex 2>/dev/null | head -n 1 | sed 's#Predict LaTeX code for image ("?"/"h" for help)\. ##'
        # pbpaste
}

# function get_latex() {
#     local image_path="$HOME/screenshots/pix2tex_screenshot.png"
#     screencapture -i -c -x
#     pngpaste "$image_path"
#     # pix2tex -f "$image_path"
#     echo | pix2tex -f "$image_path" 2>/dev/null
# }

function get_ocr() {
        # Take an interactive screenshot to the clipboard (area selection or window)
        screencapture -i -c -x

        # Wait briefly to ensure clipboard is populated
        sleep 0.2

        # Check if clipboard contains an image
        if ! pngpaste - >/dev/null 2>&1; then
                echo "Error: No image data found on the clipboard" >&2
                return 1
        fi

        # Pipe clipboard image through ImageMagick and Tesseract, strip ICC profile
        pngpaste - |
                # magick - -strip -grayscale Rec709Luma -normalize - |
                tesseract stdin stdout --psm 3 | tr -d '\n' | pbcopy
}

##NOTE: WIP
#
# function get_ocr_images() {
#     # Take an interactive screenshot to the clipboard (area selection or window)
#     screencapture -i -c -x
#
#     # Wait briefly to ensure clipboard is populated
#     sleep 0.2
#
#     # Check if clipboard contains an image
#     if ! pngpaste - >/dev/null 2>&1; then
#         echo "Error: No image data found on the clipboard" >&2
#         return 1
#     fi
#
#     # Pipe clipboard image through ImageMagick and Tesseract
#     pngpaste - |
#         magick png:- -colorspace Gray -normalize -threshold 20% -sharpen 0x1.0 -morphology Open Square:1 -background black -alpha off -flatten png:- |
#         tesseract - stdout --psm 6 | pbcopy
# }

function get_ocr_old() {
        local root_dir="$HOME/screenshots"

        local ocr_dir="$root_dir/tmp"

        mkdir -p "$ocr_dir"

        local output_file_name="$root_dir/ocr_output"
        # local output_file_name="$ocr_dir/ocr_output"
        tesseract "$(ls -t $root_dir/*.png | head -n 1)" "$output_file_name" --psm 3 && cat "$output_file_name.txt" | pbcopy
        # tesseract "$(ls -t $ocr_dir/*.png | head -n 1)" "$output_file_name" --psm 3 && cat "$output_file_name.txt" | pbcopy
}

function update_dir_cache() {
        mkdir -p $(dirname $home_dirs_cache)

        # -E "node_modules" -E ".git" ...
        (fd . "$HOME" -t d -H ${dir_exclusions[@]/#/-E} | gzip >$home_dirs_cache) &

        # Disown to prevent job from being tied to shell
        disown
}

function find_dir_then_cache() {
        local dir_viewer=${DIRVIEWER:-$editor}

        local dir=$(fd . "$HOME" --max-depth 5 -t d -H ${dir_exclusions[@]/#/-E} | fzf --prompt="Find Dir (fresh 5 levels): " --preview "tree -a -C -L 1 {}")
        if [[ -n "$dir" ]]; then
                # Update cache in the background
                (update_dir_cache) &
                # cd "$dir" && nvim .
                cd "$dir" && $dir_viewer .
        fi
}

function find_dir_from_cache() {
        local dir_viewer=${DIRVIEWER:-$editor}
        # local open_with=${1:-nvim}
        # local open_with=${1:-$EDITOR}
        local dir
        # Generate cache in background if it doesn't exist, isn't readable, or is stale
        if [[ ! -f $home_dirs_cache || ! -r $home_dirs_cache || $(find $home_dirs_cache -mtime +15 2>/dev/null) ]]; then
                find_dir_then_cache
        else
                dir=$(gunzip -c $home_dirs_cache | fzf --prompt="Find Dir (from cache): " --preview "tree -a -C -L 1 {}")
                [[ -n "$dir" ]] && cd "$dir" && $dir_viewer .

                # dir=$(fzf --prompt="Find Dir: " --preview "tree -C -L 1 {}" < $muh_cache)
                # if [[ -n "$dir" ]]; then
                #
                #     if [[ $open_with == 'nvim' ]]; then
                #         cd "$dir" && nvim .
                #     else
                #         emacsclient -c -n "$dir"
                #     fi
                # fi

                #nice alternative!
                # recent_add "$dir"

                # [[ -n "$dir" ]] && open_with_editor "$open_with" "$dir"
        fi
}

function find_file() {
        local mode="$1"
        local fd_cmd=(fd . "$HOME" -H)
        local is_raw=$([[ "$mode" == "raw" ]] && echo 1)

        # no "raw" argument passed then use exclusions list
        if [[ ! $is_raw ]]; then
                fd_cmd+=("${dir_exclusions[@]/#/-E}")
        fi

        local dir_or_file
        dir_or_file=$("${fd_cmd[@]}" | fzf --prompt="Find Files${is_raw:+ (raw)}: " --preview "$preview")

        if [[ -z "$dir_or_file" ]]; then
                # echo "No selection made."
                return 1
        fi

        if [[ -d $dir_or_file ]]; then
                cd "$dir_or_file" && "${EDITOR:-nvim}" .
        elif editable_path "$dir_or_file"; then # <-- new helper
                cd "$(dirname "$dir_or_file")" && "${EDITOR:-nvim}" "$dir_or_file"
        else
                recent_add "$dir_or_file"
                open "$dir_or_file"
        fi
}

function open_with_editor() {
        # local editor="${1:-nvim}"
        local editor="${1:-$EDITOR}"
        local dir="$2"

        case "$editor" in
        nvim) cd "$dir" && nvim . ;;
        # emacs | emacsclient) emacsclient -c -n "$dir" ;;
        emacs | emacsclient) emacsclient -c -n -e "(my/open-directory-in-vertico \"$dir\")" ;;
        code) code "$dir" ;;       # VSCode
        "") cd "$dir" && nvim . ;; # fallback
        *)
                if command -v "$editor" &>/dev/null; then
                        "$editor" "$dir"
                else
                        echo "Unknown editor: $editor"
                        return 1
                fi
                ;;
        esac
}

function clip_from_url() {
        local url="$1"
        local start_time="$2"
        local end_time="$3"
        local output_file="${4:-output_clip.mp4}"

        if [[ -z "$start_time" && -z "$end_time" ]]; then
                # If neither start nor end time is specified, just download the video
                download_video "$url" "$output_file"
        else
                # If either start or end time is specified, proceed with clipping
                local temp_video="temp_video.mp4"

                download_video "$url" "$temp_video"

                # Use default values for times if not provided
                start_time="${start_time:-00:00:00}"

                if [[ -z "$end_time" ]]; then
                        # Calculate the video's duration
                        local duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$temp_video")
                        # Convert duration to HH:MM:SS format manually
                        local seconds=${duration%.*}
                        local hours=$((seconds / 3600))
                        local minutes=$(((seconds % 3600) / 60))
                        local secs=$((seconds % 60))
                        end_time=$(printf "%02d:%02d:%02d" "$hours" "$minutes" "$secs")
                fi

                clip_video "$temp_video" "$start_time" "$end_time" "$output_file"
                rm "$temp_video" #NOTE: probably 'clip_from_url' should work under /tmp/video/ or something
        fi
}

function download_video() {
        local url="$1"
        local output_name="${2:-tmp_downloaded_video.mp4}" # fallback name 'tmp_downloaded_video'
        yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4" -o "$output_name" "$url"
}

# Function to clip a video with forced keyframes at the start
function clip_video() {
        local input_file="$1"
        local start_time="$2"                         # Expected format: HH:MM:SS
        local end_time="$3"                           # Expected format: HH:MM:SS
        local output_file="${4:-tmp_output_clip.mp4}" # Default to 'tmp_output_clip.mp4' if no fourth argument is provided

        ffmpeg -i "$input_file" -ss "$start_time" -to "$end_time" -force_key_frames "$start_time,$end_time" -c:v libx264 -c:a copy "$output_file"
        # local start_seconds=$(echo "$start_time" | awk -F: '{ print ($1 * 3600) + ($2 * 60) + $3 }')
        # ffmpeg -i "$input_file" -ss "$start_time" -to "$end_time" -force_key_frames "expr:gte(t,$start_seconds)" -c:v libx264 -c:a copy "$output_file"
}

function recent_edit() {
        local within="${1:-1h}"
        fd . "$HOME" -H --changed-within "$within" --type f --exclude '.*' --exclude 'Library' -x ls -lh {}
}

#NOTE: bug when i save file it adds weird 'tabs_dir' text

# function get_urls() {
#     local browser="${1:-brave}"
#
#     # tabs directory
#     mkdir -p "$HOME/.brave_tabs"
#
#     osascript <<EOF | tr ',' '\n' | sed 's/^[ \t]*//'
#     tell application "$browser"
#         set urlList to {}
#         repeat with w in windows
#             repeat with t in tabs of w
#                 set end of urlList to URL of t
#             end repeat
#         end repeat
#         return urlList
#     end tell
# EOF
# }

function get_title_from_url() {
        local url="$1"
        title=$(curl -s -H "User-Agent: Mozilla/5.0" "$url" | htmlq -t 'title' 2>/dev/null)
        # local title=$(curl -s -H "User-Agent: Mozilla/5.0" "$url" | xmllint --html --xpath "string(//meta[@property='og:title']/@content | //title/text())" - 2>/dev/null)
        if [ -n "$title" ]; then
                echo "$title"
        else
                echo "No title found for $url"
        fi
}

function save_tabs() {
        get_urls | while read -r url; do
                title=$(get_title_from_url "$url")
                echo "URL: $url, TITLE: $title"
        done | tee "$HOME/.brave_tabs/3.txt"
}

# autoload -Uz get_title_from_url NOTE: wtf was this
function save_tabs_test() {
        get_urls | parallel -j 10 --keep-order 'zsh -c "source ~/.shell_functions.sh; title=\$(get_title_from_url \"{}\"); echo \"URL: {}, TITLE: \$title\""' | tee "$HOME/.brave_tabs/3.txt"
}

#  used like: get_brave_tabs | open_in "safari"
# function open_tabs() {
#     local browser="${1:-firefox}" #fallback to firefox
#     while read -r url; do
#         open -a "$browser" "$url" # Use 'open -a' to open the URL in the specified application
#     done
# }

function open_tabs() {
        local browser="${1:-firefox}" #fallback to firefox
        while read -r line; do
                url=$(echo "$line" | awk -F': ' '{print $2}' | cut -d',' -f1)
                open -a "$browser" "$url" # Use 'open -a' to open the URL in the specified application
        done
}

function remove_h_old() {
        if [ -z "$1" ]; then
                echo "Usage: remove_from_history 'command to remove'"
                return 1
        fi

        local command_to_remove="$1"
        local histfile="${HISTFILE:-$HOME/.zsh_history}"
        local tempfile="${histfile}.tmp"

        # Escape special characters in the command
        local escaped_command=$(printf '%q' "$command_to_remove")

        # Count instances before removal
        local before_count=$(grep -c ": [0-9]*:[0-9];$escaped_command$" "$histfile")

        # Remove from file, accounting for Zsh history format
        sed -E "/^: [0-9]+:[0-9];$escaped_command$/d" "$histfile" >"$tempfile" && mv "$tempfile" "$histfile"

        # Count instances after removal
        local after_count=$(grep -c ": [0-9]*:[0-9];$escaped_command$" "$histfile")

        # Calculate number of removed instances
        local removed_count=$((before_count - after_count))

        # Clear the current session's history
        fc -p

        # Reload history from file
        fc -R "$histfile"

        echo "Removed $removed_count instance(s) of '$command_to_remove' from history."
}

remove_from_history() {
        if [ -z "$1" ]; then
                echo "Usage: remove_from_history 'command to remove'"
                return 1
        fi

        local command_to_remove="$1"
        local histfile="${HISTFILE:-$HOME/.zsh_history}"
        local tempfile="${histfile}.tmp"

        # Escape special characters for sed
        local escaped_command=$(printf '%s\n' "$command_to_remove" | sed -e 's/[]\/$*.^[]/\\&/g')

        # Count instances before removal
        local before_count=$(grep -c ": [0-9]*:[0-9];$escaped_command$" "$histfile")

        # Remove the specified command and the 'remove_from_history' command
        sed -E "/^: [0-9]+:[0-9];($escaped_command|remove_from_history .*)$/d" "$histfile" >"$tempfile" && mv "$tempfile" "$histfile"

        # Count instances after removal
        local after_count=$(grep -c ": [0-9]*:[0-9];$escaped_command$" "$histfile")

        # Calculate number of removed instances
        local removed_count=$((before_count - after_count))

        # Clear the current session's history
        fc -p

        # Reload history from file
        fc -R "$histfile"

        echo "Removed $removed_count instance(s) of '$command_to_remove' from history."
        echo "Also removed the 'remove_from_history' command itself."
}

function app_to_space() {
        # Get current space count
        space_count=$(defaults read com.apple.spaces | sed -n '/Spaces =/,/)/p' | grep -c 'ManagedSpaceID =')
        my_app=${1:-'iTerm2'}

        #exit early if $my_app open
        if pgrep -f $my_app >/dev/null; then
                osascript <<EOF
        tell application "System Events"
            tell process "$my_app"
                set frontmost to true
                perform action "AXRaise" of first window
            end tell
            return
        end tell
EOF

                return 0 #exit?
        fi

        # Create new space and move to it
        osascript <<EOF
    tell application "System Events"
        set numberKeyCodes to {18, 19, 20, 21, 23, 22, 26, 28, 25}

        -- Open Mission Control
        key code 160

        tell process "Dock"
            -- Add new space
            click button 1 of group 2 of group 1 of group 1
            delay 0.25

            -- Navigate to the new space
            key code (item $((space_count + 1)) of numberKeyCodes ) using {control down}
            delay 0.25

            -- tell application "$my_app" to activate -- this doesnt work
            do shell script "open -a '$my_app'"
            delay 0.25

            -- Esc
            key code 53
        end tell
    end tell
EOF
}

# im noticing that applescript control flow breaks a lot ...
function app_to_space_broken() {
        # Get current space count
        space_count=$(defaults read com.apple.spaces | sed -n '/Spaces =/,/)/p' | grep -c 'ManagedSpaceID =')
        my_app=${1:-'iTerm2'}
        # my_app='Google Chrome'

        osascript <<EOF
    tell application "System Events"
        -- Define the key code mapping for numbers 1-9
        set numberKeyCodes to {18, 19, 20, 21, 23, 22, 26, 28, 25}

     
        -- -- Check if app is running, navigate to (?) and early return
        if (name of processes) contains "$my_app" then


           tell process "$my_app"
                set frontmost to true
                perform action "AXRaise" of first window
                   
                -- set appWindow to first window
                -- set {x, y} to position of appWindow
                -- tell application "System Events" to click at {x + 10, y + 10}
            end tell

            return
        end if


        -- -- If app not open then open and navigate to that space (i.e. last space)
        -- Open Mission Control
        key code 160

        tell process "Dock"
            -- Add new space
            click button 1 of group 2 of group 1 of group 1
            delay 1

            -- Navigate to the new space
            key code (item $((space_count + 1)) of numberKeyCodes) using {control down}
            delay 0.6

            -- Open the terminal app
            -- tell application "$my_app" to activate -- this has a timing issue with GUI apps
            do shell script "open -a '$my_app'"

            -- Esc
            key code 53
        end tell
    end tell
EOF
}

# And so on up to 9
alias removeUnsupportedSimulatorDevices='xcrun simctl delete unavailable'

# NOTE: this file exists since formatting is unsupported in zsh files;
# this file then sourced into `.zshrc`

# NOTE: this is run by Alfred with a prompt word and passing the url argument
function archiver() {
        open -a "Brave Browser" "https://web.archive.org/web/*/$1"
        open -a "Brave Browser" "https://archive.is/$1"
}

# WORK IN PROGRESS ..
# function standard_backup() {
#     local FROM_PATH=$(realpath "$1")
#     local TO_PATH="${FROM_PATH}_backup"
#     backup_from_to "$FROM_PATH" "$TO_PATH"
# }
#

# NOTE: backup utility
function backup_hammerspoon() {
        # local REAL_PATH=$(realpath "$HOME/.hammerspoon/")
        # backup_dirs_from_to "$REAL_PATH" "$HOME/.hammerspoon_backup"
        standard_backup_dir "$HOME/.hammerspoon"
}

function backup_nvim() {
        # local NVIM_REAL_PATH=$(realpath "$HOME/.config/nvim")
        # backup_dirs_from_to "$NVIM_REAL_PATH" "$HOME/.config/nvim_backup"
        standard_backup_dir "$HOME/.config/nvim"
}
function backup_dotfiles() {
        # standard_backup "$HOME/.dotfiles"
        standard_backup_dir "$HOME/.dotfiles"
}
function standard_backup_dir() {
        local FROM="$1"
        backup_dirs_from_to "$FROM" "${FROM}_backup"
}

function backup_dirs_from_to() {
        if [ $# -ne 2 ]; then
                echo "Please pass 2 arguments (i.e. source directory followed by backup directory)."
                return
        fi

        local SOURCE_DIR="$1"
        local BACKUP_DIR="$2"

        # Check if source directory exists
        if [ ! -d "$SOURCE_DIR" ]; then
                echo "Error: Source directory $SOURCE_DIR does not exist."
                return
                # exit 1
        fi

        # Create backup directory if it doesn't exist
        mkdir -p "$BACKUP_DIR"

        # Check if backup directory is not empty
        if [ -n "$(ls -A "$BACKUP_DIR")" ]; then
                read -q "REPLY?Backup already exists. Do you want to overwrite? (y/n) "
                echo # Move to a new line
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        echo "Backup cancelled."
                        return
                        # exit 0
                fi
        fi

        # Perform the backup
        if rsync -avL --delete --filter=":- .backupignore" "$SOURCE_DIR/" "$BACKUP_DIR"; then
                # if rsync -avL --delete "$SOURCE_DIR/" "$BACKUP_DIR"; then
                # if rsync -a --delete "$SOURCE_DIR/" "$BACKUP_DIR"; then
                echo "Backup completed successfully ($BACKUP_DIR)"
        else
                echo "Error: Backup failed."
                return
                # exit 1
        fi
}

# works for dirs and files more robustly
function standard_backup() {
        local FROM_PATH=$(realpath "$1")

        if [ -f "$FROM_PATH" ]; then
                local DIR_NAME=$(dirname "$FROM_PATH")
                local FILE_NAME=$(basename "$FROM_PATH")

                # Get filename without extension (handles hidden files and multiple dots)
                local FILE_BASE="${FILE_NAME%.*}"
                local FILE_EXT="${FILE_NAME##*.}"

                # If the file has no extension, FILE_BASE==FILE_NAME
                if [[ "$FILE_NAME" = "$FILE_EXT" ]]; then
                        # No extension
                        local TO_PATH="${DIR_NAME}/${FILE_NAME}_backup"
                else
                        # Check if filename starts with a dot and has another dot (hidden multi-dot file)
                        if [[ "$FILE_NAME" = .*.* ]]; then
                                # Get everything except the last dot+extension
                                local FILE_BASE="${FILE_NAME:0:$((${#FILE_NAME} - ${#FILE_EXT} - 1))}"
                                local TO_PATH="${DIR_NAME}/${FILE_BASE}_backup.${FILE_EXT}"
                        else
                                local TO_PATH="${DIR_NAME}/${FILE_BASE}_backup.${FILE_EXT}"
                        fi
                fi

                if [ -f "$TO_PATH" ]; then
                        read -q "REPLY?Backup file already exists. Do you want to overwrite? (y/n) "
                        echo
                        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                                echo "Backup cancelled."
                                return
                        fi
                fi
                cp "$FROM_PATH" "$TO_PATH" && echo "Backup completed successfully ($TO_PATH)" || echo "Error: Backup failed."
        else
                local TO_PATH="${FROM_PATH}_backup"
                backup_dirs_from_to "$FROM_PATH" "$TO_PATH"
        fi
}

# NOTE: create file in some nested directory (create nested structure it doesnt exist)
function touchd() {
        mkdir -p "$(dirname "$1")" && touch "$1" && cd "$(dirname "$1")" || exit
}

# NOTE: open in zed
function zed() {
        open "$1" -a Zed.app
}

#NOTE: quick/shallow tree view
function trees() {
        tree -L "${1:-2}" "${@:2}" -I node_modules
}

function unship() {
        git revert HEAD --no-commit && git push
}

## alias deship="git revert HEAD --no-commit && git push"

## NOTE: yet to be tested (oct 5 2025); once tested delete this message
function ship_config() {
        (cd "$HOME/.dotfiles" && ship "$@")
        history -d $((HISTCMD - 1))
}

# function ship_config_alt() {
#   local repo="$HOME/.dotfiles"
#   cd "$repo" || { echo "❌  Could not cd into $repo"; return 1; }
#   echo "📦  Shipping from $(pwd)"
#   ship "$@"
# }
#
#
function ship() {
        # --- 1.  early exit if nothing to do ---
        if [[ -z $(git status --porcelain) ]]; then
                echo "Calm down Amazon, there's nothing to ship (working tree clean)."
                return 0
        fi

        # --- 2.  parse flags -------------------------------------------------------
        local yes_flag=false
        while getopts ":y" opt; do
                case $opt in
                y) yes_flag=true ;;
                \?)
                        echo "Invalid option: -$OPTARG" >&2
                        return 1
                        ;;
                esac
        done
        shift $((OPTIND - 1))

        # --- 3.  stage everything up-front -----------------------------------------
        git add .
        echo "Changes to be committed:"
        git status --short # <-- concise list of staged

        # --- 4.  interact ------------------------------------------------------------
        local response
        if [[ $yes_flag != true ]]; then
                print "(enter or y): commit & push; (d): view diff; (dd): nvim diff; anything else cancels."
                read -r response
        fi

        # --- 5.  act -----------------------------------------------------------------
        case "${response:-y}" in # default to 'y' when -y flag given
        y | Y | "")
                git commit -m "${*:-chore: quick ship}" && git push
                echo "🚀  Changes committed and pushed."
                ;;
        d | D) git diff --cached ;;
        dd | DD) nvim -c 'DiffviewOpen' ;;
        *)
                git reset HEAD . # <-- unstage on cancel
                echo "Operation cancelled."
                ;;
        esac
}

# consolidated git commit commands  ... originally to push my sveltekit app to GitHub.  Cloudflare pages listens to GitHub changes and re-deploys app
# NOTE: quick commit to github
function ship_oct5_2025() {
        # Display git status; if empty exit early
        if [ -z "$(git status --porcelain)" ]; then
                echo "Calm down Amazon there's nothing to ship (working tree clean)."
                return
        else
                git status
        fi

        # Parse flag options
        local yes_flag=false
        while getopts ":y" opt; do
                case $opt in
                y) yes_flag=true ;;
                \?)
                        echo "Invalid option: -$OPTARG"
                        return 1
                        ;;
                esac
        done

        # Shift to remove parsed options
        shift $((OPTIND - 1))

        # Get the commit message (now that options are shifted/ flags parsed)
        local input="$*"

        # Escape input
        local escaped_input="${input//\$/\\\\\$}"
        escaped_input="${escaped_input//\\/\\\\}" # Escape backslashes
        escaped_input="${escaped_input//\\/\\\\}" # Escape backslashes
        escaped_input="${escaped_input//\|/\\|}"  # Escape pipe symbols
        escaped_input="${escaped_input//\`/\\\`}" # Escape command substitution
        escaped_input="${escaped_input//\!/\\!}"  # Escape exclamation marks
        # escaped_input="${escaped_input//\'/\\\'}"   # Escape single quotes
        # escaped_input="${escaped_input//\"/\\\"}"   # Escape double quotes

        git add . && git commit -a -m "$escaped_input" -n && git push
}

function connect_to_open_wifi() {

        get_current_network() {
                networksetup -getairportnetwork en0 | awk -F': ' '{print $2}'
        }

        # SECTION A: early return if network exists
        current_network=$(get_current_network)
        if [ -n "$current_network" ]; then
                echo "Already connected ($current_network)"
                # exit 0
                return 0
        fi

        network_names=("Starbucks WiFi")

        for network_name in "${network_names[@]}"; do
                #attempt connection
                networksetup -setairportnetwork en0 "$network_name"

                if [ "$(get_current_network)" = "$network_name" ]; then
                        echo "Connected to $network_name"
                        exit 0
                        # return 0
                fi
        done

        # Fallback failure message
        echo "Failed to connect to any network"
}

function gen_ssh() {
        local key_name=${1// /_}
        ssh-keygen -t ed25519 -f "$HOME/.ssh/id_$key_name"
}

#Created these two on nov10-2025 before installing eza (aliased to lz)
function ls_show_directories() {
        ls -d */
}

function ls_show_files() {
        ls -p | grep -v /
}

#
# function nd() {
#     mkdir -p "$1" && cd -P "$1" || exit
#
# }

#
# function kPorts2() {
#     sudo lsof -iTCP:"$1"-"$2" | awk '{print $2}' | grep -v "PID" | xargs kill -9
# }
#
# function kPorts {
#     read "PORTS?Enter port numbers (e.g. 8080 3000): "
#     for PORT in $PORTS; do
#         PID=$(sudo lsof -t -i:"$PORT")
#         if [[ -n "$PID" ]]; then
#             kill "$PID"
#             echo "Process $PID for port $PORT has been terminated."
#         else
#             echo "No process found for port $PORT."
#         fi
#     done
# }
# #
# function kPorts2 {
#     read "PORTS?Enter port range (e.g. 8080-8085): "
#     IFS='-' read -r start_port end_port <<<"$PORTS"
#     for ((port = $start_port; port <= $end_port; port++)); do
#         PID=$(sudo lsof -t -i:$port)
#         if [[ -n "$PID" ]]; then
#             kill "$PID"
#             echo "Process $PID for port $port has been terminated."
#         else
#             echo "No process found for port $port."
#         fi
#     done
# }

#
#
# # use: some_zsh_fn() { _bash_to_zsh some_bash_fn }
# _bash_to_zsh() {
# 	bash -c "$(declare -f "$1"); $1"
# }
#

get_yt_title() {
        curl -s "$1" | htmlq -t title | sed 's/ - YouTube$//'
}
