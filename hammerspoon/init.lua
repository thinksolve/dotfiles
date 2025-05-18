hs.alert.show("hs init.lua loaded")

--Commmented these 2 out on 4-25-25 since not really using
-- hs.ipc.cliInstall()
-- hs.loadSpoon("EmmyLua")

require("submodules")
require("registerSpoons")

local watchers = require("watchers") -- set as variable in case want to stop a watcher
local window_management = require("window-management")
local space_management = require("space-management")

-- local function merge_modifiers_old(base_mods, ...)
-- 	return { table.unpack(base_mods), ... }
-- end

local function merge_modifiers(base_mods, ...)
	local new_mods = { table.unpack(base_mods) }

	--NOTE: deduplicating logic below for additional entries

	local exists = {}

	-- Mark existing modifiers
	for _, mod in ipairs(new_mods) do
		exists[mod] = true
	end

	-- Add new modifiers only if they don't exist
	for _, mod in ipairs({ ... }) do
		if not exists[mod] then
			table.insert(new_mods, mod)
			exists[mod] = true
		end
	end

	return new_mods
end

local space_mod = { "ctrl" }
hs.hotkey.bind(space_mod, "q", space_management.close_all_spaces_but_two)
hs.hotkey.bind(space_mod, "-", space_management.close_this_space)
hs.hotkey.bind(merge_modifiers(space_mod, "shift"), "-", space_management.add_new_space)

local screen_position_mod = { "command", "option" }
hs.hotkey.bind(screen_position_mod, "Left", window_management.LeftHalf)
hs.hotkey.bind(screen_position_mod, "Right", window_management.RightHalf)
hs.hotkey.bind(screen_position_mod, "Up", window_management.TopHalf)
hs.hotkey.bind(screen_position_mod, "Down", window_management.BottomHalf)
hs.hotkey.bind(screen_position_mod, "Space", window_management.FullScreen)
-- hs.hotkey.bind(screen_position_mod, "Return", window_management.FullScreen)

local cycle_windows = { "command" }
hs.hotkey.bind(cycle_windows, ",", function()
	window_management.cycleWindows("right")
end)
hs.hotkey.bind(merge_modifiers(cycle_windows, "shift"), ",", function()
	window_management.cycleWindows("left")
end)

local goto_app_mod = { "command", "option" }
hs.hotkey.bind(goto_app_mod, "b", function()
	window_management.goto_app("Brave Browser")
end)

local terminal_app = "ghostty"
hs.hotkey.bind(goto_app_mod, "t", function()
	window_management.goto_app(terminal_app)
end)

hs.hotkey.bind(goto_app_mod, "s", function()
	window_management.goto_app("Spotify")
end)

hs.hotkey.bind(goto_app_mod, "e", function()
	window_management.goto_app("Emacs.app")
end)


-- function runCommandInITermAndHitEnter(command, delay)
-- 	delay = delay or 0.3
--
-- 	window_management.goto_app("iterm2")
--
-- 	-- Give it a moment to become active
-- 	hs.timer.doAfter(delay, function()
-- 		-- Send the keystrokes as if you were typing
-- 		if hs.application("iterm2") then
-- 			hs.eventtap.keyStroke({ "command" }, "t")
-- 		end
-- 		hs.eventtap.keyStrokes(command)
-- 		hs.eventtap.keyStroke({}, "return") -- Press Enter
-- 	end)
-- end

local function runCommand(command)
	hs.eventtap.keyStrokes(command)
	hs.eventtap.keyStroke({}, "return")
end

local function runCommandInItermAndHitEnter(command, delay)
	local app_running = hs.application.find(terminal_app)

	delay = app_running and 0.0 or (delay or 0.25)

	hs.application.launchOrFocus(terminal_app)
	hs.timer.doAfter(delay, function()
		if app_running then
			hs.eventtap.keyStroke({ "command" }, "n")
		end
		runCommand(command)
	end)
end

-- Run a command in iTerm2, hit Enter, and unfocus iTerm2
local function runCommandInItermAndUnfocus(command, delay)
	-- Store the currently focused application
	local original_app = hs.application.frontmostApplication()

	-- Check if iTerm2 is running
	local app_running = hs.application.find(terminal_app)
	delay = app_running and 0.0 or (delay or 0.25)

	-- Launch or focus iTerm2
	hs.application.launchOrFocus(terminal_app)

	-- Execute the command and hit Enter
	hs.timer.doAfter(delay, function()
		if app_running then
			hs.eventtap.keyStroke({ "command" }, "n") -- Open new tab if iTerm2 was already running
		end
		runCommand(command)

		-- Unfocus iTerm2 by restoring focus to the original application
		hs.timer.doAfter(0.1, function()
			if original_app and original_app:isFrontmost() == false then
				original_app:activate()
			end
			-- Optional: Minimize or hide iTerm2 to ensure it’s out of the way
			local iterm = hs.application.get(terminal_app)
			if iterm then
				iterm:hide() -- or iterm:minimize()
			end
		end)
	end)
end

-- -- Directory search hotkey
hs.hotkey.bind({ "cmd" }, "/", function()
	-- runCommandInItermAndHitEnter("ruzzy")
	-- runCommandInItermAndHitEnter('cd "$(find_dirs_fuzzy_full)" && nvim .')
	-- runCommandInItermAndHitEnter('cd "$(find_dirs_fuzzy_full)" && yazi .')
	-- runCommandInItermAndHitEnter("cd $(fzf) && nvim .")
	--
	-- local command = 'cd "$(fd . "$HOME" --type d -H --max-depth 3 | fzf --prompt="Find Dir: ")" && nvim .'
	-- local command = "fcd_1_level"

	runCommandInItermAndHitEnter("find_dir_from_cache")
end)

