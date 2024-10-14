#!/bin/bash

alias removeUnsupportedSimulatorDevices='xcrun simctl delete unavailable'

# NOTE: this file exists since formatting is unsupported in zsh files;
# this file then sourced into `.zshrc`

# NOTE: this is run by Alfred with a prompt word and passing the url argument
function archiver() {
    open -a "Brave Browser" "https://web.archive.org/web/*/$1"
    open -a "Brave Browser" "https://archive.is/$1"
}

# NOTE: backup utility
function backup_nvim() {
    backup_from_to "$HOME/.config/nvim" "$HOME/.config/nvim_backup"
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
    if rsync -a --delete "$SOURCE_DIR/" "$BACKUP_DIR"; then
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
