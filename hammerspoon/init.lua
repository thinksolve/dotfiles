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
	window_management.toggle_app("Brave Browser")
end)

-- local terminal_app = "iterm2"
local terminal_app = "ghostty"
local terminal_app_id = "com.mitchellh.ghostty"
hs.hotkey.bind(goto_app_mod, "t", function()
	window_management.toggle_app_bundle_id(terminal_app_id)
	-- window_management.toggle_app(terminal_app)
end)

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
-- hs.hotkey.bind(goto_app_mod, "y", function()
-- 	runCommandInItermAndHitEnter("yazi")
-- end)

hs.hotkey.bind(goto_app_mod, "s", function()
	window_management.toggle_app("Spotify")
end)

hs.hotkey.bind(goto_app_mod, "m", function()
	-- window_management.goto_app("messages.app")
	window_management.toggle_open_close_by_bundle_id("com.apple.MobileSMS")
end)

hs.hotkey.bind(goto_app_mod, "n", function()
	window_management.toggle_app("Notes")
end)

hs.hotkey.bind(goto_app_mod, "l", function()
	-- window_management.toggle_app("Mail")
	window_management.toggle_open_close_by_bundle_id("com.apple.mail")
end)

hs.hotkey.bind(goto_app_mod, "k", function()
	-- window_management.toggle_app("Calendar")
	window_management.toggle_open_close_by_bundle_id("com.apple.iCal")
end)

hs.hotkey.bind(goto_app_mod, "f", function()
	window_management.toggle_open_close_by_bundle_id("com.runningwithcrayons.Alfred")
end)

hs.hotkey.bind(goto_app_mod, "a", function()
	window_management.toggle_open_close_by_bundle_id("com.apple.ActivityMonitor")
end)

-- hs.hotkey.bind(goto_app_mod, "e", function()
-- 	window_management.goto_app("Emacs.app")
-- end)

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

local function start_emacs_client()
	-- os.execute([[/bin/zsh -l -c "/opt/homebrew/bin/emacsclient -c -n" &]])
	-- -- why not hs.execute?
	-- -- why background process way with '&' problematic?
	os.execute([[/bin/zsh -l -c "/opt/homebrew/bin/emacsclient -c -n -a '' "]])
end
local function get_emacs_app()
	return hs.application.get("org.gnu.Emacs")
end

hs.hotkey.bind(goto_app_mod, "d", function()
	-- Try to find if Emacs server is running; os.execute seems to be needed over hs.execute here
	-- local serverRunning = os.execute("pgrep -f 'emacs.*daemon'" .. " > /dev/null 2>&1")
	-- -- this pgrep way finds other emacs daemons not responsible for emacsclient; problematic

	local serverRunning =
		os.execute([[/bin/zsh -l -c "/opt/homebrew/bin/emacsclient -e '(server-running-p)' > /dev/null 2>&1"]])

	if serverRunning then
		-- Server is running, check if there are visible Emacs frames
		-- "org.gnu.Emacs" seems to reliably get the emacsclient frame

		local emacsApp = get_emacs_app()
		-- appears if check not really needed if you start_emacs_client (which falls back to already started one if active?)
		if emacsApp and #emacsApp:allWindows() > 0 then
			-- Emacs application exists with visible windows, focus it
			emacsApp:activate()
		else
			-- Server running but no visible windows, create a new client frame
			start_emacs_client()
			-- hs.timer.doAfter(0.1, function()
			emacsApp:activate()

			-- end)
		end
	else
		-- Server not running, start server and create a frame
		hs.alert.show("Starting Emacs server and creating frame")

		-- -- Guess i dont need to explicitly start the daemon?
		-- os.execute("/bin/zsh -l -c '/opt/homebrew/bin/emacs --daemon' ")

		start_emacs_client()
		-- hs.timer.doAfter(0.4, function()
		get_emacs_app():activate()
		-- end)
	end
end)

-- NOTE: WIP below

function prompt_with_callback(place_holder_text, call_back)
	local chooser
	chooser = hs.chooser.new(function(choice)
		if not choice or not choice.text or choice.text == "" then
			return
		end
		call_back(choice.text)
	end)

	chooser:choices({ { ["text"] = "" } })
	chooser:queryChangedCallback(function(query)
		chooser:choices({ { ["text"] = query } })
	end)
	chooser:placeholderText(place_holder_text)
	chooser:width(30)
	chooser:rows(1)
	chooser:show()
end

