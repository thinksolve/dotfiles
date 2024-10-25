#!/bin/bash

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
