#!/bin/bash

#local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else less {} 2>/dev/null; fi"
#local preview="tree -a -C -L 1 {}"
# local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else cat {} 2>/dev/null; fi"
#local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else head -n 20 {} 2>/dev/null; fi"

export RECENT_DB="${XDG_DATA_HOME:-$HOME/.local/share}/shell_recent"

local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else command -v bat >/dev/null && bat --color=always {} || cat {} 2>/dev/null; fi"
local home_dirs_cache="$HOME/.cache/fcd_cache.gz"
local dir_exclusions=(node_modules .git .cache .DS_Store venv __pycache__ Trash "*.bak" "*.log")

function recent_pick() {
    local filter=${1:-.*} pick

    <"$RECENT_DB" grep -E "$filter" | tac | awk '!seen[$0]++' |
        while IFS= read -r path; do
            if [[ -d $path ]]; then
                printf '\e[34mDIR\e[0m\t%s\n' "$path"
            else
                printf '\e[33mFILE\e[0m\t%s\n' "$path"
            fi
        done |
        fzf --ansi \
            --prompt="filter: ${1:-}" \
            --header="Ctrl-E -> edit" \
            --bind "ctrl-e:execute(${EDITOR:-nvim} \"$RECENT_DB\" > /dev/tty)" \
            --with-nth=1,2 \
            --preview '
            path=$(echo {} | cut -f2-)

            if [[ -d "$path" ]]; then
                /run/current-system/sw/bin/tree -a -C -L 1 "$path"
            else
                if /run/current-system/sw/bin/bat --version >/dev/null 2>&1; then
                    /run/current-system/sw/bin/bat --color=always "$path"
                else
                    cat "$path" 2>/dev/null
                fi
            fi
        ' |
        awk -F'\t' '{print $2}' | while IFS= read -r pick; do
        [[ $pick ]] && ${EDITOR:-nvim} "$pick"
    done
}