-- NOTE: WIP below
-- hs.hotkey.bind({ "cmd", "option" }, "r", function()
-- 	prompt_with_callback("Enter comment character (e.g. #)", function(comment_char)
-- 		-- local script =
-- 		-- 	string.format("/bin/zsh -c 'source ~/.zshrc 2>/dev/null; pbpaste | rem %q | pbcopy &'", comment_char)
-- 		-- -- hs.execute(script .. " &") --  sub-shell truncates output!
-- 		-- hs.execute(script)
--
-- 		local script = string.format("source ~/.zshrc 2>/dev/null; pbpaste | rem %q | pbcopy", comment_char)
-- 		hs.task
-- 			.new("/bin/zsh", function(exitCode, stdOut, stdErr)
-- 				if exitCode == 0 then
-- 					hs.alert.show("Result copied to clipboard!")
-- 				else
-- 					hs.alert.show("Error: " .. (stdErr or "Unknown error"))
-- 				end
-- 			end, { "-c", script })
-- 			:start()
-- 		hs.alert.show("Result copied to clipboard!")
-- 	end)
-- end)

-- -- Interactive translation with UI prompt (doesn't auto-copy)
-- hs.hotkey.bind({ "cmd", "option", "shift" }, "x", function()
-- 	prompt_with_callback("Enter text to translate", function(text)
-- 		local script = string.format(
-- 			[[
--             export LANG=en_US.UTF-8
--             export LC_ALL=en_US.UTF-8
--             cd ~
--             source .zshrc
--             translate_from_to %q en es
--         ]],
-- 			text
-- 		)
--
-- 		hs.task
-- 			.new("/bin/zsh", function(exitCode, stdOut, stdErr)
-- 				if exitCode == 0 and stdOut and stdOut ~= "" then
-- 					local translation = stdOut:gsub("%s+$", "")
-- 					-- Show translation in a dialog instead of auto-copying
-- 					show_translation_result(text, translation)
-- 				else
-- 					hs.alert.show("Translation error: " .. (stdErr or "Unknown error"))
-- 				end
-- 			end, { "-c", script })
-- 			:start()
-- 	end)
-- end)

-- -- Function to show translation result with copy option
-- function show_translation_result(original, translation)
-- 	local dialog = hs.dialog.blockAlert(
-- 		"Translation Result",
-- 		string.format("Original: %s\n\nTranslation: %s", original, translation),
-- 		"Copy to Clipboard",
-- 		"Close"
-- 	)

-- 	if dialog == "Copy to Clipboard" then
-- 		hs.pasteboard.setContents(translation)
-- 		hs.alert.show("Translation copied!")
-- 	end
-- end

-- Interactive translation with real-time results in chooser
hs.hotkey.bind({ "ctrl", "option", "command" }, "t", function()
	translate_prompt_with_realtime()
end)

function translate_prompt_with_realtime()
	local chooser
	local debounceTimer = nil
	local lastTranslation = ""

	chooser = hs.chooser.new(function(choice)
		if not choice then
			return
		end

		-- If they selected the translation result, copy it
		if choice.translation then
			hs.pasteboard.setContents(choice.translation)
			hs.alert.show("Translation copied!")
			return
		end

		-- If they pressed enter on input, copy the translation if available
		if lastTranslation ~= "" then
			hs.pasteboard.setContents(lastTranslation)
			hs.alert.show("Translation copied!")
		end
	end)

	-- Function to perform translation
	-- NOTE: WIP: query edges cases like containing `" "` marks
	local function performTranslation(query)
		if query == "" then
			chooser:choices({ { ["text"] = query } })
			return
		end

		local script = string.format(
			[[
			export lang=en_us.utf-8
			export lc_all=en_us.utf-8
			cd ~
			source .zshrc
			translate=%q
			command -v $translate >/dev/null 2>&1 || { echo "error: $translate not found"; exit 1; }
			$translate %q
		    ]],
			"translate_from_to",
			query
		)

		hs.task
			.new("/bin/zsh", function(exitCode, stdOut, stdErr)
				if exitCode == 0 and stdOut and stdOut ~= "" then
					local translation = stdOut:gsub("%s+$", "")
					lastTranslation = translation

					-- Update chooser with input and translation
					chooser:choices({
						{
							["text"] = "→ " .. translation,
							["subText"] = "Translation (select to copy)",
							["translation"] = translation,
						},
					})
				else
					chooser:choices({
						{
							["text"] = query,
							["subText"] = "Input",
						},
						{
							["text"] = "❌ Translation failed",
							["subText"] = stdErr or "Unknown error",
						},
					})
				end
			end, { "-c", script })
			:start()
	end

	chooser:queryChangedCallback(function(query)
		-- Cancel previous timer
		if debounceTimer then
			debounceTimer:stop()
		end

		-- Set up debounced translation (500ms delay)
		debounceTimer = hs.timer.doAfter(0.5, function()
			performTranslation(query)
		end)

		-- Show input immediately
		chooser:choices({ { ["text"] = query, ["subText"] = "Translating..." } })
	end)

	chooser:placeholderText("Enter text to translate (EN→ES)")
	chooser:width(50)
	chooser:rows(2)
	chooser:show()
end

local clipboardActive = false
hs.hotkey.bind({ "option", "cmd", "shift" }, "v", function()
	if clipboardActive then
		-- spoon.ClipboardTool.stop()
		-- NOTE: LOL no stop() method so grok hack:
		spoon.ClipboardTool.shouldBeStored = function()
			return false
		end
		clipboardActive = false
		hs.alert.show("ClipboardTool Disabled")
	else
		spoon.ClipboardTool:start()
		clipboardActive = true
		hs.alert.show("ClipboardTool Enabled")
	end
end)

-- 1. Original “plain terminal” toggle -------------------------------------------------
local termBundle = "com.mitchellh.ghostty"

-- one helper that works for *any* terminal -------------------------------
local function launchTerminalTheRunCmd(opts)
	opts = opts or {} -- guard against nil
	local bundleID = opts.bundleID or "com.mitchellh.ghostty"
	local cmd = opts.cmd or error("opts.cmd required")
	local pollPeriod = opts.poll or 0.02 -- seconds
	local finalPause = opts.pause or 0.03 -- seconds
	local timeout = opts.timeout or 3 -- seconds

	-- 1. start the app if necessary
	local app = hs.application.get(bundleID)
	if not app then
		hs.application.launchOrFocusByBundleID(bundleID)
	end

	-- 2. poll until a window exists
	local poll
	poll = hs.timer.doEvery(pollPeriod, function()
		app = hs.application.get(bundleID)
		if app and #app:allWindows() > 0 then
			poll:stop()
			app:activate()
			hs.timer.doAfter(finalPause, function()
				hs.eventtap.keyStrokes(cmd)
				hs.eventtap.keyStroke({}, "return")
			end)
		end
	end)

	-- 3. safety kill-switch
	hs.timer.doAfter(timeout, function()
		if poll then
			poll:stop()
		end
	end)
end

local function launchTerminalWithCmd_og(opts)
	opts = opts or {}
	local cmd = opts.cmd or error("opts.cmd required")
	local bundleID = opts.bundleID or "com.mitchellh.ghostty"

	-- Explicitly source .zshrc before running command
	hs.execute(string.format("open -b %s --args -e zsh -c 'source ~/.zshrc && %s; exec zsh'", bundleID, cmd), true)
end

local function launchTerminalWithCmd(opts)
	opts = opts or {}
	local cmd = opts.cmd or error("opts.cmd required")
	local bundleID = opts.bundleID or "com.mitchellh.ghostty"

	local app = hs.application.get(bundleID)
	local newWindow = (app and app:isRunning()) and "n" or ""

	hs.execute(
		string.format("open -%sb %s --args -e zsh -c 'source ~/.zshrc && %s; exec zsh'", newWindow, bundleID, cmd),
		true
	)
end

hs.hotkey.bind({ "cmd", "alt" }, "r", function()
	launchTerminalWithCmd({ cmd = "recent_pick" })
end)

hs.hotkey.bind({ "cmd", "alt" }, "r", function()
	-- launchTerminalTheRunCmd({ cmd = "recent_pick" })
	launchTerminalWithCmd({ cmd = "recent_pick" })
end)

-- bind keys --------------------------------------------------------------
hs.hotkey.bind({ "cmd", "alt" }, "y", function()
	launchTerminalWithCmd({ cmd = "yazi" })
	-- launchTerminalTheRunCmd({ cmd = "yazi" })
	-- launchTerminalTheRunCmd({ cmd = "yazi", bundleID = "com.apple.Terminal" })
end)

-- hs.hotkey.bind({"cmd","alt"}, "r",
--   function() launchTerminalThenRunCmd{
--   bundleID = "com.apple.Terminal",
--   cmd      = "ranger",
--   poll     = 0.01,   -- 10 ms
--   pause    = 0.05,   -- 50 ms
--   timeout  = 5,
-- }end)
--

hs.hotkey.bind({ "cmd", "option" }, "/", function()
	-- runCommandInItermAndHitEnter("find_file")
	launchTerminalWithCmd({ cmd = "find_file" })
end)

hs.hotkey.bind({ "cmd" }, "/", function()
	-- runCommandInItermAndHitEnter("ruzzy")
	-- runCommandInItermAndHitEnter('cd "$(find_dirs_fuzzy_full)" && nvim .')
	-- runCommandInItermAndHitEnter('cd "$(find_dirs_fuzzy_full)" && yazi .')
	-- runCommandInItermAndHitEnter("cd $(fzf) && nvim .")
	--
	-- local command = 'cd "$(fd . "$HOME" --type d -H --max-depth 3 | fzf --prompt="Find Dir: ")" && nvim .'
	-- local command = "fcd_1_level"
	-- os.execute("cd ~ && find_dir_from_cache && exit")
	-- runCommandInItermAndHitEnter("find_dir_from_cache")

	-- runCommandInItermAndHitEnter("find_dir_from_cache 'emacs' && exit && killall ghostty")
	-- runCommandInItermAndHitEnter(string.format("find_dir_from_cache 'emacs' && killall %s", terminal_app_id))

	-- runCommandInItermAndHitEnter("find_dir_from_cache 'emacs'")
	launchTerminalWithCmd({ cmd = "find_dir_from_cache" })
end)
