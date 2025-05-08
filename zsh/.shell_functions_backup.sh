#!/bin/bash

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
# Hook: commands (functions) starting with zhide are suppressed from memory
function zshaddhistory() {
    emulate -L zsh
    local cmd=${1%%$'\n'}
    if [[ $cmd == zhide* ]]; then
        return 1 # Suppress from history
    fi
    return 0
}

# starting index and optional range for second argumment passed
function zhide_pi() {
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
local home_dirs_cache="$HOME/.cache/fcd_cache.gz"
local dir_exclusions=(node_modules .git .cache .DS_Store venv __pycache__ Trash "*.bak" "*.log")
local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else command -v bat >/dev/null && bat --color=always {} || cat {} 2>/dev/null; fi"
#local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else less {} 2>/dev/null; fi"
#local preview="tree -a -C -L 1 {}"
# local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else cat {} 2>/dev/null; fi"
#local preview="if [[ -d {} ]]; then tree -a -C -L 1 {}; else head -n 20 {} 2>/dev/null; fi"

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
        tesseract stdin stdout --psm 3 | pbcopy
}

function get_ocr_images() {
    # Take an interactive screenshot to the clipboard (area selection or window)
    screencapture -i -c -x

    # Wait briefly to ensure clipboard is populated
    sleep 0.2

    # Check if clipboard contains an image
    if ! pngpaste - >/dev/null 2>&1; then
        echo "Error: No image data found on the clipboard" >&2
        return 1
    fi

    # Pipe clipboard image through ImageMagick and Tesseract
    pngpaste - |
        magick png:- -colorspace Gray -normalize -threshold 20% -sharpen 0x1.0 -morphology Open Square:1 -background black -alpha off -flatten png:- |
        tesseract - stdout --psm 6 | pbcopy
}

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
    local dir
    # -E "node_modules" -E ".git" ...
    dir=$(fd . "$HOME" --max-depth 5 -t d -H ${dir_exclusions[@]/#/-E} | fzf --prompt="Find Dir (fresh 5 levels): " --preview "tree -a -C -L 1 {}")
    if [[ -n "$dir" ]]; then
        # Update cache in the background
        (update_dir_cache) &
        cd "$dir" && nvim .
    fi
}

function find_dir_from_cache() {
    local dir
    # Generate cache in background if it doesn't exist, isn't readable, or is stale
    if [[ ! -f $home_dirs_cache || ! -r $home_dirs_cache || $(find $home_dirs_cache -mtime +15 2>/dev/null) ]]; then
        fcd_old
    else
        dir=$(gunzip -c $home_dirs_cache | fzf --prompt="Find Dir (from cache): " --preview "tree -a -C -L 1 {}")
        # dir=$(fzf --prompt="Find Dir: " --preview "tree -C -L 1 {}" < $muh_cache)
        if [[ -n "$dir" ]]; then
            cd "$dir" && nvim .
        fi
    fi
}

function find_file() {

    local dir_or_file=$(fd . $HOME -H ${dir_exclusions[@]/#/-E} | fzf --prompt="Find Files: " --preview "$preview")

    if [[ -z "$dir_or_file" ]]; then
        echo "No directory selected."
        return 1
    fi
    if [[ -d "$dir_or_file" ]]; then
        cd "$dir_or_file" && nvim .
    else
        if [[ "$(file --mime-type -b "$dir_or_file")" =~ ^text/ ]]; then
            cd $(dirname $dir_or_file) && nvim "$dir_or_file"
        else
            open "$dir_or_file"
        fi
    fi
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

function get_urls() {
    local browser="${1:-brave}"
    # local tabs_dir="$HOME/.brave_tabs"
    # mkdir -p "$tabs_dir"

    osascript <<EOF | tr ',' '\n' | sed 's/^[ \t]*//' #| tee "$tabs_dir/1.txt"
    tell application "$browser"
        set urlList to {}
        repeat with w in windows
            repeat with t in tabs of w
                set end of urlList to URL of t
            end repeat
        end repeat
        return urlList
    end tell
EOF
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"
    #| tee "$tabs_dir/1.txt"

}

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

# WORK IN PROGRESS
# function standard_backup() {
#     local FROM_PATH=$(realpath "$1")
#     local TO_PATH="${FROM_PATH}_backup"
#     backup_from_to "$FROM_PATH" "$TO_PATH"
# }
#
function standard_backup() {
    local FROM_PATH=$(realpath "$1")

    # Check if the path is a file or directory
    if [ -f "$FROM_PATH" ]; then
        # For files, append _backup to the filename
        local DIR_NAME=$(dirname "$FROM_PATH")
        local FILE_NAME=$(basename "$FROM_PATH")
        local TO_PATH="${DIR_NAME}/${FILE_NAME}_backup"
    else
        # For directories, append _backup to the directory path
        local TO_PATH="${FROM_PATH}_backup"
    fi

    # If it's a file, we need to handle it differently
    if [ -f "$FROM_PATH" ]; then
        # Create parent directory if needed
        mkdir -p "$(dirname "$TO_PATH")"
        # Check if backup already exists
        if [ -f "$TO_PATH" ]; then
            read -q "REPLY?Backup file already exists. Do you want to overwrite? (y/n) "
            echo # Move to a new line
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Backup cancelled."
                return
            fi
        fi
        # Copy the file
        cp "$FROM_PATH" "$TO_PATH" && echo "Backup completed successfully ($TO_PATH)" || echo "Error: Backup failed."
    else
        # It's a directory, so use the existing backup_from_to function
        backup_from_to "$FROM_PATH" "$TO_PATH"
    fi
}

# NOTE: backup utility
function backup_hammerspoon() {
    local REAL_PATH=$(realpath "$HOME/.hammerspoon/")
    backup_from_to "$REAL_PATH" "$HOME/.hammerspoon_backup"
}

function backup_nvim() {
    # backup_from_to "$HOME/.config/nvim" "$HOME/.config/nvim_backup"
    local NVIM_REAL_PATH=$(realpath "$HOME/.config/nvim")
    backup_from_to "$NVIM_REAL_PATH" "$HOME/.config/nvim_backup"
}

function backup_from_to() {
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
    if rsync -avL --delete "$SOURCE_DIR/" "$BACKUP_DIR"; then
        # if rsync -a --delete "$SOURCE_DIR/" "$BACKUP_DIR"; then
        echo "Backup completed successfully ($BACKUP_DIR)"
    else
        echo "Error: Backup failed."
        return
        # exit 1
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

# consolidated git commit commands  ... originally to push my sveltekit app to GitHub.  Cloudflare pages listens to GitHub changes and re-deploys app
# NOTE: quick commit to github
function ship() {
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
    escaped_input="${escaped_input//\|/\\|}"  # Escape pipe symbols
    escaped_input="${escaped_input//\`/\\\`}" # Escape command substitution
    escaped_input="${escaped_input//\!/\\}"   # Escape exclamation marks

    local response

    if [ "$yes_flag" != true ]; then
        # Prompt for action if yes_flag is not set
        print "(enter or y): commit changes; (d): view diff; (dd): view diff in Neovim; anything else cancels."
        read -r response
    fi

    if [ "$yes_flag" = true ] || [ -z "$response" ] || [[ $response =~ ^[yY]$ ]]; then
        # Proceed with the action
        git add . && git commit -m "$escaped_input" && git push
        echo "🚀 Changes committed and pushed successfully."
    elif [[ $response =~ ^[dD]$ ]]; then
        # Display git diff using standard tool
        echo "Changes to be committed (staged):"
        git diff --cached
        echo "Changes not staged for commit:"
        git diff
    elif [[ $response =~ ^[dD][dD]$ ]]; then
        # Display git diff using Neovim
        echo "Opening diff in Neovim..."
        # nvim -c "DiffviewOpen" .
        nvim -c "InitDiffviewOpen"
        # nvim -c "doautocmd User InitDiffview | DiffviewOpen"
        # nvim -c "doautocmd User InitDiffview" -c "DiffviewOpen"
    else
        # Cancel the operation (fall back for any other input)
        echo "Operation cancelled."
    fi
}

function ship_old() {
    local input="$1"
    escaped_input="${input//\$/\\\\\$}"
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