hs.hotkey.bind({ "cmd", "option" }, "/", function()
	runCommandInItermAndHitEnter("find_file")
end)

local function runCommandInBackground(command)
	-- Set PATH to include Homebrew binaries and source Zsh environment
	local shellCommand = string.format(
		'/bin/zsh -c "export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH; source /etc/zprofile 2>/dev/null; source ~/.zshenv 2>/dev/null; source ~/.zshrc 2>/dev/null && %s"',
		command
	)
	-- Execute and capture output/errors
	local output, status, type, rc = hs.execute(shellCommand)
	if not status then
		hs.notify
			.new({
				title = "Hammerspoon",
				informativeText = "Error running " .. command .. ": " .. (output or "Unknown error"),
			})
			:send()
	else
		hs.notify
			.new({
				title = "Hammerspoon",
				informativeText = "Successfully ran " .. command .. ". Text copied to clipboard.",
			})
			:send()
	end
	return output, status
end

local function captureAndOCR()
	-- Ensure screenshots directory exists
	local screenshotsDir = os.getenv("HOME") .. "/screenshots"
	os.execute("mkdir -p " .. screenshotsDir)

	-- Generate unique filename with timestamp
	local timestamp = os.date("%Y%m%d_%H%M%S")
	local screenshotPath = screenshotsDir .. "/screenshot_" .. timestamp .. ".png"

	-- Capture screenshot interactively
	local success = os.execute("screencapture -i " .. screenshotPath)
	if not success or not hs.fs.attributes(screenshotPath) then
		hs.notify.new({ title = "Hammerspoon", informativeText = "Failed to capture screenshot" }):send()
		return
	end

	-- Run get_ocr
	runCommandInBackground("get_ocr_old")
	-- runCommandInItermAndHitEnter("get_ocr")
end

function run_without_terminal(function_or_script_path)
	-- hs.execute("/bin/zsh -c 'source ~/.zshrc 2>/dev/null; LC_ALL=en_US.UTF-8 " .. function_or_script_path .. "'")
	hs.execute(
		string.format("/bin/zsh -c 'source ~/.zshrc 2>/dev/null; LC_ALL=en_US.UTF-8 %s'", function_or_script_path)
	)
end

hs.hotkey.bind({ "ctrl", "option" }, "x", function()
	-- run_without_terminal("~/bin/get_ocr.sh") --works nicely
	run_without_terminal("get_ocr") --works nicely

	-- hs.execute("/bin/zsh -c '$HOME/bin/get_ocr.sh'") -- garbles text

	-- runCommandInItermAndHitEnter("get_ocr") --works but opens terminal
	-- captureAndOCR() --works but requires local files (no pngpaste) and logic now lives within hammerspoon function rather tham bash or script file
end)

-- Run a command in iTerm2 without focusing it

local function runCommandInItermWithoutFocus(command)
	-- Modify command to exit after completion
	local wrappedCommand = command .. "; exit"

	local script = [[
        tell application "iterm2"
            -- Create a new terminal window without activating
            set newWindow to (create window with default profile without activating)
            
            -- Get the current session of the new window
            tell current session of newWindow
                -- Run the command with exit at the end
                write text "]] .. wrappedCommand .. [["
            end tell
        end tell
    ]]

	-- Run the AppleScript
	hs.osascript.applescript(script)
end

local function runCommandInTerminal(command)
	local wrappedCommand = command .. "; exit"
	local script = [[
        tell application "Terminal"
            set newWindow to do script "]] .. wrappedCommand .. [["
            -- Optionally close the window after execution
            -- delay 1
            -- tell newWindow to close
        end tell
    ]]
	hs.osascript.applescript(script)
end

local function runCommandInGhostty(command)
	local wrappedCommand = command .. "; exit"
	-- Run Ghostty with the command
	hs.execute("/bin/zsh -c /opt/homebrew/bin/ghostty -e '" .. wrappedCommand .. "' &")
end

-- Run a command in iTerm2 without focusing the window and close when done
local function runCommandInItermWithoutFocus_broken(command)
	-- Modify command to signal completion
	local wrappedCommand = command .. "; echo 'HAMMERSPOON_COMMAND_COMPLETED'; exit"

	-- AppleScript to create a new terminal window, run command, and monitor for completion
	local script = [[
        tell application "iTerm2"
            -- Create a new terminal window without activating
            set newWindow to (create window with default profile without activating)
            
            -- Get the current session of the new window
            tell current session of newWindow
                -- Set up a handler to monitor the session output
                set isComplete to false
                set outputBuffer to ""
                
                -- Run the command
                write text "]] .. wrappedCommand .. [["
                
                -- Loop until we see our completion marker
                repeat until isComplete
                    delay 0.2
                    -- Get session contents
                    set outputBuffer to (get contents)
                    
                    -- Check if our marker is in the output
                    if outputBuffer contains "HAMMERSPOON_COMMAND_COMPLETED" then
                        set isComplete to true
                        close newWindow
                    end if
                end repeat
            end tell
        end tell
    ]]

	-- Run the AppleScript
	hs.osascript.applescript(script)
end

hs.hotkey.bind({ "ctrl", "option" }, "z", function()
	-- run_without_terminal("get_ocr_images")
	-- run_without_terminal("get_latex") --pix2tex seemingly needs actual terminal to work
	-- runCommandInItermAndUnfocus("get_latex")
	-- runCommandInItermWithoutFocus("get_latex")
	runCommandInTerminal("get_latex")
	-- runCommandInGhostty("get_latex")
end)