function recent_add() {
    [[ -e $1 ]] || return
    local dir=${RECENT_DB%/*}
    [[ -d $dir ]] || mkdir -p "$dir"
    printf '%s\n' "$(realpath "$1")" >>"$RECENT_DB" # no -m
}

#NOTE: wrapping nvim itself to interpolate 'recent_add' rather than use wonky zshrc hooks for files vs directory (inconsistent)
# function nvim() {
#     local arg=$1
#     echo "[nnvim] ARG: $arg" # Debug
#
#     if [[ -n "$arg" ]]; then
#         local full_path
#         full_path="$(/bin/realpath "$arg" 2>/dev/null)"
#         echo "[nnvim] FULL_PATH: $full_path" # Debug
#
#         if [[ -f "$full_path" || -d "$full_path" ]]; then
#             echo "[nnvim] Logging to recent_add: $full_path"
#             recent_add "$full_path"
#         fi
#     fi
#
#     command nvim "$@"
# }

# function recent_pick_og() {
#     local filter=${1:-.*} pick raw
#     while IFS= read -r raw; do
#         if [[ -d $raw ]]; then
#             # printf '📁 %s\n' "$raw"
#             printf '\e[34mDIR \e[0m%s\n' "$raw" # blue DIR
#         else
#             # printf '📄 %s\n' "$raw"
#             printf '\e[33mFILE \e[0m%s\n' "$raw" # yellow FILE
#         fi
#     done < <(<"$RECENT_DB" grep -E "$filter" | tac | awk '!seen[$0]++') |
#         fzf --ansi --prompt="recent ${1:-}> " |
#         IFS= read -r pick && [[ $pick ]] &&
#         ${EDITOR:-nvim} "${pick#* }" # strip emoji+space
# }

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
    defaults read "$1/Contents/Info" CFBundleIdentifier 2>/dev/null
    # mdls -name kMDItemCFBundleIdentifier "$1" | cut -d '"' -f 2 #not as robust
    # mdls -name kMDItemCFBundleIdentifier -raw "$1" | cut -d '"' -f 2 #not as robust
}

# useful for creating custom new Emacs.icns (havented tested yet)
function generate_icns() {
    local png="$1"
    local output_icns="$2"

    if [ ! -f "$png" ]; then
        echo "Error: PNG file $png not found"
        exit 1
    fi

    echo "Generating .icns from $png"
    mkdir -p "$ICONSET_DIR"

    # Generate required icon sizes
    sips -z 16 16 "$png" --out "$ICONSET_DIR/icon_16x16.png" >/dev/null
    sips -z 32 32 "$png" --out "$ICONSET_DIR/icon_16x16@2x.png" >/dev/null
    sips -z 32 32 "$png" --out "$ICONSET_DIR/icon_32x32.png" >/dev/null
    sips -z 64 64 "$png" --out "$ICONSET_DIR/icon_32x32@2x.png" >/dev/null
    sips -z 64 64 "$png" --out "$ICONSET_DIR/icon_64x64.png" >/dev/null
    sips -z 128 128 "$png" --out "$ICONSET_DIR/icon_64x64@2x.png" >/dev/null
    sips -z 128 128 "$png" --out "$ICONSET_DIR/icon_128x128.png" >/dev/null
    sips -z 256 256 "$png" --out "$ICONSET_DIR/icon_128x128@2x.png" >/dev/null
    sips -z 256 256 "$png" --out "$ICONSET_DIR/icon_256x256.png" >/dev/null
    sips -z 512 512 "$png" --out "$ICONSET_DIR/icon_256x256@2x.png" >/dev/null
    sips -z 512 512 "$png" --out "$ICONSET_DIR/icon_512x512.png" >/dev/null
    sips -z 1024 1024 "$png" --out "$ICONSET_DIR/icon_512x512@2x.png" >/dev/null
    sips -z 1024 1024 "$png" --out "$ICONSET_DIR/icon_1024x1024.png" >/dev/null

    # Convert to .icns
    iconutil -c icns "$ICONSET_DIR" -o "$output_icns"
    rm -rf "$ICONSET_DIR"
    echo "Created $output_icns"
}

# old way; new way with 'rat'
function rem() {
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

function rat() {
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

#NOTE: problematic zsh specific syntax disallows this bash file from formatting on save

# function not_grep() {
#     if [ $# -lt 1 ]; then
#         echo "Usage: $0 <patterns> [file]"
#         exit 1
#     fi
#
#     patterns="$1"
#     file="${2:-/dev/stdin}"
#
#     # Split patterns into array (Zsh syntax)
#     pattern_array=("${(s: :)patterns}") #NOTE: line problematic when format saving
#
#     # Use rg if available, otherwise grep
#     if command -v rg >/dev/null 2>&1; then
#         search_cmd=(rg -i -q)
#     else
#         search_cmd=(grep -i -q)
#     fi
#
#     # Read input into a temporary file if piped
#     if [ "$file" = "/dev/stdin" ] && [ -p /dev/stdin ]; then
#         temp_file=$(mktemp)
#         cat >"$temp_file"
#         file="$temp_file"
#     fi
#
#     for pattern in "${pattern_array[@]}"; do
#         if ! "${search_cmd[@]}" "$pattern" "$file"; then
#             echo "$pattern not found"
#         fi
#     done
#
#     # Clean up temporary file if created
#     [ -n "$temp_file" ] && rm -f "$temp_file"
# }
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
    local dir=$(fd . "$HOME" --max-depth 5 -t d -H ${dir_exclusions[@]/#/-E} | fzf --prompt="Find Dir (fresh 5 levels): " --preview "tree -a -C -L 1 {}")
    if [[ -n "$dir" ]]; then
        # Update cache in the background
        (update_dir_cache) &
        # cd "$dir" && nvim .
        cd "$dir" && "${EDITOR:-nvim}" .
    fi
}

function find_dir_from_cache() {
    # local open_with=${1:-nvim}
    # local open_with=${1:-$EDITOR}
    local dir
    # Generate cache in background if it doesn't exist, isn't readable, or is stale
    if [[ ! -f $home_dirs_cache || ! -r $home_dirs_cache || $(find $home_dirs_cache -mtime +15 2>/dev/null) ]]; then
        find_dir_then_cache
    else
        dir=$(gunzip -c $home_dirs_cache | fzf --prompt="Find Dir (from cache): " --preview "tree -a -C -L 1 {}")
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
        [[ -n "$dir" ]] && "${EDITOR:-nvim}" "$dir"
    fi
}

# function find_file_og() {
#
#     local dir_or_file=$(fd . $HOME -H ${dir_exclusions[@]/#/-E} | fzf --prompt="Find Files: " --preview "$preview")
#
#     if [[ -z "$dir_or_file" ]]; then
#         echo "No directory selected."
#         return 1
#     fi
#     if [[ -d "$dir_or_file" ]]; then
#         # cd "$dir_or_file" && nvim .
#         emacsclient -c -n "$dir"
#     else
#         if [[ "$(file --mime-type -b "$dir_or_file")" =~ ^text/ ]]; then
#             cd $(dirname $dir_or_file) && nvim "$dir_or_file"
#         else
#             open "$dir_or_file"
#         fi
#     fi
# }

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
        echo "No selection made."
        return 1
    fi

    if [[ -d "$dir_or_file" ]]; then
        # Directory: cd and open in editor
        cd "$dir_or_file" && "${EDITOR:-nvim}" .
    elif [[ -f "$dir_or_file" ]]; then
        # File: check if text-like, open accordingly
        if [[ "$(file --mime-type -b "$dir_or_file")" =~ ^text/ ]]; then
            cd "$(dirname "$dir_or_file")" && "${EDITOR:-nvim}" "$dir_or_file"
        else
            open "$dir_or_file" # Binary file, use system open
        fi
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
        rm "$temp_video"
    fi
}

# function clip_from_url_old() {
#     local url="$1"
#     local start_time="$2"
#     local end_time="$3"
#     local temp_video="temp_video.mp4"
#     local output_file="${4:-output_clip.mp4}"
#
#     download_video "$url" "$temp_video"
#     clip_video "$temp_video" "$start_time" "$end_time" "$output_file"
#     # Optionally, clean up the temporary file
#     rm "$temp_video"
# }

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
function ship_dotfiles() {
    (cd "$HOME/.dotfiles" && ship "$@")
}

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

# NOTE: remove neovim config
function rm_nvim_config() {
    rm -rf ~/.config/nvim
    rm -rf ~/.local/state/nvim
    rm -rf ~/.local/share/nvim
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

#
# function nd() {
#     mkdir -p "$1" && cd -P "$1" || exit
#
# }
#
# function rmD() {
#     for file in *; do
#         if [[ $(ls | grep -c "^$file$") -gt 1 ]]; then
#             rm "$file"
#         fi
#     done
#
#     echo "Duplicates removed successfully"
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
# ## remove files using a newline-delimited list the elements of which are string-escaped
# function delC() {
#     local line="$1"
#     IFS=$'\n' && arr=($(echo "${line}"))
#     for i in ${arr[@]}; do
#         escd_path=$(printf '%q\n' /Users/brightowl/Library/Application\ Support/Google/Chrome/Default/"${i}")
#         eval rm -R "${escd_path}"
#         ## echo rm -R ${escd_path}
#     done
# }
#
# # recursively delete files in git repository (i.e. accidentally committed folders)
# function rrmGit() {
#     find . -name "$1" -print0 | xargs -0 git rm -f -r --ignore-unmatch
# }
#
# # delete files in git repository (i.e. accidentally committed files)
# function rmGit() {
#     find . -name "$1" -print0 | xargs -0 git rm -f --ignore-unmatch
# }
